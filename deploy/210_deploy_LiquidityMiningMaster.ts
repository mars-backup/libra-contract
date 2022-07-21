import { HardhatRuntimeEnvironment } from "hardhat/types"
import { DeployFunction } from "hardhat-deploy/types"

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre
  const { deploy, getOrNull, log, get } = deployments
  const { deployer } = await getNamedAccounts()

  const liquidityMiningMaster = await getOrNull("LiquidityMiningMaster")
  if (liquidityMiningMaster) {
    log(`reusing "LiquidityMiningMaster" at ${liquidityMiningMaster.address}`)
  } else {
    await deploy("LiquidityMiningMaster", {
      from: deployer,
      log: true,
      skipIfAlreadyDeployed: true,
      args: [
        (await get("Core")).address,
        (await get("VestingMaster")).address,
        (await get("LBRToken")).address,
        "500000000000000000",
        0,
        "1000000000000000000"
      ]
    })
  }
}

export default func
func.tags = ["LiquidityMiningMaster"]
func.dependencies = ["Core","VestingMaster","LBRToken"]
