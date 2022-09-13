Summary
 - [locked-ether](#locked-ether) (1 results) (Medium)
 - [tautology](#tautology) (1 results) (Medium)
 - [missing-zero-check](#missing-zero-check) (1 results) (Low)
 - [assembly](#assembly) (1 results) (Informational)
 - [low-level-calls](#low-level-calls) (1 results) (Informational)
 - [similar-names](#similar-names) (1 results) (Informational)
 - [too-many-digits](#too-many-digits) (5 results) (Informational)
 - [external-function](#external-function) (1 results) (Optimization)
## locked-ether
Impact: Medium
Confidence: High
 - [ ] ID-0
Contract locking ether found:
	Contract [BeaconLightClient](flat/BeaconLightClient.f.sol#L612-L831) has payable functions:
	 - [BeaconLightClient.import_next_sync_committee(BeaconLightClient.SyncCommitteePeriodUpdate)](flat/BeaconLightClient.f.sol#L690-L704)
	 - [BeaconLightClient.import_finalized_header(BeaconLightClient.FinalizedHeaderUpdate)](flat/BeaconLightClient.f.sol#L706-L735)
	But does not have a function to withdraw the ether

flat/BeaconLightClient.f.sol#L612-L831


## tautology
Impact: Medium
Confidence: High
 - [ ] ID-1
[Bits.bits(uint256,uint8,uint16)](flat/BeaconLightClient.f.sol#L366-L373) contains a tautology or contradiction:
	- [require(bool)(0 < numBits && startIndex < 256 && startIndex + numBits <= 256)](flat/BeaconLightClient.f.sol#L371)

flat/BeaconLightClient.f.sol#L366-L373


## missing-zero-check
Impact: Low
Confidence: Medium
 - [ ] ID-2
[BeaconLightClient.constructor(address,uint64,uint64,bytes32,bytes32,bytes32,bytes32,bytes32)._bls](flat/BeaconLightClient.f.sol#L671) lacks a zero-check on :
		- [BLS_PRECOMPILE = _bls](flat/BeaconLightClient.f.sol#L680)

flat/BeaconLightClient.f.sol#L671


## assembly
Impact: Informational
Confidence: High
 - [ ] ID-3
[BeaconLightClient.fast_aggregate_verify(bytes[],bytes,bytes)](flat/BeaconLightClient.f.sol#L800-L822) uses assembly
	- [INLINE ASM](flat/BeaconLightClient.f.sol#L814-L817)

flat/BeaconLightClient.f.sol#L800-L822


## low-level-calls
Impact: Informational
Confidence: High
 - [ ] ID-4
Low level call in [BeaconLightClient.fast_aggregate_verify(bytes[],bytes,bytes)](flat/BeaconLightClient.f.sol#L800-L822):
	- [(ok,out) = BLS_PRECOMPILE.staticcall(input)](flat/BeaconLightClient.f.sol#L807)

flat/BeaconLightClient.f.sol#L800-L822


## similar-names
Impact: Informational
Confidence: Medium
 - [ ] ID-5
Variable [BeaconLightClient.FINALIZED_CHECKPOINT_ROOT_DEPTH](flat/BeaconLightClient.f.sol#L630) is too similar to [BeaconLightClient.FINALIZED_CHECKPOINT_ROOT_INDEX](flat/BeaconLightClient.f.sol#L629)

flat/BeaconLightClient.f.sol#L630


## too-many-digits
Impact: Informational
Confidence: Medium
 - [ ] ID-6
[BeaconLightClient.slitherConstructorVariables()](flat/BeaconLightClient.f.sol#L612-L831) uses literals with too many digits:
	- [BIG_PRIME = (1000003,1000033,1000037,1000039,1000081,1000099,1000117,1000121,1000133,1000151,1000159,1000171,1000183,1000187,1000193,1000199,1000211,1000213,1000231,1000249)](flat/BeaconLightClient.f.sol#L447-L450)

flat/BeaconLightClient.f.sol#L612-L831


 - [ ] ID-7
[BeaconLightClient.slitherConstructorConstantVariables()](flat/BeaconLightClient.f.sol#L612-L831) uses literals with too many digits:
	- [M128 = 0x00000000000000000000000000000000ffffffffffffffffffffffffffffffff](flat/BeaconLightClient.f.sol#L444-L445)

flat/BeaconLightClient.f.sol#L612-L831


 - [ ] ID-8
[BeaconLightClient.slitherConstructorConstantVariables()](flat/BeaconLightClient.f.sol#L612-L831) uses literals with too many digits:
	- [M64 = 0x0000000000000000ffffffffffffffff0000000000000000ffffffffffffffff](flat/BeaconLightClient.f.sol#L442-L443)

flat/BeaconLightClient.f.sol#L612-L831


 - [ ] ID-9
[BeaconLightClient.slitherConstructorConstantVariables()](flat/BeaconLightClient.f.sol#L612-L831) uses literals with too many digits:
	- [M32 = 0x00000000ffffffff00000000ffffffff00000000ffffffff00000000ffffffff](flat/BeaconLightClient.f.sol#L440-L441)

flat/BeaconLightClient.f.sol#L612-L831


 - [ ] ID-10
[BeaconLightClient.slitherConstructorConstantVariables()](flat/BeaconLightClient.f.sol#L612-L831) uses literals with too many digits:
	- [DOMAIN_SYNC_COMMITTEE = 0x07000000](flat/BeaconLightClient.f.sol#L633)

flat/BeaconLightClient.f.sol#L612-L831


## external-function
Impact: Optimization
Confidence: High
 - [ ] ID-11
state_root() should be declared external:
	- [BeaconLightClient.state_root()](flat/BeaconLightClient.f.sol#L686-L688)

flat/BeaconLightClient.f.sol#L686-L688


