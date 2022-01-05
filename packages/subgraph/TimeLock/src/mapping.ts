import { concat } from "@graphprotocol/graph-ts/helper-functions"
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
import { Proposal, Operation } from "../generated/schema"

export function handleCallExecuted(event: CallExecuted): void {
  let entity = Proposal.load(event.params.id.toHex())
  if (entity == null) {
    return
  }
  entity.status = 'Executed'
  entity.save()
}

export function handleCallScheduled(event: CallScheduled): void {
  let proposal = Proposal.load(event.params.id.toHex())
  if (proposal == null) {
    proposal = new Proposal(event.params.id.toHex())
    proposal.predecessor = event.params.predecessor
    proposal.delay = event.params.delay
    proposal.timestamp = event.block.timestamp
    proposal.status = 'Pending'
    proposal.save()
  }

  let id = event.params.id.toHex()
  let index = event.params.index.toHex()
  let op_id = id + index
  let operation = new Operation(op_id)
  operation.index = event.params.index
  operation.target = event.params.target
  operation.value = event.params.value
  operation.data = event.params.data
  operation.proposal = proposal.id
  operation.save()
}

export function handleCancelled(event: Cancelled): void {
  let entity = Proposal.load(event.params.id.toHex())
  if (entity == null) {
    return
  }
  entity.status = 'Cancelled'
  entity.save()
}
