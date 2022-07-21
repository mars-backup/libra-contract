// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "../interfaces/IPermissions.sol";

contract Permissions is IPermissions, AccessControl {
    bytes32 public constant GOVERN_ROLE = keccak256("GOVERN_ROLE");
    bytes32 public constant GUARDIAN_ROLE = keccak256("GUARDIAN_ROLE");
    bytes32 public constant FARM_ROLE = keccak256("FARM_ROLE");

    constructor() public {
        _setupGovernor(address(this));
        _setRoleAdmin(GOVERN_ROLE, GOVERN_ROLE);
        _setRoleAdmin(GUARDIAN_ROLE, GOVERN_ROLE);
    }

    modifier onlyGovernor() {
        require(
            isGovernor(msg.sender),
            "Permissions::onlyGovernor: Caller is not a governor"
        );
        _;
    }

    modifier onlyGuardian() {
        require(
            isGuardian(msg.sender),
            "Permissions::onlyGuardian: Caller is not a guardian"
        );
        _;
    }

    function createRole(bytes32 role, bytes32 adminRole)
        public
        override
        onlyGovernor
    {
        _setRoleAdmin(role, adminRole);
    }

    function grantGovernor(address governor) public override onlyGovernor {
        grantRole(GOVERN_ROLE, governor);
    }

    function grantGuardian(address guardian) public override onlyGovernor {
        grantRole(GUARDIAN_ROLE, guardian);
    }

    function grantFarm(address farm) public override onlyGovernor {
        grantRole(FARM_ROLE, farm);
    }

    function revokeGovernor(address governor) public override onlyGovernor {
        revokeRole(GOVERN_ROLE, governor);
    }

    function revokeGuardian(address guardian) public override onlyGovernor {
        revokeRole(GUARDIAN_ROLE, guardian);
    }

    function revokeFarm(address farm) public override onlyGovernor {
        revokeRole(FARM_ROLE, farm);
    }

    function revokeOverride(bytes32 role, address account)
        public
        override
        onlyGuardian
    {
        require(
            role != GOVERN_ROLE,
            "Permissions::revokeOverride: Guardian cannot revoke governor"
        );

        revokeRole(role, account);
    }

    function isGovernor(address _address)
        public
        view
        override
        virtual
        returns (bool)
    {
        return hasRole(GOVERN_ROLE, _address);
    }

    function isGuardian(address _address) public view override returns (bool) {
        return hasRole(GUARDIAN_ROLE, _address);
    }

    function isFarm(address _address) public view override returns (bool) {
        return hasRole(FARM_ROLE, _address);
    }

    function _setupGovernor(address governor) internal {
        _setupRole(GOVERN_ROLE, governor);
    }
}
