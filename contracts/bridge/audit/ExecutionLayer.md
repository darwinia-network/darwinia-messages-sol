Summary
 - [locked-ether](#locked-ether) (1 results) (Medium)
 - [missing-zero-check](#missing-zero-check) (1 results) (Low)
 - [assembly](#assembly) (2 results) (Informational)
 - [low-level-calls](#low-level-calls) (4 results) (Informational)
 - [similar-names](#similar-names) (1 results) (Informational)
 - [external-function](#external-function) (2 results) (Optimization)
## locked-ether
Impact: Medium
Confidence: High
 - [ ] ID-0
Contract locking ether found:
	Contract [ExecutionLayer](flat/ExecutionLayer.f.sol#L478-L529) has payable functions:
	 - [ExecutionLayer.import_latest_execution_payload_state_root(ExecutionLayer.ExecutionPayloadStateRootUpdate)](flat/ExecutionLayer.f.sol#L505-L514)
	But does not have a function to withdraw the ether

flat/ExecutionLayer.f.sol#L478-L529


## missing-zero-check
Impact: Low
Confidence: Medium
 - [ ] ID-1
[ExecutionLayer.constructor(address).consensus_layer](flat/ExecutionLayer.f.sol#L495) lacks a zero-check on :
		- [CONSENSUS_LAYER = consensus_layer](flat/ExecutionLayer.f.sol#L496)

flat/ExecutionLayer.f.sol#L495


## assembly
Impact: Informational
Confidence: High
 - [ ] ID-2
[Address._verifyCallResult(bool,bytes,string)](flat/ExecutionLayer.f.sol#L199-L216) uses assembly
	- [INLINE ASM](flat/ExecutionLayer.f.sol#L208-L211)

flat/ExecutionLayer.f.sol#L199-L216


 - [ ] ID-3
[Address.isContract(address)](flat/ExecutionLayer.f.sol#L54-L63) uses assembly
	- [INLINE ASM](flat/ExecutionLayer.f.sol#L61)

flat/ExecutionLayer.f.sol#L54-L63


## low-level-calls
Impact: Informational
Confidence: High
 - [ ] ID-4
Low level call in [Address.functionCallWithValue(address,bytes,uint256,string)](flat/ExecutionLayer.f.sol#L142-L149):
	- [(success,returndata) = target.call{value: value}(data)](flat/ExecutionLayer.f.sol#L147)

flat/ExecutionLayer.f.sol#L142-L149


 - [ ] ID-5
Low level call in [Address.sendValue(address,uint256)](flat/ExecutionLayer.f.sol#L81-L87):
	- [(success) = recipient.call{value: amount}()](flat/ExecutionLayer.f.sol#L85)

flat/ExecutionLayer.f.sol#L81-L87


 - [ ] ID-6
Low level call in [Address.functionDelegateCall(address,bytes,string)](flat/ExecutionLayer.f.sol#L191-L197):
	- [(success,returndata) = target.delegatecall(data)](flat/ExecutionLayer.f.sol#L195)

flat/ExecutionLayer.f.sol#L191-L197


 - [ ] ID-7
Low level call in [Address.functionStaticCall(address,bytes,string)](flat/ExecutionLayer.f.sol#L167-L173):
	- [(success,returndata) = target.staticcall(data)](flat/ExecutionLayer.f.sol#L171)

flat/ExecutionLayer.f.sol#L167-L173


## similar-names
Impact: Informational
Confidence: Medium
 - [ ] ID-8
Variable [ExecutionLayer.LATEST_EXECUTION_PAYLOAD_STATE_ROOT_DEPTH](flat/ExecutionLayer.f.sol#L484) is too similar to [ExecutionLayer.LATEST_EXECUTION_PAYLOAD_STATE_ROOT_INDEX](flat/ExecutionLayer.f.sol#L483)

flat/ExecutionLayer.f.sol#L484


## external-function
Impact: Optimization
Confidence: High
 - [ ] ID-9
merkle_root() should be declared external:
	- [ExecutionLayer.merkle_root()](flat/ExecutionLayer.f.sol#L501-L503)

flat/ExecutionLayer.f.sol#L501-L503


 - [ ] ID-10
initialize() should be declared external:
	- [ExecutionLayer.initialize()](flat/ExecutionLayer.f.sol#L499)

flat/ExecutionLayer.f.sol#L499


