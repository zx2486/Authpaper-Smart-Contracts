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
Also there is a discount on purchasing with referral

Now checking back from 2023, we can see some loopholes on the contract, please do not use until we have fixed them or you know how to fix them.

MultiSend.sol, a contract to send tokens to multiple accounts and reduce gas spending.

multiSendSelfClaim.sol, a contract to send tokens to multiple accounts, but it is claimed by the recipient so the gas is paid by the recipient

5050 folder:
This folder keeps smart contract used in a membership contract with profit sharing mechanism (so call 5050). 
The production system is working on the Tron network, and a demo platform is implemented on ETH Goerli testnet.
But the production system is closed already as the client bankrupted and government judged them as ponzi scheme.

Administrator.sol, modifier contract to allow some functions to be called by admin only.
IERC20.sol, interface to ERC-20.
SafeMath.sol, Wrappers over Solidity's arithmetic operations with added overflow checks.
If you are using solidity 0.8.0 or above, you should not need this.
ERC20.sol and ERC20Detailed.sol, standard ERC-20 contracts.

CFOT_TRC_20.sol, The main contract to create a token for this project. 
When people invests USDT, they will get tokens from this contract back and play the profit sharing mechanism. 
User can check the profit from playing this system in their wallet directly by checking the balance. This is a good thing as it looks DeFi (but it is not as token-USDT exchange is still centralized).
Whether an user has joined the mechanism or not is also recorded in this contract.
In this token contract, each user has two kinds of accounts. One is normal balance account as they can see in their wallet. Another one is so call auto_recurring_balance, which keeps some of the profits for opening new room when the current room is completed.

CFOT_5050_room.sol, The main 5050 mechanism logic works here.
The mechanism works this way.
When you join the mechanism with an initial token donation. A 2x2 room is started.
You refer others to join the mechanism and make donations, they will be place inside your room.
Half of the 2 donations from your 1st center (1 and 2) goes to you and Half goes to the person directly above you.
Half of the 4 donations from your 2nd center (3,4,5 and 6) goes to you and the other Half goes the person on your 1st center.
When all 6 centers are filled, the room is completed.
The half donations from the 1st center will be sent to the auto_recurring_balance account so when the old room is completed, a new room starts automatically using this account to give donations.
For the donations from the 2nd center, 2.5% of it will go to the platform as platform profit.
Remember this mechanism can be treated as Ponzi scheme in some countries and please do not use unless you know what you are doing both technically and legally.

