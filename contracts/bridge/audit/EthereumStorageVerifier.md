Summary
 - [events-access](#events-access) (1 results) (Low)
 - [missing-zero-check](#missing-zero-check) (1 results) (Low)
 - [variable-scope](#variable-scope) (2 results) (Low)
 - [assembly](#assembly) (9 results) (Informational)
## events-access
Impact: Low
Confidence: Medium
 - [ ] ID-0
[StorageVerifier.changeSetter(address)](flat/EthereumStorageVerifier.f.sol#L1547-L1549) should emit an event for: 
	- [setter = _setter](flat/EthereumStorageVerifier.f.sol#L1548) 

flat/EthereumStorageVerifier.f.sol#L1547-L1549


## missing-zero-check
Impact: Low
Confidence: Medium
 - [ ] ID-1
[StorageVerifier.changeSetter(address)._setter](flat/EthereumStorageVerifier.f.sol#L1547) lacks a zero-check on :
		- [setter = _setter](flat/EthereumStorageVerifier.f.sol#L1548)

flat/EthereumStorageVerifier.f.sol#L1547


## variable-scope
Impact: Low
Confidence: High
 - [ ] ID-2
Variable '[RLPDecode._decodeLength(RLPDecode.RLPItem).strLen](flat/EthereumStorageVerifier.f.sol#L584)' in [RLPDecode._decodeLength(RLPDecode.RLPItem)](flat/EthereumStorageVerifier.f.sol#L559-L628) potentially used before declaration: [strLen = mload(uint256)(ptr + 1) / 256 ** 32 - lenOfStrLen](flat/EthereumStorageVerifier.f.sol#L598)

flat/EthereumStorageVerifier.f.sol#L584


 - [ ] ID-3
Variable '[RLPDecode._decodeLength(RLPDecode.RLPItem).listLen](flat/EthereumStorageVerifier.f.sol#L607)' in [RLPDecode._decodeLength(RLPDecode.RLPItem)](flat/EthereumStorageVerifier.f.sol#L559-L628) potentially used before declaration: [listLen = mload(uint256)(ptr + 1) / 256 ** 32 - lenOfListLen](flat/EthereumStorageVerifier.f.sol#L621)

flat/EthereumStorageVerifier.f.sol#L607


## assembly
Impact: Informational
Confidence: High
 - [ ] ID-4
[BytesUtils.toBytes32(bytes)](flat/EthereumStorageVerifier.f.sol#L828-L838) uses assembly
	- [INLINE ASM](flat/EthereumStorageVerifier.f.sol#L831-L833)

flat/EthereumStorageVerifier.f.sol#L828-L838


 - [ ] ID-5
[RLPDecode._decodeLength(RLPDecode.RLPItem)](flat/EthereumStorageVerifier.f.sol#L559-L628) uses assembly
	- [INLINE ASM](flat/EthereumStorageVerifier.f.sol#L572-L574)
	- [INLINE ASM](flat/EthereumStorageVerifier.f.sol#L596-L599)
	- [INLINE ASM](flat/EthereumStorageVerifier.f.sol#L619-L622)

flat/EthereumStorageVerifier.f.sol#L559-L628


 - [ ] ID-6
[RLPDecode.readBytes32(RLPDecode.RLPItem)](flat/EthereumStorageVerifier.f.sol#L439-L458) uses assembly
	- [INLINE ASM](flat/EthereumStorageVerifier.f.sol#L448-L455)

flat/EthereumStorageVerifier.f.sol#L439-L458


 - [ ] ID-7
[RLPDecode.toRLPItem(bytes)](flat/EthereumStorageVerifier.f.sol#L337-L344) uses assembly
	- [INLINE ASM](flat/EthereumStorageVerifier.f.sol#L339-L341)

flat/EthereumStorageVerifier.f.sol#L337-L344


 - [ ] ID-8
[StorageVerifier.toUint(bytes)](flat/EthereumStorageVerifier.f.sol#L1720-L1729) uses assembly
	- [INLINE ASM](flat/EthereumStorageVerifier.f.sol#L1726-L1728)

flat/EthereumStorageVerifier.f.sol#L1720-L1729


 - [ ] ID-9
[RLPDecode._copy(uint256,uint256,uint256)](flat/EthereumStorageVerifier.f.sol#L637-L670) uses assembly
	- [INLINE ASM](flat/EthereumStorageVerifier.f.sol#L649-L651)
	- [INLINE ASM](flat/EthereumStorageVerifier.f.sol#L655-L657)
	- [INLINE ASM](flat/EthereumStorageVerifier.f.sol#L666-L668)

flat/EthereumStorageVerifier.f.sol#L637-L670


 - [ ] ID-10
[BytesUtils.slice(bytes,uint256,uint256)](flat/EthereumStorageVerifier.f.sol#L753-L818) uses assembly
	- [INLINE ASM](flat/EthereumStorageVerifier.f.sol#L764-L815)

flat/EthereumStorageVerifier.f.sol#L753-L818


 - [ ] ID-11
[RLPDecode.readList(RLPDecode.RLPItem)](flat/EthereumStorageVerifier.f.sol#L351-L383) uses assembly
	- [INLINE ASM](flat/EthereumStorageVerifier.f.sol#L378-L380)

flat/EthereumStorageVerifier.f.sol#L351-L383


 - [ ] ID-12
[RLPDecode.readBool(RLPDecode.RLPItem)](flat/EthereumStorageVerifier.f.sol#L492-L504) uses assembly
	- [INLINE ASM](flat/EthereumStorageVerifier.f.sol#L497-L499)

flat/EthereumStorageVerifier.f.sol#L492-L504


