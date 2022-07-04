// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

abstract contract Base {
    bytes4 public constant DARWINIA_CHAIN_ID = 0x64617277; // darw
    bytes4 public constant CRAB_CHAIN_ID = 0x63726162; // crab
    bytes4 public constant PANGORO_CHAIN_ID = 0x70616772; // pagr
    bytes4 public constant PANGOLIN_CHAIN_ID = 0x7061676c; // pagl
    bytes4 public constant PANGOLIN_PARACHAIN_CHAIN_ID = 0x70676c70; // pglp
    bytes4 public constant CRAB_PARACHAIN_CHAIN_ID = 0x63726170; // crap
}