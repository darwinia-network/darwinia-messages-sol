// We require the Hardhat Runtime Environment explicitly here. This is optional 
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");
const ethers = hre.ethers;

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile 
  // manually to make sure everything is compiled
  await hre.run('compile');

  const [owner, addr1, addr2] = await ethers.getSigners();

  // We get the contract to deploy

  const MMR = await ethers.getContractFactory("MMR");
  mmrLib = await MMR.deploy();
  await mmrLib.deployed();
  console.log("MMR deployed to:", mmrLib.address);

  const Scale = await ethers.getContractFactory("Scale");
  scale = await Scale.deploy();
  await scale.deployed();
  console.log("Scale deployed to:", scale.address);

  const SimpleMerkleProof = await ethers.getContractFactory("SimpleMerkleProof");
  simpleMerkleProof = await SimpleMerkleProof.deploy();
  await simpleMerkleProof.deployed();
  console.log("SimpleMerkleProof deployed to:", simpleMerkleProof.address);

  // MMR deployed to: 0x8C66aebC119a98Bbc521d192CD976E500f64a73a
  // Scale deployed to: 0xa4D869e3Eea8Ba408740779a00aFe1dd59f4993f
  // SimpleMerkleProof deployed to: 0xacfeDAf15495b430155C8554e6e3678F938B5784

  const Relay = await ethers.getContractFactory(
    'Relay',
    {
      libraries: {
        MMR: mmrLib.address,
        SimpleMerkleProof: simpleMerkleProof.address,
        Scale: scale.address
        // MMR: '0x2f0454C05591bb36d00e85b005BB2AE18C620011',
        // SimpleMerkleProof: '0x8b447F883B9f0FDfAdCDA7D0151405Fa98e63D73',
        // Scale: '0xBdD57AC8b86C14F00576BBC7788bB5b22F0723fd'
      }
    }
  );

  const relayConstructor = [
    11309,
    '0xe1fe85d768c17641379ef6dfdf50bdcabf6dd83ec325506dc82bf3ff653550dc',
    [
      await owner.getAddress(),
      await addr1.getAddress(),
      await addr2.getAddress(),
    ],
    0,
    60,
    0x43726162
  ];
  
  relay = await Relay.deploy(...relayConstructor);
  await relay.deployed();


  const TokenBacking = await ethers.getContractFactory("TokenBacking", {
    libraries: {
      Scale: scale.address,
    }
  });

  const backingConstructor = [
    "0x0000000000000000000000000000000000000000",
    // relay.address
    "0x26e920e571943C6D4789aD7b75967f9842cdc83e"
  ]

  backing = await TokenBacking.deploy();
  await backing.deployed();
  await backing.initializeContract(...backingConstructor);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });