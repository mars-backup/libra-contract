// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IPermissions {

    function createRole(bytes32 role, bytes32 adminRole) external;

    function grantGovernor(address governor) external;

    function grantGuardian(address guardian) external;

    function grantFarm(address farm) external;

    function revokeGovernor(address governor) external;

    function revokeGuardian(address guardian) external;

    function revokeFarm(address farm) external;

    function revokeOverride(bytes32 role, address account) external;

    function isGovernor(address _address) external view returns (bool);

    function isGuardian(address _address) external view returns (bool);

    function isFarm(address _address) external view returns (bool);
}
