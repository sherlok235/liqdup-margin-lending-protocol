// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract AccountAbstraction is Ownable {
    using ECDSA for bytes32;

    mapping(address => uint256) public nonces;
    mapping(address => bool) public authorized;

    event UserOpExecuted(address indexed user, bytes data);
    event Authorized(address indexed user);
    event Unauthorized(address indexed user);

    modifier onlyAuthorized() {
        require(authorized[msg.sender], "Not authorized");
        _;
    }

    // Authorize a user to perform operations
    function authorize(address user) external onlyOwner {
        authorized[user] = true;
        emit Authorized(user);
    }

    // Revoke authorization
    function unauthorize(address user) external onlyOwner {
        authorized[user] = false;
        emit Unauthorized(user);
    }

    // Execute bundled user operations: deposit, approve, borrow, repay
    function executeUserOp(address user, bytes calldata data, bytes calldata signature) external onlyAuthorized {
        require(_verify(user, data, signature), "Invalid signature");
        nonces[user]++;

        (bool success, ) = user.call(data);
        require(success, "UserOp execution failed");

        emit UserOpExecuted(user, data);
    }

    // Verify signature
    function _verify(address user, bytes calldata data, bytes calldata signature) internal view returns (bool) {
        bytes32 hash = keccak256(abi.encodePacked(user, data, nonces[user]));
        bytes32 messageHash = hash.toEthSignedMessageHash();
        address signer = messageHash.recover(signature);
        return signer == user;
    }
}
