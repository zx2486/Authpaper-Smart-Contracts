// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;

import "./ERC20Detailed.sol";
import "./Administrator.sol";
import "./SafeMath.sol";

/**
 * @title CFOT ERC20 token
 * @dev Very simple ERC20 Token example
 */
contract ERC20_CFOT is ERC20Detailed, Adminstrator {
    using SafeMath for uint256;
    
    /**
     * @dev Constructor that gives msg.sender all of existing tokens.
     */
    constructor () ERC20Detailed("Core Engine Coin 30 Mar", "CO30MAr", 5) {
        uint256 totalSupply = 32*(10 ** 5); //3.2 millions coins     
        _mint( msg.sender, totalSupply.mul(10 ** uint256(decimals())) );
    }
    ///fallback function
    fallback () external payable  { 
        revert(); 
    }
    //Receiving ETH
    receive () external payable {
        revert();
    }
    function withdrawETH(uint256 amount) public onlyAdmin returns(uint256){
		require(amount > 0, "ERC20_CFOT: No amount to send");
		require(address(this).balance >=amount);
		owner.transfer(amount);
		return 1;
	}
    function withdrawErc20(address tokenAddr, uint256 amount) public onlyAdmin returns(uint256){
		require(amount > 0, "ERC20_CFOT: No amount to send");
		require(tokenAddr != address(0),"ERC20_CFOT: Cannot send to empty address");
		IERC20 token = IERC20(tokenAddr);
		require(token.balanceOf(address(this)) >=amount);
		token.transfer(owner, amount);
		return 1;
	}
    /*
    function assignToken(address target, uint amount) public onlyAdmin returns(uint256){
        _mint(target,amount);
        return 1;
    }
    function tokenForAnotherErc20(address tokenAddr,address targetAddr, uint256 amount) public onlyAdmin returns(uint256){
		require(amount > 0, "ERC20_CFOT: No amount to send");
		require(tokenAddr != address(0),"ERC20_CFOT: Cannot send to empty address");
		require(targetAddr != address(0), "ERC20_CFOT: transfer to zero address");
		IERC20 token = IERC20(tokenAddr);
		require(token.balanceOf(address(this)) >=amount);
		token.transfer(targetAddr, amount);
		_burn(targetAddr,amount);
		return 1;
	}*/	
}