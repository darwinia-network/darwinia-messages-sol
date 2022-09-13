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
[UpgradeableProxy.constructor(address,bytes)](flat/ChainMessageCommitterProxy.f.sol#L302-L308) ignores return value by [Address.functionDelegateCall(_logic,_data)](flat/ChainMessageCommitterProxy.f.sol#L306)

flat/ChainMessageCommitterProxy.f.sol#L302-L308


 - [ ] ID-1
[TransparentUpgradeableProxy.upgradeToAndCall(address,bytes)](flat/ChainMessageCommitterProxy.f.sol#L473-L476) ignores return value by [Address.functionDelegateCall(newImplementation,data)](flat/ChainMessageCommitterProxy.f.sol#L475)

flat/ChainMessageCommitterProxy.f.sol#L473-L476


## shadowing-local
Impact: Low
Confidence: High
 - [ ] ID-2
[ChainMessageCommitterProxy.constructor(address,address,bytes)._admin](flat/ChainMessageCommitterProxy.f.sol#L534) shadows:
	- [TransparentUpgradeableProxy._admin()](flat/ChainMessageCommitterProxy.f.sol#L481-L487) (function)

flat/ChainMessageCommitterProxy.f.sol#L534


## incorrect-modifier
Impact: Low
Confidence: High
 - [ ] ID-3
Modifier [TransparentUpgradeableProxy.ifAdmin()](flat/ChainMessageCommitterProxy.f.sol#L410-L416) does not always execute _; or revert
flat/ChainMessageCommitterProxy.f.sol#L410-L416


## assembly
Impact: Informational
Confidence: High
 - [ ] ID-4
[UpgradeableProxy._setImplementation(address)](flat/ChainMessageCommitterProxy.f.sol#L346-L355) uses assembly
	- [INLINE ASM](flat/ChainMessageCommitterProxy.f.sol#L352-L354)

flat/ChainMessageCommitterProxy.f.sol#L346-L355


 - [ ] ID-5
[TransparentUpgradeableProxy._admin()](flat/ChainMessageCommitterProxy.f.sol#L481-L487) uses assembly
	- [INLINE ASM](flat/ChainMessageCommitterProxy.f.sol#L484-L486)

flat/ChainMessageCommitterProxy.f.sol#L481-L487


 - [ ] ID-6
[UpgradeableProxy._implementation()](flat/ChainMessageCommitterProxy.f.sol#L325-L331) uses assembly
	- [INLINE ASM](flat/ChainMessageCommitterProxy.f.sol#L328-L330)

flat/ChainMessageCommitterProxy.f.sol#L325-L331


 - [ ] ID-7
[Address._verifyCallResult(bool,bytes,string)](flat/ChainMessageCommitterProxy.f.sol#L175-L192) uses assembly
	- [INLINE ASM](flat/ChainMessageCommitterProxy.f.sol#L184-L187)

flat/ChainMessageCommitterProxy.f.sol#L175-L192


 - [ ] ID-8
[Proxy._delegate(address)](flat/ChainMessageCommitterProxy.f.sol#L215-L235) uses assembly
	- [INLINE ASM](flat/ChainMessageCommitterProxy.f.sol#L217-L234)

flat/ChainMessageCommitterProxy.f.sol#L215-L235


 - [ ] ID-9
[TransparentUpgradeableProxy._setAdmin(address)](flat/ChainMessageCommitterProxy.f.sol#L492-L499) uses assembly
	- [INLINE ASM](flat/ChainMessageCommitterProxy.f.sol#L496-L498)

flat/ChainMessageCommitterProxy.f.sol#L492-L499


 - [ ] ID-10
[Address.isContract(address)](flat/ChainMessageCommitterProxy.f.sol#L30-L39) uses assembly
	- [INLINE ASM](flat/ChainMessageCommitterProxy.f.sol#L37)

flat/ChainMessageCommitterProxy.f.sol#L30-L39


## low-level-calls
Impact: Informational
Confidence: High
 - [ ] ID-11
Low level call in [Address.functionStaticCall(address,bytes,string)](flat/ChainMessageCommitterProxy.f.sol#L143-L149):
	- [(success,returndata) = target.staticcall(data)](flat/ChainMessageCommitterProxy.f.sol#L147)

flat/ChainMessageCommitterProxy.f.sol#L143-L149


 - [ ] ID-12
Low level call in [Address.functionDelegateCall(address,bytes,string)](flat/ChainMessageCommitterProxy.f.sol#L167-L173):
	- [(success,returndata) = target.delegatecall(data)](flat/ChainMessageCommitterProxy.f.sol#L171)

flat/ChainMessageCommitterProxy.f.sol#L167-L173


 - [ ] ID-13
Low level call in [Address.sendValue(address,uint256)](flat/ChainMessageCommitterProxy.f.sol#L57-L63):
	- [(success) = recipient.call{value: amount}()](flat/ChainMessageCommitterProxy.f.sol#L61)

flat/ChainMessageCommitterProxy.f.sol#L57-L63


 - [ ] ID-14
Low level call in [Address.functionCallWithValue(address,bytes,uint256,string)](flat/ChainMessageCommitterProxy.f.sol#L118-L125):
	- [(success,returndata) = target.call{value: value}(data)](flat/ChainMessageCommitterProxy.f.sol#L123)

flat/ChainMessageCommitterProxy.f.sol#L118-L125


