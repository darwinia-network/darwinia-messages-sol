Summary
 - [incorrect-equality](#incorrect-equality) (3 results) (Medium)
 - [uninitialized-local](#uninitialized-local) (2 results) (Medium)
 - [events-access](#events-access) (1 results) (Low)
 - [missing-zero-check](#missing-zero-check) (1 results) (Low)
 - [variable-scope](#variable-scope) (2 results) (Low)
 - [timestamp](#timestamp) (10 results) (Low)
 - [assembly](#assembly) (2 results) (Informational)
 - [low-level-calls](#low-level-calls) (4 results) (Informational)
 - [reentrancy-unlimited-gas](#reentrancy-unlimited-gas) (2 results) (Informational)
 - [similar-names](#similar-names) (1 results) (Informational)
 - [external-function](#external-function) (1 results) (Optimization)
## incorrect-equality
Impact: Medium
Confidence: High
 - [ ] ID-0
[SimpleFeeMarket._distribute_ontime(uint256,address,address,address)](flat/SimpleFeeMarket.f.sol#L795-L818) uses a dangerous strict equality:
	- [assign_relayer == confirm_relayer](flat/SimpleFeeMarket.f.sol#L811)

flat/SimpleFeeMarket.f.sol#L795-L818


 - [ ] ID-1
[SimpleFeeMarket._distribute_ontime(uint256,address,address,address)](flat/SimpleFeeMarket.f.sol#L795-L818) uses a dangerous strict equality:
	- [assign_relayer == delivery_relayer](flat/SimpleFeeMarket.f.sol#L808)

flat/SimpleFeeMarket.f.sol#L795-L818


 - [ ] ID-2
[SimpleFeeMarket.prune(address,address)](flat/SimpleFeeMarket.f.sol#L653-L657) uses a dangerous strict equality:
	- [lockedOf[cur] == 0 && balanceOf[cur] < COLLATERAL_PER_ORDER](flat/SimpleFeeMarket.f.sol#L654)

flat/SimpleFeeMarket.f.sol#L653-L657


## uninitialized-local
Impact: Medium
Confidence: Medium
 - [ ] ID-3
[SimpleFeeMarket._pay_relayers_rewards(IFeeMarket.DeliveredRelayer[],address).delivery_reward_scope_0](flat/SimpleFeeMarket.f.sol#L757) is a local variable never initialized

flat/SimpleFeeMarket.f.sol#L757


 - [ ] ID-4
[SimpleFeeMarket._pay_relayers_rewards(IFeeMarket.DeliveredRelayer[],address).confirm_reward_scope_1](flat/SimpleFeeMarket.f.sol#L757) is a local variable never initialized

flat/SimpleFeeMarket.f.sol#L757


## events-access
Impact: Low
Confidence: Medium
 - [ ] ID-5
[SimpleFeeMarket.setSetter(address)](flat/SimpleFeeMarket.f.sol#L513-L515) should emit an event for: 
	- [setter = setter_](flat/SimpleFeeMarket.f.sol#L514) 

flat/SimpleFeeMarket.f.sol#L513-L515


## missing-zero-check
Impact: Low
Confidence: Medium
 - [ ] ID-6
[SimpleFeeMarket.setSetter(address).setter_](flat/SimpleFeeMarket.f.sol#L513) lacks a zero-check on :
		- [setter = setter_](flat/SimpleFeeMarket.f.sol#L514)

flat/SimpleFeeMarket.f.sol#L513


## variable-scope
Impact: Low
Confidence: High
 - [ ] ID-7
Variable '[SimpleFeeMarket._pay_relayers_rewards(IFeeMarket.DeliveredRelayer[],address).confirm_reward](flat/SimpleFeeMarket.f.sol#L749)' in [SimpleFeeMarket._pay_relayers_rewards(IFeeMarket.DeliveredRelayer[],address)](flat/SimpleFeeMarket.f.sol#L734-L769) potentially used before declaration: [(delivery_reward,confirm_reward) = _slash_and_unlock_late(key,late_time)](flat/SimpleFeeMarket.f.sol#L757)

flat/SimpleFeeMarket.f.sol#L749


 - [ ] ID-8
Variable '[SimpleFeeMarket._pay_relayers_rewards(IFeeMarket.DeliveredRelayer[],address).delivery_reward](flat/SimpleFeeMarket.f.sol#L749)' in [SimpleFeeMarket._pay_relayers_rewards(IFeeMarket.DeliveredRelayer[],address)](flat/SimpleFeeMarket.f.sol#L734-L769) potentially used before declaration: [(delivery_reward,confirm_reward) = _slash_and_unlock_late(key,late_time)](flat/SimpleFeeMarket.f.sol#L757)

flat/SimpleFeeMarket.f.sol#L749


## timestamp
Impact: Low
Confidence: Medium
 - [ ] ID-9
[SimpleFeeMarket._lock(address,uint256)](flat/SimpleFeeMarket.f.sol#L705-L710) uses timestamp for comparisons
	Dangerous comparisons:
	- [require(bool,string)(balanceOf[to] >= wad,!lock)](flat/SimpleFeeMarket.f.sol#L706)

flat/SimpleFeeMarket.f.sol#L705-L710


 - [ ] ID-10
[SimpleFeeMarket._slash_and_unlock(address,uint256,uint256)](flat/SimpleFeeMarket.f.sol#L719-L726) uses timestamp for comparisons
	Dangerous comparisons:
	- [require(bool,string)(lockedOf[src] >= c,!unlock)](flat/SimpleFeeMarket.f.sol#L720)
	- [require(bool,string)(c >= s,!slash)](flat/SimpleFeeMarket.f.sol#L721)

flat/SimpleFeeMarket.f.sol#L719-L726


 - [ ] ID-11
[SimpleFeeMarket._pay_relayers_rewards(IFeeMarket.DeliveredRelayer[],address)](flat/SimpleFeeMarket.f.sol#L734-L769) uses timestamp for comparisons
	Dangerous comparisons:
	- [require(bool,string)(assigned_time > 0,!exist)](flat/SimpleFeeMarket.f.sol#L741)
	- [require(bool,string)(block.timestamp >= assigned_time,!time)](flat/SimpleFeeMarket.f.sol#L742)
	- [diff_time < RELAY_TIME](flat/SimpleFeeMarket.f.sol#L747)

flat/SimpleFeeMarket.f.sol#L734-L769


 - [ ] ID-12
[SimpleFeeMarket.withdraw(uint256)](flat/SimpleFeeMarket.f.sol#L588-L593) uses timestamp for comparisons
	Dangerous comparisons:
	- [require(bool)(balanceOf[msg.sender] >= wad)](flat/SimpleFeeMarket.f.sol#L589)

flat/SimpleFeeMarket.f.sol#L588-L593


 - [ ] ID-13
[SimpleFeeMarket._unlock(address,uint256)](flat/SimpleFeeMarket.f.sol#L712-L717) uses timestamp for comparisons
	Dangerous comparisons:
	- [require(bool,string)(lockedOf[to] >= wad,!unlock)](flat/SimpleFeeMarket.f.sol#L713)

flat/SimpleFeeMarket.f.sol#L712-L717


 - [ ] ID-14
[SimpleFeeMarket._distribute_ontime(uint256,address,address,address)](flat/SimpleFeeMarket.f.sol#L795-L818) uses timestamp for comparisons
	Dangerous comparisons:
	- [message_fee > 0](flat/SimpleFeeMarket.f.sol#L801)
	- [assign_relayer == delivery_relayer](flat/SimpleFeeMarket.f.sol#L808)
	- [assign_relayer == confirm_relayer](flat/SimpleFeeMarket.f.sol#L811)

flat/SimpleFeeMarket.f.sol#L795-L818


 - [ ] ID-15
[SimpleFeeMarket.getOrderBook(uint256,bool)](flat/SimpleFeeMarket.f.sol#L536-L558) uses timestamp for comparisons
	Dangerous comparisons:
	- [flag || _enough_balance(cur)](flat/SimpleFeeMarket.f.sol#L549)

flat/SimpleFeeMarket.f.sol#L536-L558


 - [ ] ID-16
[SimpleFeeMarket.prune(address,address)](flat/SimpleFeeMarket.f.sol#L653-L657) uses timestamp for comparisons
	Dangerous comparisons:
	- [lockedOf[cur] == 0 && balanceOf[cur] < COLLATERAL_PER_ORDER](flat/SimpleFeeMarket.f.sol#L654)

flat/SimpleFeeMarket.f.sol#L653-L657


 - [ ] ID-17
[SimpleFeeMarket._enough_balance(address)](flat/SimpleFeeMarket.f.sol#L482-L484) uses timestamp for comparisons
	Dangerous comparisons:
	- [balanceOf[src] >= COLLATERAL_PER_ORDER](flat/SimpleFeeMarket.f.sol#L483)

flat/SimpleFeeMarket.f.sol#L482-L484


 - [ ] ID-18
[SimpleFeeMarket._slash_and_unlock_late(uint256,uint256)](flat/SimpleFeeMarket.f.sol#L783-L793) uses timestamp for comparisons
	Dangerous comparisons:
	- [late_time >= SLASH_TIME](flat/SimpleFeeMarket.f.sol#L788)

flat/SimpleFeeMarket.f.sol#L783-L793


## assembly
Impact: Informational
Confidence: High
 - [ ] ID-19
[Address._verifyCallResult(bool,bytes,string)](flat/SimpleFeeMarket.f.sol#L219-L236) uses assembly
	- [INLINE ASM](flat/SimpleFeeMarket.f.sol#L228-L231)

flat/SimpleFeeMarket.f.sol#L219-L236


 - [ ] ID-20
[Address.isContract(address)](flat/SimpleFeeMarket.f.sol#L74-L83) uses assembly
	- [INLINE ASM](flat/SimpleFeeMarket.f.sol#L81)

flat/SimpleFeeMarket.f.sol#L74-L83


## low-level-calls
Impact: Informational
Confidence: High
 - [ ] ID-21
Low level call in [Address.functionStaticCall(address,bytes,string)](flat/SimpleFeeMarket.f.sol#L187-L193):
	- [(success,returndata) = target.staticcall(data)](flat/SimpleFeeMarket.f.sol#L191)

flat/SimpleFeeMarket.f.sol#L187-L193


 - [ ] ID-22
Low level call in [Address.functionDelegateCall(address,bytes,string)](flat/SimpleFeeMarket.f.sol#L211-L217):
	- [(success,returndata) = target.delegatecall(data)](flat/SimpleFeeMarket.f.sol#L215)

flat/SimpleFeeMarket.f.sol#L211-L217


 - [ ] ID-23
Low level call in [Address.sendValue(address,uint256)](flat/SimpleFeeMarket.f.sol#L101-L107):
	- [(success) = recipient.call{value: amount}()](flat/SimpleFeeMarket.f.sol#L105)

flat/SimpleFeeMarket.f.sol#L101-L107


 - [ ] ID-24
Low level call in [Address.functionCallWithValue(address,bytes,uint256,string)](flat/SimpleFeeMarket.f.sol#L162-L169):
	- [(success,returndata) = target.call{value: value}(data)](flat/SimpleFeeMarket.f.sol#L167)

flat/SimpleFeeMarket.f.sol#L162-L169


## reentrancy-unlimited-gas
Impact: Informational
Confidence: Medium
 - [ ] ID-25
Reentrancy in [SimpleFeeMarket.withdraw(uint256)](flat/SimpleFeeMarket.f.sol#L588-L593):
	External calls:
	- [address(msg.sender).transfer(wad)](flat/SimpleFeeMarket.f.sol#L591)
	Event emitted after the call(s):
	- [Withdrawal(msg.sender,wad)](flat/SimpleFeeMarket.f.sol#L592)

flat/SimpleFeeMarket.f.sol#L588-L593


 - [ ] ID-26
Reentrancy in [SimpleFeeMarket.leave(address)](flat/SimpleFeeMarket.f.sol#L602-L605):
	External calls:
	- [withdraw(balanceOf[msg.sender])](flat/SimpleFeeMarket.f.sol#L603)
		- [address(msg.sender).transfer(wad)](flat/SimpleFeeMarket.f.sol#L591)
	State variables written after the call(s):
	- [delist(prev)](flat/SimpleFeeMarket.f.sol#L604)
		- [feeOf[cur] = 0](flat/SimpleFeeMarket.f.sol#L647)
	- [delist(prev)](flat/SimpleFeeMarket.f.sol#L604)
		- [relayerCount --](flat/SimpleFeeMarket.f.sol#L648)
	- [delist(prev)](flat/SimpleFeeMarket.f.sol#L604)
		- [relayers[prev] = relayers[cur]](flat/SimpleFeeMarket.f.sol#L645)
		- [relayers[cur] = address(0)](flat/SimpleFeeMarket.f.sol#L646)
	Event emitted after the call(s):
	- [Delist(prev,cur)](flat/SimpleFeeMarket.f.sol#L649)
		- [delist(prev)](flat/SimpleFeeMarket.f.sol#L604)

flat/SimpleFeeMarket.f.sol#L602-L605


## similar-names
Impact: Informational
Confidence: Medium
 - [ ] ID-27
Variable [SimpleFeeMarket.COLLATERAL_PER_ORDER](flat/SimpleFeeMarket.f.sol#L439) is too similar to [SimpleFeeMarket.constructor(uint256,uint32,uint32,uint32)._collateral_perorder](flat/SimpleFeeMarket.f.sol#L487)

flat/SimpleFeeMarket.f.sol#L439


## external-function
Impact: Optimization
Confidence: High
 - [ ] ID-28
initialize() should be declared external:
	- [SimpleFeeMarket.initialize()](flat/SimpleFeeMarket.f.sol#L499-L501)

flat/SimpleFeeMarket.f.sol#L499-L501


