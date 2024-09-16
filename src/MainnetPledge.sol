// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

contract MainnetPledge {
    uint256 public pledgeAmount;
    uint256 public lockTime;
    uint256 public unlockTime;
    uint256 public withdrawTimes;
    address public owner;

    constructor() {
        lockTime = block.timestamp;
        unlockTime = block.timestamp + 5 * 365 days;
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    function deposit() public payable onlyOwner {
        pledgeAmount += msg.value;
    }

    function withdraw() public onlyOwner {
        require(
            block.timestamp >= withdrawTimes * 365 days + unlockTime,
            "Withdraw time has not arrived."
        );
        uint256 availableTokens = calculateAvailableTokens();
        require(availableTokens > 0, "No available tokens to withdraw.");
        require(
            address(this).balance >= availableTokens,
            "Not enough balance to withdraw."
        );
        withdrawTimes += 1;
        owner.call{value: availableTokens};
    }

    function calculateAvailableTokens() private view returns (uint256) {
        uint256 amount;
        if (withdrawTimes <= 5) {
            amount = 100_000_000 * 10**18;
        } else {
            uint256 exponent = withdrawTimes - 6;
            amount = (100_000_000 * 10**18) / (2 ** exponent);

            if (amount == 0) {
                amount = 1;
            }
        }
        return amount;
    }

    function getWithdrawTime() public view returns (uint256) {
        return withdrawTimes * 365 days + unlockTime;
    }
}
