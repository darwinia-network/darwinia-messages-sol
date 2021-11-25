import { BigInt } from "@graphprotocol/graph-ts"
import {
  Sub2SubMappingTokenFactory,
  BurnAndWaitingConfirm,
  DailyLimitChange,
  IssuingERC20Created,
  IssuingMappingToken,
  MappingTokenUpdated,
  NewLogicSetted,
  OwnershipTransferred,
  RemoteUnlockConfirmed
} from "../generated/Sub2SubMappingTokenFactory/Sub2SubMappingTokenFactory"
import { BurnRecordEntity } from "../generated/schema"
import { LockRecordEntity } from "../generated/schema"

export function handleBurnAndWaitingConfirm(
  event: BurnAndWaitingConfirm
): void {
  // Entities can be loaded from the store using a string ID; this ID
  // needs to be unique across all entities of the same type
  let message_id = event.params.laneid.toHexString() + event.params.nonce.toHexString()
  let entity = BurnRecordEntity.load(message_id)

  // Entities only exist after they have been saved to the store;
  // `null` checks allow to create entities on demand
  if (entity == null) {
    entity = new BurnRecordEntity(message_id)
  }

  // Entity fields can be set based on event parameters
  entity.lane_id = event.params.laneid
  entity.nonce = event.params.nonce
  entity.sender = event.params.sender
  entity.recipient = event.params.recipient
  entity.token = event.params.token
  entity.amount = event.params.amount
  entity.request_transaction = event.transaction.hash
  entity.start_timestamp = event.block.timestamp
  // 0 --- unconfirmed
  // 1 --- confirmed return true
  // 2 --- confirmed return false
  entity.result = 0

  // Entities can be written to the store with `.save()`
  entity.save()

  // Note: If a handler doesn't require existing field values, it is faster
  // _not_ to load the entity from the store. Instead, create it fresh with
  // `new Entity(...)`, set the fields that should be updated and save the
  // entity back to the store. Fields that were not set or unset remain
  // unchanged, allowing for partial updates to be applied.

  // It is also possible to access smart contracts from mappings. For
  // example, the contract that has emitted the event can be connected to
  // with:
  //
  // let contract = Contract.bind(event.address)
  //
  // The following functions can then be called on this contract to access
  // state variables and other data:
  //
  // - contract.DISPATCH(...)
  // - contract.DISPATCH_ENCODER(...)
  // - contract.SYSTEM_ACCOUNT(...)
  // - contract.admin(...)
  // - contract.allTokens(...)
  // - contract.calcMaxWithdraw(...)
  // - contract.createERC20Contract(...)
  // - contract.dailyLimit(...)
  // - contract.lastDay(...)
  // - contract.logic(...)
  // - contract.mappingToken(...)
  // - contract.owner(...)
  // - contract.spentToday(...)
  // - contract.tokenLength(...)
  // - contract.tokenMap(...)
  // - contract.tokenToInfo(...)
  // - contract.transferUnconfirmed(...)
}

export function handleDailyLimitChange(event: DailyLimitChange): void {}

export function handleIssuingERC20Created(event: IssuingERC20Created): void {}

export function handleIssuingMappingToken(event: IssuingMappingToken): void {
    let message_id = event.params.laneid.toHexString() + event.params.nonce.toHexString()
    let entity = LockRecordEntity.load(message_id)
    if (entity == null) {
        entity = new LockRecordEntity(message_id)
    }
    entity.lane_id = event.params.laneid
    entity.nonce = event.params.nonce
    entity.mapping_token = event.params.mapping_token
    entity.recipient = event.params.recipient
    entity.amount = event.params.amount
    entity.transaction = event.transaction.hash
    entity.save()
}

export function handleMappingTokenUpdated(event: MappingTokenUpdated): void {}

export function handleNewLogicSetted(event: NewLogicSetted): void {}

export function handleOwnershipTransferred(event: OwnershipTransferred): void {}

export function handleRemoteUnlockConfirmed(
  event: RemoteUnlockConfirmed
): void {
    let message_id = event.params.laneid.toHexString() + event.params.nonce.toHexString()
    let entity = new BurnRecordEntity(message_id)
    if (entity == null) {
        return
    }
    entity.result = event.params.result ? 1 : 2
    entity.response_transaction = event.transaction.hash
    entity.end_timestamp = event.block.timestamp
    entity.save()
}
