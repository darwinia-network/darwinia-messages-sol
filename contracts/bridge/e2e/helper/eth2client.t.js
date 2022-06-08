const Eth2Client = require('./eth2client').Eth2Client
const beacon_endpoint = "http://127.0.0.1:5052"

const eth2Client = new Eth2Client(beacon_endpoint);

(async () => {
  // await eth2Client.get_latest_finalized_update()
  // await eth2Client.get_light_client_snapshot('0x11a7f75f56b4f0313b178f3feb866bf1b286ca6c6f559f8f63bec420fadcd8d1')
  const paths = [
          ["finalized_checkpoint", "root"],
        ]
  // await eth2Client.get_state_proof('594880', paths)
  await eth2Client.get_state_proof('639970', paths)
})();
