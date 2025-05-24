// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IOracleAdapter {
    function getPrice(address asset) external view returns (uint256);
}

// Example Chainlink Oracle Adapter for Arbitrum
contract ChainlinkOracleAdapter is IOracleAdapter {
    mapping(address => address) public priceFeeds;

    // Set price feed for asset
    function setPriceFeed(address asset, address feed) external {
        priceFeeds[asset] = feed;
    }

    // Get price from Chainlink feed
    function getPrice(address asset) external view override returns (uint256) {
        address feed = priceFeeds[asset];
        require(feed != address(0), "Price feed not set");
        (, int256 price, , , ) = AggregatorV3Interface(feed).latestRoundData();
        require(price > 0, "Invalid price");
        return uint256(price);
    }
}

// Placeholder for RedStone Oracle Adapter for Base chain
contract RedStoneOracleAdapter is IOracleAdapter {
    function getPrice(address asset) external view override returns (uint256) {
        // Implement RedStone price fetching logic here
        return 0;
    }
}

interface AggregatorV3Interface {
    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}
