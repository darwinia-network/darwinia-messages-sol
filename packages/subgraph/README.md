* Step 1. Init the project use abi
```
>> graph init --product subgraph-studio. --abi
✔ Product for which to initialize · hosted-service
✔ Subgraph name · wormhole/Sub2SubMappingTokenFactory
✔ Directory to create the subgraph in · Sub2SubMappingTokenFactory
✔ Ethereum network · ropsten
✔ Contract address · 0xCBe0c1ac9eFF75f2002158A1635974caaac3A811
✔ ABI file (path) · ../../contracts/mapping-token/abi/contracts/darwinia/Sub2SubMappingTokenFactory.sol/Sub2SubMappingTokenFactory.json
✔ Contract Name · Sub2SubMappingTokenFactory
———
  Generate subgraph from ABI
  Write subgraph to directory
✔ Create subgraph scaffold
✔ Initialize subgraph repository
✔ Install dependencies with yarn
✔ Generate ABI and schema types with yarn codegen

Subgraph wormhole/Sub2SubMappingTokenFactory created in Sub2SubMappingTokenFactory

Next steps:

  1. Run `graph auth` to authenticate with your deploy key.

  2. Type `cd Sub2SubMappingTokenFactory` to enter the subgraph.

  3. Run `yarn deploy` to deploy the subgraph.

Make sure to visit the documentation on https://thegraph.com/docs/ for further information.
```

* Step 2. Modify schema.graphql to define the entity.

Last step will generate a named ExampleEntity entity in schema.graphql. This maybe not suitable for our project.
So we need to modify schema.graphql and regenerate the schema files.
```
>> npx graph codegen --output-dir generated/
  Skip migration: Bump mapping apiVersion from 0.0.1 to 0.0.2
  Skip migration: Bump mapping apiVersion from 0.0.2 to 0.0.3
  Skip migration: Bump mapping apiVersion from 0.0.3 to 0.0.4
  Skip migration: Bump mapping specVersion from 0.0.1 to 0.0.2
✔ Apply migrations
✔ Load subgraph from subgraph.yaml
  Load contract ABI from abis/Sub2SubMappingTokenFactory.json
✔ Load contract ABIs
  Generate types for contract ABI: Sub2SubMappingTokenFactory (abis/Sub2SubMappingTokenFactory.json)
  Write types to generated/Sub2SubMappingTokenFactory/Sub2SubMappingTokenFactory.ts
✔ Generate types for contract ABIs
✔ Generate types for data source templates
✔ Load data source template ABIs
✔ Generate types for data source template ABIs
✔ Load GraphQL schema from schema.graphql
  Write types to generated/schema.ts
✔ Generate types for GraphQL schema

Types generated successfully
```

* Step 3. Modify the logic file src/mapping.ts

* Step 4. Create subgraph on subnode
```
>> npx graph create wormhole/Sub2SubMappingTokenFactory --node http://127.0.0.1:8020
Created subgraph: wormhole/Sub2SubMappingTokenFactory
```

* Step 5. The last step, deploy
```
>> npx graph deploy wormhole/Sub2SubMappingTokenFactory --ipfs http://localhost:5001 --node http://localhost:8020
✔ Version Label (e.g. v0.0.1) ·
  Skip migration: Bump mapping apiVersion from 0.0.1 to 0.0.2
  Skip migration: Bump mapping apiVersion from 0.0.2 to 0.0.3
  Skip migration: Bump mapping apiVersion from 0.0.3 to 0.0.4
  Skip migration: Bump mapping specVersion from 0.0.1 to 0.0.2
✔ Apply migrations
✔ Load subgraph from subgraph.yaml
  Compile data source: Sub2SubMappingTokenFactory => build/Sub2SubMappingTokenFactory/Sub2SubMappingTokenFactory.wasm
✔ Compile subgraph
  Copy schema file build/schema.graphql
  Write subgraph file build/Sub2SubMappingTokenFactory/abis/Sub2SubMappingTokenFactory.json
  Write subgraph manifest build/subgraph.yaml
✔ Write compiled subgraph to build/
  Add file to IPFS build/schema.graphql
                .. QmVRyRF12mxYcKAd9YfsiXkeHHc79wkU5LqWLDinrfnmbg
  Add file to IPFS build/Sub2SubMappingTokenFactory/abis/Sub2SubMappingTokenFactory.json
                .. QmTDhpdjATMtKcmxoeAR9nZ59fhhm2cJ1xuQ5dikJiWNyL
  Add file to IPFS build/Sub2SubMappingTokenFactory/Sub2SubMappingTokenFactory.wasm
                .. QmTDJcE1hZ1cbSa9kTx7iGVQ5VM2H8XVg7tQKCRwz3iSwZ
✔ Upload subgraph to IPFS

Build completed: QmSAjoWQcHa9B56DGuE3WTSahWR3dTy7d7VpVNuWj3VFmS

Deployed to http://localhost:8000/subgraphs/name/wormhole/Sub2SubMappingTokenFactory/graphql

Subgraph endpoints:
Queries (HTTP):     http://localhost:8000/subgraphs/name/wormhole/Sub2SubMappingTokenFactory
Subscriptions (WS): http://localhost:8001/subgraphs/name/wormhole/Sub2SubMappingTokenFactory
```
