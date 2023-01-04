# EnumerableSet



> Library for managing
https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
types.

Sets have the following properties:

- Elements are added, removed, and checked for existence in constant time
(O(1)).
- Elements are enumerated in O(n). No guarantees are made on the ordering.

```
contract Example {
    // Add the library methods
    using EnumerableSet for EnumerableSet.AddressSet;

    // Declare a set state variable
    EnumerableSet.AddressSet private mySet;
}
```

As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
and `uint256` (`UintSet`) are supported.

[WARNING]
====
Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
unusable.
See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.

In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
array of EnumerableSet.
====

## Contents
<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [Functions](#functions)
  - [add](#add)
  - [remove](#remove)
  - [contains](#contains)
  - [length](#length)
  - [at](#at)
  - [values](#values)
  - [add](#add-1)
  - [remove](#remove-1)
  - [contains](#contains-1)
  - [length](#length-1)
  - [at](#at-1)
  - [values](#values-1)
  - [add](#add-2)
  - [remove](#remove-2)
  - [contains](#contains-2)
  - [length](#length-2)
  - [at](#at-2)
  - [values](#values-2)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->




## Functions

### add
No description
> Add a value to a set. O(1).

Returns true if the value was added to the set, that is if it was not
already present.

#### Declaration
```solidity
  function add(
  ) internal returns (bool)
```

#### Modifiers:
No modifiers



### remove
No description
> Removes a value from a set. O(1).

Returns true if the value was removed from the set, that is if it was
present.

#### Declaration
```solidity
  function remove(
  ) internal returns (bool)
```

#### Modifiers:
No modifiers



### contains
No description
> Returns true if the value is in the set. O(1).

#### Declaration
```solidity
  function contains(
  ) internal returns (bool)
```

#### Modifiers:
No modifiers



### length
No description
> Returns the number of values in the set. O(1).

#### Declaration
```solidity
  function length(
  ) internal returns (uint256)
```

#### Modifiers:
No modifiers



### at
No description
> Returns the value stored at position `index` in the set. O(1).

Note that there are no guarantees on the ordering of values inside the
array, and it may change when more values are added or removed.

Requirements:

- `index` must be strictly less than {length}.

#### Declaration
```solidity
  function at(
  ) internal returns (bytes32)
```

#### Modifiers:
No modifiers



### values
No description
> Return the entire set in an array

WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
this function has an unbounded cost, and using it as part of a state-changing function may render the function
uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.

#### Declaration
```solidity
  function values(
  ) internal returns (bytes32[])
```

#### Modifiers:
No modifiers



### add
No description
> Add a value to a set. O(1).

Returns true if the value was added to the set, that is if it was not
already present.

#### Declaration
```solidity
  function add(
  ) internal returns (bool)
```

#### Modifiers:
No modifiers



### remove
No description
> Removes a value from a set. O(1).

Returns true if the value was removed from the set, that is if it was
present.

#### Declaration
```solidity
  function remove(
  ) internal returns (bool)
```

#### Modifiers:
No modifiers



### contains
No description
> Returns true if the value is in the set. O(1).

#### Declaration
```solidity
  function contains(
  ) internal returns (bool)
```

#### Modifiers:
No modifiers



### length
No description
> Returns the number of values in the set. O(1).

#### Declaration
```solidity
  function length(
  ) internal returns (uint256)
```

#### Modifiers:
No modifiers



### at
No description
> Returns the value stored at position `index` in the set. O(1).

Note that there are no guarantees on the ordering of values inside the
array, and it may change when more values are added or removed.

Requirements:

- `index` must be strictly less than {length}.

#### Declaration
```solidity
  function at(
  ) internal returns (address)
```

#### Modifiers:
No modifiers



### values
No description
> Return the entire set in an array

WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
this function has an unbounded cost, and using it as part of a state-changing function may render the function
uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.

#### Declaration
```solidity
  function values(
  ) internal returns (address[])
```

#### Modifiers:
No modifiers



### add
No description
> Add a value to a set. O(1).

Returns true if the value was added to the set, that is if it was not
already present.

#### Declaration
```solidity
  function add(
  ) internal returns (bool)
```

#### Modifiers:
No modifiers



### remove
No description
> Removes a value from a set. O(1).

Returns true if the value was removed from the set, that is if it was
present.

#### Declaration
```solidity
  function remove(
  ) internal returns (bool)
```

#### Modifiers:
No modifiers



### contains
No description
> Returns true if the value is in the set. O(1).

#### Declaration
```solidity
  function contains(
  ) internal returns (bool)
```

#### Modifiers:
No modifiers



### length
No description
> Returns the number of values in the set. O(1).

#### Declaration
```solidity
  function length(
  ) internal returns (uint256)
```

#### Modifiers:
No modifiers



### at
No description
> Returns the value stored at position `index` in the set. O(1).

Note that there are no guarantees on the ordering of values inside the
array, and it may change when more values are added or removed.

Requirements:

- `index` must be strictly less than {length}.

#### Declaration
```solidity
  function at(
  ) internal returns (uint256)
```

#### Modifiers:
No modifiers



### values
No description
> Return the entire set in an array

WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
this function has an unbounded cost, and using it as part of a state-changing function may render the function
uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.

#### Declaration
```solidity
  function values(
  ) internal returns (uint256[])
```

#### Modifiers:
No modifiers





