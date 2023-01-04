# ILane


A interface for user to fetch lane info


## Contents
<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [Functions](#functions)
  - [getLaneInfo](#getlaneinfo)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->




## Functions

### getLaneInfo
No description
> Return lane info


#### Declaration
```solidity
  function getLaneInfo(
  ) external returns (uint32 this_chain_pos, uint32 this_lane_pos, uint32 bridged_chain_pos, uint32 bridged_lane_pos)
```

#### Modifiers:
No modifiers


#### Returns:
| Type | Description |
| --- | --- |
|`this_chain_pos` | This chain position
|`this_lane_pos` | This lane position
|`bridged_chain_pos` | Bridged chain pos
|`bridged_lane_pos` | Bridged lane pos


