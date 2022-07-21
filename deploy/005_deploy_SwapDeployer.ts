import { HardhatRuntimeEnvironment } from "hardhat/types"
import { DeployFunction } from "hardhat-deploy/types"
import { isMainnet } from "../utils/network"
import { MULTISIG_ADDRESS } from "../utils/accounts"

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts, getChainId } = hre
  const { deploy, execute, read, get } = deployments
  const { deployer, libraryDeployer } = await getNamedAccounts()

  await deploy("SwapDeployer", {
    from: deployer,
    log: true,
    skipIfAlreadyDeployed: true,
    args: [
      (await get('Core')).address
    ]
  })

/*
  const currentOwner = await read("SwapDeployer", "owner")
  if (isMainnet(await getChainId()) && currentOwner != MULTISIG_ADDRESS) {
    await execute(
      "SwapDeployer",
      { from: deployer, log: true },
      "transferOwnership",
      MULTISIG_ADDRESS,
    )
  }
*/
}

export default func
func.tags = ["SwapDeployer"]
func.dependencies = ["Core"]