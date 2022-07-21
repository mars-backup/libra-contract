// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./IPermissions.sol";

interface ICore is IPermissions {
    event TokenUpdate(address _token);

    function token() external view returns (address);

    function setToken(address _token) external;
}