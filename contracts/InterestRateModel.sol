// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract InterestRateModel {
    uint256 public baseRatePerYear; // e.g., 2% = 200 basis points
    uint256 public multiplierPerYear; // e.g., 10% = 1000 basis points
    uint256 public jumpMultiplierPerYear; // e.g., 100% = 10000 basis points
    uint256 public kink; // utilization rate at which jump multiplier kicks in (scaled 1e18)

    uint256 public constant BASIS_POINTS_DIVISOR = 10000;
    uint256 public constant SCALE = 1e18;

    constructor(
        uint256 _baseRatePerYear,
        uint256 _multiplierPerYear,
        uint256 _jumpMultiplierPerYear,
        uint256 _kink
    ) {
        baseRatePerYear = _baseRatePerYear;
        multiplierPerYear = _multiplierPerYear;
        jumpMultiplierPerYear = _jumpMultiplierPerYear;
        kink = _kink;
    }

    // Calculate interest rate per second based on utilization rate
    function getInterestRate(uint256 utilizationRate) public view returns (uint256) {
        if (utilizationRate <= kink) {
            return
                baseRatePerYear +
                (multiplierPerYear * utilizationRate) / kink;
        } else {
            uint256 normalRate = baseRatePerYear + multiplierPerYear;
            uint256 excessUtil = utilizationRate - kink;
            uint256 excessRate = (jumpMultiplierPerYear * excessUtil) / (SCALE - kink);
            return normalRate + excessRate;
        }
    }
}
