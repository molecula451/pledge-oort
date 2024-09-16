// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/Test.sol";
import "../src/MainnetPledge.sol";

contract MainnetPledgeTest is Test {
    MainnetPledge public pledge;
    address public owner = address(this);

    function setUp() public {
        pledge = new MainnetPledge();
        vm.deal(owner, 100000000000 ether);
    }
    
    function testInitialization() public {
        assertEq(pledge.pledgeAmount(), 0);
        assertEq(pledge.owner(), owner);
        assertEq(pledge.withdrawTimes(), 0);

        uint256 expectedUnlockTime = block.timestamp + 5 * 365 days;
        assertEq(pledge.unlockTime(), expectedUnlockTime);
    }

    function testDeposit() public {
        uint256 depositAmount = 10 ether;
        
        pledge.deposit{value: depositAmount}();
        
        assertEq(pledge.pledgeAmount(), depositAmount);
        assertEq(address(pledge).balance, depositAmount);
    }


    function testWithdrawFirstYear() public {
        uint256 depositAmount = 100000000 ether;
        pledge.deposit{value: depositAmount}();

        fastForward(5 * 365 days);

        uint256 availableTokens = pledge.calculateAvailableTokens();
        assertEq(availableTokens, 100_000_000 * 10**18);

        uint256 initialBalance = address(owner).balance;
        pledge.withdraw();

        assertEq(pledge.withdrawTimes(), 1);
    }

    // Test withdrawal logic with halving amounts after 5 withdrawals
    function testWithdrawHalvingLogic() public {
        uint256 depositAmount = 100000000 ether;
        pledge.deposit{value: depositAmount}();

        fastForward(5 * 365 days);

        for (uint256 i = 0; i < 5; i++) {
            pledge.withdraw();
            assertEq(pledge.calculateAvailableTokens(), 100_000_000 * 10**18);
            fastForward(365 days); // Move to next year
        }

        // 6th year, tokens should halve
        pledge.withdraw();
        assertEq(pledge.calculateAvailableTokens(), 50_000_000 * 10**18);
        fastForward(365 days);

        // 7th year, tokens should halve again
        pledge.withdraw();
        assertEq(pledge.calculateAvailableTokens(), 25_000_000 * 10**18);
        fastForward(365 days);

        for (uint256 i = 2; i <= 5; i++) {
            pledge.withdraw();
            assertEq(pledge.calculateAvailableTokens(), (100_000_000 * 10**18) / (2 ** i));
            fastForward(365 days);
        }
    }

    function testWithdrawFailsWithInsufficientBalance() public {
        uint256 depositAmount = 10 ether;
        pledge.deposit{value: depositAmount}();

        fastForward(5 * 365 days);

        vm.expectRevert("Not enough balance to withdraw.");
        pledge.withdraw();
    }

    // Test onlyOwner modifier
    function testWithdrawOnlyOwner() public {
        address attacker = address(0x1234);
        uint256 depositAmount = 10 ether;
        pledge.deposit{value: depositAmount}();

        fastForward(5 * 365 days);

        // Attacker tries to withdraw
        vm.prank(attacker);
        vm.expectRevert("Only owner can call this function.");
        pledge.withdraw();
    }

    function fastForward(uint256 time) public {
        vm.warp(block.timestamp + time);
    
    }
}
