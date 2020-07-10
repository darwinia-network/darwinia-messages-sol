### darwinia-ethereum-relay

### 使用方式
blake2b需要使用[go-ethereum](https://github.com/ethereum/go-ethereum)客户端，javascript vm 执行会得到错误的结果。

1. 下载go-ethereum
2. 执行 `geth --datadir ./dataDir init ./geth-genesis.json`
3. 启动ethereum节点 `./geth --port 4321 --networkid 1234 --datadir=./dataDir --rpc --rpcport 8543 --rpcaddr 127.0.0.1 --rpcapi "eth,net,web3,personal,miner" --gasprice 0 --etherbase 0x627306090abab3a6e1400e9345bc60c78a8bef57 --mine --minerthreads=1`
4. 安装nodejs依赖 `yarn`
5. 运行测试 `yarn test-mmrlib`


### 计划
- [x] Merkle Mountain Range
- [ ] Merkle Patricia Tree
- [ ] Darwinia Relay Game - [https://github.com/darwinia-network/relayer-game]


