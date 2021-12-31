import { BigInt, Bytes, json } from "@graphprotocol/graph-ts"
import { mmr, Test } from "../generated/mmr/mmr"
import { NodeEntity } from "../generated/schema"
import { ethereum } from '@graphprotocol/graph-ts'
import { blake2b } from './blake2b'

const beginBlock: u64 = 11;

export function handleTest(event: Test): void {
}

function hash(block: ethereum.Block): Bytes {
    return block.hash;
}

function toU64(dec: BigInt): u64 {
    let decimalString = dec.toString();
    return json.toU64(decimalString);
}

export function handleBlock(block: ethereum.Block): void {
    let blocknumber = toU64(block.number);
    if (blocknumber < beginBlock) {
        return;
    }
    if (blocknumber == beginBlock) {
        init();
    }
    let block_position = leaf_index_to_pos(blocknumber);
    let record = new NodeEntity(block_position.toString());

    record.position = block_position.toString();
    record.hash = hash(block);
    record.save();

    checkPeaks(block_position);
}

function checkPeaks(block_position: u64): void {
    let height = 0;
    let pos = block_position;

    while (pos_height_in_tree(pos + 1) > height) {
        pos += 1;
        let left_pos = pos - parent_offset(height);
        let  right_pos = left_pos + sibling_offset(height);
        let left_elem = NodeEntity.load(left_pos.toString());
        let right_elem = NodeEntity.load(right_pos.toString());
        let record = new NodeEntity(pos.toString());

        record.position = pos.toString();
        record.hash = merge(left_elem.hash, right_elem.hash);
        record.save();
        height += 1;
    }
}

function saveRecord(position: u64, hash: Bytes): void {
    let record = new NodeEntity(position.toString());
    record.position = position.toString();
    record.hash = hash;
    record.save();
}

function init(): void {
    saveRecord(14, Bytes.fromHexString("0xc3a8ce843d747b2ce3b0551e0a21de2340351e598282de4dca3aac0f9e7d1f59") as Bytes);
    saveRecord(17, Bytes.fromHexString("0xf7c0b157923da200c3b0ecbbf549a219a475494c819bc74ad4fa8dfb6b3a1cb0") as Bytes);
    saveRecord(18, Bytes.fromHexString("0xb3074f936815a0425e674890d7db7b5e94f3a06dca5b22d291b55dcd02dde93e") as Bytes);
}

/* ---------------------------------------helper fns-------------------------------------- */
function merge(left: Bytes, right: Bytes): Bytes {
    //let res = concatTypedArrays(left, right);
    let res = new Uint8Array(left.length + right.length);
    for (let i = 0; i < left.length; i++) {
        res[i] = left[i];
        res[i + left.length] = right[i];
    }
    return blake2b(res) as Bytes;
}

function leaf_index_to_pos(index: u64): u64 {
  // mmr_size - H - 1, H is the height(intervals) of last peak
  return leaf_index_to_mmr_size(index) - trailing_zeros(index + 1) - 1;
}

function leaf_index_to_mmr_size(index: u64): u64 {
  // leaf index start with 0
  let leaves_count = index + 1;

  // the peak count(k) is actually the count of 1 in leaves count's binary representation
  let peak_count = count_ones(leaves_count);

  return 2 * leaves_count - peak_count;
}

function count_ones(dec: u64): u64 {
    let ones = 0;
    for (let i = 0; i < 64; i++) {
        if ((dec & (1 << i)) > 0) {
            ones += 1;
        }
   }
    return ones;
}

function trailing_zeros(dec: u64): u64 {
    let zeros = 0;
    for (let i = 0; i < 64; i++) {
        if ((dec & (1 << i)) == 0) {
            zeros += 1;
        } else {
            break;
        }
    }
    return zeros;
}

function leading_zeros(dec: u64): i32 {
    let zeros = 0;

    for (let i = 63; i >= 0; i--) {
        if ((dec & (1 << i)) == 0) {
            zeros += 1;
        } else {
            break;
        }
    }

    return zeros;
}

function all_ones(dec: u64): boolean {
    let bit_length = 64 - leading_zeros(dec);
    return ((1 << bit_length) - 1) == dec;
}

function jump_left(pos: u64): u64 {
  let bit_length = 64 - leading_zeros(pos);
  let most_significant_bits = 1 << (bit_length - 1);

  return pos - (most_significant_bits - 1);
}

function pos_height_in_tree(pos: u64): i32 {
  pos += 1;

  while (!all_ones(pos)) {
    pos = jump_left(pos);
  }

  return 64 - leading_zeros(pos) - 1;
}

function parent_offset(height: u64): u64 {
  return 2 << height;
}

function sibling_offset(height: u64): u64 {
  return (2 << height) - 1;
}

