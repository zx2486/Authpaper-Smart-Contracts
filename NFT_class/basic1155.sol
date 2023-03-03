// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./ERC1155.sol";
import "./Administrator.sol";
import "./SafeMath.sol";
import "./IERC20.sol";

contract basic1155 is ERC1155, Adminstrator {
	uint256 private _totalSupply;
	mapping (uint => bool) public _isExist;
	mapping (uint256 => uint256) public tokenSupply;
	string public name;
	string public symbol;
	
	constructor () ERC1155("ipfs://QmSt1dU4LF8jtfwPQF8Nr2Msda2BN4fJ6C5XNAod6RDNik/{id}.json") {
        //Minting 1000 NFT with tokenID 0 to the sender address
		address _initialTokenAddress = msg.sender;
		mintToken(_initialTokenAddress,1000,0);
		//Minting 1 NFT with tokenID 1 to the sender address with custom URL
		mintToken(_initialTokenAddress,1,1);
		//Information of this collection
		name = "Core Engine Coin 1155";
		symbol = "CEC15";
    }
	
	//The following are not standard functions
	function setNameSymbol(string memory newName,string memory newSymbol) public onlyAdmin {
		name = newName;
		symbol = newSymbol;
	}
	
	/**
     * Total number of NFT
     */
    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }
	function totalSupply(uint256 _id) public view returns (uint256) {
		return tokenSupply[_id];
	}
	
	function getNewTokenID() public view virtual returns (uint256) {
		uint256 tokenId = _totalSupply;
		while(_isExist[tokenId]){
			tokenId += 1;
		}
		return tokenId;
	}
	function mintToken(address account, uint256 amount) public onlyAdmin{
		mintToken(account,amount,getNewTokenID());
	}
	//Minting new token, only admin can do it
	function mintToken(address account, uint256 amount, uint256 tokenId) public onlyAdmin{
		require(account != address(0), "basicNFT: mint to the zero address");
		_mint(account,tokenId,amount,"");
		tokenSupply[tokenId] += amount;
		if(!_isExist[tokenId]){
			_isExist[tokenId] = true;
			_totalSupply += 1;
		}
	}
	//Burn token, only admin can do it
	function burnToken(address account, uint256 tokenId, uint256 amount) public onlyAdmin{
		require(account != address(0), "basicNFT: burn from zero address");
		require(_isExist[tokenId], "basicNFT: token is not minted");
		_burn(account, tokenId, amount);
		tokenSupply[tokenId] -= amount;
		if(tokenSupply[tokenId] <=0){
			_isExist[tokenId] = false;
			_totalSupply -= 1;
		}
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
	function withdrawETH(uint256 amount) public onlyAdmin returns(uint256){
		require(amount > 0, "basicNFT: No amount to send");
		require(address(this).balance >=amount);
		address payable owner = payable(msg.sender);
		owner.transfer(amount);
		return 1;
	}
	//In case someone send in a ERC-20 token to the token address, taking it out and give to admin
    function withdrawErc20(address tokenAddr, uint256 amount) public onlyAdmin returns(uint256){
		require(amount > 0, "basicNFT: No amount to send");
		require(tokenAddr != address(0),"basicNFT: Cannot send to empty address");
		IERC20 token = IERC20(tokenAddr);
		address payable owner = payable(msg.sender);
		require(token.balanceOf(address(this)) >=amount);
		token.transfer(owner, amount);
		return 1;
	}
}