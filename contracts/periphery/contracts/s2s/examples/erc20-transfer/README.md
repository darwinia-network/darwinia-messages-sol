## Pangolin SmartChain(PSC) -> Pangoro SmartChain(OSC)

This is a simple backing-issuing example which has no token remote-registeration process. The locked and issued ERC20 are specified.

Back tokens on the PSC and then issue tokens on the OSC.

#### Prepare:
  1. Deploy the same ERC20 to the PSC and OSC
  2. Deploy the `Issuing` contract to OSC. Here we get the `Issuing` contract address: `issuing_contract_address`  
  3. Deploy the `Backing` to PSC. Here we get a `Backing` contract address: `backing_contract_address`

#### On the OSC:
  4. Call `setSrcMessageSender(backing_contract_address)` of the `Issuing` contract

#### On the PSC:
  5. Call `lockAndRemoteIssue(..., issuing_contract_address, ...)` of the `Backing` contract  
     Note: the caller should must some tokens

#### On the OSC:
  6. Check if the recipient address has received the tokens.