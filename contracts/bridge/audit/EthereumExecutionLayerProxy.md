Summary
 - [unused-return](#unused-return) (2 results) (Medium)
 - [shadowing-local](#shadowing-local) (1 results) (Low)
 - [incorrect-modifier](#incorrect-modifier) (1 results) (Low)
 - [assembly](#assembly) (7 results) (Informational)
 - [low-level-calls](#low-level-calls) (4 results) (Informational)
## unused-return
Impact: Medium
Confidence: Medium
 - [ ] ID-0
[TransparentUpgradeableProxy.upgradeToAndCall(address,bytes)](flat/EthereumExecutionLayerProxy.f.sol#L473-L476) ignores return value by [Address.functionDelegateCall(newImplementation,data)](flat/EthereumExecutionLayerProxy.f.sol#L475)

flat/EthereumExecutionLayerProxy.f.sol#L473-L476


 - [ ] ID-1
[UpgradeableProxy.constructor(address,bytes)](flat/EthereumExecutionLayerProxy.f.sol#L302-L308) ignores return value by [Address.functionDelegateCall(_logic,_data)](flat/EthereumExecutionLayerProxy.f.sol#L306)

flat/EthereumExecutionLayerProxy.f.sol#L302-L308


## shadowing-local
Impact: Low
Confidence: High
 - [ ] ID-2
[EthereumExecutionLayerProxy.constructor(address,address,bytes)._admin](flat/EthereumExecutionLayerProxy.f.sol#L534) shadows:
	- [TransparentUpgradeableProxy._admin()](flat/EthereumExecutionLayerProxy.f.sol#L481-L487) (function)

flat/EthereumExecutionLayerProxy.f.sol#L534


## incorrect-modifier
Impact: Low
Confidence: High
 - [ ] ID-3
Modifier [TransparentUpgradeableProxy.ifAdmin()](flat/EthereumExecutionLayerProxy.f.sol#L410-L416) does not always execute _; or revert
flat/EthereumExecutionLayerProxy.f.sol#L410-L416


## assembly
Impact: Informational
Confidence: High
 - [ ] ID-4
[UpgradeableProxy._implementation()](flat/EthereumExecutionLayerProxy.f.sol#L325-L331) uses assembly
	- [INLINE ASM](flat/EthereumExecutionLayerProxy.f.sol#L328-L330)

flat/EthereumExecutionLayerProxy.f.sol#L325-L331


 - [ ] ID-5
[Address._verifyCallResult(bool,bytes,string)](flat/EthereumExecutionLayerProxy.f.sol#L175-L192) uses assembly
	- [INLINE ASM](flat/EthereumExecutionLayerProxy.f.sol#L184-L187)

flat/EthereumExecutionLayerProxy.f.sol#L175-L192


 - [ ] ID-6
[UpgradeableProxy._setImplementation(address)](flat/EthereumExecutionLayerProxy.f.sol#L346-L355) uses assembly
	- [INLINE ASM](flat/EthereumExecutionLayerProxy.f.sol#L352-L354)

flat/EthereumExecutionLayerProxy.f.sol#L346-L355


 - [ ] ID-7
[TransparentUpgradeableProxy._setAdmin(address)](flat/EthereumExecutionLayerProxy.f.sol#L492-L499) uses assembly
	- [INLINE ASM](flat/EthereumExecutionLayerProxy.f.sol#L496-L498)

flat/EthereumExecutionLayerProxy.f.sol#L492-L499


 - [ ] ID-8
[Proxy._delegate(address)](flat/EthereumExecutionLayerProxy.f.sol#L215-L235) uses assembly
	- [INLINE ASM](flat/EthereumExecutionLayerProxy.f.sol#L217-L234)

flat/EthereumExecutionLayerProxy.f.sol#L215-L235


 - [ ] ID-9
[Address.isContract(address)](flat/EthereumExecutionLayerProxy.f.sol#L30-L39) uses assembly
	- [INLINE ASM](flat/EthereumExecutionLayerProxy.f.sol#L37)

flat/EthereumExecutionLayerProxy.f.sol#L30-L39


 - [ ] ID-10
[TransparentUpgradeableProxy._admin()](flat/EthereumExecutionLayerProxy.f.sol#L481-L487) uses assembly
	- [INLINE ASM](flat/EthereumExecutionLayerProxy.f.sol#L484-L486)

flat/EthereumExecutionLayerProxy.f.sol#L481-L487


## low-level-calls
Impact: Informational
Confidence: High
 - [ ] ID-11
Low level call in [Address.functionDelegateCall(address,bytes,string)](flat/EthereumExecutionLayerProxy.f.sol#L167-L173):
	- [(success,returndata) = target.delegatecall(data)](flat/EthereumExecutionLayerProxy.f.sol#L171)

flat/EthereumExecutionLayerProxy.f.sol#L167-L173


 - [ ] ID-12
Low level call in [Address.sendValue(address,uint256)](flat/EthereumExecutionLayerProxy.f.sol#L57-L63):
	- [(success) = recipient.call{value: amount}()](flat/EthereumExecutionLayerProxy.f.sol#L61)

flat/EthereumExecutionLayerProxy.f.sol#L57-L63


 - [ ] ID-13
Low level call in [Address.functionStaticCall(address,bytes,string)](flat/EthereumExecutionLayerProxy.f.sol#L143-L149):
	- [(success,returndata) = target.staticcall(data)](flat/EthereumExecutionLayerProxy.f.sol#L147)

flat/EthereumExecutionLayerProxy.f.sol#L143-L149


 - [ ] ID-14
Low level call in [Address.functionCallWithValue(address,bytes,uint256,string)](flat/EthereumExecutionLayerProxy.f.sol#L118-L125):
	- [(success,returndata) = target.call{value: value}(data)](flat/EthereumExecutionLayerProxy.f.sol#L123)

flat/EthereumExecutionLayerProxy.f.sol#L118-L125


