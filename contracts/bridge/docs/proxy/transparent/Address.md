# Address



> Collection of functions related to the address type

## Contents
<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

  - [Functions](#functions)
    - [isContract](#iscontract)
- [[IMPORTANT]](#important)
- [[IMPORTANT]](#important-1)
- [Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
constructor.](#preventing-calls-from-contracts-is-highly-discouraged-it-breaks-composability-breaks-support-for-smart-wallets%0Alike-gnosis-safe-and-does-not-provide-security-since-it-can-be-circumvented-by-calling-from-a-contract%0Aconstructor)
    - [sendValue](#sendvalue)
    - [functionCall](#functioncall)
    - [functionCall](#functioncall-1)
    - [functionCallWithValue](#functioncallwithvalue)
    - [functionCallWithValue](#functioncallwithvalue-1)
    - [functionStaticCall](#functionstaticcall)
    - [functionStaticCall](#functionstaticcall-1)
    - [functionDelegateCall](#functiondelegatecall)
    - [functionDelegateCall](#functiondelegatecall-1)
    - [verifyCallResultFromTarget](#verifycallresultfromtarget)
    - [verifyCallResult](#verifycallresult)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->




## Functions

### isContract
No description
> Returns true if `account` is a contract.

[IMPORTANT]
====
It is unsafe to assume that an address for which this function returns
false is an externally-owned account (EOA) and not a contract.

Among others, `isContract` will return false for the following
types of addresses:

 - an externally-owned account
 - a contract in construction
 - an address where a contract will be created
 - an address where a contract lived, but was destroyed
====

[IMPORTANT]
====
You shouldn't rely on `isContract` to protect against flash loan attacks!

Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
constructor.
====

#### Declaration
```solidity
  function isContract(
  ) internal returns (bool)
```

#### Modifiers:
No modifiers



### sendValue
No description
> Replacement for Solidity's `transfer`: sends `amount` wei to
`recipient`, forwarding all available gas and reverting on errors.

https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
of certain opcodes, possibly making contracts go over the 2300 gas limit
imposed by `transfer`, making them unable to receive funds via
`transfer`. {sendValue} removes this limitation.

https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].

IMPORTANT: because control is transferred to `recipient`, care must be
taken to not create reentrancy vulnerabilities. Consider using
{ReentrancyGuard} or the
https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].

#### Declaration
```solidity
  function sendValue(
  ) internal
```

#### Modifiers:
No modifiers



### functionCall
No description
> Performs a Solidity function call using a low level `call`. A
plain `call` is an unsafe replacement for a function call: use this
function instead.

If `target` reverts with a revert reason, it is bubbled up by this
function (like regular Solidity function calls).

Returns the raw returned data. To convert to the expected return value,
use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].

Requirements:

- `target` must be a contract.
- calling `target` with `data` must not revert.

_Available since v3.1._

#### Declaration
```solidity
  function functionCall(
  ) internal returns (bytes)
```

#### Modifiers:
No modifiers



### functionCall
No description
> Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
`errorMessage` as a fallback revert reason when `target` reverts.

_Available since v3.1._

#### Declaration
```solidity
  function functionCall(
  ) internal returns (bytes)
```

#### Modifiers:
No modifiers



### functionCallWithValue
No description
> Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
but also transferring `value` wei to `target`.

Requirements:

- the calling contract must have an ETH balance of at least `value`.
- the called Solidity function must be `payable`.

_Available since v3.1._

#### Declaration
```solidity
  function functionCallWithValue(
  ) internal returns (bytes)
```

#### Modifiers:
No modifiers



### functionCallWithValue
No description
> Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
with `errorMessage` as a fallback revert reason when `target` reverts.

_Available since v3.1._

#### Declaration
```solidity
  function functionCallWithValue(
  ) internal returns (bytes)
```

#### Modifiers:
No modifiers



### functionStaticCall
No description
> Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
but performing a static call.

_Available since v3.3._

#### Declaration
```solidity
  function functionStaticCall(
  ) internal returns (bytes)
```

#### Modifiers:
No modifiers



### functionStaticCall
No description
> Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
but performing a static call.

_Available since v3.3._

#### Declaration
```solidity
  function functionStaticCall(
  ) internal returns (bytes)
```

#### Modifiers:
No modifiers



### functionDelegateCall
No description
> Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
but performing a delegate call.

_Available since v3.4._

#### Declaration
```solidity
  function functionDelegateCall(
  ) internal returns (bytes)
```

#### Modifiers:
No modifiers



### functionDelegateCall
No description
> Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
but performing a delegate call.

_Available since v3.4._

#### Declaration
```solidity
  function functionDelegateCall(
  ) internal returns (bytes)
```

#### Modifiers:
No modifiers



### verifyCallResultFromTarget
No description
> Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.

_Available since v4.8._

#### Declaration
```solidity
  function verifyCallResultFromTarget(
  ) internal returns (bytes)
```

#### Modifiers:
No modifiers



### verifyCallResult
No description
> Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
revert reason or using the provided one.

_Available since v4.3._

#### Declaration
```solidity
  function verifyCallResult(
  ) internal returns (bytes)
```

#### Modifiers:
No modifiers





