Summary
 - [reentrancy-events](#reentrancy-events) (1 results) (Low)
 - [low-level-calls](#low-level-calls) (2 results) (Informational)
 - [too-many-digits](#too-many-digits) (1 results) (Informational)
 - [external-function](#external-function) (1 results) (Optimization)
## reentrancy-events
Impact: Low
Confidence: Medium
 - [ ] ID-0
Reentrancy in [InboundLane._receive_message(SourceChain.Message[])](flat/InboundLane.f.sol#L733-L780):
	External calls:
	- [dispatch_result = _dispatch(message_payload)](flat/InboundLane.f.sol#L762)
		- [(dispatch_result,None) = payload.target.call{gas: MAX_GAS_PER_MESSAGE}(payload.encoded)](flat/InboundLane.f.sol#L801)
	Event emitted after the call(s):
	- [MessageDispatched(key.nonce,dispatch_result)](flat/InboundLane.f.sol#L764)

flat/InboundLane.f.sol#L733-L780


## low-level-calls
Impact: Informational
Confidence: High
 - [ ] ID-1
Low level call in [InboundLane._filter(address,bytes)](flat/InboundLane.f.sol#L812-L819):
	- [(ok,result) = target.staticcall{gas: GAS_BUFFER}(encoded)](flat/InboundLane.f.sol#L813)

flat/InboundLane.f.sol#L812-L819


 - [ ] ID-2
Low level call in [InboundLane._dispatch(SourceChain.MessagePayload)](flat/InboundLane.f.sol#L790-L803):
	- [(dispatch_result,None) = payload.target.call{gas: MAX_GAS_PER_MESSAGE}(payload.encoded)](flat/InboundLane.f.sol#L801)

flat/InboundLane.f.sol#L790-L803


## too-many-digits
Impact: Informational
Confidence: Medium
 - [ ] ID-3
[InboundLane.slitherConstructorConstantVariables()](flat/InboundLane.f.sol#L548-L820) uses literals with too many digits:
	- [MAX_GAS_PER_MESSAGE = 200000](flat/InboundLane.f.sol#L569)

flat/InboundLane.f.sol#L548-L820


## external-function
Impact: Optimization
Confidence: High
 - [ ] ID-4
encodeMessageKey(uint64) should be declared external:
	- [InboundLaneVerifier.encodeMessageKey(uint64)](flat/InboundLane.f.sol#L162-L169)

flat/InboundLane.f.sol#L162-L169


