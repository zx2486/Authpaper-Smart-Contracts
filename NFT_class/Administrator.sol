// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.6.0;

/**
 * @title Adminstrator contract
 * @dev This function defines basic checking of admin and owner, as well as functions related to adding and removing admin to a contract
 */
contract Adminstrator {
  mapping (address => bool) public admin;
  address payable public owner;
  modifier onlyAdmin() { 
        require(admin[msg.sender] == true || msg.sender == owner,"Adminstrator: Not authorized"); 
        _;
  } 
  modifier onlyOwner(){
      require(msg.sender == owner,"Adminstrator: Not authorized"); 
        _;
  }
  constructor() {
    admin[msg.sender]=true;
	owner = payable(msg.sender);
  }
  function addAdmin(address newAdmin) public onlyOwner {
    admin[newAdmin]=true;
  }
  function removeAdmin(address newAdmin) public onlyOwner {
    admin[newAdmin]=false;
  }
}