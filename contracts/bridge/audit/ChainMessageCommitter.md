Summary
 - [events-access](#events-access) (1 results) (Low)
 - [missing-zero-check](#missing-zero-check) (1 results) (Low)
 - [calls-loop](#calls-loop) (1 results) (Low)
 - [assembly](#assembly) (3 results) (Informational)
 - [low-level-calls](#low-level-calls) (4 results) (Informational)
 - [external-function](#external-function) (2 results) (Optimization)
## events-access
Impact: Low
Confidence: Medium
 - [ ] ID-0
[ChainMessageCommitter.changeSetter(address)](flat/ChainMessageCommitter.f.sol#L640-L642) should emit an event for: 
	- [setter = _setter](flat/ChainMessageCommitter.f.sol#L641) 

flat/ChainMessageCommitter.f.sol#L640-L642


## missing-zero-check
Impact: Low
Confidence: Medium
 - [ ] ID-1
[ChainMessageCommitter.changeSetter(address)._setter](flat/ChainMessageCommitter.f.sol#L640) lacks a zero-check on :
		- [setter = _setter](flat/ChainMessageCommitter.f.sol#L641)

flat/ChainMessageCommitter.f.sol#L640


## calls-loop
Impact: Low
Confidence: Medium
 - [ ] ID-2
[MessageCommitter.commitment(uint256)](flat/ChainMessageCommitter.f.sol#L502-L509) has external calls inside a loop: [IMessageCommitter(leaf).commitment()](flat/ChainMessageCommitter.f.sol#L507)

flat/ChainMessageCommitter.f.sol#L502-L509


## assembly
Impact: Informational
Confidence: High
 - [ ] ID-3
[MessageCommitter.hash_node(bytes32,bytes32)](flat/ChainMessageCommitter.f.sol#L555-L565) uses assembly
	- [INLINE ASM](flat/ChainMessageCommitter.f.sol#L560-L564)

flat/ChainMessageCommitter.f.sol#L555-L565


 - [ ] ID-4
[Address.isContract(address)](flat/ChainMessageCommitter.f.sol#L92-L101) uses assembly
	- [INLINE ASM](flat/ChainMessageCommitter.f.sol#L99)

flat/ChainMessageCommitter.f.sol#L92-L101


 - [ ] ID-5
[Address._verifyCallResult(bool,bytes,string)](flat/ChainMessageCommitter.f.sol#L237-L254) uses assembly
	- [INLINE ASM](flat/ChainMessageCommitter.f.sol#L246-L249)

flat/ChainMessageCommitter.f.sol#L237-L254


## low-level-calls
Impact: Informational
Confidence: High
 - [ ] ID-6
Low level call in [Address.functionCallWithValue(address,bytes,uint256,string)](flat/ChainMessageCommitter.f.sol#L180-L187):
	- [(success,returndata) = target.call{value: value}(data)](flat/ChainMessageCommitter.f.sol#L185)

flat/ChainMessageCommitter.f.sol#L180-L187


 - [ ] ID-7
Low level call in [Address.functionDelegateCall(address,bytes,string)](flat/ChainMessageCommitter.f.sol#L229-L235):
	- [(success,returndata) = target.delegatecall(data)](flat/ChainMessageCommitter.f.sol#L233)

flat/ChainMessageCommitter.f.sol#L229-L235


 - [ ] ID-8
Low level call in [Address.functionStaticCall(address,bytes,string)](flat/ChainMessageCommitter.f.sol#L205-L211):
	- [(success,returndata) = target.staticcall(data)](flat/ChainMessageCommitter.f.sol#L209)

flat/ChainMessageCommitter.f.sol#L205-L211


 - [ ] ID-9
Low level call in [Address.sendValue(address,uint256)](flat/ChainMessageCommitter.f.sol#L119-L125):
	- [(success) = recipient.call{value: amount}()](flat/ChainMessageCommitter.f.sol#L123)

flat/ChainMessageCommitter.f.sol#L119-L125


## external-function
Impact: Optimization
Confidence: High
 - [ ] ID-10
initialize() should be declared external:
	- [ChainMessageCommitter.initialize()](flat/ChainMessageCommitter.f.sol#L620-L622)

flat/ChainMessageCommitter.f.sol#L620-L622


 - [ ] ID-11
commitment() should be declared external:
	- [MessageCommitter.commitment()](flat/ChainMessageCommitter.f.sol#L482-L496)

flat/ChainMessageCommitter.f.sol#L482-L496


