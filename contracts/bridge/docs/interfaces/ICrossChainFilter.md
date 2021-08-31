# ICrossChainFilter


The app layer must implement the interface `ICrossChainFilter`


## Contents
<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [Functions](#functions)
  - [crossChainFilter](#crosschainfilter)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->




## Functions

### crossChainFilter
Verify the source sender and payload of source chain messages,
Generally, app layer cross-chain messages require validation of sourceAccount



#### Declaration
```solidity
  function crossChainFilter(
    address sourceAccount,
    bytes payload
  ) external returns (bool)
```

#### Modifiers:
No modifiers

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`sourceAccount` | address | The derived DVM address of pallet ID which send the message
|`payload` | bytes | The calldata which encoded by ABI Encoding

#### Returns:
| Type | Description |
| --- | --- |
|`Can` | call target contract if returns true


