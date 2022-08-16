# Claims

# How to prepare a claim

## Generating JSON file with every asset and associated data

You have to use (or create) a script using the graph or other data source depending on the context, to create a JSON file containing asset IDs and amounts.

JSON format:

```json
[
  {
    "to": "0x9E7A5b836Da4d55D681Eed4495370e96295c785f", // recipient of the assets
    "erc1155": [
      {
        "ids": [
          // array of asset id
          "106914169990095390281037231343508379541260342522117732053367995686304065005572",
          "106914169990095390281037231343508379541260342522117732053367995686304065005568"
        ],
        "values": [
          // array of amount for each asset id
          1,
          1
        ],
        "contractAddress": "0xa342f5D851E866E18ff98F351f2c6637f4478dB5" // address of asset contract (most of the time our contract 0xa342f5D851E866E18ff98F351f2c6637f4478dB5)
      }
    ],
    "erc721": [], // empty
    "erc20": {
      // empty
      "amounts": [],
      "contractAddresses": []
    }
  }
]
```

Save your script (if you had to create one) in the repos and add the link to it in the first paragraph of the _Claims Template_ file.
Save also your JSON file in the `data/<network>/<claim_name>_salt` folder.

Note:
- we use the strictly unique incremental ID for `salt`.
- `to` should be unique in the same json.

## Execute script to gen merkle root and proofs

### Generate merkle root and proofs

`yarn gen <network> <claim_name> <salt>`

example:

`yarn gen mumbai test 1`

After the script execution, proof locate at `data/<network>/proof/<claim_name>_salt`
and merkle root locate at `data/<network>/root/<claim_name>_salt`

### Add merkle root to claims contract

### Verify the proof to ensure the root is right
