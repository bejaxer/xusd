// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;
pragma abicoder v2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./interfaces/IxUSD.sol";

/**
 * @title Staking
 */
contract Staking is Ownable {
    using SafeERC20 for IERC20;

    struct UserInfo {
        /// @notice staking amount
        uint256 amount;
        /// @notice last updated timestamp
        uint256 lastUpdatedAt;
        /// @notice reward amount
        uint256 reward;
    }

    /// @notice xUSD token address
    address public immutable xUSD;

    /// @notice user => info
    mapping(address => UserInfo) public info;

    /// @notice fixed APY
    uint256 public constant APY = 50;

    /// @notice multiplier
    uint256 public constant MULTIPLIER = 10000;

    /////////////////////////////
    //          EVENT          //
    /////////////////////////////
    event Deposit(address indexed user, uint256 amount);

    event Withdraw(address indexed user, uint256 amount);

    event Redeem(address indexed user, uint256 amount);

    /////////////////////////////
    //        INITIALIZE       //
    /////////////////////////////
    constructor(address _xUSD) Ownable() {
        xUSD = _xUSD;
    }

    modifier updateInfo(address user) {
        UserInfo storage userInfo = info[user];

        if (userInfo.amount > 0) {
            userInfo.reward +=
                (userInfo.amount *
                    (block.timestamp - userInfo.lastUpdatedAt) *
                    APY) /
                (365 days * MULTIPLIER);
        }

        userInfo.lastUpdatedAt = block.timestamp;
        _;
    }

    /////////////////////////////
    //       USER FUNCTION     //
    /////////////////////////////
    function deposit(uint256 amount) external updateInfo(msg.sender) {
        require(amount > 0, "INVALID_AMOUNT");

        // because amount is less than total supply
        unchecked {
            info[msg.sender].amount += amount;
        }

        IERC20(xUSD).safeTransferFrom(msg.sender, address(this), amount);

        emit Deposit(msg.sender, amount);
    }

    function withdraw(uint256 amount) external updateInfo(msg.sender) {
        require(amount > 0, "INVALID_AMOUNT");
        require(amount <= info[msg.sender].amount, "EXCEED_AMOUNT");

        // because amount is less than staking amount
        unchecked {
            info[msg.sender].amount -= amount;
        }

        IERC20(xUSD).safeTransfer(msg.sender, amount);

        emit Withdraw(msg.sender, amount);
    }

    function redeem() external updateInfo(msg.sender) {
        uint256 amount = info[msg.sender].reward;
        info[msg.sender].reward = 0;

        if (amount > 0) {
            IxUSD(xUSD).mint(msg.sender, amount);
        }

        emit Redeem(msg.sender, amount);
    }
}
