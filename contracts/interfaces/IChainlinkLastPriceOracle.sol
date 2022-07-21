// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IChainlinkLastPriceOracle {
    function token() external view returns (address);

    function getLatestPrice() external view returns (uint256, uint8);
}