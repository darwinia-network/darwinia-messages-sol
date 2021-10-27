// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
import "./BasicMappingTokenFactory.sol";

contract Ethereum2DarwiniaMappingTokenFactory is BasicMappingTokenFactory {
    // create new erc20 mapping token contract
    // save and manage the token list
    function newErc20Contract(
        uint32 tokenType,
        string memory name,
        string memory symbol,
        uint8 decimals,
        address backing_address,
        address original_token
    ) public virtual override onlySystem returns (address mapping_token) {
        mapping_token = super.newErc20Contract(
            tokenType,
            name,
            symbol,
            decimals,
            backing_address,
            original_token
        );
        // send the register response message to backing
        (bool encodeSuccess, bytes memory register_response) = DISPATCH_ENCODER.call(
            abi.encodePacked(bytes4(keccak256("e2d_token_register_response()")),
                             abi.encode(backing_address, original_token, mapping_token)));
        require(encodeSuccess, "create: encode e2d_token_register_response failed");
        (bool success, ) = DISPATCH.call(register_response);
        require(success, "create: call create erc20 precompile failed");
    }

    // cross transfer to remote chain without waiting any confirm information,
    // this require the burn proof can be always verified by the remote chain corrently.
    // so, here the user's token burned directly.
    function burnAndRemoteUnlock(address mapping_token, bytes memory recipient, uint256 amount) external {
        require(amount > 0, "can not transfer amount zero");
        TokenInfo memory info = mappingToken2Info[mapping_token];
        require(info.original_token != address(0), "token is not created by factory");
        // Lock the fund in this before message on remote backing chain get dispatched successfully and burn finally
        // If remote backing chain unlock the origin token successfully, then this fund will be burned.
        // Otherwise, this fund will be transfered back to the msg.sender.
        require(IERC20(mapping_token).transferFrom(msg.sender, address(this), amount), "transfer token failed");
        IERC20(mapping_token).burn(address(this), amount);

        (bool encodeSuccess, bytes memory unlock_message) = DISPATCH_ENCODER.call(
            abi.encodePacked(bytes4(keccak256("e2d_burn_and_remote_unlock()")),
                abi.encode(
                    info.tokenType,
                    info.backing_address,
                    msg.sender, 
                    info.original_token,
                    recipient, 
                    amount)));
        require(encodeSuccess, "burn: encode unlock message failed");
        (bool success, ) = DISPATCH.call(unlock_message);
        require(success, "burn: call send unlock message failed");
    }
}
    
