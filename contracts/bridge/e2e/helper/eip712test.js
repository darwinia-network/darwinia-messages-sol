const { signHash } = require('./eip712')

message = {
  "block_number": 11170,
  "message_root": "0xf2479cdacab42936aa272f26caf69b08891232cb480d44704c9007ead04edea4",
  "nonce": 0
}

console.log(signHash(message).toString('hex'))
