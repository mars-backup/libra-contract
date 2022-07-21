import { HardhatRuntimeEnvironment } from "hardhat/types"
import { DeployFunction } from "hardhat-deploy/types"

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre
  const { execute, deploy, get, getOrNull, log } = deployments
  const { deployer } = await getNamedAccounts()

  const libraUSDmMetaPool = await getOrNull("LibraUSDmMetaPoolDeposit")
  if (libraUSDmMetaPool) {
    log(`reusing "LibraUSDmMetaPoolDeposit" at ${libraUSDmMetaPool.address}`)
  } else {
    await deploy("LibraUSDmMetaPoolDeposit", {
      from: deployer,
      log: true,
      contract: "MetaSwapDeposit",
      skipIfAlreadyDeployed: true,
    })

    await execute(
      "LibraUSDmMetaPoolDeposit",
      { from: deployer, log: true },
      "initialize",
      (
        await get("LibraUSDPool")
      ).address,
      (
        await get("LibraUSDmMetaPool")
      ).address,
      (
        await get("LibraUSDmMetaPoolLPToken")
      ).address,
    )
  }
}

export default func
func.tags = ["USDmMetaPoolDeposit"]
func.dependencies = ["USDmMetaPoolTokens", "USDmMetaPool"]
