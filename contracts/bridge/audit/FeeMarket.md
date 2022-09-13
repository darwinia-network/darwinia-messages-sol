Summary
 - [events-access](#events-access) (1 results) (Low)
 - [missing-zero-check](#missing-zero-check) (2 results) (Low)
 - [timestamp](#timestamp) (3 results) (Low)
 - [assembly](#assembly) (2 results) (Informational)
 - [low-level-calls](#low-level-calls) (4 results) (Informational)
 - [reentrancy-unlimited-gas](#reentrancy-unlimited-gas) (2 results) (Informational)
 - [similar-names](#similar-names) (1 results) (Informational)
 - [external-function](#external-function) (2 results) (Optimization)
## events-access
Impact: Low
Confidence: Medium
 - [ ] ID-0
[FeeMarket.setSetter(address)](flat/FeeMarket.f.sol#L529-L531) should emit an event for: 
	- [setter = _setter](flat/FeeMarket.f.sol#L530) 

flat/FeeMarket.f.sol#L529-L531


## missing-zero-check
Impact: Low
Confidence: Medium
 - [ ] ID-1
[FeeMarket.constructor(address,uint256,uint32,uint32,uint32,uint32)._vault](flat/FeeMarket.f.sol#L498) lacks a zero-check on :
		- [VAULT = _vault](flat/FeeMarket.f.sol#L507)

flat/FeeMarket.f.sol#L498


 - [ ] ID-2
[FeeMarket.setSetter(address)._setter](flat/FeeMarket.f.sol#L529) lacks a zero-check on :
		- [setter = _setter](flat/FeeMarket.f.sol#L530)

flat/FeeMarket.f.sol#L529


## timestamp
Impact: Low
Confidence: Medium
 - [ ] ID-3
[FeeMarket.getOrder(uint256)](flat/FeeMarket.f.sol#L549-L556) uses timestamp for comparisons
	Dangerous comparisons:
	- [slot < order.number](flat/FeeMarket.f.sol#L552)

flat/FeeMarket.f.sol#L549-L556


 - [ ] ID-4
[FeeMarket._get_order_status(uint256)](flat/FeeMarket.f.sol#L823-L835) uses timestamp for comparisons
	Dangerous comparisons:
	- [is_ontime = diff_time < order.number * RELAY_TIME](flat/FeeMarket.f.sol#L834)

flat/FeeMarket.f.sol#L823-L835


 - [ ] ID-5
[FeeMarket._settle_order(uint256)](flat/FeeMarket.f.sol#L798-L821) uses timestamp for comparisons
	Dangerous comparisons:
	- [require(bool,string)(orderOf[key].time > 0,!exist)](flat/FeeMarket.f.sol#L803)

flat/FeeMarket.f.sol#L798-L821


## assembly
Impact: Informational
Confidence: High
 - [ ] ID-6
[Address._verifyCallResult(bool,bytes,string)](flat/FeeMarket.f.sol#L219-L236) uses assembly
	- [INLINE ASM](flat/FeeMarket.f.sol#L228-L231)

flat/FeeMarket.f.sol#L219-L236


 - [ ] ID-7
[Address.isContract(address)](flat/FeeMarket.f.sol#L74-L83) uses assembly
	- [INLINE ASM](flat/FeeMarket.f.sol#L81)

flat/FeeMarket.f.sol#L74-L83


## low-level-calls
Impact: Informational
Confidence: High
 - [ ] ID-8
Low level call in [Address.sendValue(address,uint256)](flat/FeeMarket.f.sol#L101-L107):
	- [(success) = recipient.call{value: amount}()](flat/FeeMarket.f.sol#L105)

flat/FeeMarket.f.sol#L101-L107


 - [ ] ID-9
Low level call in [Address.functionCallWithValue(address,bytes,uint256,string)](flat/FeeMarket.f.sol#L162-L169):
	- [(success,returndata) = target.call{value: value}(data)](flat/FeeMarket.f.sol#L167)

flat/FeeMarket.f.sol#L162-L169


 - [ ] ID-10
Low level call in [Address.functionDelegateCall(address,bytes,string)](flat/FeeMarket.f.sol#L211-L217):
	- [(success,returndata) = target.delegatecall(data)](flat/FeeMarket.f.sol#L215)

flat/FeeMarket.f.sol#L211-L217


 - [ ] ID-11
Low level call in [Address.functionStaticCall(address,bytes,string)](flat/FeeMarket.f.sol#L187-L193):
	- [(success,returndata) = target.staticcall(data)](flat/FeeMarket.f.sol#L191)

flat/FeeMarket.f.sol#L187-L193


## reentrancy-unlimited-gas
Impact: Informational
Confidence: Medium
 - [ ] ID-12
Reentrancy in [FeeMarket.withdraw(uint256)](flat/FeeMarket.f.sol#L633-L638):
	External calls:
	- [address(msg.sender).transfer(wad)](flat/FeeMarket.f.sol#L636)
	Event emitted after the call(s):
	- [Withdrawal(msg.sender,wad)](flat/FeeMarket.f.sol#L637)

flat/FeeMarket.f.sol#L633-L638


 - [ ] ID-13
Reentrancy in [FeeMarket.leave(address)](flat/FeeMarket.f.sol#L647-L650):
	External calls:
	- [withdraw(balanceOf[msg.sender])](flat/FeeMarket.f.sol#L648)
		- [address(msg.sender).transfer(wad)](flat/FeeMarket.f.sol#L636)
	State variables written after the call(s):
	- [delist(prev)](flat/FeeMarket.f.sol#L649)
		- [feeOf[cur] = 0](flat/FeeMarket.f.sol#L740)
	- [delist(prev)](flat/FeeMarket.f.sol#L649)
		- [relayerCount --](flat/FeeMarket.f.sol#L741)
	- [delist(prev)](flat/FeeMarket.f.sol#L649)
		- [relayers[prev] = relayers[cur]](flat/FeeMarket.f.sol#L738)
		- [relayers[cur] = address(0)](flat/FeeMarket.f.sol#L739)
	Event emitted after the call(s):
	- [Delist(prev,cur)](flat/FeeMarket.f.sol#L742)
		- [delist(prev)](flat/FeeMarket.f.sol#L649)

flat/FeeMarket.f.sol#L647-L650


## similar-names
Impact: Informational
Confidence: Medium
 - [ ] ID-14
Variable [FeeMarket.COLLATERAL_PER_ORDER](flat/FeeMarket.f.sol#L445) is too similar to [FeeMarket.constructor(address,uint256,uint32,uint32,uint32,uint32)._collateral_perorder](flat/FeeMarket.f.sol#L499)

flat/FeeMarket.f.sol#L445


## external-function
Impact: Optimization
Confidence: High
 - [ ] ID-15
initialize() should be declared external:
	- [FeeMarket.initialize()](flat/FeeMarket.f.sol#L515-L517)

flat/FeeMarket.f.sol#L515-L517


 - [ ] ID-16
leave(address) should be declared external:
	- [FeeMarket.leave(address)](flat/FeeMarket.f.sol#L647-L650)

flat/FeeMarket.f.sol#L647-L650


