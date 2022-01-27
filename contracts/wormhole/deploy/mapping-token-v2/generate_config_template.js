// this will generate Darwinina Smart Chain<>Binance Smart Chain configuration template
// Darwinina Chain Position 42
// Binance Chain Position 56
// Darwinia inBoundLanePosition  1 <-> 1 Bsc outBoundLanePosition
// Darwinia outBoundLanePosition 2 <-> 2 Bsc inBoundLanePosition
// Backing is on Darwinia, Issuing is on Bsc
const fs = require('fs');

async function main() {
    // simulate the message protocal v2
    // mock all the contract needed
    // inbouldlane contract at darwinia & bsc
    const inboundLaneContract = await ethers.getContractFactory("MockInboundLane");
    const darwiniaInboundLane = await inboundLaneContract.deploy(42, 1, 56, 1);
    await darwiniaInboundLane.deployed();
    const bscInboundLane = await inboundLaneContract.deploy(56, 2, 42, 2);
    await bscInboundLane.deployed();

    // outboundlane contract at darwinia & bsc
    const outboundLaneContract = await ethers.getContractFactory("MockOutboundLane");
    const darwiniaOutboundLane = await outboundLaneContract.deploy(42, 2, 56, 2, bscInboundLane.address);
    await darwiniaOutboundLane.deployed();
    const bscOutboundLane = await outboundLaneContract.deploy(56, 1, 42, 1, darwiniaInboundLane.address);
    await bscOutboundLane.deployed();

    // feemarket contract at darwinia & bsc
    const feeMarketContract = await ethers.getContractFactory("MockFeeMarket");
    const darwiniaFeeMarket = await feeMarketContract.deploy();
    await darwiniaFeeMarket.deployed();
    const bscFeeMarket = await feeMarketContract.deploy();
    await bscFeeMarket.deployed();

    // guards
    let wallets = [];
    let guards = [];
    for (let i = 0; i < 3; i++) {
        const wallet = ethers.Wallet.createRandom();
        wallets.push(wallet);
    }
    wallets = wallets.sort((x, y) => {
        return x.address.toLowerCase().localeCompare(y.address.toLowerCase())
    });
    for (wallet of wallets) {
        guards.push(wallet.address);
    }

    // generate template
    var configure = {
        "backing": {
            "bridgedChainPosition": 56,
            "feeMarketAddress": darwiniaFeeMarket.address,
            "localChainName": "Darwinia",
            "outBoundLane": darwiniaOutboundLane.address,
            "inBoundLane": darwiniaInboundLane.address
        },
        "mappingTokenFactory": {
            "feeMarketAddress": bscFeeMarket.address,
            "outBoundLane": bscOutboundLane.address,
            "inBoundLane": bscInboundLane.address
        },
        "guard": {
            "guards": guards,
            "threshold": 2,
            "maxUnclaimableTime": 100
        },
        "deployed": {
            "mappingTokenFactory": {
                "proxyAdmin": "null",
                "logic": "null",
                "proxy": "null",
                "guard": "null"
            },
            "backing": {
                "proxyAdmin": "null",
                "logic": "null",
                "proxy": "null",
                "guard": "null"
            },
            "erc20": "null",
        }
    }
    let storeData = JSON.stringify(configure, null, 2);
    var jsonpath = process.env.CONFIG;
    fs.writeFileSync(jsonpath, storeData);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
