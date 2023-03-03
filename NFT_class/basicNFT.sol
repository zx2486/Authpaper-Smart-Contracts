// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Administrator.sol";
import "./SafeMath.sol";
import "./IERC20.sol";

contract basicNFT is ERC721, Adminstrator {
	uint256 private _totalSupply;
	string _baseURIStore;
	
	constructor () ERC721("Core Engine Coin Sep NFT", "CECSN") {
        //Mint initial token to the owner contract first
		mintToken(msg.sender);
		setBaseURI("ipfs://QmSt1dU4LF8jtfwPQF8Nr2Msda2BN4fJ6C5XNAod6RDNik/");
    }
	
	
	//The following functions are not part of the NFT standard
	/**
     * Total number of NFT
     */
    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }
	
	function getNewTokenID() public view virtual returns (uint256) {
		uint256 tokenId = _totalSupply;
		while(_exists(tokenId)){
			tokenId += 1;
		}
		return tokenId;
	}
	function mintToken(address account) public onlyAdmin{
		mintToken(account,getNewTokenID());
	}
	//Minting new token, only admin can do it
	function mintToken(address account, uint256 tokenId) public onlyAdmin{
		require(account != address(0), "basicNFT: mint to the zero address");
		_safeMint(account,tokenId);
		_totalSupply += 1;
	}
	//Burn token, only admin can do it
	function burnToken(address account, uint256 tokenId) public onlyAdmin{
		require(account != address(0), "basicNFT: burn from zero address");
		require(_exists(tokenId), "basicNFT: token is not minted");
		//_burn(account, amount);
		_burn(tokenId);
		_totalSupply -= 1;
	}
	
	/**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, SafeMath.uint2str(tokenId),".json")) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIStore;
    }
	function setBaseURI(string memory newURI) public onlyAdmin{
		_baseURIStore = newURI;
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
		require(amount > 0, "ERC721_basicNFT: No amount to send");
		require(address(this).balance >=amount);
		address payable owner = payable(msg.sender);
		owner.transfer(amount);
		return 1;
	}
	//In case someone send in a ERC-20 token to the token address, taking it out and give to admin
    function withdrawErc20(address tokenAddr, uint256 amount) public onlyAdmin returns(uint256){
		require(amount > 0, "ERC721_basicNFT: No amount to send");
		require(tokenAddr != address(0),"ERC721_basicNFT: Cannot send to empty address");
		IERC20 token = IERC20(tokenAddr);
		address payable owner = payable(msg.sender);
		require(token.balanceOf(address(this)) >=amount);
		token.transfer(owner, amount);
		return 1;
	}
}