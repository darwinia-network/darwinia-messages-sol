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
    print(testcases)
