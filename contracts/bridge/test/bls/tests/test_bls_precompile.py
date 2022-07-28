import os
import json

DIR = os.path.dirname(__file__)

def _load_json(filename):
    filepath = f"../case/12381/{filename}.json"
    path = os.path.join(DIR, filepath)
    with open(path) as f:
        return json.load(f)

def test_g1_add(bls_contract):
    testcases = _load_json('blsG1Add')
    for testcase in testcases:
        name = testcase['Name']
        print(name)
        i = testcase['Input']
        e = testcase['Expected']
        o = bls_contract.functions.add_g1(i).call()
        assert e == o.hex()


def test_g2_add(bls_contract):
    testcases = _load_json('blsG2Add')
    for testcase in testcases:
        name = testcase['Name']
        print(name)
        i = testcase['Input']
        e = testcase['Expected']
        o = bls_contract.functions.add_g2(i).call()
        assert e == o.hex()


def test_g2_mul(bls_contract):
    testcases = _load_json('blsG2Mul')
    for testcase in testcases:
        name = testcase['Name']
        print(name)
        i = testcase['Input']
        e = testcase['Expected']
        o = bls_contract.functions.mul_g2(i).call()
        assert e == o.hex()


def test_map_g2(bls_contract):
    testcases = _load_json('blsMapG2')
    for testcase in testcases:
        name = testcase['Name']
        print(name)
        i = testcase['Input']
        e = testcase['Expected']
        o = bls_contract.functions.map_to_curve_g2(i).call()
        assert e == o.hex()


def test_pairing(bls_contract):
    testcases = _load_json('blsPairing')
    for testcase in testcases:
        name = testcase['Name']
        print(name)
        i = testcase['Input']
        e = testcase['Expected']
        o = bls_contract.functions.pairing(i).call()
        assert e == o.hex()


# def test_map_g1(bls_contract):
#     testcases = _load_json('blsMapG1')
#     for testcase in testcases:
#         name = testcase['Name']
#         print(name)
#         i = testcase['Input']
#         e = testcase['Expected']
#         print(i)
#         print(e)
#         o = bls_contract.functions.add_g1(i).call()
#         print(o.hex())
#         assert e == o.hex()

