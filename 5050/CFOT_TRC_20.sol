// SPDX-License-Identifier: GPL-3.0
// Enable optimization
pragma solidity >=0.6.0;

import "./ERC20Detailed.sol";
import "./Adminstrator.sol";

/**
 * @title CFOT TRC token
 * @dev Very simple TRC20 Token example, and each user also has a auto recurring account and reserved account 
 * The users also have a referral relationship table and whether new tokens from admin should go to reserved account or default account
 */
contract ATST_ERC20 is ERC20, ERC20Detailed,Adminstrator {
    using SafeMath for uint256;

    mapping (address => mapping(uint => uint256)) public auto_recurring_balances;
    
    mapping (address => address payable) private parentAddr;
    event TransferToAutoRecurring(address indexed fromAddr, address indexed to, uint256 value);
    event TransferFromAutoRecurring(address indexed fromAddr, address indexed to, uint256 value);
    address payable public defaultOwner;
    bool public isTransferAllowed;
    
    /**
     * @dev Constructor that gives msg.sender all of existing tokens.
     */
    constructor () ERC20Detailed("Authpaper Test Setup Token", "ATST", 6) {
        //_mint(msg.sender, 0 * (10 ** uint256(decimals())));
        defaultOwner = payable(msg.sender);
        isTransferAllowed = false;
    }
    ///fallback function
    fallback () external payable  { 
        revert(); 
    }
    //Receiving TRX
    receive () external payable {
        revert();
    }
    function withdrawErc20(address tokenAddr,address targetAddr, uint256 amount) public onlyAdmin returns(bool){
		require(amount > 0, "ATST_ERC20: No amount to send");
		require(tokenAddr != address(0),"ATST_ERC20: Cannot send to empty address");
		require(targetAddr != address(0), "ATST_ERC20: transfer to zero address");
		ERC20 token = ERC20(tokenAddr);
		require(token.balanceOf(address(this)) >=amount);
		token.transfer(targetAddr, amount);
		return true;
	}
	function withdrawETH(uint256 amount) public onlyAdmin returns(bool){
		require(amount > 0, "ATST_ERC20: No amount to send");
		require(address(this).balance >=amount);
		owner.transfer(amount);
		return true;
	}

    //Registrations related
    function isRegistered(address payable tokenOwner) public view returns(bool) {
        if(parentAddr[tokenOwner] == address(0)) return false;
        else return true;
    } 
    function getReferral(address payable tokenOwner) public view returns(address payable) {
        if(parentAddr[tokenOwner] == address(0)) return defaultOwner;
        else return parentAddr[tokenOwner];
    }
    function setReferral(address payable tokenOwner, address payable parentAddress) public onlyAdmin returns (bool) {
        parentAddr[tokenOwner] = parentAddress;
        return true;
    }
    //Room operations related
    function depositToAutoAccount(address fromAddr, address target, uint index, uint256 amount) public onlyAdmin returns(bool){
        require(target != address(0), "ATST_ERC20: transfer to zero address");
        require(fromAddr != address(0), "ATST_ERC20: transfer from zero address");
        require(amount >= 0, "ATST_ERC20: negative amount");
        require(balanceOf(address(fromAddr)) >= amount, "ATST_ERC20: account not enough balance");

        auto_recurring_balances[target][index] = auto_recurring_balances[target][index].add(amount);
        _transfer(fromAddr,address(this),amount);
        //_mint(address(this),amount);
        emit TransferToAutoRecurring(fromAddr, target, amount);
        return true;
    }
    function withdrawFromAutoAccount(address fromAddr, address target,uint index, uint256 amount) public onlyAdmin returns(bool){
        require(target != address(0), "ATST_ERC20: transfer to zero address");
        require(fromAddr != address(0), "ATST_ERC20: transfer from zero address");
        require(amount >= 0, "ATST_ERC20: negative amount");
        require(auto_recurring_balances[fromAddr][index] >= amount, "ATST_ERC20: account not enough balance");
        
        //uint256 transferAmount = reserved_balances[target];
        _transfer(address(this),target,amount);
        auto_recurring_balances[fromAddr][index] = auto_recurring_balances[fromAddr][index].sub(amount);
        emit TransferFromAutoRecurring(fromAddr, target, amount);
        return true;
    }
    function assignToken(address target, uint amount) public onlyAdmin returns(bool){
        _mint(target,amount);
        return true;
    }
    function adminTransfer(address fromAddr, address target, uint256 amount) public onlyAdmin returns(bool){
	    _transfer(fromAddr,target,amount);
	    return true;
	}
	function adminMoveFromAutoToAuto(address fromAddr, address target,uint index, uint256 amount) public onlyAdmin returns(bool){
	    require(target != address(0), "ATST_ERC20: transfer to zero address");
        require(fromAddr != address(0), "ATST_ERC20: transfer from zero address");
        require(amount >= 0, "ATST_ERC20: negative amount");
        require(auto_recurring_balances[fromAddr][index] >= amount, "ATST_ERC20: account not enough balance");
        
        auto_recurring_balances[target][index] = auto_recurring_balances[target][index].add(amount);
        emit TransferToAutoRecurring(fromAddr, target, amount);
        auto_recurring_balances[fromAddr][index] = auto_recurring_balances[fromAddr][index].sub(amount);
        emit TransferFromAutoRecurring(fromAddr, target, amount);
        return true;
	}    

    //Disable transfer
    function transfer(address recipient, uint256 amount) public override virtual returns (bool) {
        require(isTransferAllowed, "ATST_ERC20: Transfer is disabled.");
        return super.transfer(recipient,amount);
    }
    function transferFrom(address sender, address recipient, uint256 amount) public override virtual returns (bool) {
        require(isTransferAllowed, "ATST_ERC20: Transfer is disabled.");
        return super.transferFrom(sender,recipient,amount);
    }
    function setTransferAllowed(bool isAllowed) public onlyAdmin returns (bool) {
        isTransferAllowed = isAllowed;
        return true;
    }
}