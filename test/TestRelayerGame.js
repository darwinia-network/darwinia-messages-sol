
const RelayerGameWrapper = artifacts.require('RelayerGameWrapper');
const RelayerGame = artifacts.require("RelayerGame");

contract('RelayerGame', (accounts) => {
  let relayerGameLib;
  let relayerGameWrapper;

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
      await relayerGameWrapper.setDeadLineStep(600);
      const info = await relayerGameWrapper.getGameInfo();
      assert.equal(info.deadLineStep.toNumber(), 600);
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

    it('updateRound', async () => {
      data_round1.forEach(async (element, index) => {
        if (index != 0) {
          await relayerGameWrapper.appendProposalByRound(
            0,  // roundIndex
            '0x00',
            [
              element.hash,
            ],
            [
              '0x' + element.value,
            ]);
          // const info = await relayerGameWrapper.getRoundInfo(0);
        }
      })
    })
  });
});
