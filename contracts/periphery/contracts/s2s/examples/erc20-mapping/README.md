## Pangolin SmartChain(PSC) -> Pangoro SmartChain(OSC)

#### Prepare:
  1. Deploy the same ERC20 to the PSC and OSC
  2. Deploy the `Issuing` contract to OSC. Here we get a `Issuing` contract address
  3. Update the `Issuing` contract address in the `Backing.sol`
  4. Deploy the `Backing` to PSC. Here we get a `Backing` contract address
  5. Call `setRemoteSender(contractAddressOfBacking)` of the `Issuing` contract
  6. Call `lockAndRemoteIssue` of the `Backing` contract

#### On the PSC:
  1. Send some tokens your PSC address
  2. Use your PSC address to call `lockAndRemoteIssue`

#### On the OSC:
  3. Check if the recipient address has received tokens.