import hashlib
import secrets

from eth_utils import to_tuple, keccak
from py_ecc.bls.g2_primatives import pubkey_to_G1, signature_to_G2
from py_ecc.bls.hash import expand_message_xmd
from py_ecc.bls.hash_to_curve import (
    clear_cofactor_G2,
    hash_to_field_FQ2,
    hash_to_G2,
    map_to_curve_G2,
)
from py_ecc.bls import G2ProofOfPossession
from py_ecc.optimized_bls12_381 import FQ2, normalize

def test_expand_message_matches_spec(bls_contract, signing_root, dst):
    result = bls_contract.functions.expand_message_xmd(signing_root).call()

    spec_result = expand_message_xmd(signing_root, dst, 256, hashlib.sha256)

    assert result == spec_result

def _convert_int_to_fp_repr(field_element):
    element_as_bytes = int(field_element).to_bytes(48, byteorder="big")
    a_bytes = element_as_bytes[:16]
    b_bytes = element_as_bytes[16:]
    return (
        int.from_bytes(a_bytes, byteorder="big"),
        int.from_bytes(b_bytes, byteorder="big"),
    )

def _serialize_uncompressed_g1(g1):
    x = int(g1[0]).to_bytes(48, byteorder="big")
    y = int(g1[1]).to_bytes(48, byteorder="big")
    return x + y

@to_tuple
def _convert_int_to_fp2_repr(field_element):
    for coeff in field_element.coeffs:
        yield _convert_int_to_fp_repr(coeff)

def _convert_fp_to_int(fp_repr):
    a, b = fp_repr
    a_bytes = a.to_bytes(16, byteorder="big")
    b_bytes = b.to_bytes(32, byteorder="big")
    full_bytes = b"".join((a_bytes, b_bytes))
    return int.from_bytes(full_bytes, byteorder="big")

def _convert_fp2_to_int(fp2_repr):
    a, b = fp2_repr
    return FQ2((_convert_fp_to_int(a), _convert_fp_to_int(b)))

def test_hash_to_field_matches_spec(bls_contract, signing_root, dst):
    result = bls_contract.functions.hash_to_field_fq2(signing_root).call()
    converted_result = tuple(_convert_fp2_to_int(fp2_repr) for fp2_repr in result)

    spec_result = hash_to_field_FQ2(signing_root, 2, dst, hashlib.sha256)

    assert converted_result == spec_result

def test_map_to_curve_matches_spec(bls_contract, signing_root):
    field_elements_parts = bls_contract.functions.hash_to_field_fq2(signing_root).call()
    field_elements = tuple(
        _convert_fp2_to_int(fp2_repr) for fp2_repr in field_elements_parts
    )

    # NOTE: mapToCurve (called below) precompile includes "clearing the cofactor"
    first_group_element = normalize(
        clear_cofactor_G2(map_to_curve_G2(field_elements[0]))
    )

    computed_first_group_element_parts = bls_contract.functions.map_to_curve(
        field_elements_parts[0]
    ).call()
    computed_first_group_element = tuple(
        _convert_fp2_to_int(fp2_repr) for fp2_repr in computed_first_group_element_parts
    )
    assert computed_first_group_element == first_group_element

    second_group_element = normalize(
        clear_cofactor_G2(map_to_curve_G2(field_elements[1]))
    )

    computed_second_group_element_parts = bls_contract.functions.map_to_curve(
        field_elements_parts[1]
    ).call()

    computed_second_group_element = tuple(
        _convert_fp2_to_int(fp2_repr)
        for fp2_repr in computed_second_group_element_parts
    )
    assert computed_second_group_element == second_group_element

def test_hash_to_curve_matches_spec(bls_contract, signing_root, dst):
    result = bls_contract.functions.hash_to_curve_g2(signing_root).call()
    converted_result = tuple(_convert_fp2_to_int(fp2_repr) for fp2_repr in result)

    spec_result = normalize(hash_to_G2(signing_root, dst, hashlib.sha256))

    assert converted_result == spec_result

def test_bls_pairing_check(bls_contract, signing_root, bls_public_key, signature):
    public_key_point = pubkey_to_G1(bls_public_key)
    public_key = normalize(public_key_point)
    public_key_repr = (
        _convert_int_to_fp_repr(public_key[0]),
        _convert_int_to_fp_repr(public_key[1]),
    )

    message_on_curve = bls_contract.functions.hash_to_curve_g2(signing_root).call()

    projective_signature_point = signature_to_G2(signature)
    signature_point = normalize(projective_signature_point)
    signature_repr = (
        _convert_int_to_fp2_repr(signature_point[0]),
        _convert_int_to_fp2_repr(signature_point[1]),
    )

    assert bls_contract.functions.bls_pairing_check(
        public_key_repr, message_on_curve, signature_repr
    ).call()

def test_deserialize_g1(bls_contract):
    g1 = bytes.fromhex('0802ed05cd0f8b5a7e53915959a91d105f61c3e6a3483281a677de70456cbe80c4367d8bf1727dd7cbfb3c20dd2067db04563a80ae1e8c140e1a2a9681e390b6ce39c1920742c5cc2005a12b0ebf143d51e511feb83169624999b12e0700ae75')
    p = bls_contract.functions.deserialize_g1(g1).call()
    e = ((10649015950676493634620504066709069072, 43142456839214771564757806897632051492022874594939430609558377413119351744475), (5764636087822793275149787389346681014, 93278493064807042609479760054494757548897347451312429333844174966115434278517))

    assert p == e

    s = bls_contract.functions.serialize_g1(p).call()
    compressed_p = bytes.fromhex('8802ed05cd0f8b5a7e53915959a91d105f61c3e6a3483281a677de70456cbe80c4367d8bf1727dd7cbfb3c20dd2067db')

    assert s == compressed_p

def test_deserialize_g2(bls_contract):
    g2 = bytes.fromhex('016d4c6b8cd9345709d083ea4c4188c8b91800a3a1caafc06ce2f906c1f76b60cb34dbeb7bb502507bb4075b61a965a60c26952837b1f30e3725cffadd55033ec62f9360659c68188b7192f4e641f39bc15a8b8847e942c5218f7eae57ed215e0a6bb39fd7b06d281beffb5f467375531c51fcd6806da645632f411647fc311789f21c8f23b6a07c591ecfe2defe5ef00a900e323870437512d5fd969791096cd9d9447a9a93d1820c5dd4b2788481415083449cfc94e7da3eb1e808f1e9afa3')
    p = bls_contract.functions.deserialize_g2(g2).call()
    e = (((16151068495437561801725848888167170878, 89642002987100070632632767689389170464052999910370829768562836973736617124190), (1896738337498964084125711630950566088, 83720285728968929179342853752928184368010530093097347811765285655377967932838)), ((14040258638087629544122117905280207212, 98535766579769692703063581988100677270816044198382309708122405093706635521955), (13851498937061842235997261836865205587, 12809619395611566517490361690486986994655575793052973210605792449286148873968)))

    assert p == e

    s = bls_contract.functions.serialize_g2(p).call()
    compressed_p = bytes.fromhex('816d4c6b8cd9345709d083ea4c4188c8b91800a3a1caafc06ce2f906c1f76b60cb34dbeb7bb502507bb4075b61a965a60c26952837b1f30e3725cffadd55033ec62f9360659c68188b7192f4e641f39bc15a8b8847e942c5218f7eae57ed215e')

    assert s == compressed_p

def test_aggregate_pks(bls_contract):
    pks = [
bytes.fromhex('a572cbea904d67468808c8eb50a9450c9721db309128012543902d0ac358a62ae28f75bb8f1c7c42c39a8c5529bf0f4e'),
bytes.fromhex('89ece308f9d1f0131765212deca99697b112d61f9be9a5f1f3780a51335b3ff981747a0b2ca2179b96d2c0c9024e5224')
            ]
    uncompressed_pubkeys = [normalize(pubkey_to_G1(pk)) for pk in pks]
    serialized_pks = [ _serialize_uncompressed_g1(pk) for pk in uncompressed_pubkeys ]

    agg_pk = bls_contract.functions.aggregate_pks(serialized_pks).call();
    s_agg_pk = bls_contract.functions.serialize_g1(agg_pk).call();

    e_pk = bytes.fromhex('b0e7791fb972fe014159aa33a98622da3cdc98ff707965e536d8636b5fcc5ac7a91a8c46e59a00dca575af0f18fb13dc')

    assert s_agg_pk == e_pk

