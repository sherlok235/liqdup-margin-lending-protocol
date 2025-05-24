// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IOracleAdapter {
    function getPrice(address asset) external view returns (uint256);
}

interface IBorrowing {
    function loans(address borrower) external view returns (uint256 principal, uint256 interestAccrued, uint256 lastAccrualTimestamp);
}

interface IPositionCollateralization {
    function getPositionValue(uint256 tokenId) external view returns (uint256);
}

contract Liquidation is Ownable {
    IOracleAdapter public oracleAdapter;
    IBorrowing public borrowingContract;
    IPositionCollateralization public positionCollateralization;

    uint256 public healthFactorThreshold = 1e18; // 1.0 in 18 decimals

    event LiquidationTriggered(address indexed borrower, uint256 repayAmount, uint256 collateralClaimed);

    constructor(
        address oracleAdapterAddress,
        address borrowingAddress,
        address positionCollateralizationAddress
    ) {
        oracleAdapter = IOracleAdapter(oracleAdapterAddress);
        borrowingContract = IBorrowing(borrowingAddress);
        positionCollateralization = IPositionCollateralization(positionCollateralizationAddress);
    }

    // Calculate health factor: collateral value / (loan principal + interest)
    function getHealthFactor(address borrower, uint256 positionTokenId) public view returns (uint256) {
        (uint256 principal, uint256 interestAccrued, ) = borrowingContract.loans(borrower);
        uint256 totalDebt = principal + interestAccrued;
        if (totalDebt == 0) return type(uint256).max;

        uint256 collateralValue = positionCollateralization.getPositionValue(positionTokenId);
        return (collateralValue * 1e18) / totalDebt;
    }

    // Trigger liquidation if health factor below threshold
    function liquidate(address borrower, uint256 positionTokenId, uint256 repayAmount) external {
        uint256 healthFactor = getHealthFactor(borrower, positionTokenId);
        require(healthFactor < healthFactorThreshold, "Health factor above threshold");

        // For simplicity, fixed penalty liquidation: liquidator repays loan, claims collateral minus penalty
        // Penalty and auction logic can be added here

        // Transfer stablecoin from liquidator to contract (assumed borrowing contract handles stablecoin)
        // Repay loan on behalf of borrower (not implemented here, would require borrowing contract interaction)

        // Transfer collateral NFT from borrower to liquidator (simplified)
        // positionCollateralization.safeTransferFrom(borrower, msg.sender, positionTokenId);

        emit LiquidationTriggered(borrower, repayAmount, positionTokenId);
    }

    // Owner can update health factor threshold
    function setHealthFactorThreshold(uint256 newThreshold) external onlyOwner {
        healthFactorThreshold = newThreshold;
    }
}
