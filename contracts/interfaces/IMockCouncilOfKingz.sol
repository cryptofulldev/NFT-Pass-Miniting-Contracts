// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IMockCouncilOfKingz {
    function burn(uint256[] memory _tokenIds) external;

    function burnEnabled() external view returns (bool);
}