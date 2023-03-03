// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract massDistributionContract {
    uint public distributedAmount = 0;
    address payable private owner;
    
    constructor () {
        owner = payable(msg.sender);
    }
    //fallback function
    fallback () external payable  { 
        revert(); 
    }
    //Prevent someone sending in ETH
    receive () external payable {
        revert();
    }
	//In case someone send in ETH to the token address, taking it out and give to admin
	function withdrawETH(uint256 amount) public returns(uint256){
		require(amount > 0, "ERC721_basicNFT: No amount to send");
		require(address(this).balance >=amount);
		owner.transfer(amount);
		return 1;
	}
    function distributeToken(address[] memory addrs) public payable {
        uint256 totalETH = msg.value;
        uint256 addrAmount = addrs.length;
        require(totalETH > 0 && addrAmount > 0, "massDistributionContract: zero ETH or zero address to send");
        uint256 oneReceive = msg.value / addrs.length;
        for(uint i=0;i<addrs.length;i++){
            require(address(this).balance >= oneReceive, "No enough ETH to distribute");
            address payable oneAddr = payable(addrs[i]);
            oneAddr.transfer(oneReceive);
        }
    }
}