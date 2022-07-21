// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface ICoreRef {
    event CoreUpdate(address indexed _core);

    function setCore(address core_) external;

    function pause() external;

    function unpause() external;

    function core() external view returns (address);

    function token() external view returns (address);
}