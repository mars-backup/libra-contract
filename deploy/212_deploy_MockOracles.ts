import { HardhatRuntimeEnvironment } from "hardhat/types"
import { DeployFunction } from "hardhat-deploy/types"
import { isMainnet } from "../utils/network"

const TOKENS_ARGS: { [token: string]: string } = {
  BUSD: '98000000',
  USDC: '100200000',
  USDT: '101600000'
}

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts, getChainId } = hre
  const { deploy, get } = deployments
  const { deployer } = await getNamedAccounts()

  if (!isMainnet(await getChainId())) {
    for (const token in TOKENS_ARGS) {
      await deploy(token + 'Oracle', {
        from: deployer,
        log: true,
        contract: "MockLastPriceOracle",
        args: [
          (await get(token)).address,
          TOKENS_ARGS[token]
        ],
        skipIfAlreadyDeployed: true,
      })
    }
  }
}

export default func
func.tags = ["MockOracles"]
func.dependencies = ["USDPoolTokens"]