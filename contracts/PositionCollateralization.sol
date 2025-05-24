// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IPositionOracle {
    function getPositionValue(uint256 positionId) external view returns (uint256);
}

contract PositionCollateralization is ERC721, Ownable {
    uint256 private _tokenIdCounter;
    IPositionOracle public positionOracle;

    // Mapping from tokenId to external position data (e.g., protocol, positionId)
    struct PositionData {
        address protocol;
        uint256 externalPositionId;
    }
    mapping(uint256 => PositionData) public positionData;

    event PositionWrapped(address indexed owner, uint256 indexed tokenId, address protocol, uint256 externalPositionId);
    event PositionUnwrapped(address indexed owner, uint256 indexed tokenId);

    constructor(address oracleAddress) ERC721("PositionCollateral", "POSCOL") {
        positionOracle = IPositionOracle(oracleAddress);
    }

    // Wrap an external position as an ERC721 token
    function wrapPosition(address protocol, uint256 externalPositionId) external returns (uint256) {
        _tokenIdCounter++;
        uint256 newTokenId = _tokenIdCounter;

        positionData[newTokenId] = PositionData(protocol, externalPositionId);
        _safeMint(msg.sender, newTokenId);

        emit PositionWrapped(msg.sender, newTokenId, protocol, externalPositionId);
        return newTokenId;
    }

    // Unwrap position and burn the token
    function unwrapPosition(uint256 tokenId) external {
        require(ownerOf(tokenId) == msg.sender, "Not token owner");
        _burn(tokenId);
        delete positionData[tokenId];

        emit PositionUnwrapped(msg.sender, tokenId);
    }

    // Get the current value of the wrapped position via oracle
    function getPositionValue(uint256 tokenId) external view returns (uint256) {
        require(_exists(tokenId), "Token does not exist");
        PositionData memory data = positionData[tokenId];
        return positionOracle.getPositionValue(data.externalPositionId);
    }

    // Owner can update the oracle address
    function setPositionOracle(address oracleAddress) external onlyOwner {
        positionOracle = IPositionOracle(oracleAddress);
    }
}
