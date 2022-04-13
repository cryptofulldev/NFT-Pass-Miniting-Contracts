// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IMockCouncilOfKingzMintPass {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function isUsed(uint256 tokenId) external view returns (bool);
    function isExpired(uint256 tokenId) external view returns (bool);
    function setAsUsed(uint256 tokenId) external;
}