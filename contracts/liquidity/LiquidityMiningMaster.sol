// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../interfaces/ILiquidityMiningMaster.sol";
import "../interfaces/IVestingMaster.sol";
import "../core/CoreRef.sol";
import "../extend/DAOToken.sol";

contract LiquidityMiningMaster is
    ILiquidityMiningMaster,
    ReentrancyGuard,
    CoreRef,
    DAOToken
{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IVestingMaster public vestingMaster;

    PoolInfo[] public override poolInfo;

    mapping(uint256 => mapping(address => UserInfo)) public override userInfo;

    mapping(address => uint256) public override pair2Pid;
    mapping(IERC20 => bool) public override poolExistence;

    uint256 public override rewardPerBlock;

    uint256 public constant override BONUS_MULTIPLIER = 1;

    uint256 public override totalAllocPoint = 0;

    uint256 public override startBlock;

    uint256 public override endBlock;

    IERC20 public override rewardToken;

    constructor(
        address _core,
        address _vestingMaster,
        address _rewardToken,
        uint256 _rewardPerBlock,
        uint256 _startBlock,
        uint256 _endBlock
    ) public CoreRef(_core) DAOToken("LBR Farms Seed Token", "LSEED") {
        require(
            _startBlock < _endBlock,
            "LiquidityMiningMaster::constructor: End less than start"
        );
        vestingMaster = IVestingMaster(_vestingMaster);
        rewardToken = IERC20(_rewardToken);
        rewardPerBlock = _rewardPerBlock;
        startBlock = _startBlock;
        endBlock = _endBlock;
    }

    modifier nonDuplicated(IERC20 _lpToken) {
        require(
            !poolExistence[_lpToken],
            "LiquidityMiningMaster::nonDuplicated: Duplicated lp"
        );
        require(
            _lpToken != rewardToken || address(_lpToken) == token(),
            "LiquidityMiningMaster::nonDuplicated: Duplicated reward and lp"
        );
        _;
    }

    modifier validatePid(uint256 _pid) {
        require(
            _pid < poolInfo.length,
            "LiquidityMiningMaster::validatePid: Not exist"
        );
        _;
    }

    function transfer(address to, uint256 amount)
        public
        override
        returns (bool)
    {
        revert("LiquidityMiningMaster::transferFrom: Not support transfer");
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override returns (bool) {
        revert("LiquidityMiningMaster::transferFrom: Not support transferFrom");
    }

    function poolLength() public view override returns (uint256) {
        return poolInfo.length;
    }

    function addPool(
        uint256 _allocPoint,
        IERC20 _lpToken,
        bool _locked,
        bool _withUpdate
    ) public override onlyGuardianOrGovernor nonDuplicated(_lpToken) {
        require(
            block.number < endBlock,
            "LiquidityMiningMaster::addPool: Exceed endblock"
        );
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock
            ? block.number
            : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolExistence[_lpToken] = true;
        poolInfo.push(
            PoolInfo({
                lpToken: _lpToken,
                allocPoint: _allocPoint,
                lastRewardBlock: lastRewardBlock,
                accRewardPerShare: 0,
                locked: _locked
            })
        );
        pair2Pid[address(_lpToken)] = poolLength() - 1;
    }

    function setPool(
        uint256 _pid,
        uint256 _allocPoint,
        bool _locked,
        bool _withUpdate
    ) public override validatePid(_pid) onlyGuardianOrGovernor {
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(
            _allocPoint
        );
        poolInfo[_pid].allocPoint = _allocPoint;
        poolInfo[_pid].locked = _locked;
    }

    function getMultiplier(uint256 _from, uint256 _to)
        public
        pure
        override
        returns (uint256)
    {
        return _to.sub(_from).mul(BONUS_MULTIPLIER);
    }

    function getReward(uint256 _pid)
        internal
        view
        returns (uint256 reward)
    {
        PoolInfo storage pool = poolInfo[_pid];
        require(
            pool.lastRewardBlock < block.number,
            "LiquidityMiningMaster::getReward: Must little than the current block number"
        );
        uint256 multiplier = getMultiplier(
            pool.lastRewardBlock,
            block.number >= endBlock ? endBlock : block.number
        );
        if (totalAllocPoint > 0) {
            reward = multiplier.mul(rewardPerBlock).mul(pool.allocPoint).div(
                totalAllocPoint
            );
        }
    }

    function pendingReward(uint256 _pid, address _user)
        public
        view
        override
        validatePid(_pid)
        returns (uint256)
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accRewardPerShare = pool.accRewardPerShare;
        uint256 lpSupply = token() == address(pool.lpToken)
            ? totalSupply()
            : pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 shareReward = getReward(_pid);
            accRewardPerShare = accRewardPerShare.add(
                shareReward.mul(1e12).div(lpSupply)
            );
        }
        return user.amount.mul(accRewardPerShare).div(1e12).sub(user.rewardDebt);
    }

    function massUpdatePools() public override {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; pid++) {
            updatePool(pid);
        }
    }

    function updatePool(uint256 _pid) public override validatePid(_pid) {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        if (pool.lastRewardBlock >= endBlock) {
            return;
        }
        uint256 lpSupply = token() == address(pool.lpToken)
            ? totalSupply()
            : pool.lpToken.balanceOf(address(this));
        uint256 lastRewardBlock = block.number >= endBlock
            ? endBlock
            : block.number;
        if (lpSupply == 0 || pool.allocPoint == 0) {
            pool.lastRewardBlock = lastRewardBlock;
            return;
        }
        uint256 shareReward = getReward(_pid);
        pool.accRewardPerShare = pool.accRewardPerShare.add(
            shareReward.mul(1e12).div(lpSupply)
        );
        pool.lastRewardBlock = lastRewardBlock;
    }

    function deposit(uint256 _pid, uint256 _amount)
        public
        override
        validatePid(_pid)
        nonReentrant
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending = user
                .amount
                .mul(pool.accRewardPerShare)
                .div(1e12)
                .sub(user.rewardDebt);
            if (pending > 0) {
                uint256 locked;
                if (pool.locked && address(vestingMaster) != address(0)) {
                    locked = pending
                        .div(vestingMaster.lockedPeriodAmount() + 1)
                        .mul(vestingMaster.lockedPeriodAmount());
                }
                safeTokenTransfer(msg.sender, pending.sub(locked));
                if (locked > 0) {
                    uint256 actualAmount = safeTokenTransfer(
                        address(vestingMaster),
                        locked
                    );
                    vestingMaster.lock(msg.sender, actualAmount);
                }
            }
        }
        if (_amount > 0) {
            uint256 before = pool.lpToken.balanceOf(address(this));
            pool.lpToken.safeTransferFrom(
                address(msg.sender),
                address(this),
                _amount
            );
            _amount = pool.lpToken.balanceOf(address(this)).sub(before);
            if (token() == address(pool.lpToken)) {
                _mint(msg.sender, _amount);
            }
            user.amount = user.amount.add(_amount);
        }
        user.rewardDebt = user.amount.mul(pool.accRewardPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);
    }

    function withdraw(uint256 _pid, uint256 _amount)
        public
        override
        validatePid(_pid)
        nonReentrant
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(
            user.amount >= _amount,
            "LiquidityMiningMaster::withdraw: Not good"
        );
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending = user
                .amount
                .mul(pool.accRewardPerShare)
                .div(1e12)
                .sub(user.rewardDebt);
            if (pending > 0) {
                uint256 locked;
                if (pool.locked && address(vestingMaster) != address(0)) {
                    locked = pending
                        .div(vestingMaster.lockedPeriodAmount() + 1)
                        .mul(vestingMaster.lockedPeriodAmount());
                }
                safeTokenTransfer(msg.sender, pending.sub(locked));
                if (locked > 0) {
                    uint256 actualAmount = safeTokenTransfer(
                        address(vestingMaster),
                        locked
                    );
                    vestingMaster.lock(msg.sender, actualAmount);
                }
            }
        }
        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            if (token() == address(pool.lpToken)) {
                _burn(msg.sender, _amount);
            }
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
        }
        user.rewardDebt = user.amount.mul(pool.accRewardPerShare).div(1e12);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    function emergencyWithdraw(uint256 _pid)
        public
        override
        validatePid(_pid)
        nonReentrant
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        if (token() == address(pool.lpToken)) {
            _burn(msg.sender, amount);
        }
        pool.lpToken.safeTransfer(address(msg.sender), amount);
        emit EmergencyWithdraw(msg.sender, _pid, amount);
    }

    function safeTokenTransfer(address _to, uint256 _amount)
        internal
        virtual
        returns (uint256)
    {
        uint256 balance = rewardToken.balanceOf(address(this));
        uint256 amount;
        uint256 floorAmount = address(rewardToken) == token() ? totalSupply() : 0;
        if (balance > floorAmount) {
            balance = balance.sub(floorAmount);
            if (_amount > balance) {
                amount = balance;
            } else {
                amount = _amount;
            }
        }

        rewardToken.safeTransfer(_to, amount);
        return amount;
    }

    function updateRewardPerBlock(uint256 _rewardPerBlock)
        public
        override
        onlyGuardianOrGovernor
    {
        massUpdatePools();
        rewardPerBlock = _rewardPerBlock;
        emit UpdateEmissionRate(msg.sender, _rewardPerBlock);
    }

    function updateEndBlock(uint256 _endBlock)
        public
        override
        onlyGuardianOrGovernor
    {
        require(
            _endBlock > startBlock && _endBlock >= block.number,
            "LiquidityMiningMaster::updateEndBlock: Less"
        );
        for (uint256 pid = 0; pid < poolInfo.length; ++pid) {
            require(
                _endBlock > poolInfo[pid].lastRewardBlock,
                "LiquidityMiningMaster::updateEndBlock: Less"
            );
        }
        massUpdatePools();
        endBlock = _endBlock;
        emit UpdateEndBlock(msg.sender, _endBlock);
    }

    function updateVestingMaster(address _vestingMaster)
        public
        override
        onlyGovernor
    {
        vestingMaster = IVestingMaster(_vestingMaster);
        emit UpdateVestingMaster(msg.sender, _vestingMaster);
    }
}