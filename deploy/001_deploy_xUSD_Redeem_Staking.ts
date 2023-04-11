import { HardhatRuntimeEnvironment } from 'hardhat/types'
import { DeployFunction } from 'hardhat-deploy/types'
import { waitSeconds } from '../helper/utils'
import { XUSD, PriceOracleAggregator, Redeem, Staking } from '../types'

const deploy: DeployFunction = async (hre: HardhatRuntimeEnvironment) => {
  const { deployments, ethers } = hre
  const { deploy } = deployments
  const [deployer] = await ethers.getSigners()

  /////////////////////////
  //        xUSD         //
  /////////////////////////
  await deploy('xUSD', {
    from: deployer.address,
    args: [],
    log: true,
  })

  const xUSD = <XUSD>await ethers.getContract('xUSD')
  const minterRole = await xUSD.MINTER_ROLE()

  ///////////////////////////
  // PriceOracleAggregator //
  ///////////////////////////
  await deploy('PriceOracleAggregator', {
    from: deployer.address,
    args: [xUSD.address],
    log: true,
  })

  const priceOracleAggregator = <PriceOracleAggregator>(
    await ethers.getContract('PriceOracleAggregator')
  )

  ///////////////////////////
  // stETH & PriceAdapter  //
  ///////////////////////////
  let stETH = '',
    stETHPriceAdpater = ''
  stETH = (
    await deploy('stETH', {
      from: deployer.address,
      contract: 'MockToken',
      args: ['Mocked stETH', 'stETH', 18],
      log: true,
    })
  ).address
  stETHPriceAdpater = (
    await deploy('stETHMockChainlinkUSDAdapter', {
      from: deployer.address,
      contract: 'MockChainlinkUSDAdapter',
      args: [ethers.utils.parseUnits('1900', 8)],
      log: true,
    })
  ).address
  await (
    await priceOracleAggregator.updateOracleForAsset(stETH, stETHPriceAdpater)
  ).wait()

  ///////////////////////////
  //  rETH & PriceAdapter  //
  ///////////////////////////
  let rETH = '',
    rETHPriceAdpater = ''
  rETH = (
    await deploy('rETH', {
      from: deployer.address,
      contract: 'MockToken',
      args: ['Mocked rETH', 'rETH', 18],
      log: true,
    })
  ).address
  rETHPriceAdpater = (
    await deploy('rETHMockChainlinkUSDAdapter', {
      from: deployer.address,
      contract: 'MockChainlinkUSDAdapter',
      args: [ethers.utils.parseUnits('2040', 8)],
      log: true,
    })
  ).address
  await (
    await priceOracleAggregator.updateOracleForAsset(rETH, rETHPriceAdpater)
  ).wait()

  ///////////////////////////
  // cbETH & PriceAdapter  //
  ///////////////////////////
  let cbETH = '',
    cbETHPriceAdpater = ''
  cbETH = (
    await deploy('cbETH', {
      from: deployer.address,
      contract: 'MockToken',
      args: ['Mocked cbETH', 'cbETH', 18],
      log: true,
    })
  ).address
  cbETHPriceAdpater = (
    await deploy('cbETHMockChainlinkUSDAdapter', {
      from: deployer.address,
      contract: 'MockChainlinkUSDAdapter',
      args: [ethers.utils.parseUnits('1950', 8)],
      log: true,
    })
  ).address
  await (
    await priceOracleAggregator.updateOracleForAsset(cbETH, cbETHPriceAdpater)
  ).wait()

  ///////////////////////////
  //        Redeem         //
  ///////////////////////////
  await deploy('Redeem', {
    from: deployer.address,
    args: [xUSD.address, priceOracleAggregator.address],
    log: true,
  })

  const redeem = <Redeem>await ethers.getContract('Redeem')

  //   await (await redeem.addSupportedCoin(stETH)).wait()
  //   await (await redeem.addSupportedCoin(rETH)).wait()
  //   await (await redeem.addSupportedCoin(cbETH)).wait()

  await (await xUSD.grantRole(minterRole, redeem.address)).wait()

  ///////////////////////////
  //        Staking        //
  ///////////////////////////
  await deploy('Staking', {
    from: deployer.address,
    args: [xUSD.address],
    log: true,
  })

  const staking = <Staking>await ethers.getContract('Staking')

  await (await xUSD.grantRole(minterRole, staking.address)).wait()

  ///////////////////////////
  //        VERIFY         //
  ///////////////////////////
  if (hre.network.name !== 'localhost' && hre.network.name !== 'hardhat') {
    await waitSeconds(10)
    console.log('=====> Verifing ....')
    try {
      await hre.run('verify:verify', {
        address: xUSD.address,
        contract: 'contracts/xUSD.sol:xUSD',
        constructorArguments: [],
      })
    } catch (_) {}
    await waitSeconds(10)
    try {
      await hre.run('verify:verify', {
        address: priceOracleAggregator.address,
        contract:
          'contracts/oracle/PriceOracleAggregator.sol:PriceOracleAggregator',
        constructorArguments: [],
      })
    } catch (_) {}
    await waitSeconds(10)
    try {
      await hre.run('verify:verify', {
        address: redeem.address,
        contract: 'contracts/Redeem.sol:Redeem',
        constructorArguments: [xUSD.address, priceOracleAggregator.address],
      })
    } catch (_) {}
    await waitSeconds(10)
    try {
      await hre.run('verify:verify', {
        address: staking.address,
        contract: 'contracts/Staking.sol:Staking',
        constructorArguments: [xUSD.address],
      })
    } catch (_) {}
  }
}

export default deploy
deploy.tags = ['xUSD']
