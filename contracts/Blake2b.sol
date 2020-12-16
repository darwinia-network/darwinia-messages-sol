/*
 * Blake2b library in Solidity using EIP-152
 *
 * Copyright (C) 2019 Alex Beregszaszi
 *
 * License: Apache 2.0
 */

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.7.0;
pragma experimental ABIEncoderV2;

library Blake2b {
    struct Instance {
        // This is a bit misleadingly called state as it not only includes the Blake2 state,
        // but every field needed for the "blake2 f function precompile".
        //
        // This is a tightly packed buffer of:
        // - rounds: 32-bit BE
        // - h: 8 x 64-bit LE
        // - m: 16 x 64-bit LE
        // - t: 2 x 64-bit LE
        // - f: 8-bit
        bytes state;
        // Expected output hash length. (Used in `finalize`.)
        uint out_len;
        // Data passed to "function F".
        // NOTE: this is limited to 24 bits.
        uint input_counter;
    }

    // Initialise the state with a given `key` and required `out_len` hash length.
    function init(bytes memory key, uint out_len)
        internal
        view
        returns (Instance memory instance)
    {
        // Safety check that the precompile exists.
        // TODO: remove this?
        // assembly {
        //    if eq(extcodehash(0x09), 0) { revert(0, 0) }
        //}

        reset(instance, key, out_len);
    }

    // Initialise the state with a given `key` and required `out_len` hash length.
    function reset(Instance memory instance, bytes memory key, uint out_len)
        internal
        view
    {
        instance.out_len = out_len;
        instance.input_counter = 0;

        // This is entire state transmitted to the precompile.
        // It is byteswapped for the encoding requirements, additionally
        // the IV has the initial parameter block 0 XOR constant applied, but
        // not the key and output length.
        instance.state = hex"0000000c08c9bdf267e6096a3ba7ca8485ae67bb2bf894fe72f36e3cf1361d5f3af54fa5d182e6ad7f520e511f6c3e2b8c68059b6bbd41fbabd9831f79217e1319cde05b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000";
        bytes memory state = instance.state;

        // Update parameter block 0 with key length and output length.
        uint key_len = key.length;
        assembly {
            let ptr := add(state, 36)
            let tmp := mload(ptr)
            let p0 := or(shl(240, key_len), shl(248, out_len))
            tmp := xor(tmp, p0)
            mstore(ptr, tmp)
        }

        // TODO: support salt and personalization

        if (key_len > 0) {
            require(key_len == 64);
            // FIXME: the key must be zero padded
            assert(key.length == 128);
            update(instance, key, key_len);
        }
    }

    // This calls the blake2 precompile ("function F of the spec").
    // It expects the state was updated with the next block. Upon returning the state will be updated,
    // but the supplied block data will not be cleared.
    function call_function_f(Instance memory instance)
        private
        view
    {
        bytes memory state = instance.state;
        assembly {
            let state_ptr := add(state, 32)
            if iszero(staticcall(not(0), 0x09, state_ptr, 0xd5, add(state_ptr, 4), 0x40)) {
                revert(0, 0)
            }
        }
    }

    // This function will split blocks correctly and repeatedly call the precompile.
    // NOTE: this is dumb right now and expects `data` to be 128 bytes long and padded with zeroes,
    //       hence the real length is indicated with `data_len`
    function update_loop(Instance memory instance, bytes memory data, uint data_len, bool last_block)
        private
        view
    {
        bytes memory state = instance.state;
        uint input_counter = instance.input_counter;

        // This is the memory location where the "data block" starts for the precompile.
        uint state_ptr;
        assembly {
            // The `rounds` field is 4 bytes long and the `h` field is 64-bytes long.
            // Also adjust for the size of the bytes type.
            state_ptr := add(state, 100)
        }

        // This is the memory location where the input data resides.
        uint data_ptr;
        assembly {
            data_ptr := add(data, 32)
        }

        uint len = data.length;
        while (len > 0) {
            if (len >= 128) {
                assembly {
                    mstore(state_ptr, mload(data_ptr))
                    data_ptr := add(data_ptr, 32)

                    mstore(add(state_ptr, 32), mload(data_ptr))
                    data_ptr := add(data_ptr, 32)

                    mstore(add(state_ptr, 64), mload(data_ptr))
                    data_ptr := add(data_ptr, 32)

                    mstore(add(state_ptr, 96), mload(data_ptr))
                    data_ptr := add(data_ptr, 32)
                }

                len -= 128;
                // FIXME: remove this once implemented proper padding
                if (data_len < 128) {
                    input_counter += data_len;
                } else {
                    data_len -= 128;
                    input_counter += 128;
                }
            } else {
                // FIXME: implement support for smaller than 128 byte blocks
                revert();
            }

            // Set length field (little-endian) for maximum of 24-bits.
            assembly {
                mstore8(add(state, 228), and(input_counter, 0xff))
                mstore8(add(state, 229), and(shr(8, input_counter), 0xff))
                mstore8(add(state, 230), and(shr(16, input_counter), 0xff))
            }

            // Set the last block indicator.
            // Only if we've processed all input.
            if (len == 0) {
                assembly {
                    // Writing byte 212 here.
                    mstore8(add(state, 244), last_block)
                }
            }

            // Call the precompile
            call_function_f(instance);
        }

        instance.input_counter = input_counter;
    }

    // Update the state with a non-final block.
    // NOTE: the input must be complete blocks.
    function update(Instance memory instance, bytes memory data, uint data_len)
        internal
        view
    {
        require((data.length % 128) == 0);
        update_loop(instance, data, data_len, false);
    }

    // Update the state with a final block and return the hash.
    function finalize(Instance memory instance, bytes memory data)
        internal
        view
        returns (bytes memory output)
    {
        // FIXME: support incomplete blocks (zero pad them)
        uint input_length = data.length;
        if (input_length == 0 || (input_length % 128) != 0) {
            data = concat(data, new bytes(128 - (input_length % 128)));
        }
        assert((data.length % 128) == 0);
        update_loop(instance, data, input_length, true);

        // FIXME: support other lengths
        // assert(instance.out_len == 64);

        bytes memory state = instance.state;
        output = new bytes(instance.out_len);
        if(instance.out_len == 32) {
            assembly {
                mstore(add(output, 32), mload(add(state, 36)))
            }
        } else {
            assembly {
                mstore(add(output, 32), mload(add(state, 36)))
                mstore(add(output, 64), mload(add(state, 68)))
            }
        }
    }

    function concat(
        bytes memory _preBytes,
        bytes memory _postBytes
    )
        internal
        pure
        returns (bytes memory)
    {
        bytes memory tempBytes;

        assembly {
            // Get a location of some free memory and store it in tempBytes as
            // Solidity does for memory variables.
            tempBytes := mload(0x40)

            // Store the length of the first bytes array at the beginning of
            // the memory for tempBytes.
            let length := mload(_preBytes)
            mstore(tempBytes, length)

            // Maintain a memory counter for the current write location in the
            // temp bytes array by adding the 32 bytes for the array length to
            // the starting location.
            let mc := add(tempBytes, 0x20)
            // Stop copying when the memory counter reaches the length of the
            // first bytes array.
            let end := add(mc, length)

            for {
                // Initialize a copy counter to the start of the _preBytes data,
                // 32 bytes into its memory.
                let cc := add(_preBytes, 0x20)
            } lt(mc, end) {
                // Increase both counters by 32 bytes each iteration.
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                // Write the _preBytes data into the tempBytes memory 32 bytes
                // at a time.
                mstore(mc, mload(cc))
            }

            // Add the length of _postBytes to the current length of tempBytes
            // and store it as the new length in the first 32 bytes of the
            // tempBytes memory.
            length := mload(_postBytes)
            mstore(tempBytes, add(length, mload(tempBytes)))

            // Move the memory counter back from a multiple of 0x20 to the
            // actual end of the _preBytes data.
            mc := end
            // Stop copying when the memory counter reaches the new combined
            // length of the arrays.
            end := add(mc, length)

            for {
                let cc := add(_postBytes, 0x20)
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }

            // Update the free-memory pointer by padding our last write location
            // to 32 bytes: add 31 bytes to the end of tempBytes to move to the
            // next 32 byte block, then round down to the nearest multiple of
            // 32. If the sum of the length of the two arrays is zero then add
            // one before rounding down to leave a blank 32 bytes (the length block with 0).
            mstore(0x40, and(
              add(add(end, iszero(add(length, mload(_preBytes)))), 31),
              not(31) // Round down to the nearest 32 bytes.
            ))
        }

        return tempBytes;
    }

}