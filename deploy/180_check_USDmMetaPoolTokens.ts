import { DeployFunction } from "hardhat-deploy/types"
import { HardhatRuntimeEnvironment } from "hardhat/types"
import { isMainnet } from "../utils/network"
import { BigNumber } from "ethers"

const USD_TOKENS_ARGS: { [token: string]: any[] } = {
  USDm: ["Mars USD", "USDm", "18"],
}

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts, getChainId } = hre
  const { deploy, execute } = deployments
  const { deployer } = await getNamedAccounts()

  for (const token in USD_TOKENS_ARGS) {
    const result = await deploy(token, {
      from: deployer,
      log: true,
      contract: "GenericERC20",
      args: USD_TOKENS_ARGS[token],
      skipIfAlreadyDeployed: true,
    })

    if (!isMainnet(await getChainId()) && result.newlyDeployed) {
      const decimals = USD_TOKENS_ARGS[token][2]
      await execute(
        token,
        { from: deployer, log: true },
        "mint",
        deployer,
        BigNumber.from(10).pow(decimals).mul(1000000),
      )
    }
  }
}

export default func
func.tags = ["USDmMetaPoolTokens"]
func.dependencies = ["USDPool"]
