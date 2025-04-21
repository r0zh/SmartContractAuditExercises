// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

uint256 constant THRESHOLD = 10;

 
///@notice The contract allows to vote on open disputes. If the dispute is resolved in favor of the buyer,
/// the seller have to refund the buyer. If the dispute is resolved in favor of the seller, the sale is closed.
///@dev Security review is pending... should we deploy this?
///@custom:exercise This contract is part of the exercises at https://github.com/jcr-security/solidity-security-teaching-resources
contract VulnerableDAO is Ownable {

    /** 
        @notice A Dispute includes the itemId, the reasoning of the buyer and the seller on the claim,
        and the number of votes for and against the dispute.
        @dev A Dispute is always written from the POV of the buyer
            - FOR is in favor of the buyer claim
            - AGAINST is in favor of the seller claim
     */
    struct Dispute {
        uint256 itemId;
        string buyerReasoning;
        string sellerReasoning;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 totalVoters;
    }

    mapping(uint256 disputeId => Dispute) public disputes;

    uint256 public revealBlock;
    mapping(address => bytes32) public commits;
    bytes32 public globalSeed;

    /************************************** Events and modifiers *****************************************************/

    event AwardNFT(address user);

    /************************************** External  ****************************************************************/ 

    /**
        @notice Constructor initializes the owner of the contract
    */
    constructor() Ownable(msg.sender) {
        revealBlock = 0;
        // No need for password initialization
    }

    /**
        @notice Update the contract's configuration details
        @dev Only the contract owner can call this function
     */
    function updateConfig() external onlyOwner {
        /*
        * DAO configuration logic goes here.
        * Consider this missing piece of code to be correct, do not ponder
        * about potential lack of validtaion or checks here
        */
    }


    /**
        @notice Cast a vote on a dispute
        @param disputeId The ID of the target dispute
        @param vote The vote, true for FOR, false for AGAINST
     */
    function castVote(uint256 disputeId, bool vote) external {  
        /*
        * DAO vote casting logic goes here.
        * Consider this missing piece of code to be correct, do not ponder
        * about potential lack of validtaion or checks here
        */
    }


    /**
        @notice Open a dispute
        @param itemId The ID of the item involved in the dispute
        @param buyerReasoning The reasoning of the buyer in favor of the claim
        @param sellerReasoning The reasoning of the seller against the claim
     */
    function newDispute( 
        uint256 itemId, 
        string calldata buyerReasoning, 
        string calldata sellerReasoning
    ) external onlyOwner returns (uint256) { 
        /*
        * DAO dispute logic goes here.
        * Consider this missing piece of code to be correct, do not ponder
        * about potential lack of validtaion or checks here
        */
    }    


    /**
        @notice Resolve a dispute if enough users have voted and remove it from the storage
        @param disputeId The ID of the target dispute
     */
    function endDispute(uint256 disputeId) external {  
        /*
        * DAO dispute logic goes here.
        * Consider this missing piece of code to be correct, do not ponder
        * about potential lack of validtaion or checks here
        */
    }    


    /**
     *  Lottery functionality replacement.
     *  This version uses the commit-reveal scheme for the lottery
     *  and solves the weak pseudo-randomness problem by introducing a
     *  random input in the start of the reveal phase, since no one can predict when will it
     *  be called.
     *  However, if the owner account is compromised or malicious, it could lead to
     *  potential exploitation of the lottery mechanism.
     */

    /**
        @notice Commit to a lottery
        @param commitHash The hash of the commit
        @dev The commit phase is open until the reveal phase starts
     */
    function commitToLottery(bytes32 commitHash) external {
        require(revealBlock == 0, "Commit phase closed");
        commits[msg.sender] = commitHash;
    }

    /**
        @notice Start the reveal phase for the lottery
        @dev Only the contract owner can call this function
     */
    function startRevealPhase() external onlyOwner {
        revealBlock = block.number + 100; // Reveal after 100 blocks
        globalSeed = keccak256(abi.encodePacked(blockhash(block.number - 1)));
    }

    /**
        @notice Close the reveal phase for the lottery
        @dev Only the contract owner can call this function
     */
    function closeRevealPhase() external onlyOwner {
        revealBlock = 0;
    }

    /**
        @notice Reveal and check the lottery results
        @param nonce The nonce used for the commit
        @dev This function checks if the reveal phase has started and validates the nonce
     */
    function revealAndCheckLottery(uint256 nonce) view external {
        console.log(block.number);
        console.log(revealBlock);
        require(block.number >= revealBlock && revealBlock != 0, "Reveal not started");
        require(commits[msg.sender] == keccak256(abi.encodePacked(msg.sender, nonce)), "Invalid nonce");
        
        uint256 randomNumber = uint256(keccak256(abi.encode(
            globalSeed,
            nonce,
            blockhash(revealBlock - 100)
        )));
        
        // If number is even, user wins an NFT
        if (randomNumber % 2 == 0) {
            /*
            * Award NFT logic goes here.
            * Consider this missing piece of code to be correct, do not ponder
            * about potential lack of validtaion or checks here
            */
        }
    }

    /**
     *  @dev This functions is just for testing purpose
     */
    function getCommitHashFromNonce(uint256 nonce) external view returns (bytes32){
        return keccak256(abi.encodePacked(msg.sender, nonce));
    }

    /************************************** Views ********************************************************************/

    /**
        @notice Query the details of a dispute
        @param disputeId The ID of the target dispute
     */
    function query_dispute(uint256 disputeId) public view returns (Dispute memory) {
        return disputes[disputeId];
    }
}