Summary
 - [events-access](#events-access) (1 results) (Low)
 - [missing-zero-check](#missing-zero-check) (1 results) (Low)
 - [calls-loop](#calls-loop) (1 results) (Low)
 - [assembly](#assembly) (1 results) (Informational)
 - [external-function](#external-function) (2 results) (Optimization)
## events-access
Impact: Low
Confidence: Medium
 - [ ] ID-0
[LaneMessageCommitter.changeSetter(address)](flat/LaneMessageCommitter.f.sol#L318-L320) should emit an event for: 
	- [setter = _setter](flat/LaneMessageCommitter.f.sol#L319) 

flat/LaneMessageCommitter.f.sol#L318-L320


## missing-zero-check
Impact: Low
Confidence: Medium
 - [ ] ID-1
[LaneMessageCommitter.changeSetter(address)._setter](flat/LaneMessageCommitter.f.sol#L318) lacks a zero-check on :
		- [setter = _setter](flat/LaneMessageCommitter.f.sol#L319)

flat/LaneMessageCommitter.f.sol#L318


## calls-loop
Impact: Low
Confidence: Medium
 - [ ] ID-2
[MessageCommitter.commitment(uint256)](flat/LaneMessageCommitter.f.sol#L183-L190) has external calls inside a loop: [IMessageCommitter(leaf).commitment()](flat/LaneMessageCommitter.f.sol#L188)

flat/LaneMessageCommitter.f.sol#L183-L190


## assembly
Impact: Informational
Confidence: High
 - [ ] ID-3
[MessageCommitter.hash_node(bytes32,bytes32)](flat/LaneMessageCommitter.f.sol#L236-L246) uses assembly
	- [INLINE ASM](flat/LaneMessageCommitter.f.sol#L241-L245)

flat/LaneMessageCommitter.f.sol#L236-L246


## external-function
Impact: Optimization
Confidence: High
 - [ ] ID-4
proof(uint256) should be declared external:
	- [MessageCommitter.proof(uint256)](flat/LaneMessageCommitter.f.sol#L192-L200)

flat/LaneMessageCommitter.f.sol#L192-L200


 - [ ] ID-5
commitment() should be declared external:
	- [MessageCommitter.commitment()](flat/LaneMessageCommitter.f.sol#L163-L177)

flat/LaneMessageCommitter.f.sol#L163-L177


