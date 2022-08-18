const ethUtil = require('ethereumjs-util');
const abi = require('ethereumjs-abi');

const typedData = {
    types: {
        DOMAIN_SEPARATOR: '38a6d9f96ef6e79768010f6caabfe09abc43e49792d5c787ef0d4fc802855947',
        COMMIT_TYPEHASH: '78094893060403532648017515506754197708665517209499283813842244044760214381091',
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
    return Buffer.from('1927575a20e860281e614acf70aa85920a1187ed2fb847ee50d71702e80e2b8f', 'hex');
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
    return ethUtil.keccak256(encodeData(primaryType, data));
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
