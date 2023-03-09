const ethUtil = require('ethereumjs-util');
const abi = require('ethereumjs-abi');

const typedData = {
    types: {

        DOMAIN_SEPARATOR: '6516caa5e629f7c38609c9a51c87c41bcae861829b3c6d4e540f727ede06fa51',
        COMMIT_TYPEHASH: 'aca824a0c4edb3b2c17f33fea9cb21b33c7ee16c8e634c36b3bf851c9de7a223',
        Commitment: [
            { name: 'block_number', type: 'uint32' },
            { name: 'message_root', type: 'bytes32' },
            { name: 'nonce', type: 'uint256' }
        ],
    },
    primaryType: 'Commitment'
};

const types = typedData.types;

function dependencies(primaryType, found = []) {
    if (found.includes(primaryType)) {
        return found;
    }
    if (types[primaryType] === undefined) {
        return found;
    }
    found.push(primaryType);
    for (let field of types[primaryType]) {
        for (let dep of dependencies(field.type, found)) {
            if (!found.includes(dep)) {
                found.push(dep);
            }
        }
    }
    return found;
}

function typeHash() {
    return Buffer.from('aca824a0c4edb3b2c17f33fea9cb21b33c7ee16c8e634c36b3bf851c9de7a223', 'hex');
}

function encodeData(primaryType, data) {
    let encTypes = [];
    let encValues = [];

    // Add typehash
    encTypes.push('bytes32');
    encValues.push(typeHash());

    // Add field contents
    for (let field of types[primaryType]) {
        let value = data[field.name];
        if (field.type == 'string' || field.type == 'bytes') {
            encTypes.push('bytes32');
            value = ethUtil.keccakFromString(value, 256);
            encValues.push(value);
        } else if (types[field.type] !== undefined) {
            encTypes.push('bytes32');
            value = ethUtil.keccak256(encodeData(field.type, value));
            encValues.push(value);
        } else if (field.type.lastIndexOf(']') === field.type.length - 1) {
            throw 'TODO: Arrays currently unimplemented in encodeData';
        } else {
            encTypes.push(field.type);
            encValues.push(value);
        }
    }

    return abi.rawEncode(encTypes, encValues);
}

function structHash(primaryType, data) {
    let a = ethUtil.keccak256(encodeData(primaryType, data))
    console.log(a.toString('hex'))
    return a;
}

function signHash(message) {
    return ethUtil.keccak256(
        Buffer.concat([
            Buffer.from('1901', 'hex'),
            Buffer.from(types.DOMAIN_SEPARATOR, 'hex'),
            structHash(typedData.primaryType, message),
        ]),
    );
}

module.exports = {
  signHash,
}
