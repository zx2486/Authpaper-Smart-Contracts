# Authpaper Smart Contracts
 This keeps the smart contracts used in different projects by Authpaper Limited

Unless stated otherwise, all contracts here are under the GNU GPLv3 license.

Welcome to review the code and post any problem. You may also use the code for your own project, just follow the license.

We have the following contracts:

AUPC folder:
AUPC.sol, the AUPC ERC-20 smart contract. 
It is implemented on the ETH network here: https://etherscan.io/address/0x500df47e1df0ef06039218dcf0960253d89d6658
There is a transfer limitation (lockup period) on holding the coin.

AUPC_sale_contract.sol, the AUPC sales contract.
It is implemented on the ETH network here: https://etherscan.io/address/0x76c944a5fc6d98477e374e5a605f5c3b11b27148
In this sales contract we have tried to implement a multi-level reward logic. 
When someone sends in ETH to purchase AUPC, his referrer, referrer' referrer and the third level referrer will receive AUPC awards.

Now checking back from 2023, we can see some loopholes on the contract, please do not use until we have fixed them or you know how to fix them.

