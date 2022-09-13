Summary
 - [locked-ether](#locked-ether) (1 results) (Medium)
 - [assembly](#assembly) (3 results) (Informational)
 - [low-level-calls](#low-level-calls) (4 results) (Informational)
 - [external-function](#external-function) (6 results) (Optimization)
## locked-ether
Impact: Medium
Confidence: High
 - [ ] ID-0
Contract locking ether found:
	Contract [POSALightClient](flat/POSALightClient.f.sol#L846-L889) has payable functions:
	 - [POSALightClient.import_message_commitment(POSACommitmentScheme.Commitment,bytes[])](flat/POSALightClient.f.sol#L873-L888)
	But does not have a function to withdraw the ether

flat/POSALightClient.f.sol#L846-L889


## assembly
Impact: Informational
Confidence: High
 - [ ] ID-1
[Address._verifyCallResult(bool,bytes,string)](flat/POSALightClient.f.sol#L199-L216) uses assembly
	- [INLINE ASM](flat/POSALightClient.f.sol#L208-L211)

flat/POSALightClient.f.sol#L199-L216


 - [ ] ID-2
[ECDSA.recover(bytes32,bytes)](flat/POSALightClient.f.sol#L460-L481) uses assembly
	- [INLINE ASM](flat/POSALightClient.f.sol#L474-L478)

flat/POSALightClient.f.sol#L460-L481


 - [ ] ID-3
[Address.isContract(address)](flat/POSALightClient.f.sol#L54-L63) uses assembly
	- [INLINE ASM](flat/POSALightClient.f.sol#L61)

flat/POSALightClient.f.sol#L54-L63


## low-level-calls
Impact: Informational
Confidence: High
 - [ ] ID-4
Low level call in [Address.functionStaticCall(address,bytes,string)](flat/POSALightClient.f.sol#L167-L173):
	- [(success,returndata) = target.staticcall(data)](flat/POSALightClient.f.sol#L171)

flat/POSALightClient.f.sol#L167-L173


 - [ ] ID-5
Low level call in [Address.sendValue(address,uint256)](flat/POSALightClient.f.sol#L81-L87):
	- [(success) = recipient.call{value: amount}()](flat/POSALightClient.f.sol#L85)

flat/POSALightClient.f.sol#L81-L87


 - [ ] ID-6
Low level call in [Address.functionCallWithValue(address,bytes,uint256,string)](flat/POSALightClient.f.sol#L142-L149):
	- [(success,returndata) = target.call{value: value}(data)](flat/POSALightClient.f.sol#L147)

flat/POSALightClient.f.sol#L142-L149


 - [ ] ID-7
Low level call in [Address.functionDelegateCall(address,bytes,string)](flat/POSALightClient.f.sol#L191-L197):
	- [(success,returndata) = target.delegatecall(data)](flat/POSALightClient.f.sol#L195)

flat/POSALightClient.f.sol#L191-L197


## external-function
Impact: Optimization
Confidence: High
 - [ ] ID-8
merkle_root() should be declared external:
	- [POSALightClient.merkle_root()](flat/POSALightClient.f.sol#L866-L868)

flat/POSALightClient.f.sol#L866-L868


 - [ ] ID-9
get_threshold() should be declared external:
	- [EcdsaAuthority.get_threshold()](flat/POSALightClient.f.sol#L732-L734)

flat/POSALightClient.f.sol#L732-L734


 - [ ] ID-10
is_relayer(address) should be declared external:
	- [EcdsaAuthority.is_relayer(address)](flat/POSALightClient.f.sol#L736-L738)

flat/POSALightClient.f.sol#L736-L738


 - [ ] ID-11
get_relayers() should be declared external:
	- [EcdsaAuthority.get_relayers()](flat/POSALightClient.f.sol#L742-L754)

flat/POSALightClient.f.sol#L742-L754


 - [ ] ID-12
block_number() should be declared external:
	- [POSALightClient.block_number()](flat/POSALightClient.f.sol#L862-L864)

flat/POSALightClient.f.sol#L862-L864


 - [ ] ID-13
initialize(address[],uint256,uint256) should be declared external:
	- [POSALightClient.initialize(address[],uint256,uint256)](flat/POSALightClient.f.sol#L854-L860)

flat/POSALightClient.f.sol#L854-L860


