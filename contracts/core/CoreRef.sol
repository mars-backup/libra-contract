// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/utils/Pausable.sol";
import "../interfaces/ICore.sol";
import "../interfaces/ICoreRef.sol";

abstract contract CoreRef is ICoreRef, Pausable {

    ICore private _core;

    constructor(address core_) public {
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

    modifier onlyFarm() {
        require(
            _core.isFarm(msg.sender),
            "CoreRef::onlyFarm: Caller is not a farm"
        );
        _;
    }

    function setCore(address core_) public override onlyGovernor {
        _core = ICore(core_);
        emit CoreUpdate(core_);
    }

    function pause() public override onlyGuardianOrGovernor {
        _pause();
    }

    function unpause() public override onlyGuardianOrGovernor {
        _unpause();
    }

    function core() public view override returns (address) {
        return address(_core);
    }

    function token() public view override returns (address) {
        return _core.token();
    }
}
