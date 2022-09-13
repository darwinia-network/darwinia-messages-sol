Summary
 - [unused-return](#unused-return) (2 results) (Medium)
 - [incorrect-modifier](#incorrect-modifier) (1 results) (Low)
 - [assembly](#assembly) (7 results) (Informational)
 - [low-level-calls](#low-level-calls) (6 results) (Informational)
 - [redundant-statements](#redundant-statements) (1 results) (Informational)
 - [external-function](#external-function) (7 results) (Optimization)
## unused-return
Impact: Medium
Confidence: Medium
 - [ ] ID-0
[UpgradeableProxy.constructor(address,bytes)](flat/BridgeProxyAdmin.f.sol#L397-L403) ignores return value by [Address.functionDelegateCall(_logic,_data)](flat/BridgeProxyAdmin.f.sol#L401)

flat/BridgeProxyAdmin.f.sol#L397-L403


 - [ ] ID-1
[TransparentUpgradeableProxy.upgradeToAndCall(address,bytes)](flat/BridgeProxyAdmin.f.sol#L568-L571) ignores return value by [Address.functionDelegateCall(newImplementation,data)](flat/BridgeProxyAdmin.f.sol#L570)

flat/BridgeProxyAdmin.f.sol#L568-L571


## incorrect-modifier
Impact: Low
Confidence: High
 - [ ] ID-2
Modifier [TransparentUpgradeableProxy.ifAdmin()](flat/BridgeProxyAdmin.f.sol#L505-L511) does not always execute _; or revert
flat/BridgeProxyAdmin.f.sol#L505-L511


## assembly
Impact: Informational
Confidence: High
 - [ ] ID-3
[TransparentUpgradeableProxy._setAdmin(address)](flat/BridgeProxyAdmin.f.sol#L587-L594) uses assembly
	- [INLINE ASM](flat/BridgeProxyAdmin.f.sol#L591-L593)

flat/BridgeProxyAdmin.f.sol#L587-L594


 - [ ] ID-4
[Address.isContract(address)](flat/BridgeProxyAdmin.f.sol#L125-L134) uses assembly
	- [INLINE ASM](flat/BridgeProxyAdmin.f.sol#L132)

flat/BridgeProxyAdmin.f.sol#L125-L134


 - [ ] ID-5
[UpgradeableProxy._implementation()](flat/BridgeProxyAdmin.f.sol#L420-L426) uses assembly
	- [INLINE ASM](flat/BridgeProxyAdmin.f.sol#L423-L425)

flat/BridgeProxyAdmin.f.sol#L420-L426


 - [ ] ID-6
[UpgradeableProxy._setImplementation(address)](flat/BridgeProxyAdmin.f.sol#L441-L450) uses assembly
	- [INLINE ASM](flat/BridgeProxyAdmin.f.sol#L447-L449)

flat/BridgeProxyAdmin.f.sol#L441-L450


 - [ ] ID-7
[Address._verifyCallResult(bool,bytes,string)](flat/BridgeProxyAdmin.f.sol#L270-L287) uses assembly
	- [INLINE ASM](flat/BridgeProxyAdmin.f.sol#L279-L282)

flat/BridgeProxyAdmin.f.sol#L270-L287


 - [ ] ID-8
[Proxy._delegate(address)](flat/BridgeProxyAdmin.f.sol#L310-L330) uses assembly
	- [INLINE ASM](flat/BridgeProxyAdmin.f.sol#L312-L329)

flat/BridgeProxyAdmin.f.sol#L310-L330


 - [ ] ID-9
[TransparentUpgradeableProxy._admin()](flat/BridgeProxyAdmin.f.sol#L576-L582) uses assembly
	- [INLINE ASM](flat/BridgeProxyAdmin.f.sol#L579-L581)

flat/BridgeProxyAdmin.f.sol#L576-L582


## low-level-calls
Impact: Informational
Confidence: High
 - [ ] ID-10
Low level call in [Address.functionCallWithValue(address,bytes,uint256,string)](flat/BridgeProxyAdmin.f.sol#L213-L220):
	- [(success,returndata) = target.call{value: value}(data)](flat/BridgeProxyAdmin.f.sol#L218)

flat/BridgeProxyAdmin.f.sol#L213-L220


 - [ ] ID-11
Low level call in [Address.sendValue(address,uint256)](flat/BridgeProxyAdmin.f.sol#L152-L158):
	- [(success) = recipient.call{value: amount}()](flat/BridgeProxyAdmin.f.sol#L156)

flat/BridgeProxyAdmin.f.sol#L152-L158


 - [ ] ID-12
Low level call in [Address.functionStaticCall(address,bytes,string)](flat/BridgeProxyAdmin.f.sol#L238-L244):
	- [(success,returndata) = target.staticcall(data)](flat/BridgeProxyAdmin.f.sol#L242)

flat/BridgeProxyAdmin.f.sol#L238-L244


 - [ ] ID-13
Low level call in [ProxyAdmin.getProxyImplementation(TransparentUpgradeableProxy)](flat/BridgeProxyAdmin.f.sol#L625-L631):
	- [(success,returndata) = address(proxy).staticcall(0x5c60da1b)](flat/BridgeProxyAdmin.f.sol#L628)

flat/BridgeProxyAdmin.f.sol#L625-L631


 - [ ] ID-14
Low level call in [ProxyAdmin.getProxyAdmin(TransparentUpgradeableProxy)](flat/BridgeProxyAdmin.f.sol#L640-L646):
	- [(success,returndata) = address(proxy).staticcall(0xf851a440)](flat/BridgeProxyAdmin.f.sol#L643)

flat/BridgeProxyAdmin.f.sol#L640-L646


 - [ ] ID-15
Low level call in [Address.functionDelegateCall(address,bytes,string)](flat/BridgeProxyAdmin.f.sol#L262-L268):
	- [(success,returndata) = target.delegatecall(data)](flat/BridgeProxyAdmin.f.sol#L266)

flat/BridgeProxyAdmin.f.sol#L262-L268


## redundant-statements
Impact: Informational
Confidence: High
 - [ ] ID-16
Redundant expression "[this](flat/BridgeProxyAdmin.f.sol#L25)" in[Context](flat/BridgeProxyAdmin.f.sol#L19-L28)

flat/BridgeProxyAdmin.f.sol#L25


## external-function
Impact: Optimization
Confidence: High
 - [ ] ID-17
renounceOwnership() should be declared external:
	- [Ownable.renounceOwnership()](flat/BridgeProxyAdmin.f.sol#L84-L87)

flat/BridgeProxyAdmin.f.sol#L84-L87


 - [ ] ID-18
upgradeAndCall(TransparentUpgradeableProxy,address,bytes) should be declared external:
	- [ProxyAdmin.upgradeAndCall(TransparentUpgradeableProxy,address,bytes)](flat/BridgeProxyAdmin.f.sol#L678-L680)

flat/BridgeProxyAdmin.f.sol#L678-L680


 - [ ] ID-19
getProxyAdmin(TransparentUpgradeableProxy) should be declared external:
	- [ProxyAdmin.getProxyAdmin(TransparentUpgradeableProxy)](flat/BridgeProxyAdmin.f.sol#L640-L646)

flat/BridgeProxyAdmin.f.sol#L640-L646


 - [ ] ID-20
getProxyImplementation(TransparentUpgradeableProxy) should be declared external:
	- [ProxyAdmin.getProxyImplementation(TransparentUpgradeableProxy)](flat/BridgeProxyAdmin.f.sol#L625-L631)

flat/BridgeProxyAdmin.f.sol#L625-L631


 - [ ] ID-21
transferOwnership(address) should be declared external:
	- [Ownable.transferOwnership(address)](flat/BridgeProxyAdmin.f.sol#L93-L97)

flat/BridgeProxyAdmin.f.sol#L93-L97


 - [ ] ID-22
changeProxyAdmin(TransparentUpgradeableProxy,address) should be declared external:
	- [ProxyAdmin.changeProxyAdmin(TransparentUpgradeableProxy,address)](flat/BridgeProxyAdmin.f.sol#L655-L657)

flat/BridgeProxyAdmin.f.sol#L655-L657


 - [ ] ID-23
upgrade(TransparentUpgradeableProxy,address) should be declared external:
	- [ProxyAdmin.upgrade(TransparentUpgradeableProxy,address)](flat/BridgeProxyAdmin.f.sol#L666-L668)

flat/BridgeProxyAdmin.f.sol#L666-L668


