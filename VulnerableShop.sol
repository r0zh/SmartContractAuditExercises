// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";


///@notice The contract allows anyone to sell and buy goods. The seller has to lock funds to avoid malicious behaviour.
/// In addition, unhappy buyers can open a claim and the DAO will decide if the seller misbehaved or not.
///@dev Security review is pending... should we deploy this?
///@custom:ctf This contract is part of JC's mock-audit exercise at https://github.com/jcr-security/solidity-security-teaching-resources
contract VulnerableShop is Ownable {

    using SafeERC20 for IERC20;

    /************************************** State vars  and Structs *******************************************************/
    
    ///@dev A Sale can be in one of three states: 
    /// `Vacation` the seller is on vacation, sale halted. Enum's default.
    /// `Selling` deal still active
    /// `Disputed` the buyer submitted a claim
    /// `Pending` waiting buyer confirmation
    /// `Sold` deal is over, no claim was submitted
    enum State {
        Vacation,
        Selling,
        Pending,
        Disputed,
        Sold
    }


    ///@dev A Sale struct represent each of the active sales in the shop.
    ///@param seller The address of the seller
    ///@param buyer The address of the buyer, if any
    ///@param title The title of the item being sold
    ///@param description A description of the item being sold
    ///@param price The price in Ether of the item being sold
    ///@param state The current state of the sale
    struct Sale {
        address seller;
        address buyer;
        string title;
        string description; 
        uint256 price;
        State state;
    }

    
    ///@dev A Dispute struct represent each of the active disputes in the shop.
    ///@param itemId The ID of the item being disputed
    ///@param buyerReasoning The reasoning of the buyer for the claim
    ///@param sellerReasoning The reasoning of the seller against the claim
    struct Dispute {
        uint256 disputeId;
        string buyerReasoning;
        string sellerReasoning;
    }


    mapping (uint256 itemId => Sale) public offered_items;
    ///@dev The index of the next new Sale
    uint256 public  offerIndex;
    mapping (uint256 itemId => Dispute) public disputed_items;
    address[] public blacklistedSellers;

    IERC20 public immutable token;


    /************************************** Events and modifiers *****************************************************/
    event Buy(address user, uint256 item);
    event NewItem(uint256 id, string title);
    event Reimburse(address user);
    event SaleFinished(uint256 itemId);
    event AwardNFT(address user);
    event DeletedSale(uint256 itemId);
    

    /************************************** External  ****************************************************************/ 
    ///@notice Constructor of the contract
    ///@param _token The address of the ERC20 token used in the shop
    constructor(address _token) {
        token = IERC20(_token);
    }


    ///@notice Endpoint to buy an item
    ///@param itemId The ID of the item being bought
    ///@dev The user must send the exact amount of Ether to buy the item
    function doBuy(uint256 itemId) external payable {
        require(offered_items[itemId].state == State.Selling, "ItemId cannot be bought");
  
        /*
        * C2C buying logic goes here.
        * Consider this missing piece of code to be correct, do not ponder
        * about potential lack of validtaion or checks here
        */
        
        emit Buy(msg.sender, itemId);
    }
	

    ///@notice Endpoint to create a new sale. The seller must have enough funds staked in the Vault so  
    /// price amount can be locked to desincentivice malicious behavior
    ///@param title The title of the item being sold
    ///@param description A description of the item being sold
    ///@param price The price in Ether of the item being sold
    function newSale(string calldata title, string calldata description, uint256 price) external {
        // Assigns the initial value and adds one to offerIndex
        uint256 itemId = offerIndex++;

        /*
        * C2C selling logic goes here.
        * Consider this missing piece of code to be correct, do not ponder
        * about potential lack of validtaion or checks here
        */
        
        emit NewItem(itemId, title);
    }


    ///@notice Endpoint to dispute a sale. The buyer will supply the supporting info to the DAO
    ///@param itemId The ID of the item being disputed
    ///@param buyerReasoning The reasoning of the buyer for the claim
    function disputeSale(uint256 itemId, string calldata buyerReasoning) external {   
        require(offered_items[itemId].state == State.Pending, "ItemId cannot be disputed"); 
        require(offered_items[itemId].buyer == msg.sender, "Only buyer can open a dispute"); 

        /*
        * C2C dispute logic goes here.
        * Consider this missing piece of code to be correct, do not ponder
        * about potential lack of validtaion or checks here
        */
    }


    ///@notice Reimburse a buyer at discretion of the Owner. 
    ///@param itemId The ID of the item being reimbursed
    /// @custom:fix Changed token recipient from msg.sender to the actual buyer
    function reimburse(uint256 itemId) external onlyOwner {
        require(
            offered_items[itemId].state == State.Disputed,
            "A dispute should be opened before reimbursing"
        );
        uint256 amount = offered_items[itemId].price; 		

		/*
        * Reimbursement logic goes here.
        * Consider this missing piece of code to be correct, do not ponder
        * about potential lack of validtaion or checks here
        */

        // Send the tokens back to the buyer of itemId
        address buyer = offered_items[itemId].buyer;
        token.safeTransfer(buyer, amount);
        emit Reimburse(buyer);      
	}


    ///@notice Endpoint to confirm the receipt of an item and trigger the payment to the seller. 
    ///@param itemId The ID of the item being confirmed
    function itemReceived(uint256 itemId) external { 
        require(offered_items[itemId].state == State.Pending, "ItemId is not being shipped"); 
        require(offered_items[itemId].buyer == msg.sender, "Only buyer can open mark item as received"); 

        /*
        * C2C confirmation logic goes here.
        * Consider this missing piece of code to be correct, do not ponder
        * about potential lack of validtaion or checks here
        */
        offered_items[itemId].state = State.Sold;

        emit SaleFinished(itemId);
    }


    ///@notice Endpoint to remove a malicious sale and slash the stake. The owner of the contract can remove a malicious sale and blacklist the seller
    ///@param itemId The ID of the item which sale is considered malicious
    function removeMaliciousSale(uint256 itemId) external onlyOwner {
        require(offered_items[itemId].seller != address(0), "itemId does not exist");

        /*
        * Privileged removal of malicious sale logic goes here.
        * Consider this missing piece of code to be correct, do not ponder
        * about potential lack of validtaion or checks here
        */

        deleteSale(itemId, false);
    }


    /************************************** Internal *****************************************************************/
    ///@notice Remove a sale from the list and do some slashing afterwards
    ///@param itemId The ID of the item which sale is being removed
    ///@param toBePaid If the seller should be paid or not
    ///@custom:fix Changed the function to be internal
    function deleteSale(uint256 itemId, bool toBePaid) internal {
        delete offered_items[itemId];

        /*
        * Slashing code goes here.
        * Consider this missing piece of code to be correct, do not ponder
        * about potential lack of validtaion or checks here
        */
        emit DeletedSale(itemId);
    }


    /************************************** Views ********************************************************************/
    ///@notice View function to return the user's disputed sales
    ///@param itemId The ID of the item being disputed
    ///@return The dispute details
	function query_dispute (uint256 itemId) public view returns (Dispute memory) {
		return disputed_items[itemId];
	}

}