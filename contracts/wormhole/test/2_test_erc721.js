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

      // deploy erc721 serializer, local and remote
      const monkeyAttrContract = await ethers.getContractFactory("Erc721MonkeyAttributeSerializer");
      const monkeyAttrContractOnBsc = await monkeyAttrContract.deploy();
      await monkeyAttrContractOnBsc.deployed();
      const monkeyAttrContractOnDarwinia = await monkeyAttrContract.deploy();
      await monkeyAttrContractOnDarwinia.deployed();
      console.log("deploy erc721 attribute serializer success");
      /******* deploy mapping token factory at bsc *******/
      // deploy mapping token factory
      const mapping_token_factory = await ethers.getContractFactory("Erc721MappingTokenFactory");
      const mtf = await mapping_token_factory.deploy();
      await mtf.deployed();
      console.log("mapping-token-factory address", mtf.address);
      /******* deploy mapping token factory  end *******/

      /******* deploy backing at darwinia ********/
      backingContract = await ethers.getContractFactory("Erc721TokenBacking");
      const backing = await backingContract.deploy();
      await backing.deployed();
      console.log("backing address", backing.address);
      /******* deploy backing end ***************/

      //********** configure mapping-token-factory ***********
      // init owner
      await mtf.initialize(feeMarket.address);
      // add inboundLane
      await mtf.addInboundLane(backing.address, bscInboundLane.address);
      await mtf.addOutBoundLane(bscOutboundLane.address);
      //************ configure mapping-token end *************

      //********* configure backing **************************
      // init owner
      await backing.initialize(2, mtf.address, feeMarket.address, "Darwinia");
      // add inboundLane
      await backing.addInboundLane(mtf.address, darwiniaInboundLane.address);
      // add outboundLane
      await backing.addOutboundLane(darwiniaOutboundLane.address);
      //********* configure backing end   ********************

      // this contract can be any erc721 contract. We use MappingToken as an example
      const originalContract = await ethers.getContractFactory("Erc721MappingToken");
      const originalToken = await originalContract.deploy("Original", monkeyAttrContractOnBsc.address);
      await originalToken.deployed();
      await monkeyAttrContractOnDarwinia.setAttr(1001, 18, 60);

      const zeroAddress = "0x0000000000000000000000000000000000000000";

      // test register not enough fee
      await expect(backing.registerErc721Token(
          2,
          originalToken.address,
          monkeyAttrContractOnDarwinia.address,
          monkeyAttrContractOnBsc.address,
          {value: ethers.utils.parseEther("9.9999999999")}
      )).to.be.revertedWith("Backing:not enough fee to pay");
      // test register successed
      await backing.registerErc721Token(
          2,
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

      const [owner] = await ethers.getSigners();
      // test lock
      await originalToken.mint(owner.address, 1001);
      await originalToken.approve(backing.address, 1001);
      
      // test lock successful
      await expect(backing.lockAndRemoteIssuing(
          2,
          originalToken.address,
          owner.address,
          [1001],
          {value: ethers.utils.parseEther("9.999999999")}
      )).to.be.revertedWith("not enough fee to pay");
      // balance before
      expect(await originalToken.ownerOf(1001)).to.equal(owner.address);
      await backing.lockAndRemoteIssuing(2, originalToken.address, owner.address, [1001], {value: ethers.utils.parseEther("10.0")});
      await darwiniaOutboundLane.mock_confirm(2);
      // check lock and remote successed
      expect(await originalToken.ownerOf(1001)).to.equal(backing.address);
      // check issuing successed
      var mappedToken = await ethers.getContractAt("Erc721MappingToken", mappingTokenAddress);
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
      await mtf.burnAndRemoteUnlockWaitingConfirm(1, mappingTokenAddress, owner.address, [1001], {value: ethers.utils.parseEther("10.0")});
      // before confirmed
      expect(await mappedToken.ownerOf(1001)).to.equal(mtf.address);
      // after confirmed
      await bscOutboundLane.mock_confirm(1);
      expect(await originalToken.ownerOf(1001)).to.equal(owner.address);
      expect(await monkeyAttrContractOnDarwinia.getAge(1001)).to.equal(19);
      expect(await monkeyAttrContractOnDarwinia.getWeight(1001)).to.equal(70);
  });
});

