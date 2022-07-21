// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../interfaces/ICore.sol";
import "./Permissions.sol";

contract Core is ICore, Permissions {

    address public override token;

    constructor() public {
        _setupGovernor(msg.sender);
    }

    function setToken(address _token) public override onlyGovernor {
        _setToken(_token);
    }

    function _setToken(address _token) internal {
        token = _token;
        emit TokenUpdate(_token);
    }
}
