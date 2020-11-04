const Bytes = artifacts.require("Bytes");
const Hash = artifacts.require("Hash");
const Input = artifacts.require("Input");
const Memory = artifacts.require("Memory");
const Nibble = artifacts.require("Nibble");
const Node = artifacts.require("Node");
const Scale = artifacts.require("Scale");
const MPTest = artifacts.require("MerkleProofTest");

module.exports = function(deployer) {
  deployer.deploy(Bytes);
  deployer.deploy(Hash);
  deployer.deploy(Input);
  deployer.deploy(Memory);
  deployer.deploy(Nibble);
  deployer.deploy(Node);
  deployer.deploy(Scale);

  deployer.link(Bytes, MPTest);
  deployer.link(Hash, MPTest);
  deployer.link(Input, MPTest);
  deployer.link(Memory, MPTest);
  deployer.link(Nibble, MPTest);
  deployer.link(Node, MPTest);
  deployer.link(Scale, MPTest);
  deployer.deploy(MPTest);
};