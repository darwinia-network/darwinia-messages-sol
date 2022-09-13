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
[TransparentUpgradeableProxy.upgradeToAndCall(address,bytes)](flat/FeeMarketProxy.f.sol#L473-L476) ignores return value by [Address.functionDelegateCall(newImplementation,data)](flat/FeeMarketProxy.f.sol#L475)

flat/FeeMarketProxy.f.sol#L473-L476


 - [ ] ID-1
[UpgradeableProxy.constructor(address,bytes)](flat/FeeMarketProxy.f.sol#L302-L308) ignores return value by [Address.functionDelegateCall(_logic,_data)](flat/FeeMarketProxy.f.sol#L306)

flat/FeeMarketProxy.f.sol#L302-L308


## shadowing-local
Impact: Low
Confidence: High
 - [ ] ID-2
[FeeMarketProxy.constructor(address,address,bytes)._admin](flat/FeeMarketProxy.f.sol#L534) shadows:
	- [TransparentUpgradeableProxy._admin()](flat/FeeMarketProxy.f.sol#L481-L487) (function)

flat/FeeMarketProxy.f.sol#L534


## incorrect-modifier
Impact: Low
Confidence: High
 - [ ] ID-3
Modifier [TransparentUpgradeableProxy.ifAdmin()](flat/FeeMarketProxy.f.sol#L410-L416) does not always execute _; or revert
flat/FeeMarketProxy.f.sol#L410-L416


## assembly
Impact: Informational
Confidence: High
 - [ ] ID-4
[Address._verifyCallResult(bool,bytes,string)](flat/FeeMarketProxy.f.sol#L175-L192) uses assembly
	- [INLINE ASM](flat/FeeMarketProxy.f.sol#L184-L187)

flat/FeeMarketProxy.f.sol#L175-L192


 - [ ] ID-5
[UpgradeableProxy._implementation()](flat/FeeMarketProxy.f.sol#L325-L331) uses assembly
	- [INLINE ASM](flat/FeeMarketProxy.f.sol#L328-L330)

flat/FeeMarketProxy.f.sol#L325-L331


 - [ ] ID-6
[UpgradeableProxy._setImplementation(address)](flat/FeeMarketProxy.f.sol#L346-L355) uses assembly
	- [INLINE ASM](flat/FeeMarketProxy.f.sol#L352-L354)

flat/FeeMarketProxy.f.sol#L346-L355


 - [ ] ID-7
[Proxy._delegate(address)](flat/FeeMarketProxy.f.sol#L215-L235) uses assembly
	- [INLINE ASM](flat/FeeMarketProxy.f.sol#L217-L234)

flat/FeeMarketProxy.f.sol#L215-L235


 - [ ] ID-8
[TransparentUpgradeableProxy._setAdmin(address)](flat/FeeMarketProxy.f.sol#L492-L499) uses assembly
	- [INLINE ASM](flat/FeeMarketProxy.f.sol#L496-L498)

flat/FeeMarketProxy.f.sol#L492-L499


 - [ ] ID-9
[TransparentUpgradeableProxy._admin()](flat/FeeMarketProxy.f.sol#L481-L487) uses assembly
	- [INLINE ASM](flat/FeeMarketProxy.f.sol#L484-L486)

flat/FeeMarketProxy.f.sol#L481-L487


 - [ ] ID-10
[Address.isContract(address)](flat/FeeMarketProxy.f.sol#L30-L39) uses assembly
	- [INLINE ASM](flat/FeeMarketProxy.f.sol#L37)

flat/FeeMarketProxy.f.sol#L30-L39


## low-level-calls
Impact: Informational
Confidence: High
 - [ ] ID-11
Low level call in [Address.sendValue(address,uint256)](flat/FeeMarketProxy.f.sol#L57-L63):
	- [(success) = recipient.call{value: amount}()](flat/FeeMarketProxy.f.sol#L61)

flat/FeeMarketProxy.f.sol#L57-L63


 - [ ] ID-12
Low level call in [Address.functionDelegateCall(address,bytes,string)](flat/FeeMarketProxy.f.sol#L167-L173):
	- [(success,returndata) = target.delegatecall(data)](flat/FeeMarketProxy.f.sol#L171)

flat/FeeMarketProxy.f.sol#L167-L173


 - [ ] ID-13
Low level call in [Address.functionStaticCall(address,bytes,string)](flat/FeeMarketProxy.f.sol#L143-L149):
	- [(success,returndata) = target.staticcall(data)](flat/FeeMarketProxy.f.sol#L147)

flat/FeeMarketProxy.f.sol#L143-L149


 - [ ] ID-14
Low level call in [Address.functionCallWithValue(address,bytes,uint256,string)](flat/FeeMarketProxy.f.sol#L118-L125):
	- [(success,returndata) = target.call{value: value}(data)](flat/FeeMarketProxy.f.sol#L123)

flat/FeeMarketProxy.f.sol#L118-L125


