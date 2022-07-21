// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "../interfaces/ICore.sol";
import "../interfaces/ICoreRef.sol";

abstract contract CoreRefUpgradeable is ICoreRef, PausableUpgradeable {

    ICore private _core;

    function __CoreRef_init(address core_) internal initializer {
        __Pausable_init_unchained();
        __CoreRef_init_unchained(core_);
    }

    function __CoreRef_init_unchained(address core_) internal initializer {
        _core = ICore(core_);
    }

    modifier onlyGovernor() {
        require(
            _core.isGovernor(msg.sender),
            "CoreRef::onlyGovernor: Caller is not a governor"
        );
        _;
    }

    modifier onlyGuardianOrGovernor() {
        require(
            _core.isGovernor(msg.sender) || _core.isGuardian(msg.sender),
            "CoreRef::onlyGuardianOrGovernor: Caller is not a guardian or governor"
        );
        _;
    }

    function pause() public override onlyGuardianOrGovernor {
        _pause();
    }

    function unpause() public override onlyGuardianOrGovernor {
        _unpause();
    }

    function setCore(address core_) public override onlyGovernor {
        _core = ICore(core_);
        emit CoreUpdate(core_);
    }

    function core() public view override returns (address) {
        return address(_core);
    }

    function token() public view override returns (address) {
        return _core.token();
    }
}
