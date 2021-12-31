import { BigInt } from "@graphprotocol/graph-ts"
import {
  TimeLock,
  CallExecuted,
  CallScheduled,
  Cancelled,
  MinDelayChange,
  RoleAdminChanged,
  RoleGranted,
  RoleRevoked
} from "../generated/TimeLock/TimeLock"
import { ProposalItem } from "../generated/schema"

export function handleCallExecuted(event: CallExecuted): void {
  let entity = ProposalItem.load(event.params.id.toHex())
    if (entity == null) {
      return
    }
  entity.status = 2
  entity.save()
}

export function handleCallScheduled(event: CallScheduled): void {
    let entity = new ProposalItem(event.params.id.toHex())
    if (entity == null) {
      return
    }
    entity.index = event.params.index
    entity.target = event.params.target
    entity.value = event.params.value
    entity.data = event.params.data
    entity.predecessor = event.params.predecessor
    entity.delay = event.params.delay
    entity.timestamp = event.block.timestamp
  // 0 --- pending
  // 1 --- ready
  // 2 --- done
  // 3 --- cancel
    entity.status = 0
    entity.save()
}

export function handleCancelled(event: Cancelled): void {
  let entity = ProposalItem.load(event.params.id.toHex())
    if (entity == null) {
      return
    }
  entity.status = 3
  entity.save()
}
