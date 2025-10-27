// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/console.sol";

/**
 * @title RebaseToken
 * @dev A deflationary ERC20 token that uses a scaling factor mechanism for rebasing
 * @notice This token implements ERC20 standard but uses internal shares and a global scaling factor
 *         balanceOf(account) = rawShares[account] * index / BASE
 *         transfer() and transferFrom() operate in shares: shares = amount * BASE / index
 */
contract RebaseToken {
    // ============ Constants ============
    
    /// @dev Base unit for scaling calculations (1e18)
    uint256 public constant BASE = 1e18;
    
    /// @dev Maximum uint256 value for overflow protection
    uint256 private constant MAX_UINT256 = type(uint256).max;
    
    // ============ Events ============
    
    /// @dev Emitted when tokens are transferred
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    /// @dev Emitted when allowance is set
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    /// @dev Emitted when a rebase occurs
    event Rebase(uint256 oldIndex, uint256 newIndex, uint256 timestamp);
    
    // ============ State Variables ============
    
    /// @dev Token name
    string public name;
    
    /// @dev Token symbol
    string public symbol;
    
    /// @dev Token decimals
    uint8 public decimals;
    
    /// @dev Global scaling factor index (starts at BASE = 1e18)
    uint256 public index = BASE;
    
    /// @dev Total supply in shares (not adjusted by index)
    uint256 public totalShares;
    
    /// @dev Owner address (can perform rebase)
    address public owner;
    
    /// @dev Internal balances stored as raw shares
    mapping(address => uint256) private rawShares;
    
    /// @dev Allowances stored as raw shares
    mapping(address => mapping(address => uint256)) private allowances;
    
    // ============ Modifiers ============
    
    /// @dev Only owner can call
    modifier onlyOwner() {
        require(msg.sender == owner, "RebaseToken: caller is not the owner");
        _;
    }
    
    // ============ Constructor ============
    
    /**
     * @dev Constructor initializes the token
     * @param _name Token name
     * @param _symbol Token symbol
     * @param _decimals Token decimals
     * @param _initialSupply Initial supply of tokens
     */
    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _initialSupply
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        owner = msg.sender;
        
        // Convert initial supply to shares and mint to owner
        uint256 shares = _initialSupply * BASE / index;
        rawShares[owner] = shares;
        totalShares = shares;
        
        emit Transfer(address(0), owner, _initialSupply);
    }
    
    // ============ View Functions ============
    
    /**
     * @dev Returns the total supply of tokens (adjusted by current index)
     * @return Total supply
     */
    function totalSupply() external view returns (uint256) {
        return totalShares * index / BASE;
    }
    
    /**
     * @dev Returns the balance of the specified account (adjusted by current index)
     * @param account The account to query
     * @return Balance of the account
     */
    function balanceOf(address account) external view returns (uint256) {
        return rawShares[account] * index / BASE;
    }
    
    /**
     * @dev Returns the allowance of the spender for the owner
     * @param ownerAddr The address of the token owner
     * @param spenderAddr The address of the spender
     * @return Allowance amount
     */
    function allowance(address ownerAddr, address spenderAddr) external view returns (uint256) {
        return allowances[ownerAddr][spenderAddr] * index / BASE;
    }
    
    // ============ Transfer Functions ============
    
    /**
     * @dev Transfers tokens from sender to recipient
     * @param to The address to transfer to
     * @param amount The amount to transfer
     * @return True if transfer succeeds
     */
    function transfer(address to, uint256 amount) external returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }
    
    /**
     * @dev Transfers tokens from one address to another using allowance
     * @param from The address to transfer from
     * @param to The address to transfer to
     * @param amount The amount to transfer
     * @return True if transfer succeeds
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        address spender = msg.sender;
        
        // Check and update allowance
        uint256 currentAllowance = allowances[from][spender] * index / BASE;
        require(currentAllowance >= amount, "RebaseToken: transfer amount exceeds allowance");
        
        // Update allowance (convert back to shares)
        uint256 sharesToDeduct = amount * BASE / index;
        allowances[from][spender] -= sharesToDeduct;
        
        _transfer(from, to, amount);
        return true;
    }
    
    /**
     * @dev Approves the spender to spend tokens on behalf of the owner
     * @param spender The address to approve
     * @param amount The amount to approve
     * @return True if approval succeeds
     */
    function approve(address spender, uint256 amount) external returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }
    
    // ============ Internal Functions ============
    
    /**
     * @dev Internal transfer function
     * @param fromAddr The address to transfer from
     * @param toAddr The address to transfer to
     * @param amount The amount to transfer
     */
    function _transfer(address fromAddr, address toAddr, uint256 amount) internal {
        require(fromAddr != address(0), "RebaseToken: transfer from the zero address");
        require(toAddr != address(0), "RebaseToken: transfer to the zero address");
        
        // Convert amount to shares
        uint256 shares = amount * BASE / index;
        
        // Check balance (convert shares back to tokens for comparison)
        uint256 fromBalance = rawShares[fromAddr] * index / BASE;
        require(fromBalance >= amount, "RebaseToken: transfer amount exceeds balance");
        
        // Update balances
        rawShares[fromAddr] -= shares;
        rawShares[toAddr] += shares;
        
        // Note: totalShares remains constant as we're just moving shares between accounts
        
        emit Transfer(fromAddr, toAddr, amount);
    }
    
    /**
     * @dev Internal approval function
     * @param ownerAddr The address of the token owner
     * @param spenderAddr The address of the spender
     * @param amount The amount to approve
     */
    function _approve(address ownerAddr, address spenderAddr, uint256 amount) internal {
        require(ownerAddr != address(0), "RebaseToken: approve from the zero address");
        require(spenderAddr != address(0), "RebaseToken: approve to the zero address");
        
        // Convert amount to shares for storage
        uint256 shares = amount * BASE / index;
        allowances[ownerAddr][spenderAddr] = shares;
        
        emit Approval(ownerAddr, spenderAddr, amount);
    }
    
    // ============ Rebase Functions ============
    
    /**
     * @dev Performs a rebase by reducing the index by 1%
     * @notice Only owner can call this function
     * @notice Reduces index by 1%: newIndex = oldIndex * 99 / 100
     */
    function rebase() external onlyOwner {
        uint256 oldIndex = index;
        
        // Reduce index by 1%: newIndex = oldIndex * 99 / 100
        // This creates deflationary pressure
        uint256 newIndex = oldIndex * 99 / 100;
        
        // Ensure index doesn't go below a minimum threshold to prevent precision issues
        require(newIndex >= BASE / 1000, "RebaseToken: index too low");
        
        index = newIndex;
        
        emit Rebase(oldIndex, newIndex, block.timestamp);
    }
    
    /**
     * @dev Returns the current scaling factor index
     * @return Current index value
     */
    function getIndex() external view returns (uint256) {
        return index;
    }
    
    /**
     * @dev Returns the raw shares for an account (for internal use)
     * @param account The account to query
     * @return Raw shares
     */
    function getRawShares(address account) external view returns (uint256) {
        return rawShares[account];
    }
    
    // ============ Owner Functions ============
    
    /**
     * @dev Transfers ownership to a new owner
     * @param newOwner The new owner address
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "RebaseToken: new owner is the zero address");
        owner = newOwner;
    }
}
