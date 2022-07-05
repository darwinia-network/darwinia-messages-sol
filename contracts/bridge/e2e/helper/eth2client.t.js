const Eth2Client = require('./eth2client').Eth2Client
const beacon_endpoint = "http://127.0.0.1:5052"

const eth2Client = new Eth2Client(beacon_endpoint);

const log = console.log;

(async () => {
  // const sync_change = await eth2Client.get_sync_committee_period_update(11, 1)
  // log(sync_change)
  // const finality_update = await eth2Client.get_finality_update()
  // log(finality_update)
  // const optimistic_update = await eth2Client.get_optimistic_update()
  // log(optimistic_update)
  const bootstrap = await eth2Client.get_bootstrap('0x91d8726435c53b12e360fce5579f989ea397d993ad1ab00edad8833e09796f90')
  log(bootstrap)
  // log(JSON.stringify(sync_change, null, 2))
  // log(await eth2Client.get_next_sync_committee_branch(651296))
  // const sync_change = await eth2Client.get_sync_committee_period_update(79, 79)
  // log(JSON.stringify(sync_change, null, 2))
  // log(await eth2Client.get_next_sync_committee_branch(651296))
  // log(await eth2Client.get_latest_execution_payload_state_root_branch(653120))
  // log(await eth2Client.get_finality_branch(653120))
  // log(sync_change[1].attested_header)
  // log(sync_change[1].sync_aggregate)
  // let sync_slot = Number(sync_change[1].attested_header.slot) + 1
  // let sync_block = (await eth2Client.get_beacon_block(sync_slot))
  // while(!sync_block) {
  //   sync_slot += 1
  //   sync_block = (await eth2Client.get_beacon_block(sync_slot))
  // }
  // log(sync_block)
  // log(sync_block.message.body.sync_aggregate)
  //
  // finalized_header: {
  //   slot: '651232',
  //   proposer_index: '86325',
  //   parent_root: '0x13189ed59789d8c28c9e4f8aed4494979075cf3c0a1ee9fd03f93816f65bbe16',
  //   state_root: '0xd29f11a73f0207a356e38ad5dccdaa2fdf6c94aa9c51d34e6ca29ce9dbdd6550',
  //   body_root: '0x6a52c3e5c4d195607035457f4263b3a3a653d9b143bc73bef5ca5c1154b5c02d'
  // },
  // const update = await eth2Client.get_latest_finalized_update()
  // log(update)
  // const finalized_block = await eth2Client.get_beacon_block(update.finalized_header.slot)
  // const finalized_block = await eth2Client.get_beacon_block(651366)
  // const ssz_sync_committee_bits = finalized_block.message.body.sync_aggregate.sync_committee_bits
  // log(ssz_sync_committee_bits)
  // const latest_execution_payload_state_root = finalized_block.message.body.execution_payload.state_root
  // log(latest_execution_payload_state_root)
  // const latest_execution_payload_state_root_branch = await eth2Client.get_latest_execution_payload_state_root_branch(finalized_block.message.slot)
  // log(latest_execution_payload_state_root_branch)
  // const fork_version = await eth2Client.get_fork_version(finalized_block.message.slot)
  // log('fork_version', fork_version)
  // log(await eth2Client.get_fork_version(651232))
  // log(await eth2Client.get_genesis())
  // const header = await eth2Client.get_header(update.finalized_header.slot)
  // log(header)
  // const snapshot = await eth2Client.get_light_client_snapshot(header.root)
  // log(snapshot)
  // const current_sync_committee = snapshot.current_sync_committee
  // log(JSON.stringify(current_sync_committee.pubkeys, null, 2))
  // log('-----------------------------------------------------')
  // log(current_sync_committee.aggregate_pubkey)

  // await eth2Client.get_next_sync_committee_branch('105671')
  // const paths = [
  //         ["finalized_checkpoint", "root"],
  //       ]
  // await eth2Client.get_state_proof('594880', paths)
  // await eth2Client.get_state_proof('639970', paths)
  // await eth2Client.get_latest_finalized_update()
  // const block = await eth2Client.get_beacon_block(641441)
  // console.log(block.message.body.finalized_checkpoint)
})();
