const { expect } = require("chai");
const { solidity } = require("ethereum-waffle");
const chai = require("chai");
const ethUtil = require('ethereumjs-util');
const abi = require('ethereumjs-abi');
const secp256k1 = require('secp256k1');

chai.use(solidity);

describe("darwinia<>bsc erc721 mapping token tests", () => {
  before(async () => {
  });

  it("test_supporting_confirm_flow", async function () {
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

      // deploy erc721 serializer, local and remote
      const monkeyAttrContract = await ethers.getContractFactory("Erc721MonkeyAttributeSerializer");
      const monkeyAttrContractOnBsc = await monkeyAttrContract.deploy();
      await monkeyAttrContractOnBsc.deployed();
      const monkeyAttrContractOnDarwinia = await monkeyAttrContract.deploy();
      await monkeyAttrContractOnDarwinia.deployed();
      console.log("deploy erc721 attribute serializer success");
      /******* deploy mapping token factory at bsc *******/
      // deploy mapping token factory
      const mapping_token_factory = await ethers.getContractFactory("Erc721MappingTokenFactorySupportingConfirm");
      const mtf = await mapping_token_factory.deploy();
      await mtf.deployed();
      console.log("mapping-token-factory address", mtf.address);
      /******* deploy mapping token factory  end *******/

      /******* deploy backing at darwinia ********/
      backingContract = await ethers.getContractFactory("Erc721BackingSupportingConfirm");
      const backing = await backingContract.deploy();
      await backing.deployed();
      console.log("backing address", backing.address);
      /******* deploy backing end ***************/

      //********** configure mapping-token-factory ***********
      // init owner
      await mtf.initialize(bscMessageHandle.address, backing.address);
      await bscMessageHandle.grantRole(bscMessageHandle.CALLER_ROLE(), mtf.address);
      //************ configure mapping-token end *************

      //********* configure backing **************************
      // init owner
      await backing.initialize(darwiniaMessageHandle.address, mtf.address);
      const [owner] = await ethers.getSigners();
      await backing.grantRole(backing.OPERATOR_ROLE(), owner.address);
      await darwiniaMessageHandle.grantRole(darwiniaMessageHandle.CALLER_ROLE(), backing.address);
      //********* configure backing end   ********************

      // this contract can be any erc721 contract. We use MappingToken as an example
      const originalContract = await ethers.getContractFactory("Erc721MappingToken");
      const originalToken = await originalContract.deploy(monkeyAttrContractOnBsc.address);
      await originalToken.deployed();
      await monkeyAttrContractOnDarwinia.setAttr(1001, 18, 60);

      const zeroAddress = "0x0000000000000000000000000000000000000000";

      // test register not enough fee
      await expect(backing.registerErc721Token(
          originalToken.address,
          monkeyAttrContractOnDarwinia.address,
          monkeyAttrContractOnBsc.address,
          {value: ethers.utils.parseEther("9.9999999999")}
      )).to.be.revertedWith("DarwiniaMessageHandle:not enough fee to pay");
      // test register successed
      await backing.registerErc721Token(
          originalToken.address,
          monkeyAttrContractOnDarwinia.address,
          monkeyAttrContractOnBsc.address,
          {value: ethers.utils.parseEther("10.0")});
      // check not exist
      expect((await backing.registeredTokens(originalToken.address)).token).to.equal(zeroAddress);
      // confirmed
      await darwiniaOutboundLane.mock_confirm(1);
      // check register successed
      expect((await backing.registeredTokens(originalToken.address)).token).to.equal(originalToken.address);
      expect(await mtf.tokenLength()).to.equal(1);
      const mappingTokenAddress = await mtf.allMappingTokens(0);
      
      // check unregistered
      expect((await backing.registeredTokens(zeroAddress)).token).to.equal(zeroAddress);
      expect(await mtf.tokenLength()).to.equal(1);

      // test lock
      await originalToken.mint(owner.address, 1001);
      await originalToken.approve(backing.address, 1001);
      
      var mappedToken = await ethers.getContractAt("Erc721MappingToken", mappingTokenAddress);
      // test lock successful
      await expect(backing.lockAndRemoteIssuing(
          originalToken.address,
          owner.address,
          [1001],
          {value: ethers.utils.parseEther("9.999999999")}
      )).to.be.revertedWith("not enough fee to pay");
      // balance before
      expect(await originalToken.ownerOf(1001)).to.equal(owner.address);
      expect(await mappedToken.totalSupply()).to.equal(0);
      await backing.lockAndRemoteIssuing(originalToken.address, owner.address, [1001], {value: ethers.utils.parseEther("10.0")});
      await darwiniaOutboundLane.mock_confirm(2);
      // check lock and remote successed
      expect(await originalToken.ownerOf(1001)).to.equal(backing.address);
      expect(await mappedToken.totalSupply()).to.equal(1);
      expect(await mappedToken.tokenOfOwnerByIndex(owner.address, 0)).to.equal(1001);
      expect(await mappedToken.tokenByIndex(0)).to.equal(1001);
      // check issuing successed
      expect(await mappedToken.ownerOf(1001)).to.equal(owner.address);
      expect(await monkeyAttrContractOnBsc.getAge(1001)).to.equal(18);
      expect(await monkeyAttrContractOnBsc.getWeight(1001)).to.equal(60);

      // update attr
      await monkeyAttrContractOnBsc.setAttr(1001, 19, 70);

      // test burn and unlock
      await originalToken.transferOwnership(backing.address);
      //approve to mapping-token-factory
      await mappedToken.approve(mtf.address, 1001);
      expect(await mappedToken.ownerOf(1001)).to.equal(owner.address);
      await mtf.burnAndRemoteUnlockWaitingConfirm(mappingTokenAddress, owner.address, [1001], {value: ethers.utils.parseEther("10.0")});
      // before confirmed
      expect(await mappedToken.ownerOf(1001)).to.equal(mtf.address);
      // after confirmed
      await bscOutboundLane.mock_confirm(1);
      expect(await mappedToken.totalSupply()).to.equal(0);
      expect(await originalToken.ownerOf(1001)).to.equal(owner.address);
      expect(await monkeyAttrContractOnDarwinia.getAge(1001)).to.equal(19);
      expect(await monkeyAttrContractOnDarwinia.getWeight(1001)).to.equal(70);
  });
});

