import { HardhatRuntimeEnvironment } from "hardhat/types"
import { DeployFunction } from "hardhat-deploy/types"
import { BigNumber } from "ethers"

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { getNamedAccounts, deployments } = hre
  const { deployer } = await getNamedAccounts()
  const { execute, read, log } = deployments

  const T = await deployments.get("T")

  // We're minting 10B T, which is the value of the T supply on the production
  // environment.

  await execute(
    "T",
    { from: deployer },
    "mint",
    deployer,
    BigNumber.from(10).pow(28)
  )

  const tTotalSupply = await read("T", "totalSupply")

  log("minted", tTotalSupply.toString(), "T")
}

export default func

func.tags = ["MintT"]
func.dependencies = ["T"]
