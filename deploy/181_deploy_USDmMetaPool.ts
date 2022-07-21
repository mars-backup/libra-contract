import { HardhatRuntimeEnvironment } from "hardhat/types"
import { DeployFunction } from "hardhat-deploy/types"
import { MULTISIG_ADDRESS } from "../utils/accounts"

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre
  const { execute, deploy, get, getOrNull, log, read, save } = deployments
  const { deployer } = await getNamedAccounts()

  const libraUSDmMetaPool = await getOrNull("LibraUSDmMetaPool")
  if (libraUSDmMetaPool) {
    log(`reusing "LibraUSDmMetaPool" at ${libraUSDmMetaPool.address}`)
  } else {
    const TOKEN_ADDRESSES = [
      (await get("USDm")).address,
      (await get("LibraUSDPoolLPToken")).address,
    ]
    const TOKEN_DECIMALS = [18, 18]
    const LP_TOKEN_NAME = "Mars USD/libraUSD"
    const LP_TOKEN_SYMBOL = "libraUSDm"
    const INITIAL_A = 100
    const SWAP_FEE = 4e6 // 4bps
    const ADMIN_FEE = 0

    await deploy("LibraUSDmMetaPool", {
      from: deployer,
      log: true,
      contract: "MetaSwap",
      skipIfAlreadyDeployed: true,
      libraries: {
        SwapUtils: (await get("SwapUtils")).address,
        MetaSwapUtils: (await get("MetaSwapUtils")).address,
        AmplificationUtils: (await get("AmplificationUtils")).address,
      },
    })

    await execute(
      "LibraUSDmMetaPool",
      {
        from: deployer,
        log: true,
      },
      "initializeMetaSwap",
      (await get("Core")).address,
      TOKEN_ADDRESSES,
      TOKEN_DECIMALS,
      LP_TOKEN_NAME,
      LP_TOKEN_SYMBOL,
      INITIAL_A,
      SWAP_FEE,
      ADMIN_FEE,
      (
        await get("LPToken")
      ).address,
      (
        await get("LibraUSDPool")
      ).address,
    )
/*
    await execute(
      "LibraUSDmMetaPool",
      { from: deployer, log: true },
      "transferOwnership",
      MULTISIG_ADDRESS,
    )
*/
  }

  const lpTokenAddress = (await read("LibraUSDmMetaPool", "swapStorage"))
    .lpToken
  log(`Libra USDm MetaSwap LP Token at ${lpTokenAddress}`)

  await save("LibraUSDmMetaPoolLPToken", {
    abi: (await get("LPToken")).abi,
    address: lpTokenAddress,
  })
}

export default func
func.tags = ["USDmMetaPool"]
func.dependencies = [
  "Core",
  "USDmMetaPoolTokens",
  "USDPool",
  "MetaSwapUtils",
  "AmplificationUtils",
]
