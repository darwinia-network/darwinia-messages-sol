const { expect } = require("chai");
const { solidity } = require("ethereum-waffle");
const chai = require("chai");
const ethUtil = require('ethereumjs-util');
const abi = require('ethereumjs-abi');
const secp256k1 = require('secp256k1');

chai.use(solidity);

describe("darwinia<>bsc erc1155 mapping token tests", () => {
  before(async () => {
      const [owner] = await ethers.getSigners();
      await network.provider.send("hardhat_setBalance", [
          owner.address,
          "0x21e19e0c9bab2400000",
      ]);
  });

  it("test_flow", async function () {
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

      // deploy darwiniaMessageHandle
      const messageHandleContract = await ethers.getContractFactory("DarwiniaMessageHandle");
      const darwiniaMessageHandle = await messageHandleContract.deploy();
      await darwiniaMessageHandle.deployed();
      const bscMessageHandle = await messageHandleContract.deploy();
      await bscMessageHandle.deployed();
      /******* deploy darwiniaMessageHandle ******/
      // configure darwiniaMessageHandle
      await darwiniaMessageHandle.setBridgeInfo(2, bscMessageHandle.address);
      await darwiniaMessageHandle.setFeeMarket(feeMarket.address);
      await darwiniaMessageHandle.setInboundLane(darwiniaInboundLane.address);
      await darwiniaMessageHandle.setOutboundLane(darwiniaOutboundLane.address);
      await bscMessageHandle.setBridgeInfo(1, darwiniaMessageHandle.address);
      await bscMessageHandle.setFeeMarket(feeMarket.address);
      await bscMessageHandle.setInboundLane(bscInboundLane.address);
      await bscMessageHandle.setOutboundLane(bscOutboundLane.address);
      // end configure

      // deploy erc1155 metadata
      const materialAttrContract = await ethers.getContractFactory("Erc1155MaterialMetadata");
      const materialAttrContractOnBsc = await materialAttrContract.deploy();
      await materialAttrContractOnBsc.deployed();
      const materialAttrContractOnDarwinia = await materialAttrContract.deploy();
      await materialAttrContractOnDarwinia.deployed();
      console.log("deploy erc1155 attribute serializer success");
      /******* deploy mapping token factory at bsc *******/
      // deploy mapping token factory
      const mapping_token_factory = await ethers.getContractFactory("Erc1155MappingTokenFactorySupportingConfirm");
      const mtf = await mapping_token_factory.deploy();
      await mtf.deployed();
      console.log("mapping-token-factory address", mtf.address);
      /******* deploy mapping token factory  end *******/

      /******* deploy backing at darwinia ********/
      backingContract = await ethers.getContractFactory("Erc1155BackingSupportingConfirm");
      const backing = await backingContract.deploy();
      await backing.deployed();
      console.log("backing address", backing.address);
      /******* deploy backing end ***************/

      //********** configure mapping-token-factory ***********
      // init owner
      await mtf.initialize(bscMessageHandle.address, backing.address);
      await bscMessageHandle.grantRole(bscMessageHandle.CALLER_ROLE(), mtf.address);
      console.log("configure mapping token factory finished");
      //************ configure mapping-token end *************

      //********* configure backing **************************
      // init owner
      await backing.initialize(darwiniaMessageHandle.address, mtf.address);
      const [owner] = await ethers.getSigners();
      await backing.grantRole(backing.OPERATOR_ROLE(), owner.address);
      await darwiniaMessageHandle.grantRole(darwiniaMessageHandle.CALLER_ROLE(), backing.address);
      console.log("configure backing finished");
      //********* configure backing end   ********************

      // this contract can be any erc1155 contract. We use MappingToken as an example
      const originalContract = await ethers.getContractFactory("Erc1155MappingToken");
      const originalToken = await originalContract.deploy(materialAttrContractOnBsc.address);
      await originalToken.deployed();
      console.log("generate original token contract finished");

      const zeroAddress = "0x0000000000000000000000000000000000000000";

      // test register not enough fee
      await expect(backing.registerErc1155Token(
          originalToken.address,
          materialAttrContractOnDarwinia.address,
          {value: ethers.utils.parseEther("9.9999999999")}
      )).to.be.revertedWith("DarwiniaMessageHandle:not enough fee to pay");
      // test register successed
      await backing.registerErc1155Token(
          originalToken.address,
          materialAttrContractOnDarwinia.address,
          {value: ethers.utils.parseEther("10.0")});
      // check not exist
      expect((await backing.registeredTokens(originalToken.address))).to.equal(false);
      // confirmed
      await darwiniaOutboundLane.mock_confirm(1);
      // check register successed
      expect((await backing.registeredTokens(originalToken.address))).to.equal(true);
      expect(await mtf.tokenLength()).to.equal(1);
      const mappingTokenAddress = await mtf.allMappingTokens(0);
      console.log("test register erc1155 finished");
      
      // check unregistered
      expect((await backing.registeredTokens(zeroAddress))).to.equal(false);
      expect(await mtf.tokenLength()).to.equal(1);

      // test lock
      await originalToken.mintBatch(owner.address, [1001, 1002, 1003], [1000, 2000, 3000]);
      await originalToken.setApprovalForAll(backing.address, true);
      
      var mappedToken = await ethers.getContractAt("Erc1155MappingToken", mappingTokenAddress);
      // test lock successful
      await expect(backing.lockAndRemoteIssuing(
          originalToken.address,
          owner.address,
          [1001, 1002, 1003],
          [10, 20, 30],
          {value: ethers.utils.parseEther("9.999999999")}
      )).to.be.revertedWith("not enough fee to pay");
      // balance before
      expect(await originalToken.balanceOf(owner.address, 1001)).to.equal(1000);
      expect(await originalToken.balanceOf(owner.address, 1002)).to.equal(2000);
      expect(await originalToken.balanceOf(owner.address, 1003)).to.equal(3000);
      await backing.lockAndRemoteIssuing(originalToken.address, owner.address, [1001, 1002, 1003], [10, 20, 30], {value: ethers.utils.parseEther("10.0")});
      await darwiniaOutboundLane.mock_confirm(2);
      // check lock and remote successed
      expect(await originalToken.balanceOf(owner.address, 1001)).to.equal(1000-10);
      expect(await originalToken.balanceOf(owner.address, 1002)).to.equal(2000-20);
      expect(await originalToken.balanceOf(owner.address, 1003)).to.equal(3000-30);

      expect(await originalToken.balanceOf(backing.address, 1001)).to.equal(10);
      expect(await originalToken.balanceOf(backing.address, 1002)).to.equal(20);
      expect(await originalToken.balanceOf(backing.address, 1003)).to.equal(30);
      // check issuing successed
      expect(await mappedToken.balanceOf(owner.address, 1001)).to.equal(10);
      expect(await mappedToken.balanceOf(owner.address, 1002)).to.equal(20);
      expect(await mappedToken.balanceOf(owner.address, 1003)).to.equal(30);
      console.log("test issuing erc1155 finished");

      // test burn and unlock
      await originalToken.transferOwnership(backing.address);
      //approve to mapping-token-factory
      await mappedToken.setApprovalForAll(mtf.address, true);

      await mtf.burnAndRemoteUnlockWaitingConfirm(mappingTokenAddress, owner.address, [1001], [3], {value: ethers.utils.parseEther("10.0")});
      // before confirmed
      expect(await mappedToken.balanceOf(mtf.address, 1001)).to.equal(3);
      // after confirmed
      await bscOutboundLane.mock_confirm(1);
      expect(await originalToken.balanceOf(owner.address, 1001)).to.equal(1000-10+3);
      console.log("test burning erc1155 finished");
  });
});

