# Wormhole Mapping Token Metadata Standards

Created At: September 16, 2021 10:10 AM
Last Edited At: September 26, 2021 10:50 PM
Project: Wormhole
Reviewers: Anonymous
Status: Final

## Specification

```jsx
mapping(token) = {symbol: token_prefix + token.symbol, name: token.name + name_postfix, ...}
```

### Proposal

1. symbol prefix: "x"

    Example: If the original symbol is "RING", the mapping token's symbol will be "xRING". If this token is mapped to a third chain further, the symbol will be "xxRING".

2. name postfix: "[${backing_chain_short_name}>"

    Example: If RING is mapped from Darwinia to Crab, assume RING's name on Darwinia is "Darwinia Network Native Token" (Note: it is using balances pallet instead of ERC20, so the name was newly created in Backing Pallet).  The mapping ERC20 token's name on Crab will be "Darwinia Network Native Token[Darwinia>", the token is mapped from Crab to Moonriver again, the name will be "Darwinia Network Native Token[Darwinia>[Crab>"

## Supported Token Types

### ERC20:

[ERC-20 Token Standard | ethereum.org](https://ethereum.org/en/developers/docs/standards/tokens/erc-20/)

### Substrate Balances:

[substrate/frame/balances at master · paritytech/substrate](https://github.com/paritytech/substrate/tree/master/frame/balances)

### ERC721:

[EIP-721: Non-Fungible Token Standard](https://eips.ethereum.org/EIPS/eip-721)

### ERC1155(Not supported, TBD):

> Metadata Choices

> The symbol-function (found in the ERC-20 and ERC-721 standards) was not included as we do not believe this is a globally useful piece of data to identify a generic virtual item/asset and are also prone to collisions. Short-hand symbols are used in tickers and currency trading, but they aren’t as useful outside of that space.

> The name function (for human-readable asset names, on-chain) was removed from the standard to allow the Metadata JSON to be the definitive asset name and reduce duplication of data. This also allows localization for names, which would otherwise be prohibitively expensive if each language string was stored on-chain, not to mention bloating the standard interface. While this decision may add a small burden on implementers to host a JSON file containing metadata, we believe any serious implementation of ERC-1155 will already utilize JSON Metadata.

[EIP-1155: Multi Token Standard](https://eips.ethereum.org/EIPS/eip-1155#rationale)

### Substrate Assets(TBD):

[substrate/frame/assets at master · paritytech/substrate](https://github.com/paritytech/substrate/tree/master/frame/assets)