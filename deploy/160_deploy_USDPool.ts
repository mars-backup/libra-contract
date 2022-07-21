import { HardhatRuntimeEnvironment } from "hardhat/types"
import { DeployFunction } from "hardhat-deploy/types"

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre
  const { execute, get, getOrNull, log, read, save } = deployments
  const { deployer } = await getNamedAccounts()

  const libraUSDPool = await getOrNull("LibraUSDPool")
  if (libraUSDPool) {
    log(`reusing "LibraUSDPool" at ${libraUSDPool.address}`)
  } else {
    const TOKEN_ADDRESSES = [
      (await get("BUSD")).address,
      (await get("USDC")).address,
      (await get("USDT")).address,
    ]
    const TOKEN_DECIMALS = [18, 18, 18]
    const LP_TOKEN_NAME = "Libra BUSD/USDC/USDT"
    const LP_TOKEN_SYMBOL = "lbrUSD"
    const INITIAL_A = 200
    const SWAP_FEE = 4e6 // 4bps
    const ADMIN_FEE = 0

    const receipt = await execute(
      "SwapDeployer",
      { from: deployer, log: true },
      "deploy",
      (
        await get("SwapFlashLoan")
      ).address,
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
    )

    const newPoolEvent = receipt?.events?.find(
      (e: any) => e["event"] == "NewSwapPool",
    )
    const usdSwapAddress = newPoolEvent["args"]["swapAddress"]
    log(`deployed USD pool (targeting "SwapFlashLoan") at ${usdSwapAddress}`)
    await save("LibraUSDPool", {
      abi: (await get("SwapFlashLoan")).abi,
      address: usdSwapAddress,
    })
  }

  const lpTokenAddress = (await read("LibraUSDPool", "swapStorage")).lpToken
  log(`USD pool LP Token at ${lpTokenAddress}`)

  await save("LibraUSDPoolLPToken", {
    abi: (await get("LPToken")).abi,
    address: lpTokenAddress,
  })
}

export default func
func.tags = ["USDPool"]
func.dependencies = [
  "SwapUtils",
  "SwapDeployer",
  "SwapFlashLoan",
  "USDPoolTokens",
  "LPToken",
]
