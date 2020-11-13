const Bytes = artifacts.require("Bytes");
const Hash = artifacts.require("Hash");
const Input = artifacts.require("Input");
const Memory = artifacts.require("Memory");
const Nibble = artifacts.require("Nibble");
const Node = artifacts.require("Node");
const Scale = artifacts.require("Scale");
const CMPTest = artifacts.require("CompactMerkleProofTest");
const SMPTest = artifacts.require("SimpleMerkleProofTest");


module.exports = function(deployer) {
  deployer.deploy(Bytes);
  deployer.deploy(Hash);
  deployer.deploy(Input);
  deployer.deploy(Memory);
  deployer.deploy(Nibble);
  deployer.deploy(Node);
  deployer.deploy(Scale);

  deployer.link(Bytes, CMPTest);
  deployer.link(Bytes, SMPTest);
  deployer.link(Hash, CMPTest);
  deployer.link(Hash, SMPTest);
  deployer.link(Input, CMPTest);
  deployer.link(Input, SMPTest);
  deployer.link(Memory, CMPTest);
  deployer.link(Memory, SMPTest);
  deployer.link(Nibble, CMPTest);
  deployer.link(Nibble, SMPTest);
  deployer.link(Node, CMPTest);
  deployer.link(Node, SMPTest);
  deployer.link(Scale, CMPTest);
  deployer.link(Scale, SMPTest);

  deployer.deploy(CMPTest);
  deployer.deploy(SMPTest);
};