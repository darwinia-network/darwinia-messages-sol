# Darwinia Bridge Solidity

## Packages
```
.
├── contracts
│   ├── bridge
│   ├── issuing-burn
│   ├── mapping-token
│   ├── tokens
│   ├── utils
│   └── verify
└── packages
    ├── addresses
    └── assets
```

### Install dependencies

Make sure you are using Yarn v1.22.10. To install using brew:

```bash
brew install yarn@1.22.10
```

Then install dependencies

```bash
yarn install
```

### Environment variables

`.env` example:

```bash
MAINNET_RPC_URL="https://eth-mainnet.alchemyapi.io/v2/your-api-key"
RINKEBY_RPC_URL="https://eth-rinkeby.alchemyapi.io/v2/your-api-key" 
ROPSTEN_RPC_URL="https://eth-ropsten.alchemyapi.io/v2/your-api-key"
KOVAN_RPC_URL="https://eth-kovan.alchemyapi.io/v2/your-api-key" 
PRIVATE_KEY=your private key 
ETHERSCAN_API_KEY="Your etherscan API key" (optional)
```

### Build

To build all packages:

```bash
yarn build
```

To build a specific package:

```bash
PKG=@darwinia/contracts-bridge yarn build
```

To build all contracts packages:

```bash
yarn build:contracts
```

### Clean

Clean all packages:

```bash
yarn clean
```

Clean a specific package

```bash
PKG=@darwinia/contracts-bridge yarn clean
```

### Rebuild

To re-build (clean & build) all packages:

```bash
yarn rebuild
```

To re-build (clean & build) a specific package & it's deps:

```bash
PKG=@darwinia/contracts-bridge yarn rebuild
```

