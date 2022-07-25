import hashlib
import json
import os

import eth_tester
import pytest
from eth.vm.forks.berlin import BerlinVM
from eth_tester import EthereumTester, PyEVMBackend
from py_ecc.bls.ciphersuites import G2ProofOfPossession
from py_ecc.bls.g2_primatives import pubkey_to_G1, signature_to_G2
from py_ecc.optimized_bls12_381.optimized_curve import normalize
from web3 import Web3
from web3.providers.eth_tester import EthereumTesterProvider

DIR = os.path.dirname(__file__)

def _get_json(filename):
    with open(filename) as f:
        return json.load(f)

def get_bls_contract_json():
    filename = os.path.join(DIR, "../../../artifacts/src/utils/bls12381/BLS.sol/BLS.json")
    return _get_json(filename)

@pytest.fixture
def berlin_vm_configuration():
    return ((0, BerlinVM),)

@pytest.fixture
def tester(berlin_vm_configuration):
    return EthereumTester(PyEVMBackend(vm_configuration=berlin_vm_configuration))

@pytest.fixture
def w3(tester):
    web3 = Web3(EthereumTesterProvider(tester))
    return web3

def _deploy_contract(contract_json, w3, *args):
    contract_bytecode = contract_json["bytecode"]
    contract_abi = contract_json["abi"]
    registration = w3.eth.contract(abi=contract_abi, bytecode=contract_bytecode)
    tx_hash = registration.constructor(*args).transact()
    tx_receipt = w3.eth.waitForTransactionReceipt(tx_hash)
    contract_deployed = w3.eth.contract(
        address=tx_receipt.contractAddress, abi=contract_abi
    )
    return contract_deployed

@pytest.fixture
def deposit_contract(w3):
    return _deploy_contract(get_deposit_contract_json(), w3)

@pytest.fixture
def assert_tx_failed(tester):
    def assert_tx_failed(
        function_to_test, exception=eth_tester.exceptions.TransactionFailed
    ):
        snapshot_id = tester.take_snapshot()
        with pytest.raises(exception):
            function_to_test()
        tester.revert_to_snapshot(snapshot_id)

    return assert_tx_failed

@pytest.fixture
def seed():
    return "some-secret".encode()

@pytest.fixture
def bls_private_key(seed):
    return G2ProofOfPossession.KeyGen(seed)

@pytest.fixture
def bls_public_key(bls_private_key):
    return G2ProofOfPossession.SkToPk(bls_private_key)

@pytest.fixture
def signing_root():
    return bytes.fromhex('3a896ca4b5db102b9dfd47528b06220a91bd12461dcc86793ce2d591f41ea4f8')

@pytest.fixture
def signature(bls_private_key, signing_root):
    return G2ProofOfPossession.Sign(bls_private_key, signing_root)


@pytest.fixture
def public_key_witness(bls_public_key):
    group_element = pubkey_to_G1(bls_public_key)
    normalized_group_element = normalize(group_element)
    return normalized_group_element[1]


@pytest.fixture
def signature_witness(signature):
    print("---------------------------------------------------------------")
    print(signature.hex())
    group_element = signature_to_G2(signature)
    print(group_element)
    normalized_group_element = normalize(group_element)
    print(normalized_group_element)
    return normalized_group_element[1]

@pytest.fixture
def dst():
    return G2ProofOfPossession.DST
