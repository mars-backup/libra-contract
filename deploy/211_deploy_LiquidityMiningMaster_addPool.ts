import { HardhatRuntimeEnvironment } from "hardhat/types"
import { DeployFunction } from "hardhat-deploy/types"

const POOLS = [
  {
    name: 'LBRToken',
    allocPoint: 1000
  },
  {
    name: 'LibraUSDPoolLPToken',
    allocPoint: 1000
  },
  {
    name: 'LibraUSDmMetaPoolLPToken',
    allocPoint: 1000
  }
]

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre
  const { get, execute, getOrNull, save } = deployments
  const { deployer } = await getNamedAccounts()

  for (let i = 0; i < POOLS.length; i++) {
    const { name, allocPoint } = POOLS[i]
    const poolName = 'LiquidityMiningMaster-' + name
    const pool = await getOrNull(poolName)
    if (pool) continue

    await execute(
      "LiquidityMiningMaster",
      { from: deployer, log: true },
      "addPool",
      allocPoint,
      (await get(name)).address,
      true,
      true
    )
    await save(poolName, {
      abi: (await get("LiquidityMiningMaster")).abi,
      address: (await get("LiquidityMiningMaster")).address
    })
  }
}

export default func
func.tags = ["LiquidityMiningMasterAddPool"]
func.dependencies = ["LiquidityMiningMaster"]