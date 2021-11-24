const { expect } = require("chai");
const { solidity } = require("ethereum-waffle");
const chai = require("chai");

chai.use(solidity);

describe("sub<>sub mapping token tests", () => {
  before(async () => {
      // mock precompile contracts
      const mockSub2SubBridgeArtifact = await artifacts.readArtifact("MockSubToSubBridge");
      await ethers.provider.send("hardhat_setCode", [
          "0x0000000000000000000000000000000000000018",
          mockSub2SubBridgeArtifact.deployedBytecode,
      ]);
      const mockDispatchCallArtifact = await artifacts.readArtifact("MockDispatchCall");
      await ethers.provider.send("hardhat_setCode", [
          "0x0000000000000000000000000000000000000019",
          mockDispatchCallArtifact.deployedBytecode,
      ]);

      // give money to system account
      await network.provider.send("hardhat_setBalance", [
          "0x6D6F646C6461722f64766D700000000000000000",
          "0x10000000000000000000000",
      ]);
  });

  it("test_s2s_flow", async function () {
      // deploy erc20 logic
      const mappingTokenContract = await ethers.getContractFactory("MappingERC20");
      const mappingToken = await mappingTokenContract.deploy();
      await mappingToken.deployed();

      // deploy mapping token factory
      const mapping_token_factory = await ethers.getContractFactory("Sub2SubMappingTokenFactory");
      const mtf = await mapping_token_factory.deploy();
      await mtf.deployed();

      // init owner
      await mtf.initialize();
      // owner set some params
      await mtf.setTokenContractLogic(0, mappingToken.address);
      await mtf.setTokenContractLogic(1, mappingToken.address);
      await mtf.setMessagePalletIndex(43);
      await mtf.setLaneId("0x726f6c69");

      // impersonate system account
      const system_account = await mtf.SYSTEM_ACCOUNT();
      expect(await mtf.tokenLength()).to.equal(0);
      await hre.network.provider.request({
          method: "hardhat_impersonateAccount",
          params: [system_account],
      });
      const system_signer = await ethers.getSigner(system_account)

      // register new erc20 mapping token
      const backing = "0x28F900e9928C356287Bb8806C9044168560dEE80";
      const original = "0x6D6F646C64612f6272696e670000000000000000";
      await mtf.connect(system_signer).newErc20Contract(
          0, // token type
          "Darwinia RING",
          "RING",
          9,
          backing,
          original
      );

      // check register successed
      expect(await mtf.tokenLength()).to.equal(1);
      const mappingToken0 = await mtf.allMappingTokens(0);
      expect(await mtf.mappingToken(backing, original)).to.equal(mappingToken0);

      // issuing mapping token
      // check daily limited
      await expect(mtf.connect(system_signer).issueMappingToken(
          mappingToken0,
          system_account,
          1000
      )).to.be.revertedWith("DailyLimit:: expendDailyLimit: Out ot daily limit.");

      // set daily limit
      await mtf.setDailyLimit(mappingToken0, 1000);
      const [owner] = await ethers.getSigners();
      // check normal accout forbidden
      await expect(mtf.issueMappingToken(
          mappingToken0,
          owner.address,
          1000
      )).to.be.revertedWith("System: caller is not the system account");

      // issuing from system
      await mtf.connect(system_signer).issueMappingToken(
          mappingToken0,
          owner.address,
          1000
      );

      // check issuing successed
      var mappingTokenProxy = await ethers.getContractAt("MappingERC20", mappingToken0);
      expect(await mappingTokenProxy.balanceOf(owner.address)).to.equal(1000);

      // test burn and remote unlock waiting confirm
      // must approve first
      await expect(mtf.burnAndRemoteUnlockWaitingConfirm(
          26100,
          62867101,
          mappingToken0,
          "0xd43593c715fdd31c61141abd04a99fd6822c8558854ccde39a5684e7a56da27d",
          300
      )).to.be.revertedWith("ERC20: transfer amount exceeds allowance");

      // approve
      await mappingTokenProxy.approve(mtf.address, 100000);
      // not enough balance
      await expect(mtf.burnAndRemoteUnlockWaitingConfirm(
          26100,
          62867101,
          mappingToken0,
          "0xd43593c715fdd31c61141abd04a99fd6822c8558854ccde39a5684e7a56da27d",
          1001
      )).to.be.revertedWith("ERC20: transfer amount exceeds balance");
      // burn success
      await mtf.burnAndRemoteUnlockWaitingConfirm(
          26100,
          62867101,
          mappingToken0,
          "0xd43593c715fdd31c61141abd04a99fd6822c8558854ccde39a5684e7a56da27d",
          300
      );
      // check the balance locked in mapping token factory contract
      expect(await mappingTokenProxy.balanceOf(owner.address)).to.equal(1000-300);
      expect(await mappingTokenProxy.balanceOf(mtf.address)).to.equal(300);

      // confirm burn process
      // get message nonce
      var precompile_bridger = await ethers.getContractAt("MockSubToSubBridge", "0x0000000000000000000000000000000000000018");
      const message_nonce = await precompile_bridger.outbound_latest_generated_nonce("0x726f6c69");
      // normal account has no right to call confirm
      await expect(mtf.confirmBurnAndRemoteUnlock("0x726f6c69", message_nonce, false))
          .to.be.revertedWith("System: caller is not the system account");
      // confirm return false
      await mtf.connect(system_signer).confirmBurnAndRemoteUnlock("0x726f6c69", message_nonce, false);
      // the token returns to user
      expect(await mappingTokenProxy.balanceOf(owner.address)).to.equal(1000);
      expect(await mappingTokenProxy.balanceOf(mtf.address)).to.equal(0);

      // burn another amount of mapping token
      await mtf.burnAndRemoteUnlockWaitingConfirm(
          26100,
          62867101,
          mappingToken0,
          "0xd43593c715fdd31c61141abd04a99fd6822c8558854ccde39a5684e7a56da27d",
          100
      );
      // check balance
      expect(await mappingTokenProxy.balanceOf(owner.address)).to.equal(1000-100);
      expect(await mappingTokenProxy.balanceOf(mtf.address)).to.equal(100);
      const message_nonce_02 = await precompile_bridger.outbound_latest_generated_nonce("0x726f6c69");
      // confirm return true
      await mtf.connect(system_signer).confirmBurnAndRemoteUnlock("0x726f6c69", message_nonce_02, true);
      // the token burnt
      expect(await mappingTokenProxy.balanceOf(owner.address)).to.equal(1000-100);
      expect(await mappingTokenProxy.balanceOf(mtf.address)).to.equal(0);
      // error if confirmed twice
      await expect(mtf.connect(system_signer).confirmBurnAndRemoteUnlock("0x726f6c69", message_nonce_02, true))
          .to.be.revertedWith("invalid unconfirmed message");
  });
});

