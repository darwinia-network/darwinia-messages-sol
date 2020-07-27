
const RelayerGameWrapper = artifacts.require('RelayerGameWrapper');
const RelayerGame = artifacts.require("RelayerGame");
const pify = require('pify')



contract('RelayerGame', (accounts) => {
  let relayerGameLib;
  let relayerGameWrapper;

  const waitNBlocks = async n => {
    const sendAsync = pify(web3.currentProvider.send);
    await Promise.all(
      [...Array(n).keys()].map(i =>
        sendAsync({
          jsonrpc: '2.0',
          method: 'evm_mine',
          id: i
        })
      )
    );
  };

  const data_round1 = [
    {
      value: '0001',
      hash: '0x55b3d52f4d4d7d05df4311c2ecaa0a527397653aca45e8be878ccf2bfed5fb91'
    },
    {
      value: '0002',
      hash: '0x53db26eab5ab133a0e005fc40d7fb67c4477a57b43d939d4bdd437f3ad12affb'
    },
    {
      value: '0003',
      hash: '0xa1792325aa42252bf5d6a094540772ad40526ae5fcd5a18938368432561abe0a'
    },
    {
      value: '0004',
      hash: '0xa2463b5abfb89d9ade5021579b0b1ad84fa83f92dfec13b733f51f3404ab966e'
    },
  ];

  const data_round2 = [
    {
      value: ['0x0005', '0x0006'],
      hash: [
        '0x5db64e2f460f5a21c02e7b48eb3ccb508fca63eab9869dcdd3a4d2c64ca2c078',
        '0x2db408d27e1d1b88835af3c8a996e09a3ec4a857584320997a191e79809282e3'
      ]
    }
  ];

  before(async () => {
    relayerGameLib = await RelayerGame.new();
    await RelayerGameWrapper.link('RelayerGame', relayerGameLib.address);
  });

  describe('TestRelayerGame', async () => {
    before(async () => {
      relayerGameWrapper = await RelayerGameWrapper.new();

    });

    it('setDeadLineStep', async () => {
      await relayerGameWrapper.setDeadLineStep(50);
      const info = await relayerGameWrapper.getGameInfo();
      assert.equal(info.deadLineStep.toNumber(), 50);
    });

    it('startGame', async () => {
      await relayerGameWrapper.startGame(100, '0x00', [
        data_round1[0].hash,
      ], [
        '0x' + data_round1[0].value,
      ])

      let relayer = await relayerGameWrapper.getRoundInfo(0);
      assert.equal(relayer.activeProposalStart.toNumber(), 0);
      assert.equal(relayer.activeProposalEnd.toNumber(), 0);

      relayer.proposalLeafs.forEach((element, index) => {
        if (index === 0) {
          assert.equal(element, '0x0000000000000000000000000000000000000000000000000000000000000000');
        } else {
          assert.equal(element, data_round1[index - 1].hash);
        }
      });
    });

    it('appendProposalByRound', async () => {
      let relayer = await relayerGameWrapper.getRoundInfo(0);
      for (var i = 1; i < data_round1.length; i++) {
        await relayerGameWrapper.appendProposalByRound(
          0,  // roundIndex
          relayer.deadline,
          '0x00',
          [
            data_round1[i].hash,
          ],
          [
            '0x' + data_round1[i].value,
          ]);
        const info = await relayerGameWrapper.getRoundInfo(0);
        assert.equal(info.proposalLeafs.length, 2 + i);
        assert.equal(info.proposalLeafs[info.proposalLeafs.length - 1], data_round1[i].hash);
      }
    })

    it('updateRound', async () => {
      let block = await web3.eth.getBlock("latest")
      console.log('current blocknumber: ', block.number)

      waitNBlocks(51);

      block = await web3.eth.getBlock("latest")
      console.log('current blocknumber: ', block.number)

      let relayer = await relayerGameWrapper.getRoundInfo(0);
      console.log('updateRound: dealine ', relayer.deadline)
      for (var i = 0; i < data_round2.length; i++) {
        await relayerGameWrapper.appendProposalByRound(
          0,  // roundIndex
          relayer.deadline.toNumber() + 1,
          data_round1[i].hash,
          data_round2[i].hash,
          data_round2[i].value,
        );
        const info = await relayerGameWrapper.getRoundInfo(0);
        console.log(info)
        assert.equal(info.activeProposalStart.toNumber(), 1);
        assert.equal(info.activeProposalEnd.toNumber(), 4);

        const block = await relayerGameWrapper.getBlockPool('0x5db64e2f460f5a21c02e7b48eb3ccb508fca63eab9869dcdd3a4d2c64ca2c078');
        assert.equal(block.parent, '0x55b3d52f4d4d7d05df4311c2ecaa0a527397653aca45e8be878ccf2bfed5fb91');
        assert.equal(block.data, '0x0005');
      }
    })
  });
});
