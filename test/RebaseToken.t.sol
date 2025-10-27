// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/RebaseToken.sol";

/**
 * @title RebaseTokenTest
 * @dev Comprehensive test suite for RebaseToken contract
 * @notice Tests initialization, rebase mechanics, transfers, rounding, and permissions
 */
contract RebaseTokenTest is Test {
    RebaseToken public token;
    address public owner;
    address public alice;
    address public bob;
    address public charlie;
    
    uint256 public constant INITIAL_SUPPLY = 1000000 * 1e18; // 1M tokens
    uint256 public constant BASE = 1e18;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Rebase(uint256 oldIndex, uint256 newIndex, uint256 timestamp);
    
    function setUp() public {
        owner = address(this);
        alice = makeAddr("alice");
        bob = makeAddr("bob");
        charlie = makeAddr("charlie");
        
        token = new RebaseToken(
            "RebaseToken",
            "RBT",
            18,
            INITIAL_SUPPLY
        );
    }
    
    // ============ Initialization Tests ============
    
    function testInitialization() public {
        // Test basic token properties
        assertEq(token.name(), "RebaseToken");
        assertEq(token.symbol(), "RBT");
        assertEq(token.decimals(), 18);
        assertEq(token.owner(), owner);
        
        // Test initial index
        assertEq(token.getIndex(), BASE);
        
        // Test initial supply
        assertEq(token.totalSupply(), INITIAL_SUPPLY);
        assertEq(token.balanceOf(owner), INITIAL_SUPPLY);
        
        // Test raw shares calculation
        uint256 expectedShares = INITIAL_SUPPLY * BASE / BASE; // Should equal INITIAL_SUPPLY
        assertEq(token.getRawShares(owner), expectedShares);
        
        // Test that other accounts have zero balance
        assertEq(token.balanceOf(alice), 0);
        assertEq(token.balanceOf(bob), 0);
        assertEq(token.getRawShares(alice), 0);
        assertEq(token.getRawShares(bob), 0);
    }
    
    function testInitialSupplyConsistency() public {
        // Verify that totalSupply matches sum of all balances
        uint256 totalBalance = token.balanceOf(owner);
        assertEq(token.totalSupply(), totalBalance);
        
        // Verify scaling factor consistency
        uint256 totalShares = token.getRawShares(owner);
        uint256 calculatedSupply = totalShares * token.getIndex() / BASE;
        assertEq(token.totalSupply(), calculatedSupply);
    }
    
    // ============ Single Rebase Tests ============
    
    function testSingleRebase() public {
        uint256 initialIndex = token.getIndex();
        uint256 initialSupply = token.totalSupply();
        uint256 initialBalance = token.balanceOf(owner);
        
        // Perform rebase
        vm.expectEmit(true, true, true, true);
        emit Rebase(initialIndex, initialIndex * 99 / 100, block.timestamp);
        token.rebase();
        
        // Check new index (1% reduction)
        uint256 expectedNewIndex = initialIndex * 99 / 100;
        assertEq(token.getIndex(), expectedNewIndex);
        
        // Check that total supply decreased by 1%
        uint256 expectedNewSupply = initialSupply * 99 / 100;
        assertEq(token.totalSupply(), expectedNewSupply);
        
        // Check that owner's balance decreased by 1%
        uint256 expectedNewBalance = initialBalance * 99 / 100;
        assertEq(token.balanceOf(owner), expectedNewBalance);
        
        // Verify raw shares remain unchanged
        assertEq(token.getRawShares(owner), INITIAL_SUPPLY);
        
        // Verify consistency: balance = shares * index / BASE
        uint256 calculatedBalance = token.getRawShares(owner) * token.getIndex() / BASE;
        assertEq(token.balanceOf(owner), calculatedBalance);
    }
    
    function testSingleRebaseSupplyConsistency() public {
        uint256 initialSupply = token.totalSupply();
        
        token.rebase();
        
        // Verify total supply consistency after rebase
        uint256 totalShares = token.getRawShares(owner);
        uint256 calculatedSupply = totalShares * token.getIndex() / BASE;
        assertEq(token.totalSupply(), calculatedSupply);
        
        // Verify supply decreased by exactly 1%
        assertEq(token.totalSupply(), initialSupply * 99 / 100);
    }
    
    // ============ Transfer + Rebase Tests ============
    
    function testTransferBeforeRebase() public {
        uint256 transferAmount = 100000 * 1e18; // 100k tokens
        
        // Transfer tokens to alice
        token.transfer(alice, transferAmount);
        
        // Verify balances
        assertEq(token.balanceOf(owner), INITIAL_SUPPLY - transferAmount);
        assertEq(token.balanceOf(alice), transferAmount);
        
        // Verify raw shares
        uint256 expectedOwnerShares = (INITIAL_SUPPLY - transferAmount) * BASE / BASE;
        uint256 expectedAliceShares = transferAmount * BASE / BASE;
        assertEq(token.getRawShares(owner), expectedOwnerShares);
        assertEq(token.getRawShares(alice), expectedAliceShares);
        
        // Verify total supply consistency
        assertEq(token.totalSupply(), token.balanceOf(owner) + token.balanceOf(alice));
    }
    
    function testTransferAfterRebase() public {
        uint256 transferAmount = 100000 * 1e18; // 100k tokens
        
        // First rebase
        token.rebase();
        
        // Transfer tokens to alice
        token.transfer(alice, transferAmount);
        
        // Verify balances are consistent with raw shares and index
        uint256 ownerBalance = token.getRawShares(owner) * token.getIndex() / BASE;
        uint256 aliceBalance = token.getRawShares(alice) * token.getIndex() / BASE;
        assertEq(token.balanceOf(owner), ownerBalance);
        assertEq(token.balanceOf(alice), aliceBalance);
        
        // Verify total supply consistency (allowing for small rounding differences)
        uint256 totalBalance = token.balanceOf(owner) + token.balanceOf(alice);
        uint256 totalSupply = token.totalSupply();
        assertTrue(totalSupply >= totalBalance);
        assertTrue(totalSupply - totalBalance <= 1);
    }
    
    function testTransferFromAfterRebase() public {
        uint256 approveAmount = 50000 * 1e18; // 50k tokens
        uint256 transferAmount = 30000 * 1e18; // 30k tokens
        
        // Approve alice to spend tokens
        token.approve(alice, approveAmount);
        
        // First rebase
        token.rebase();
        
        // Transfer from owner to bob using alice as spender
        vm.prank(alice);
        token.transferFrom(owner, bob, transferAmount);
        
        // Verify balances are consistent with raw shares and index
        uint256 ownerBalance = token.getRawShares(owner) * token.getIndex() / BASE;
        uint256 bobBalance = token.getRawShares(bob) * token.getIndex() / BASE;
        assertEq(token.balanceOf(owner), ownerBalance);
        assertEq(token.balanceOf(bob), bobBalance);
        
        // Verify total supply consistency (allowing for small rounding differences)
        uint256 totalBalance = token.balanceOf(owner) + token.balanceOf(bob);
        uint256 totalSupply = token.totalSupply();
        assertTrue(totalSupply >= totalBalance);
        assertTrue(totalSupply - totalBalance <= 1);
    }
    
    // ============ Multiple Rebase Tests ============
    
    function testMultipleRebase() public {
        uint256 initialSupply = token.totalSupply();
        uint256 initialIndex = token.getIndex();
        
        // Perform 3 rebases
        token.rebase();
        token.rebase();
        token.rebase();
        
        // Calculate expected values after 3 rebases
        uint256 expectedIndex = initialIndex * 99 / 100 * 99 / 100 * 99 / 100;
        uint256 expectedSupply = initialSupply * 99 / 100 * 99 / 100 * 99 / 100;
        
        // Verify index
        assertEq(token.getIndex(), expectedIndex);
        
        // Verify total supply
        assertEq(token.totalSupply(), expectedSupply);
        
        // Verify owner's balance
        assertEq(token.balanceOf(owner), expectedSupply);
        
        // Verify raw shares remain unchanged
        assertEq(token.getRawShares(owner), INITIAL_SUPPLY);
        
        // Verify consistency
        uint256 calculatedSupply = token.getRawShares(owner) * token.getIndex() / BASE;
        assertEq(token.totalSupply(), calculatedSupply);
    }
    
    function testMultipleRebaseWithTransfers() public {
        uint256 transferAmount = 200000 * 1e18; // 200k tokens
        
        // Transfer tokens to alice and bob
        token.transfer(alice, transferAmount);
        token.transfer(bob, transferAmount);
        
        uint256 initialTotalSupply = token.totalSupply();
        
        // Perform 3 rebases
        token.rebase();
        token.rebase();
        token.rebase();
        
        // Verify all balances are scaled consistently
        uint256 expectedTotalSupply = initialTotalSupply * 99 / 100 * 99 / 100 * 99 / 100;
        assertEq(token.totalSupply(), expectedTotalSupply);
        
        // Verify individual balances are scaled by the same factor
        uint256 expectedOwnerBalance = (INITIAL_SUPPLY - 2 * transferAmount) * 99 / 100 * 99 / 100 * 99 / 100;
        uint256 expectedAliceBalance = transferAmount * 99 / 100 * 99 / 100 * 99 / 100;
        uint256 expectedBobBalance = transferAmount * 99 / 100 * 99 / 100 * 99 / 100;
        
        assertEq(token.balanceOf(owner), expectedOwnerBalance);
        assertEq(token.balanceOf(alice), expectedAliceBalance);
        assertEq(token.balanceOf(bob), expectedBobBalance);
        
        // Verify total supply equals sum of all balances
        assertEq(token.totalSupply(), token.balanceOf(owner) + token.balanceOf(alice) + token.balanceOf(bob));
    }
    
    // ============ Rounding Edge Case Tests ============
    
    function testRoundingEdgeCase1Wei() public {
        // Transfer 1 wei to alice
        token.transfer(alice, 1);
        
        // Verify 1 wei transfer
        assertEq(token.balanceOf(alice), 1);
        assertEq(token.balanceOf(owner), INITIAL_SUPPLY - 1);
        
        // Perform rebase
        token.rebase();
        
        // Verify rounding behavior - Alice's balance should be 0 after rebase
        assertEq(token.balanceOf(alice), 0);
        
        // Verify consistency - total supply should equal sum of all balances
        // Note: There might be a small difference due to rounding when transferring small amounts
        uint256 totalBalance = token.balanceOf(owner) + token.balanceOf(alice);
        uint256 totalSupply = token.totalSupply();
        
        // The difference should be at most 1 wei due to rounding
        assertTrue(totalSupply >= totalBalance);
        assertTrue(totalSupply - totalBalance <= 1);
        
        // Verify that each balance is consistent with raw shares and index
        uint256 ownerBalance = token.getRawShares(owner) * token.getIndex() / BASE;
        uint256 aliceBalance = token.getRawShares(alice) * token.getIndex() / BASE;
        assertEq(token.balanceOf(owner), ownerBalance);
        assertEq(token.balanceOf(alice), aliceBalance);
    }
    
    function testRoundingWithSmallAmounts() public {
        uint256 smallAmount = 100; // 100 wei
        
        // Transfer small amount to alice
        token.transfer(alice, smallAmount);
        
        // Perform rebase
        token.rebase();
        
        // Verify rounding behavior for small amounts
        uint256 expectedAliceBalance = smallAmount * 99 / 100;
        assertEq(token.balanceOf(alice), expectedAliceBalance);
        
        // Verify total supply consistency
        assertEq(token.totalSupply(), token.balanceOf(owner) + token.balanceOf(alice));
    }
    
    function testRoundingPrecision() public {
        // Test with amounts that don't divide evenly
        uint256 amount = 1000000000000000001; // 1.000000000000000001 tokens
        
        token.transfer(alice, amount);
        
        // Perform rebase
        token.rebase();
        
        // Verify rounding behavior
        uint256 expectedBalance = amount * 99 / 100;
        assertEq(token.balanceOf(alice), expectedBalance);
        
        // Verify raw shares calculation
        uint256 expectedShares = amount * BASE / BASE; // Before rebase
        assertEq(token.getRawShares(alice), expectedShares);
        
        // Verify consistency after rebase
        uint256 calculatedBalance = token.getRawShares(alice) * token.getIndex() / BASE;
        assertEq(token.balanceOf(alice), calculatedBalance);
    }
    
    // ============ Permission Control Tests ============
    
    function testRebaseOnlyOwner() public {
        // Try to call rebase from non-owner account
        vm.prank(alice);
        vm.expectRevert("RebaseToken: caller is not the owner");
        token.rebase();
        
        // Verify state unchanged
        assertEq(token.getIndex(), BASE);
        assertEq(token.totalSupply(), INITIAL_SUPPLY);
    }
    
    function testRebaseFromOwner() public {
        // Call rebase from owner (should succeed)
        token.rebase();
        
        // Verify rebase occurred
        assertEq(token.getIndex(), BASE * 99 / 100);
        assertEq(token.totalSupply(), INITIAL_SUPPLY * 99 / 100);
    }
    
    function testTransferOwnership() public {
        // Transfer ownership to alice
        token.transferOwnership(alice);
        
        // Verify ownership transfer
        assertEq(token.owner(), alice);
        
        // Try to call rebase from old owner (should fail)
        vm.expectRevert("RebaseToken: caller is not the owner");
        token.rebase();
        
        // Call rebase from new owner (should succeed)
        vm.prank(alice);
        token.rebase();
        
        // Verify rebase occurred
        assertEq(token.getIndex(), BASE * 99 / 100);
    }
    
    function testTransferOwnershipToZeroAddress() public {
        vm.expectRevert("RebaseToken: new owner is the zero address");
        token.transferOwnership(address(0));
    }
    
    // ============ Comprehensive Consistency Tests ============
    
    function testSupplyConsistencyAfterComplexOperations() public {
        uint256 transfer1 = 100000 * 1e18;
        uint256 transfer2 = 50000 * 1e18;
        uint256 approveAmount = 75000 * 1e18;
        
        // Complex sequence of operations
        token.transfer(alice, transfer1);
        token.rebase();
        token.transfer(bob, transfer2);
        token.approve(charlie, approveAmount);
        token.rebase();
        
        vm.prank(charlie);
        token.transferFrom(owner, bob, transfer2);
        token.rebase();
        
        // Verify total supply equals sum of all balances (allowing for small rounding differences)
        uint256 totalBalance = token.balanceOf(owner) + 
                              token.balanceOf(alice) + 
                              token.balanceOf(bob);
        uint256 totalSupply = token.totalSupply();
        assertTrue(totalSupply >= totalBalance);
        assertTrue(totalSupply - totalBalance <= 1);
        
        // Verify each balance is consistent with raw shares and index
        uint256 ownerBalance = token.getRawShares(owner) * token.getIndex() / BASE;
        uint256 aliceBalance = token.getRawShares(alice) * token.getIndex() / BASE;
        uint256 bobBalance = token.getRawShares(bob) * token.getIndex() / BASE;
        
        assertEq(token.balanceOf(owner), ownerBalance);
        assertEq(token.balanceOf(alice), aliceBalance);
        assertEq(token.balanceOf(bob), bobBalance);
    }
    
    function testIndexMinimumThreshold() public {
        // Perform rebases until we hit the minimum threshold
        uint256 rebaseCount = 0;
        try token.rebase() {
            rebaseCount++;
            // Continue rebasing until we hit the limit
            while (rebaseCount < 1000) {
                try token.rebase() {
                    rebaseCount++;
                } catch {
                    break;
                }
            }
        } catch {
            // Expected to fail at some point
        }
        
        // Verify index is at or above minimum threshold
        assertTrue(token.getIndex() >= BASE / 1000);
        
        // Verify total supply is still consistent
        uint256 calculatedSupply = token.getRawShares(owner) * token.getIndex() / BASE;
        assertEq(token.totalSupply(), calculatedSupply);
    }
}
