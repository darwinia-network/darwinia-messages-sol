const { expect } = require("chai");
const { solidity } = require("ethereum-waffle");
const chai = require("chai");
const ethUtil = require('ethereumjs-util');
const abi = require('ethereumjs-abi');
const secp256k1 = require('secp256k1');

chai.use(solidity);

describe("darwinia<>bsc mapping token tests", () => {
  before(async () => {
  });

  it("test_bsc_flow", async function () {
      // lane
      // darwinia chain position 1
      // bsc chain position      2
      // darwinia inboundLanePosition  1 <-----> 1 outboundLanePosition bsc
      // darwinia outboundLanePosition 2 <-----> 2 inboundLanePosition  bsc
      // from darwinia to bsc
      
      /*******      deploy inboundLane/outboundLane     ********/
      // deploy inboundLane
      const inboundLaneContract = await ethers.getContractFactory("MockInboundLane");
      const darwiniaInboundLane = await inboundLaneContract.deploy(1, 1, 2, 1);
      await darwiniaInboundLane.deployed();
      const bscInboundLane = await inboundLaneContract.deploy(2, 2, 1, 2);
      await bscInboundLane.deployed();
      console.log("deploy mock inboundLane success");
      // deploy outboundLane
      const outboundLaneContract = await ethers.getContractFactory("MockOutboundLane");
      const darwiniaOutboundLane = await outboundLaneContract.deploy(1, 2, 2, 2, bscInboundLane.address);
      await darwiniaOutboundLane.deployed();
      const bscOutboundLane = await outboundLaneContract.deploy(2, 1, 1, 1, darwiniaInboundLane.address);
      await bscOutboundLane.deployed();
      console.log("deploy mock outboundLane success");
      /******* deploy inboundLane/outboundLane finished ********/

      // deploy fee market
      const feeMarketContract = await ethers.getContractFactory("MockFeeMarket");
      const feeMarket = await feeMarketContract.deploy();
      await feeMarket.deployed();
      /****** deploy fee market *****/

      /******* deploy mapping token factory at bsc *******/
      // deploy erc20 logic
      const mappingTokenContract = await ethers.getContractFactory("MappingERC20");
      const mappingToken = await mappingTokenContract.deploy();
      await mappingToken.deployed();
      console.log("deploy erc20 logic success");
      // deploy mapping token factory
      const mapping_token_factory = await ethers.getContractFactory("FungibleMappingTokenFactory");
      const mtf = await mapping_token_factory.deploy();
      await mtf.deployed();
      console.log("mapping-token-factory address", mtf.address);
      /******* deploy mapping token factory  end *******/

      /******* deploy backing at darwinia ********/
      backingContract = await ethers.getContractFactory("FungibleTokenBacking");
      const backing = await backingContract.deploy();
      await backing.deployed();
      console.log("backing address", backing.address);
      /******* deploy backing end ***************/

      //********** configure mapping-token-factory ***********
      // init owner
      await mtf.initialize(1, backing.address, feeMarket.address, "BSC");
      // set logic mapping token
      await mtf.setTokenContractLogic(0, mappingToken.address);
      await mtf.setTokenContractLogic(1, mappingToken.address);
      // add inboundLane
      await mtf.addInboundLane(backing.address, bscInboundLane.address);
      await mtf.addOutboundLane(bscOutboundLane.address);
      //************ configure mapping-token end *************

      //********* configure backing **************************
      // init owner
      await backing.initialize(2, mtf.address, feeMarket.address, "Darwinia");
      const [owner] = await ethers.getSigners();
      await backing.grantRole(backing.OPERATOR_ROLE(), owner.address);
      // add inboundLane
      await backing.addInboundLane(mtf.address, darwiniaInboundLane.address);
      // add outboundLane
      await backing.addOutboundLane(darwiniaOutboundLane.address);
      //********* configure backing end   ********************

      // use a mapping erc20 as original token
      const tokenName = "Darwinia Native Ring";
      const tokenSymbol = "RING";
      const originalContract = await ethers.getContractFactory("MappingERC20");
      const originalToken = await originalContract.deploy();
      await originalToken.deployed();
      await originalToken.initialize(tokenName, tokenSymbol, 9);

      const zeroAddress = "0x0000000000000000000000000000000000000000";

      // test register not enough fee
      await expect(backing.registerErc20Token(
          2,
          originalToken.address,
          tokenName,
          tokenSymbol,
          9,
          {value: ethers.utils.parseEther("9.9999999999")}
      )).to.be.revertedWith("HelixApp:not enough fee to pay");
      // test register successed
      await backing.registerErc20Token(2, originalToken.address, tokenName, tokenSymbol, 9, {value: ethers.utils.parseEther("10.0")});
      // check not exist
      expect(await backing.registeredTokens(originalToken.address)).to.equal(false);
      // confirmed
      await darwiniaOutboundLane.mock_confirm(1);
      // check register successed
      expect(await backing.registeredTokens(originalToken.address)).to.equal(true);
      expect(await mtf.tokenLength()).to.equal(1);
      const mappingTokenAddress = await mtf.allMappingTokens(0);
      
      // check unregistered
      expect(await backing.registeredTokens(zeroAddress)).to.equal(false);
      expect(await mtf.tokenLength()).to.equal(1);

      // test lock
      await originalToken.mint(owner.address, 1000);
      await originalToken.approve(backing.address, 1000);
      
      // test lock successful
      await mtf.changeDailyLimit(mappingTokenAddress, 1000);

      await expect(backing.lockAndRemoteIssuing(
          2,
          originalToken.address,
          owner.address,
          100,
          {value: ethers.utils.parseEther("9.999999999")}
      )).to.be.revertedWith("not enough fee to pay");
      // balance before
      await backing.lockAndRemoteIssuing(2, originalToken.address, owner.address, 100, {value: ethers.utils.parseEther("10.0")});
      await darwiniaOutboundLane.mock_confirm(2);
      // check lock and remote successed
      expect(await originalToken.balanceOf(backing.address)).to.equal(100);
      expect(await originalToken.balanceOf(owner.address)).to.equal(1000 - 100);
      // check issuing successed
      var mappedToken = await ethers.getContractAt("MappingERC20", mappingTokenAddress);
      expect(await mappedToken.balanceOf(owner.address)).to.equal(100);

      // test lock failed
      await mtf.changeDailyLimit(mappingTokenAddress, 0);
      const balanceBefore = await ethers.provider.getBalance(owner.address);
      await backing.lockAndRemoteIssuing(2, originalToken.address, owner.address, 100, {value: ethers.utils.parseEther("50.0")});
      const balanceAfter = await ethers.provider.getBalance(owner.address);
      expect(balanceBefore - balanceAfter > ethers.utils.parseEther("10.0")).to.equal(true);
      expect(balanceBefore - balanceAfter < ethers.utils.parseEther("10.1")).to.equal(true);
      expect(await originalToken.balanceOf(backing.address)).to.equal(200);
      expect(await originalToken.balanceOf(owner.address)).to.equal(1000 - 200);
      await darwiniaOutboundLane.mock_confirm(3);
      expect(await originalToken.balanceOf(backing.address)).to.equal(100);
      expect(await originalToken.balanceOf(owner.address)).to.equal(1000 - 100);

      // test burn and unlock
      //approve to mapping-token-factory
      await mappedToken.approve(mtf.address, 1000);
      await backing.changeDailyLimit(originalToken.address, 1000);
      await mtf.burnAndRemoteUnlockWaitingConfirm(1, mappingTokenAddress, owner.address, 21, {value: ethers.utils.parseEther("10.0")});
      expect(await originalToken.balanceOf(owner.address)).to.equal(1000 - 100 + 21);
      // before confirmed
      expect(await mappedToken.balanceOf(owner.address)).to.equal(100 - 21);
      expect(await mappedToken.balanceOf(mtf.address)).to.equal(21);
      // after confirmed
      await bscOutboundLane.mock_confirm(1);
      expect(await mappedToken.balanceOf(owner.address)).to.equal(100 - 21);
      expect(await mappedToken.balanceOf(mtf.address)).to.equal(0);

      // test burn and unlock failed(daily limited)
      await backing.changeDailyLimit(originalToken.address, 0);

      //const balanceBurnBefore = await ethers.provider.getBalance(owner.address);
      const tx = await mtf.burnAndRemoteUnlockWaitingConfirm(
          1,
          mappingTokenAddress,
          owner.address,
          7,
          {
              value: ethers.utils.parseEther("10.0"),
              gasPrice: 20000000000
          }
      );
      //const balanceBurnAfter = await ethers.provider.getBalance(owner.address);
      //const receipt = await tx.wait();
      //const gasUsed = receipt.gasUsed;
      //expect(balanceBurnBefore - balanceBurnAfter).to.equal(10000000000000000000 + gasUsed * 20000000000);
      expect(await originalToken.balanceOf(owner.address)).to.equal(1000 - 100 + 21);
      // before confirmed
      expect(await mappedToken.balanceOf(owner.address)).to.equal(100 - 21 - 7);
      expect(await mappedToken.balanceOf(mtf.address)).to.equal(7);
      // after confirmed
      await bscOutboundLane.mock_confirm(2);
      expect(await mappedToken.balanceOf(owner.address)).to.equal(100 - 21);
      expect(await mappedToken.balanceOf(mtf.address)).to.equal(0);

      expect(await mappedToken.name()).to.equal(tokenName + "[Darwinia>");
      expect(await mappedToken.symbol()).to.equal("x" + tokenSymbol);
  });
  it("test_bsc_guard", async function () {
      const tokenName = "Darwinia Native Ring";
      const tokenSymbol = "RING";
      const originalContract = await ethers.getContractFactory("MappingERC20");
      const originalToken = await originalContract.deploy();
      await originalToken.deployed();
      await originalToken.initialize(tokenName, tokenSymbol, 9);
      const [owner] = await ethers.getSigners();
      await originalToken.mint(owner.address, 1000);

      // test guard
      let wallets = [];
      for (let i = 0; i < 3; i++) {
          const wallet = ethers.Wallet.createRandom();
          wallets.push(wallet);
      }
      wallets = wallets.sort((x, y) => {
          return x.address.toLowerCase().localeCompare(y.address.toLowerCase())
      });
      const guardContract = await ethers.getContractFactory("Guard");
      const guard = await guardContract.deploy([wallets[0].address, wallets[1].address, wallets[2].address], 3, 60, owner.address);
      await guard.deployed();

      await originalToken.approve(guard.address, 1000);
      await guard.deposit(1, originalToken.address, wallets[1].address, 100);
      await guard.deposit(2, originalToken.address, wallets[2].address, 200);

      // encode value
      const structHash =
          ethUtil.keccak256(
              abi.rawEncode(
                  ['bytes4', 'bytes', 'uint256'],
                  [abi.methodID('claim', [ 'uint256[]', 'bytes[]' ]),
                  abi.rawEncode(['uint256[]'], [[1, 2]]),
                  0]
              )
          );
      // cannot claim without signatures
      await expect(guard.claimByTimeout(2)).to.be.revertedWith("Guard: claim at invalid time");

      const dataHash = await guard.encodeDataHash(structHash);
      console.log("data hash", dataHash);
      const signatures = wallets.map((wallet) => {
          const address = wallet.address;
          const privateKey = ethers.utils.arrayify(wallet.privateKey);
          const signatureECDSA = secp256k1.ecdsaSign(ethers.utils.arrayify(dataHash), privateKey);
          const ethRecID = signatureECDSA.recid + 27;
          const signature = Uint8Array.from(
              signatureECDSA.signature.join().split(',').concat(ethRecID)
          );
          return ethers.utils.hexlify(signature);
      });
      await guard.claim([1, 2], signatures);
      expect(await originalToken.balanceOf(wallets[1].address)).to.equal(100);
      expect(await originalToken.balanceOf(wallets[2].address)).to.equal(200);
  });
});

