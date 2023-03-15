const { signHash } = require('./eip712')

message = {
  "block_number": 10580,
  "message_root": "0x56223be3175f9a12197c701ea64c9d7ae73d686fdf6129c85840a592e5e66d12",
  "nonce": 0
}

console.log(signHash(message).toString('hex'))
