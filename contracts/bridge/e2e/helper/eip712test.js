const { signHash } = require('./eip712')

message = {
  "block_number": 4900,
  "message_root": "0xc19bb9951026bddb8aac800b900e8f26e4ba01ac31e1447070ce57ac5e1f9a5d",
  "nonce": 0
}

console.log(signHash(message).toString('hex'))
