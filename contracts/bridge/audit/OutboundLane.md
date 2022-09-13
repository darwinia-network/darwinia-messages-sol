Summary
 - [reentrancy-eth](#reentrancy-eth) (1 results) (High)
 - [missing-zero-check](#missing-zero-check) (1 results) (Low)
 - [reentrancy-benign](#reentrancy-benign) (1 results) (Low)
 - [reentrancy-events](#reentrancy-events) (1 results) (Low)
## reentrancy-eth
Impact: High
Confidence: Medium
 - [ ] ID-0
Reentrancy in [OutboundLane.send_message(address,bytes)](flat/OutboundLane.f.sol#L655-L680):
	External calls:
	- [require(bool,string)(IFeeMarket(FEE_MARKET).assign{value: msg.value}(encoded_key),AssignRelayersFailed)](flat/OutboundLane.f.sol#L664)
	State variables written after the call(s):
	- [outboundLaneNonce.latest_generated_nonce = nonce](flat/OutboundLane.f.sol#L666)
	- [_prune_messages(MAX_PRUNE_MESSAGES_ATONCE)](flat/OutboundLane.f.sol#L674)
		- [outboundLaneNonce.oldest_unpruned_nonce = nonce.oldest_unpruned_nonce](flat/OutboundLane.f.sol#L797)

flat/OutboundLane.f.sol#L655-L680


## missing-zero-check
Impact: Low
Confidence: Medium
 - [ ] ID-1
[OutboundLane.constructor(address,address,uint32,uint32,uint32,uint32,uint64,uint64,uint64)._feeMarket](flat/OutboundLane.f.sol#L626) lacks a zero-check on :
		- [FEE_MARKET = _feeMarket](flat/OutboundLane.f.sol#L646)

flat/OutboundLane.f.sol#L626


## reentrancy-benign
Impact: Low
Confidence: Medium
 - [ ] ID-2
Reentrancy in [OutboundLane.send_message(address,bytes)](flat/OutboundLane.f.sol#L655-L680):
	External calls:
	- [require(bool,string)(IFeeMarket(FEE_MARKET).assign{value: msg.value}(encoded_key),AssignRelayersFailed)](flat/OutboundLane.f.sol#L664)
	State variables written after the call(s):
	- [messages[nonce] = hash(payload)](flat/OutboundLane.f.sol#L672)
	- [_prune_messages(MAX_PRUNE_MESSAGES_ATONCE)](flat/OutboundLane.f.sol#L674)
		- [delete messages[nonce.oldest_unpruned_nonce]](flat/OutboundLane.f.sol#L792)

flat/OutboundLane.f.sol#L655-L680


## reentrancy-events
Impact: Low
Confidence: Medium
 - [ ] ID-3
Reentrancy in [OutboundLane.send_message(address,bytes)](flat/OutboundLane.f.sol#L655-L680):
	External calls:
	- [require(bool,string)(IFeeMarket(FEE_MARKET).assign{value: msg.value}(encoded_key),AssignRelayersFailed)](flat/OutboundLane.f.sol#L664)
	Event emitted after the call(s):
	- [MessageAccepted(nonce,msg.sender,target,encoded)](flat/OutboundLane.f.sol#L675-L679)
	- [MessagePruned(outboundLaneNonce.oldest_unpruned_nonce)](flat/OutboundLane.f.sol#L798)
		- [_prune_messages(MAX_PRUNE_MESSAGES_ATONCE)](flat/OutboundLane.f.sol#L674)

flat/OutboundLane.f.sol#L655-L680


