// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.6.0;
//import "github.com/oraclize/ethereum-api/oraclizeAPI.sol";

import "./Adminstrator.sol";
import "./CFOT_TRC_20.sol";

/**
 * @title CFOT 5050 Room
 * @dev This is the control contract for the 5050 system. It controls the TRC 20 tokens and do the 5050 logic
 */
contract CFOT_5050_Room is Adminstrator {
    using SafeMath for uint256;
    uint public divideRadio = 475; //The divide ratio, each uplevel will get 0.475 by default
    uint public divideRadioBase = 1000;
    uint public divideAutoRecurr = 500;
    address payable public adminWallet; //To receive operation profit
    address payable public token_Addr; //To control the token
   
	//About the tree
	//event completeTree(address indexed _self, uint indexed _nodeID, uint indexed _amount);
	event startTree(address indexed _self, uint indexed _nodeID, uint indexed _amount);	
	event advanceTree(address indexed _self, uint indexed _nodeID, uint indexed _amount);	
	mapping (address => mapping (uint => uint)) public nodeIDIndex;	
	mapping (address => mapping (uint => mapping (uint => mapping (uint => treeNode)))) public treeChildren;
	mapping (address => mapping (uint => mapping (uint => treeNode))) public treeParent;
	mapping (address => mapping (uint => mapping (uint => uint))) public treeStartTime;
	//Keep the current running nodes given an address
	mapping (address => mapping (uint => bool)) public currentNodes;
	uint public spread=2;
	uint[] public possibleNodeType = [25,50,100,200,400,800,1600,3200];
	uint8 private _decimals = 6;
	
	struct treeNode {
		 address payable ethAddress; 
		 uint nodeType; 
		 uint nodeID;
	}
	struct rewardDistribution {
		address payable first;
		address payable second;
	}
	
	//Statistic issue
	bool public paused=false;
	event Paused(address account);
	event Unpaused(address account);
	
	//Setting the variables
	constructor(address payable newAdmin, address payable newToken) {
		addAdmin(address(this));
		setSpec(newAdmin,newToken);
        pause(false);
    }
	function pause(bool isPause) public onlyAdmin{
		paused = isPause;
		if(isPause) emit Paused(msg.sender);
		else emit Unpaused(msg.sender);
	}
	function setSpec(address payable newAdmin, address payable newToken) public onlyOwner returns(bool){
	    require(newAdmin != address(0), "CFOT_5050_Room: admin wallet to zero address");
	    require(newToken != address(0), "CFOT_5050_Room: token address to zero address");
	    adminWallet = newAdmin;
		addAdmin(adminWallet);
	    token_Addr = newToken;
	    ATST_ERC20 underlineToken = ATST_ERC20(newToken);
	    _decimals = underlineToken.decimals();
	    return true;
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
	//Functions related to new members
	function addMember(address payable _member, address payable _parent, uint256 newDepositAmount) public onlyAdmin {
		require(_member != address(0));
		ATST_ERC20 underlineToken = ATST_ERC20(token_Addr);
		underlineToken.setReferral(_member,_parent);
		if(newDepositAmount >0) underlineToken.assignToken(_member,newDepositAmount);
		uint treeType = possibleNodeType[0] * 10 ** uint256(_decimals);
		if(!currentNodes[_member][treeType] && underlineToken.balanceOf(_member) >= treeType) 
			openRoom(_member,treeType);
	}
	
	/*function resetProject(address payable member, uint nodeType) public payable onlyAdmin {
		uint treeType = nodeType * 10 ** uint256(_decimals);
		require(nodeIDIndex[member][treeType] >0);
		currentNodes[member][treeType] = false;
		uint totalRequireETH = nodeIDIndex[member][treeType] - 1;
		delete treeStartTime[member][treeType][totalRequireETH];
		nodeIDIndex[member][treeType] -= 1;
		//delete isReatingTree[member][treeType];
		for (uint256 i=0; i < spread; i++) {
			if(treeChildren[member][treeType][totalRequireETH][i].nodeType != 0){
				treeNode memory o = treeChildren[member][treeType][totalRequireETH][i];
				delete treeParent[o.ethAddress][o.nodeType][o.nodeID];
				delete treeChildren[member][treeType][totalRequireETH][i];
			}
		}
		treeNode memory dad = treeParent[member][treeType][totalRequireETH];
		if(dad.nodeType != 0){
			for (uint256 i=0; i < spread; i++) {
				if(treeChildren[dad.ethAddress][treeType][dad.nodeID][i].ethAddress == member){
					delete treeChildren[dad.ethAddress][treeType][dad.nodeID][i];
				}
			}
		}
		delete treeParent[member][treeType][totalRequireETH];
	}*/
	function checkTreeComplete(address payable _root, uint _treeType) public onlyAdmin {
		//_checkTreeComplete(_root,_treeType,_nodeID);
		uint cNodeID = nodeIDIndex[_root][_treeType];
		if(cNodeID > 0 && _checkTreeComplete(_root,_treeType,cNodeID - 1)){
			repeatingOpeningRoom(_root,_treeType);
		}
	}
	function publicOpenRoom(uint256 totalETH) public {
		_openAdminRoom(payable(msg.sender),totalETH);
	}
	function openRoom(address payable treeRoot, uint256 totalETH) public onlyAdmin {
		_openAdminRoom(treeRoot,totalETH);
	}
	function _openAdminRoom(address payable treeRoot, uint256 totalETH) internal {
	    require(!paused,"CFOT_5050_Room: The contract is paused");
		require(treeRoot != address(0), "CFOT_5050_Room: open room of zero address");
        require(totalETH >=0 , "CFOT_5050_Room: open room of zero value");
        ATST_ERC20 underlineToken = ATST_ERC20(token_Addr);
		require(underlineToken.isRegistered(treeRoot), "CFOT_TRC_20: User is not registered yet.");
		bool isUsingAutoRecur = (underlineToken.auto_recurring_balances(treeRoot,totalETH) >= totalETH)?
			true:false;
	    uint256 balance = (!isUsingAutoRecur)? underlineToken.balanceOf(treeRoot) : 
	    underlineToken.auto_recurring_balances(treeRoot,totalETH);
		require(balance >= totalETH, "CFOT_5050_Room: User does not have enough token to open room.");
		require(!currentNodes[treeRoot][totalETH], "CFOT_5050_Room: User cannot open room which is opened already.");
		
        address payable parentAddress = underlineToken.getReferral(treeRoot);
		address payable coldWallet = underlineToken.defaultOwner();
        if(parentAddress == address(0)) parentAddress = coldWallet;
        
        currentNodes[treeRoot][totalETH] = true;
        uint totalRequireETH = nodeIDIndex[treeRoot][totalETH];
		treeStartTime[treeRoot][totalETH][totalRequireETH]=block.timestamp;
        nodeIDIndex[treeRoot][totalETH] += 1;
        
        emit startTree(treeRoot,totalRequireETH,totalETH);
        
        //Find the parent and grand parent to receive award
        rewardDistribution memory rewardResult = _placeChildTree(parentAddress,totalETH,treeRoot,totalRequireETH);
        address payable grandAddress = underlineToken.getReferral(parentAddress);
        if(rewardResult.first == address(0) && grandAddress != address(0)){
        	//Try grandparent
        	rewardResult = _placeChildTree(grandAddress,totalETH,treeRoot,totalRequireETH);
        }
        if(rewardResult.first == address(0)){
            //ghost address
        	rewardResult = rewardDistribution(coldWallet,coldWallet);
        }
        //Do the reward distributions
        if(rewardResult.second != address(0)){
        	distributeETH(treeRoot,rewardResult.first,rewardResult.second,totalETH,isUsingAutoRecur);
        	uint cNodeID = nodeIDIndex[rewardResult.second][totalETH];
        	if(cNodeID > 0 && _checkTreeComplete(rewardResult.second,totalETH,cNodeID - 1)){
        		repeatingOpeningRoom(rewardResult.second,totalETH);
        	}
        }else{
        	distributeETH(treeRoot,rewardResult.first,coldWallet,totalETH,isUsingAutoRecur);
        }
	}
	
	function _placeChildTree(address payable firstUpline, uint treeType, address payable treeRoot, uint treeNodeID) internal returns(rewardDistribution memory) {
		//We do BFS here, so need to search layer by layer
		if(firstUpline == address(0)) return rewardDistribution(payable(0),payable(0));
		address payable getETHOne = payable(0); address payable getETHTwo = payable(0);
		
		if(currentNodes[firstUpline][treeType] && nodeIDIndex[firstUpline][treeType] <(2 ** 32) -1){
			uint cNodeID=nodeIDIndex[firstUpline][treeType] - 1;
			if(treeNodeID >0 && 
				treeStartTime[treeRoot][treeType][treeNodeID-1] > treeStartTime[firstUpline][treeType][cNodeID]){
				//If the upline starts his/her project before 
				//the starting time of the last completed project of the node	
				//This is not a new project so should not join
				return rewardDistribution(payable(0),payable(0));
			}
			uint8 childNum = findChildFromTop(treeRoot,firstUpline,treeType,cNodeID);
			if(childNum !=0) return rewardDistribution(payable(0),payable(0));
		}
		
		uint8 firstLevelSearch=_placeChild(firstUpline,treeType,treeRoot,treeNodeID); 
		if(firstLevelSearch == 1){
			getETHOne=firstUpline;
			uint cNodeID=nodeIDIndex[firstUpline][treeType] - 1;
			//So the firstUpline will get the money, as well as the parent of the firstUpline
			if(treeParent[firstUpline][treeType][cNodeID].nodeType != 0){
				getETHTwo = treeParent[firstUpline][treeType][cNodeID].ethAddress;
			}
		}
		//The same address has been here before
		if(firstLevelSearch == 2) return rewardDistribution(payable(0),payable(0));
		if(getETHOne == address(0)){
			//Now search the grandchildren of the firstUpline for a place
			if(currentNodes[firstUpline][treeType] && nodeIDIndex[firstUpline][treeType] <(2 ** 32) -1){
				uint cNodeID=nodeIDIndex[firstUpline][treeType] - 1;
				for (uint256 i=0; i < spread; i++) {
					if(treeChildren[firstUpline][treeType][cNodeID][i].nodeType != 0){
						treeNode memory kids = treeChildren[firstUpline][treeType][cNodeID][i];
						uint _placeChildResult = _placeChild(kids.ethAddress,treeType,treeRoot,treeNodeID);
						//The same address has been here before
						if(_placeChildResult == 2) return rewardDistribution(payable(0),payable(0));
						if(_placeChildResult == 1){
							getETHOne=kids.ethAddress;
							//So the child of firstUpline will get the money, as well as the child
							getETHTwo = firstUpline;
							break;
						}
					}
				}
			}
		}
		return rewardDistribution(getETHOne,getETHTwo);
	}
	//Return 0, there is no place for the node, 1, there is a place and placed, 2, duplicate node is found
	function _placeChild(address payable firstUpline, uint treeType, address payable treeRoot, uint treeNodeID) 
		internal returns(uint8) {
		if(currentNodes[firstUpline][treeType] && nodeIDIndex[firstUpline][treeType] <(2 ** 32) -1){
			uint cNodeID=nodeIDIndex[firstUpline][treeType] - 1;
			for (uint256 i=0; i < spread; i++) {
				if(treeChildren[firstUpline][treeType][cNodeID][i].nodeType == 0){
					//firstUpline has a place
					treeChildren[firstUpline][treeType][cNodeID][i]
						= treeNode(treeRoot,treeType,treeNodeID);
					//Set parent
					treeParent[treeRoot][treeType][treeNodeID] 
						= treeNode(firstUpline,treeType,cNodeID);
					emit advanceTree(firstUpline,cNodeID,treeType);	
					return 1;
				}else{
				    treeNode memory kids = treeChildren[firstUpline][treeType][cNodeID][i];
				    //The child has been here in previous project
				    if(kids.ethAddress == treeRoot) return 2;
				}
			}
		}
		return 0;
	}
	function _checkTreeComplete(address payable _root, uint _treeType, uint _nodeID) internal returns(bool){
		require(_root != address(0), "CFOT_5050_Room: Tree root to check completness is 0");
		bool _isCompleted = true;
		uint _isDirectRefCount = 0;
		for (uint256 i=0; i < spread; i++) {
			if(treeChildren[_root][_treeType][_nodeID][i].nodeType == 0){
				_isCompleted = false;
				break;
			}else{
				//Search the grandchildren
				treeNode memory _child = treeChildren[_root][_treeType][_nodeID][i];
				ATST_ERC20 underlineToken = ATST_ERC20(token_Addr);
                address referral = underlineToken.getReferral(_child.ethAddress);
				if(referral == _root) _isDirectRefCount += 1;
				for (uint256 a=0; a < spread; a++) {
					if(treeChildren[_child.ethAddress][_treeType][_child.nodeID][a].nodeType == 0){
						_isCompleted = false;
						break;
					}else{
						treeNode memory _gChild=treeChildren[_child.ethAddress][_treeType][_child.nodeID][a];
						address referral2 = underlineToken.getReferral(_gChild.ethAddress);
						if(referral2 == _root) _isDirectRefCount += 1;
					}
				}
				if(!_isCompleted) break;
			}
		}
		if(!_isCompleted) return false;
		//The tree is completed, root can start over again
		currentNodes[_root][_treeType] = false;
		return true;
	}
	function repeatingOpeningRoom(address payable _root, uint _treeType) internal{
		bool isRoomOpened = false;
		ATST_ERC20 underlineToken = ATST_ERC20(token_Addr);
		for(uint i=0;i<possibleNodeType.length;i++){
			uint256 testTreeType = possibleNodeType[i] * 10 ** uint256(_decimals);
			if(_treeType == testTreeType){
			    uint256 balance = underlineToken.auto_recurring_balances(_root,testTreeType);
			    if(balance >= testTreeType){
			        openRoom(_root,_treeType);
				    isRoomOpened = true;   
			    }
				//return;
			}/*else if(isRoomOpened){
        		if(!currentNodes[_root][testTreeType]){
        		    //uint256 balance = underlineToken.auto_recurring_balances(_root,testTreeType);
        		    //uint256 cumulatedPofit = underlineToken.cumulative_profit(_root);
        		    //if(cumulatedPofit >= (2*testTreeType)){
        		        //if(balance >= testTreeType) openRoom(_root,testTreeType,true);
                	    //else{
                	        uint256 balance = underlineToken.balanceOf(_root);
                	        if(balance >= (2*testTreeType)) openRoom(_root,testTreeType);
                	    //}
        		    //}
        		}
			}*/
		}
	}
	function findChildFromTop(address searchTarget, address _root, uint _treeType, uint _nodeID) internal view returns(uint8){
		require(_root != address(0), "CFOT_5050_Room: Tree root to check completness is 0");
		uint referenceTime = 0;		
		//Get the time this target join the tree
		for (uint8 i=0; i < spread; i++) {
			if(treeChildren[_root][_treeType][_nodeID][i].nodeType == 0){
				continue;
			}else{
				//Search the grandchildren
				treeNode memory _child = treeChildren[_root][_treeType][_nodeID][i];
				if(_child.ethAddress == searchTarget){
					referenceTime = treeStartTime[_child.ethAddress][_treeType][_child.nodeID];
					break;
				} 
				for (uint8 a=0; a < spread; a++) {
					if(treeChildren[_child.ethAddress][_treeType][_child.nodeID][a].nodeType == 0){
						continue;
					}else{
						treeNode memory _gChild=treeChildren[_child.ethAddress][_treeType][_child.nodeID][a];
						if(_gChild.ethAddress == searchTarget){
							referenceTime = treeStartTime[_gChild.ethAddress][_treeType][_gChild.nodeID];
							break;
						}
					}
				}
			}
		}
		if(referenceTime <=0) return 0;
		//Count how many child nodes enter before the reference node
		uint8 childNum = 0;
		for (uint8 i=0; i < spread; i++) {
			if(treeChildren[_root][_treeType][_nodeID][i].nodeType == 0){
				continue;
			}else{
				//Search the grandchildren
				treeNode memory _child = treeChildren[_root][_treeType][_nodeID][i];
				if(referenceTime >= treeStartTime[_child.ethAddress][_treeType][_child.nodeID]){
					childNum +=1;
				}				
				for (uint8 a=0; a < spread; a++) {
					if(treeChildren[_child.ethAddress][_treeType][_child.nodeID][a].nodeType == 0){
						continue;
					}else{
						treeNode memory _gChild=treeChildren[_child.ethAddress][_treeType][_child.nodeID][a];
						if(referenceTime >= treeStartTime[_gChild.ethAddress][_treeType][_gChild.nodeID]){
							childNum +=1;
						}
					}
				}
			}
		}
		return childNum;
	}
	function distributeETH(address treeRoot, address payable rewardFirst, address payable rewardSecond, uint256 totalETH, 
		bool isUsingAutoRecur) internal{
		//Distribute the award, the first level reward goes to auto recurring account, the second level goes to valid account
		uint256 moneyToDistribute = (totalETH * divideRadio) / divideRadioBase;
		uint256 moneyToAutoRecur = (totalETH * divideAutoRecurr) / divideRadioBase;
		uint256 sentETHThisTime = 0;
		//require(totalETH >= 2*(moneyToDistribute+moneyToAutoRecur), "CFOT_5050_room: Too much token to send");
		require(totalETH >= 2*moneyToAutoRecur, "CFOT_5050_room: Too much token to send");
		require(totalETH >= 2*moneyToDistribute, "CFOT_5050_room: Too much token to send");
		require(moneyToDistribute > 0, "CFOT_5050_room: No token for second upline");
		require(moneyToAutoRecur > 0, "CFOT_5050_room: No token for first upline");
		
		if(rewardFirst != address(0)){
			//rewardFirst.transfer(moneyToDistribute);
			sendOutETH(treeRoot,rewardFirst,0,moneyToAutoRecur,totalETH,isUsingAutoRecur);
			//sentETHThisTime = sentETHThisTime.add(moneyToDistribute);
			sentETHThisTime = sentETHThisTime.add(moneyToAutoRecur);
		} 
		if(rewardSecond != address(0)){
		    sendOutETH(treeRoot,rewardSecond,moneyToDistribute,0,totalETH,isUsingAutoRecur);
			sentETHThisTime = sentETHThisTime.add(moneyToDistribute);
			//sentETHThisTime = sentETHThisTime.add(moneyToAutoRecur);
		}		
		uint256 toPlatform = totalETH.sub(sentETHThisTime);
		if(toPlatform >0){
			sendOutETH(treeRoot,adminWallet,toPlatform,0,totalETH,isUsingAutoRecur);
		}
		// Asserts are used to find bugs in your code. They should never fail
        //assert(address(this).balance + sentETHThisTime >= previousBalances);
	}
	function sendOutETH(address treeRoot, address payable rewardFirst, uint256 moneyToDistribute, uint256 moneyToAutoRecur,
	    uint256 totalETH, bool isUsingAutoRecur) internal{
		ATST_ERC20 underlineToken = ATST_ERC20(token_Addr);
		if(moneyToDistribute >0){
		    if(!isUsingAutoRecur){
				underlineToken.adminTransfer(treeRoot,rewardFirst,moneyToDistribute);
    		}else{
				underlineToken.withdrawFromAutoAccount(treeRoot,rewardFirst,totalETH,moneyToDistribute);
    		}
		}
		if(moneyToAutoRecur >0){
		    if(!isUsingAutoRecur){
                underlineToken.depositToAutoAccount(treeRoot,rewardFirst,totalETH,moneyToAutoRecur);
    		}else{
    		    underlineToken.adminMoveFromAutoToAuto(treeRoot,rewardFirst,totalETH,moneyToAutoRecur);
    		}
		}
	}
}