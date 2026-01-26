# Proveably Random Raffle Contracts
​
## About
​
This code is to create a proveably random smart contract lottery.
​
## What we want it to do?
​
1. Users should be able to enter the raffle by paying for a ticket. The ticket fees are going to be the prize the winner receives.
2. The lottery should automatically and programmatically draw a winner after a certain period.
3. Chainlink VRF should generate a provably random number.
4. Chainlink Automation should trigger the lottery draw regularly.


```solidity
// Layout of the contract file:
// version
// imports
// errors
// interfaces, libraries, contract
​
// Inside Contract:
// Type declarations
// State variables
// Events
// Modifiers
// Functions
​
// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions
```

状态变量加上 s_的前缀，event不是随便用的，用着状态变量改变的时候