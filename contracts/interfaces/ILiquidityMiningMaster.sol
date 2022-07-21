// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ILiquidityMiningMaster {

    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
    }

    struct PoolInfo {
        IERC20 lpToken;
        uint256 allocPoint;
        uint256 lastRewardBlock;
        uint256 accRewardPerShare;
        bool locked;
    }

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );
    event UpdateEmissionRate(address indexed user, uint256 rewardPerBlock);
    event UpdateEndBlock(address indexed user, uint256 endBlock);
    event UpdateVestingMaster(address indexed user, address vestingMaster);

    function massUpdatePools() external;

    function updatePool(uint256 pid) external;

    function deposit(uint256 pid, uint256 amount) external;

    function withdraw(uint256 pid, uint256 amount) external;

    function emergencyWithdraw(uint256 pid) external;

    function addPool(
        uint256 allocPoint,
        IERC20 lpToken,
        bool locked,
        bool withUpdate
    ) external;

    function setPool(
        uint256 pid,
        uint256 allocPoint,
        bool locked,
        bool withUpdate
    ) external;

    function updateRewardPerBlock(uint256 _rewardPerBlock) external;

    function updateEndBlock(uint256 _endBlock) external;

    function updateVestingMaster(address _vestingMaster) external;

    function pair2Pid(address pair) external view returns (uint256);

    function pendingReward(uint256 pid, address user)
        external
        view
        returns (uint256);

    function poolInfo(uint256 pid)
        external
        view
        returns (
            IERC20 lpToken,
            uint256 allocPoint,
            uint256 lastRewardBlock,
            uint256 accRewardPerShare,
            bool locked
        );

    function userInfo(uint256 pid, address user)
        external
        view
        returns (uint256 amount, uint256 rewardDebt);

    function poolExistence(IERC20 lp) external view returns (bool);

    function rewardPerBlock() external view returns (uint256);

    function BONUS_MULTIPLIER() external view returns (uint256);

    function totalAllocPoint() external view returns (uint256);

    function startBlock() external view returns (uint256);

    function endBlock() external view returns (uint256);

    function poolLength() external view returns (uint256);

    function getMultiplier(uint256 from, uint256 to)
        external
        pure
        returns (uint256);

    function rewardToken() external view returns (IERC20);
}
