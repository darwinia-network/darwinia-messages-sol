const feeMaketFixure = async () => {
  const VAULT = "0x0000000000000000000000000000000000000000"
  const COLLATERAL_PERORDER = ethers.utils.parseEther("10")
  const ASSIGNED_RELAYERS_NUMBER = 3;
  const SLASH_TIME = 100
  const RELAY_TIME = 100
  const [one, two, three] = await ethers.getSigners();
  const FeeMarket = await ethers.getContractFactory("FeeMarket")
  const feeMarket = await FeeMarket.deploy(VAULT, COLLATERAL_PERORDER, ASSIGNED_RELAYERS_NUMBER, SLASH_TIME, RELAY_TIME)
  let overrides = {
      value: ethers.utils.parseEther("100")
  }
  const [oneFee, twoFee, threeFee] = [
    ethers.utils.parseEther("10"),
    ethers.utils.parseEther("20"),
    ethers.utils.parseEther("30")
  ]
  await feeMarket.connect(one).enroll(feeMarket.SENTINEL_HEAD, oneFee)
  return {feeMarket}
}

module.exports = {
  feeMaketFixure
}
