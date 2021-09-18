>> graph init --product subgraph-studio. --abi
✔ Product for which to initialize · hosted-service
✔ Subgraph name · wormhole/DarwiniaMappingTokenFactory
✔ Directory to create the subgraph in · DarwiniaMappingTokenFactory
✔ Ethereum network · ropsten
✔ Contract address · 0xCBe0c1ac9eFF75f2002158A1635974caaac3A811
✔ ABI file (path) · ../../contracts/mapping-token/abi/contracts/darwinia/DarwiniaMappingTokenFactory.sol/DarwiniaMappingTokenFactory.json
✔ Contract Name · DarwiniaMappingTokenFactory
———
  Generate subgraph from ABI
  Write subgraph to directory
✔ Create subgraph scaffold
✔ Initialize subgraph repository
✔ Install dependencies with yarn
✔ Generate ABI and schema types with yarn codegen

Subgraph wormhole/DarwiniaMappingTokenFactory created in DarwiniaMappingTokenFactory

Next steps:

  1. Run `graph auth` to authenticate with your deploy key.

  2. Type `cd DarwiniaMappingTokenFactory` to enter the subgraph.

  3. Run `yarn deploy` to deploy the subgraph.

Make sure to visit the documentation on https://thegraph.com/docs/ for further information.

This will generate a named ExampleEntity entity in schema.graphql. This maybe not suitable for our project.
So we need to modify schema.graphql and regenerate the schema files.

>> npx graph codegen --output-dir generated/
  Skip migration: Bump mapping apiVersion from 0.0.1 to 0.0.2
  Skip migration: Bump mapping apiVersion from 0.0.2 to 0.0.3
  Skip migration: Bump mapping apiVersion from 0.0.3 to 0.0.4
  Skip migration: Bump mapping specVersion from 0.0.1 to 0.0.2
✔ Apply migrations
✔ Load subgraph from subgraph.yaml
  Load contract ABI from abis/DarwiniaMappingTokenFactory.json
✔ Load contract ABIs
  Generate types for contract ABI: DarwiniaMappingTokenFactory (abis/DarwiniaMappingTokenFactory.json)
  Write types to generated/DarwiniaMappingTokenFactory/DarwiniaMappingTokenFactory.ts
✔ Generate types for contract ABIs
✔ Generate types for data source templates
✔ Load data source template ABIs
✔ Generate types for data source template ABIs
✔ Load GraphQL schema from schema.graphql
  Write types to generated/schema.ts
✔ Generate types for GraphQL schema

Types generated successfully

Then we need modify the logic file src/mapping.ts

Then create subgraph on subnode
>> npx graph create wormhole/DarwiniaMappingTokenFactory --node http://127.0.0.1:8020
Created subgraph: wormhole/DarwiniaMappingTokenFactory

The last step, deploy
>> npx graph deploy wormhole/DarwiniaMappingTokenFactory --ipfs http://localhost:5001 --node http://localhost:8020
✔ Version Label (e.g. v0.0.1) ·
  Skip migration: Bump mapping apiVersion from 0.0.1 to 0.0.2
  Skip migration: Bump mapping apiVersion from 0.0.2 to 0.0.3
  Skip migration: Bump mapping apiVersion from 0.0.3 to 0.0.4
  Skip migration: Bump mapping specVersion from 0.0.1 to 0.0.2
✔ Apply migrations
✔ Load subgraph from subgraph.yaml
  Compile data source: DarwiniaMappingTokenFactory => build/DarwiniaMappingTokenFactory/DarwiniaMappingTokenFactory.wasm
✔ Compile subgraph
  Copy schema file build/schema.graphql
  Write subgraph file build/DarwiniaMappingTokenFactory/abis/DarwiniaMappingTokenFactory.json
  Write subgraph manifest build/subgraph.yaml
✔ Write compiled subgraph to build/
  Add file to IPFS build/schema.graphql
                .. QmVRyRF12mxYcKAd9YfsiXkeHHc79wkU5LqWLDinrfnmbg
  Add file to IPFS build/DarwiniaMappingTokenFactory/abis/DarwiniaMappingTokenFactory.json
                .. QmTDhpdjATMtKcmxoeAR9nZ59fhhm2cJ1xuQ5dikJiWNyL
  Add file to IPFS build/DarwiniaMappingTokenFactory/DarwiniaMappingTokenFactory.wasm
                .. QmTDJcE1hZ1cbSa9kTx7iGVQ5VM2H8XVg7tQKCRwz3iSwZ
✔ Upload subgraph to IPFS

Build completed: QmSAjoWQcHa9B56DGuE3WTSahWR3dTy7d7VpVNuWj3VFmS

Deployed to http://localhost:8000/subgraphs/name/wormhole/DarwiniaMappingTokenFactory/graphql

Subgraph endpoints:
Queries (HTTP):     http://localhost:8000/subgraphs/name/wormhole/DarwiniaMappingTokenFactory
Subscriptions (WS): http://localhost:8001/subgraphs/name/wormhole/DarwiniaMappingTokenFactory

