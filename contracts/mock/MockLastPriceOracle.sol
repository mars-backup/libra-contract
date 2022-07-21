// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../interfaces/IChainlinkLastPriceOracle.sol";

contract MockLastPriceOracle is IChainlinkLastPriceOracle {
    address public override token;

    uint256 public price;

    constructor(address _token, uint256 _price) public {
        token = _token;
        price = _price;
    }

    function getLatestPrice() public view override returns (uint256, uint8) {
        return (price, uint8(8));
    }
}