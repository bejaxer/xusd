// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;
pragma abicoder v2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "./interfaces/IRedeem.sol";
import "./interfaces/IxUSD.sol";
import "./interfaces/IPriceOracleAggregator.sol";

/**
 * @title Redeem
 */
contract Redeem is IRedeem, Ownable {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    /// @notice xUSD token address
    address public immutable xUSD;

    /// @notice token price oracle aggregator
    address public priceOracleAggregator;

    /// @notice supported stable coins
    EnumerableSet.AddressSet _supportedAssets;

    /////////////////////////////
    //          EVENT          //
    /////////////////////////////
    event Deposit(
        address indexed user,
        address indexed token,
        uint256 tokenAmount,
        uint256 xUSDAmount
    );

    /////////////////////////////
    //        INITIALIZE       //
    /////////////////////////////
    constructor(address _xUSD, address _priceOracleAggregator) Ownable() {
        xUSD = _xUSD;
        priceOracleAggregator = _priceOracleAggregator;
    }

    /////////////////////////////
    //      POLICY FUNCTION    //
    /////////////////////////////
    function updatePriceOracleAggregator(
        address _priceOracleAggregator
    ) external onlyOwner {
        priceOracleAggregator = _priceOracleAggregator;
    }

    function addSupportedCoin(address coin) external onlyOwner {
        require(!_supportedAssets.contains(coin), "already exists");
        _supportedAssets.add(coin);
    }

    function removeSupportedCoin(address coin) external onlyOwner {
        require(_supportedAssets.contains(coin), "not exists");
        _supportedAssets.remove(coin);
    }

    /////////////////////////////
    //       VIEW FUNCTION     //
    /////////////////////////////
    function isSupportedCoin(address coin) public view returns (bool) {
        return _supportedAssets.contains(coin);
    }

    function getSupportedCoins() external view returns (address[] memory) {
        return _supportedAssets.values();
    }

    /////////////////////////////
    //       USER FUNCTION     //
    /////////////////////////////
    function deposit(
        address token,
        uint256 tokenAmount
    ) external override returns (uint256 xUSDAmount) {
        require(_supportedAssets.contains(token), "not supported coin");

        IPriceOracleAggregator aggregator = IPriceOracleAggregator(
            priceOracleAggregator
        );
        xUSDAmount =
            (tokenAmount *
                aggregator.viewPriceInUSD(token) *
                (10 ** IERC20Metadata(xUSD).decimals())) /
            (aggregator.viewPriceInUSD(xUSD) *
                10 ** IERC20Metadata(token).decimals());

        // receive token
        IERC20(token).safeTransferFrom(msg.sender, address(this), tokenAmount);

        // mint xUSD
        IxUSD(xUSD).mint(msg.sender, xUSDAmount);

        emit Deposit(msg.sender, token, tokenAmount, xUSDAmount);
    }
}
