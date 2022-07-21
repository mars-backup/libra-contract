import { HardhatRuntimeEnvironment } from "hardhat/types"
import { DeployFunction } from "hardhat-deploy/types"

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre
  const { deploy, getOrNull, log, get, execute } = deployments
  const { deployer } = await getNamedAccounts()

  const lbrToken = await getOrNull("LBRToken")
  if (lbrToken) {
    log(`reusing "LBRToken" at ${lbrToken.address}`)
  } else {
    const result = await deploy("LBRToken", {
      from: deployer,
      log: true,
      skipIfAlreadyDeployed: true,
      args: [
        (await get("Core")).address
      ]
    })

    if (result.newlyDeployed) {
      await execute(
        "Core",
        { from: deployer, log: true },
        "setToken",
        (await get("LBRToken")).address
      )
    }
  }
}

export default func
func.tags = ["LBRToken"]
func.dependencies = ["Core"]
