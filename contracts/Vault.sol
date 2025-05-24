// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Vault is ERC4626, Ownable {
    constructor(IERC20 asset) ERC4626(asset) ERC20("LiqdUp Vault", "LQDV") {}

    // Additional logic can be added here if needed, such as custom deposit/withdrawal restrictions

    // Owner can recover tokens mistakenly sent to the vault
    function recoverERC20(address token, uint256 amount) external onlyOwner {
        require(token != address(asset()), "Cannot recover underlying asset");
        IERC20(token).transfer(owner(), amount);
    }
}
