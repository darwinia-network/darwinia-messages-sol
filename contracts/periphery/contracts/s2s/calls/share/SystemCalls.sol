// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

import "../../types/PalletSystem.sol";
import "@darwinia/contracts-utils/contracts/SafeMath.sol";

library SystemCalls {
    using SafeMath for uint256;

    function remark(bytes memory rmk)
        internal
        pure
        returns (bytes memory, uint64)
    {
        PalletSystem.RemarkCall memory call = PalletSystem.RemarkCall(
            hex"0001",
            rmk
        );
        return (PalletSystem.encodeRemarkCall(call), 0);
    }

    function remarkWithEvent(bytes memory rmk)
        internal
        pure
        returns (bytes memory, uint64)
    {
        PalletSystem.RemarkCall memory call = PalletSystem.RemarkCall(
            hex"0009",
            rmk
        );

        // Note: the params we used to calc weight should be set carefully.
        // https://github.com/darwinia-network/substrate/blob/1df7fe589a94caa33e8b9290dd474613bc170416/frame/system/src/weights.rs#L68
        uint256 weight = rmk.length.mul(2_000);

        return (PalletSystem.encodeRemarkCall(call), uint64(weight));
    }
}
