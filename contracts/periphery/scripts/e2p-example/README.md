## Goerli > Pangolin2 > Parachain example

1. setup
   - setup the goerli endpoint and pangolin 2 endpoint,
   - setup the caller2 contract as the Dapp.
```bash
node ./scripts/e2p-example/setup.js
```

1. do a cross-chain call from the caller2
```bash
node ./scripts/e2p-example/dispatch-on-parachain.js <caller2Address>
```