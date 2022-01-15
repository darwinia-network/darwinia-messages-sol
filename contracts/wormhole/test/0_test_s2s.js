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

  it("test_s2s_native", async function () {
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
      var mappingRing = await ethers.getContractAt("MappingERC20", mappingToken0);
      expect(await mappingRing.balanceOf(owner.address)).to.equal(1000);

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
      await mappingRing.approve(mtf.address, 100000);
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
      expect(await mappingRing.balanceOf(owner.address)).to.equal(1000-300);
      expect(await mappingRing.balanceOf(mtf.address)).to.equal(300);

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
      expect(await mappingRing.balanceOf(owner.address)).to.equal(1000);
      expect(await mappingRing.balanceOf(mtf.address)).to.equal(0);

      // burn another amount of mapping token
      await mtf.burnAndRemoteUnlockWaitingConfirm(
          26100,
          62867101,
          mappingToken0,
          "0xd43593c715fdd31c61141abd04a99fd6822c8558854ccde39a5684e7a56da27d",
          100
      );
      // check balance
      expect(await mappingRing.balanceOf(owner.address)).to.equal(1000-100);
      expect(await mappingRing.balanceOf(mtf.address)).to.equal(100);
      const message_nonce_02 = await precompile_bridger.outbound_latest_generated_nonce("0x726f6c69");
      // confirm return true
      await mtf.connect(system_signer).confirmBurnAndRemoteUnlock("0x726f6c69", message_nonce_02, true);
      // the token burnt
      expect(await mappingRing.balanceOf(owner.address)).to.equal(1000-100);
      expect(await mappingRing.balanceOf(mtf.address)).to.equal(0);
      // error if confirmed twice
      await expect(mtf.connect(system_signer).confirmBurnAndRemoteUnlock("0x726f6c69", message_nonce_02, true))
          .to.be.revertedWith("invalid unconfirmed message");

      // test pause
      await mtf.pause();
      // cannot register
      const original_kton = "0x6Be02d1d3665660d22FF9624b7BE0551ee1Ac91b";
      await expect(mtf.connect(system_signer).newErc20Contract(
          0, // token type
          "Darwinia Kton",
          "KTON",
          18,
          backing,
          original_kton
      )).to.be.revertedWith("Pausable: paused");
      // cannot issuing
      await expect(mtf.connect(system_signer).issueMappingToken(
          mappingToken0,
          system_account,
          1000
      )).to.be.revertedWith("Pausable: paused");
      // cannot redeem
      await expect(mtf.burnAndRemoteUnlockWaitingConfirm(
          26100,
          62867101,
          mappingToken0,
          "0xd43593c715fdd31c61141abd04a99fd6822c8558854ccde39a5684e7a56da27d",
          300
      )).to.be.revertedWith("Pausable: paused");
      // unpause
      await mtf.unpause();
      // unpause: register success
      await mtf.connect(system_signer).newErc20Contract(
          0, // token type
          "Darwinia Kton",
          "KTON",
          18,
          backing,
          original_kton
      );
      expect(await mtf.tokenLength()).to.equal(2);

      const mappingToken1 = await mtf.allMappingTokens(1);
      // unpause: issuing from system
      await mtf.setDailyLimit(mappingToken1, 1000);
      await mtf.connect(system_signer).issueMappingToken(
          mappingToken1,
          owner.address,
          999
      );

      // check issuing successed
      var mappingKton = await ethers.getContractAt("MappingERC20", mappingToken1);
      expect(await mappingKton.balanceOf(owner.address)).to.equal(999);

      // unpause: burn mapping token
      await mappingKton.approve(mtf.address, 100000);
      await mtf.burnAndRemoteUnlockWaitingConfirm(
          26100,
          62867101,
          mappingToken1,
          "0xd43593c715fdd31c61141abd04a99fd6822c8558854ccde39a5684e7a56da27d",
          100
      );
      // check balance
      expect(await mappingKton.balanceOf(owner.address)).to.equal(999-100);
      expect(await mappingKton.balanceOf(mtf.address)).to.equal(100);
  });

  it("test_s2s_erc20", async function () {
      // deploy kton contract
      const ktonContract = await ethers.getContractFactory("MappingERC20");
      const wkton = await ktonContract.deploy();
      await wkton.deployed();
      await wkton.initialize("Darwinia wkton", "WKTON", 18);

      const [owner] = await ethers.getSigners();
      wkton.mint(owner.address, 10000);

      // deploy backing
      const s2s_backing = await ethers.getContractFactory("Sub2SubBacking");
      const backing = await s2s_backing.deploy();
      await backing.deployed();

      // init owner
      await backing.initialize();
      // owner set some params
      await backing.setMessagePalletIndex(43);
      //await backing.changeDailyLimit(1000000000);

      // impersonate system account
      const system_account = await backing.SYSTEM_ACCOUNT();
      await hre.network.provider.request({
          method: "hardhat_impersonateAccount",
          params: [system_account],
      });
      const system_signer = await ethers.getSigner(system_account)

      // register
      await backing.registerErc20Token(
          1180,
          100000000,
          0x726f6c69,
          wkton.address,
          await wkton.name(),
          await wkton.symbol(),
          await wkton.decimals()
      );
      expect(await backing.registeredTokens(wkton.address)).to.equal(false);
      var precompile_bridger = await ethers.getContractAt("MockSubToSubBridge", "0x0000000000000000000000000000000000000018");
      const message_nonce = await precompile_bridger.outbound_latest_generated_nonce("0x726f6c69");
      await backing.connect(system_signer).confirmRemoteLockOrRegister(
          0x726f6c69,
          message_nonce,
          true
      );
      expect(await backing.registeredTokens(wkton.address)).to.equal(true);

      // lock and remote issue
      await expect(backing.lockAndRemoteIssuing(
        1180,
        1000000000,
        0x726f6c69,
        wkton.address,
        "0x0000000000000000000000000000000000000001",
        1000)).to.be.revertedWith("ERC20: transfer amount exceeds allowance");
      // must approve first
      await wkton.approve(backing.address, 100000);
      await backing.lockAndRemoteIssuing(
        1180,
        1000000000,
        0x726f6c69,
        wkton.address,
        "0x0000000000000000000000000000000000000001",
        1000);
      expect(await wkton.balanceOf(owner.address)).to.equal(10000 - 1000);
      // confirm failed
      const lock_nonce = await precompile_bridger.outbound_latest_generated_nonce("0x726f6c69");
      await backing.connect(system_signer).confirmRemoteLockOrRegister(
          0x726f6c69,
          lock_nonce,
          false
      );
      expect(await wkton.balanceOf(owner.address)).to.equal(10000);
      // confirm successed
      await backing.lockAndRemoteIssuing(
        1180,
        1000000000,
        0x726f6c69,
        wkton.address,
        "0x0000000000000000000000000000000000000001",
        1000);
      expect(await wkton.balanceOf(owner.address)).to.equal(10000 - 1000);
      const lock_success_nonce = await precompile_bridger.outbound_latest_generated_nonce("0x726f6c69");
      await backing.connect(system_signer).confirmRemoteLockOrRegister(
          0x726f6c69,
          lock_success_nonce,
          true
      )
      expect(await wkton.balanceOf(owner.address)).to.equal(10000 - 1000);

      await expect(backing.connect(system_signer).unlockFromRemote(
        wkton.address,
        owner.address,
        500
      )).to.be.revertedWith("DailyLimit:: expendDailyLimit: Out ot daily limit.");
      await backing.changeDailyLimit(wkton.address, 100000);
      await backing.connect(system_signer).unlockFromRemote(
          wkton.address,
          owner.address,
          500
      );
      expect(await wkton.balanceOf(owner.address)).to.equal(10000 - 1000 + 500);
      await expect(backing.connect(system_signer).unlockFromRemote(
        wkton.address,
        owner.address,
        600
      )).to.be.revertedWith("ERC20: transfer amount exceeds balance");
  });
});

