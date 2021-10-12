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

    const abi_proxy_admin = "./artifacts/@openzeppelin/contracts/proxy/ProxyAdmin.sol/ProxyAdmin.json";
    const abi_erc_20 = "./artifacts/contracts/darwinia/MappingERC20.sol/MappingERC20.json";
    const abi_e2d_mapping_token_factory = "./artifacts/contracts/darwinia/Ethereum2DarwiniaMappingTokenFactory.sol/Ethereum2DarwiniaMappingTokenFactory.json";
    const abi_s2s_mapping_token_factory = "./artifacts/contracts/darwinia/Sub2SubMappingTokenFactory.sol/Sub2SubMappingTokenFactory.json";
    const abi_proxy = "./artifacts/@openzeppelin/contracts/proxy/TransparentUpgradeableProxy.sol/TransparentUpgradeableProxy.json";

    // 1. proxy admin
    console.log("1. start to deploy proxy admin");
    const adminjson = require(abi_proxy_admin);
    const admin_addr = await deploy.deployJson(web3, adminjson, []);

    //console.log("start to deploy darwinia=>ethereum contract");
    //const fee_addr = "0x0000000000000000000000000000000000000000";
    //const darwinia_backing_logic_addr = await deploy.deploy(web3, "./build/DarwiniaBacking.bin", "./build/DarwiniaBacking.abi", []);
    //var calldata = deploy.callData(web3, "./build/DarwiniaBacking.abi", darwinia_backing_logic_addr, "initialize", fee_addr, fee_addr);
    //const darwinia_backing_proxy_addr = await deploy.deploy(web3, "./build/DarwiniaBackingProxy.bin", "./build/DarwiniaBackingProxy.abi", [darwinia_backing_logic_addr, admin_addr, calldata]);

    // 2. mapping erc20 logic
    console.log("2. start to deploy mapping erc20 logic");
    const erc20json = require(abi_erc_20);
    const issuing_addr = await deploy.deployJson(web3, erc20json, []);

    // 3. ethereum<>darwinia mapping token factory logic
    console.log("3. start to deploy ethereum<>darwinia mapping token factory logic");
    const e2d_mapping_logic = require(abi_e2d_mapping_token_factory);
    const e2d_mapping_logic_addr = await deploy.deployJson(web3, e2d_mapping_logic, []);
    var e2d_mtf_calldata = deploy.callData(web3, e2d_mapping_logic.abi, e2d_mapping_logic_addr, "initialize");

    // 4. sub<>sub mapping token factory logic
    console.log("4. start to deploy sub<>sub mapping token factory logic");
    const s2s_mapping_logic = require(abi_s2s_mapping_token_factory);
    const s2s_mapping_logic_addr = await deploy.deployJson(web3, s2s_mapping_logic, []);
    var s2s_mtf_calldata = deploy.callData(web3, s2s_mapping_logic.abi, s2s_mapping_logic_addr, "initialize");

    // 5. mapping token proxy for erc20
    console.log("5. start to deploy e2d mapping token factory proxy");
    const e2d_proxyjson = require(abi_proxy);
    const e2d_mapping_proxy_addr = await deploy.deployJson(web3, e2d_proxyjson, [e2d_mapping_logic_addr, admin_addr, e2d_mtf_calldata]);
    const e2d_mapping_proxy = new web3.eth.Contract(e2d_mapping_logic.abi, e2d_mapping_proxy_addr);

    //await api.send(web3, mapping_contract, 'initialize', addr);
    console.log("set admin");
    await api.send(web3, e2d_mapping_proxy, 'setAdmin', addr, admin_addr);
    console.log("set erc20 logic");
    await api.send(web3, e2d_mapping_proxy, 'setTokenContractLogic', addr, 0, issuing_addr);
    await api.send(web3, e2d_mapping_proxy, 'setTokenContractLogic', addr, 1, issuing_addr);
    
    // 5. mapping token proxy for s2s
    console.log("6. start to deploy s2s mapping token factory proxy");
    const s2sproxyjson = require(abi_proxy);
    const s2s_mapping_proxy_addr = await deploy.deployJson(web3, s2sproxyjson, [s2s_mapping_logic_addr, admin_addr, s2s_mtf_calldata]);
    const s2s_mapping_proxy = new web3.eth.Contract(s2s_mapping_logic.abi, s2s_mapping_proxy_addr);
    console.log("set admin");
    await api.send(web3, s2s_mapping_proxy, 'setAdmin', addr, admin_addr);
    console.log("set erc20 logic");
    await api.send(web3, s2s_mapping_proxy, 'setTokenContractLogic', addr, 0, issuing_addr);
    await api.send(web3, s2s_mapping_proxy, 'setTokenContractLogic', addr, 1, issuing_addr);
    console.log("deploy fininshed");
}

deployContract();
