/**
 * Deploys smart contracts
 * 
 */
const Web3 = require('web3');
const fs = require("fs");
var readlineSync = require('readline-sync');
var deploy = require("./compile/deploy.js")
var api = require("./compile/api.js")

var version = process.argv[2];

const deployContract = async function () {
    var web3 = new Web3("http://localhost:9933");
    //var calldata = deploy.callData(web3, "./build/EthereumMappingTokenFactory.abi", "0x80B36477F3694997E4e49cb1d36E92387533A824", "initialize", "0xF8CD27F2e18104A0EdEc401f7ca137bebd4A98E8", 3);
    //console.log(calldata);
    //return;

    // get backing calldata
    //var calldata = deploy.callData(web3, "./build/Ethereum2DarwiniaBacking.abi", "0x683995eEc57712061bbC09aB653E5D17d4836aCf", "initialize", "0xF8CD27F2e18104A0EdEc401f7ca137bebd4A98E8", "0x1994100c58753793D52c6f457f189aa3ce9cEe94", "0xb52FBE2B925ab79a821b261C82c5Ba0814AAA5e0");
    //console.log(calldata);
    //return;

    if (version == "pro") {
        console.log("it is production env");
        web3 = new Web3("http://pangolin-rpc.darwinia.network");
    }
    const key =  "0x...";
    const addr = "0x...";
    web3.eth.accounts.wallet.add(key);
    const _1e8 = web3.utils.toHex("0x52b7d2dcc80cd2e4000000");

    // 1. proxy admin
    console.log("1. start to deploy proxy admin");
    const adminjson = require("./artifacts/@openzeppelin/contracts/proxy/ProxyAdmin.sol/ProxyAdmin.json");
    const admin_addr = await deploy.deployJson(web3, adminjson, []);

    //console.log("start to deploy darwinia=>ethereum contract");
    //const fee_addr = "0x0000000000000000000000000000000000000000";
    //const darwinia_backing_logic_addr = await deploy.deploy(web3, "./build/DarwiniaBacking.bin", "./build/DarwiniaBacking.abi", []);
    //var calldata = deploy.callData(web3, "./build/DarwiniaBacking.abi", darwinia_backing_logic_addr, "initialize", fee_addr, fee_addr);
    //const darwinia_backing_proxy_addr = await deploy.deploy(web3, "./build/DarwiniaBackingProxy.bin", "./build/DarwiniaBackingProxy.abi", [darwinia_backing_logic_addr, admin_addr, calldata]);

    // 2. mapping erc20 logic
    console.log("2. start to deploy mapping erc20 logic");
    const erc20json = require("./artifacts/contracts/darwinia/MappingERC20.sol/MappingERC20.json");
    const issuing_addr = await deploy.deployJson(web3, erc20json, []);

    // 3. mapping token factory logic
    console.log("3. start to deploy mapping token factory logic");
    const mapping_logic = require("./artifacts/contracts/darwinia/DarwiniaMappingTokenFactory.sol/DarwiniaMappingTokenFactory.json");
    const mapping_logic_addr = await deploy.deployJson(web3, mapping_logic, []);

    var calldata = deploy.callData(web3, "./abi/contracts/darwinia/DarwiniaMappingTokenFactory.sol/DarwiniaMappingTokenFactory.json", mapping_logic_addr, "initialize");

    // 4. mapping token proxy for erc20
    console.log("4. start to deploy erc20 mapping token factory proxy");
    const erc20_proxyjson = require("./artifacts/@openzeppelin/contracts/proxy/TransparentUpgradeableProxy.sol/TransparentUpgradeableProxy.json");
    const erc20_mapping_proxy_addr = await deploy.deployJson(web3, erc20_proxyjson, [mapping_logic_addr, admin_addr, calldata]);
    const erc20_mapping_proxy = api.createContractObj(web3, "./abi/contracts/darwinia/DarwiniaMappingTokenFactory.sol/DarwiniaMappingTokenFactory.json", erc20_mapping_proxy_addr);
    //await api.send(web3, mapping_contract, 'initialize', addr);
    console.log("set admin");
    await api.send(web3, erc20_mapping_proxy, 'setAdmin', addr, admin_addr);
    console.log("set erc20 logic");
    await api.send(web3, erc20_mapping_proxy, 'setERC20Logic', addr, issuing_addr);
    
    // 5. mapping token proxy for s2s
    console.log("5. start to deploy s2s mapping token factory proxy");
    const s2sproxyjson = require("./artifacts/@openzeppelin/contracts/proxy/TransparentUpgradeableProxy.sol/TransparentUpgradeableProxy.json");
    const s2s_mapping_proxy_addr = await deploy.deployJson(web3, s2sproxyjson, [mapping_logic_addr, admin_addr, calldata]);
    const s2s_mapping_proxy = api.createContractObj(web3, "./abi/contracts/darwinia/DarwiniaMappingTokenFactory.sol/DarwiniaMappingTokenFactory.json", s2s_mapping_proxy_addr);
    console.log("set admin");
    await api.send(web3, s2s_mapping_proxy, 'setAdmin', addr, admin_addr);
    console.log("set erc20 logic");
    await api.send(web3, s2s_mapping_proxy, 'setERC20Logic', addr, issuing_addr);
    console.log("deploy fininshed");
}

deployContract();
