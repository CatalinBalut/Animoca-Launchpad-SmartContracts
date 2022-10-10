// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import {ERC20Wrapper, IWrappedERC20} from "./utils/ERC20Wrapper.sol";
import {EnumMap, EnumSet, SaleBase} from "./SaleBase.sol";
import {PurchaseLifeCyclesStorage} from "./purchaseLifeCycle/libraries/PurchaseLifeCyclesStorage.sol";
import {PayoutWalletStorage} from "@animoca/ethereum-contracts/contracts/payment/libraries/PayoutWalletStorage.sol";

/**
 * @title FixedPricesSale
 * An Sale which implements a fixed prices strategy.
 *  The final implementer is responsible for implementing any additional pricing and/or delivery logic.
 */
abstract contract FixedPricesSale is SaleBase {
    using ERC20Wrapper for IWrappedERC20;
    using EnumMap for EnumMap.Map;
    using PurchaseLifeCyclesStorage for PurchaseLifeCyclesStorage.Layout;
    using PayoutWalletStorage for PayoutWalletStorage.Layout;

    /**
     * Constructor.
     * @dev Emits the `MagicValues` event.
     * @dev Emits the `Paused` event.
     * @param payoutWallet_ the payout wallet.
     * @param skusCapacity the cap for the number of managed SKUs.
     * @param tokensPerSkuCapacity the cap for the number of tokens managed per SKU.
     */
    constructor(
        address payable payoutWallet_,
        uint256 skusCapacity,
        uint256 tokensPerSkuCapacity
    ) SaleBase(skusCapacity, tokensPerSkuCapacity) {}

    /*                               Internal Life Cycle Functions                               */

    /**
     * Lifecycle step which computes the purchase price.
     * @dev Responsibilities:
     *  - Computes the pricing formula, including any discount logic and price conversion;
     *  - Set the value of `purchase.totalPrice`;
     *  - Add any relevant extra data related to pricing in `purchase.pricingData` and document how to interpret it.
     * @dev Reverts if `purchase.sku` does not exist.
     * @dev Reverts if `purchase.token` is not supported by the SKU.
     * @dev Reverts in case of price overflow.
     * @param purchase The purchase conditions.
     */
    function _pricing(PurchaseLifeCyclesStorage.Layout memory purchase) internal view virtual override {
        SkuInfo storage skuInfo = _skuInfos[purchase.sku];
        require(skuInfo.totalSupply != 0, "Sale: unsupported SKU");
        EnumMap.Map storage prices = skuInfo.prices;
        uint256 unitPrice = _unitPrice(purchase, prices);
        purchase.totalPrice = unitPrice * purchase.quantity;
    }

    /**
     * Lifecycle step which manages the transfer of funds from the purchaser.
     * @dev Responsibilities:
     *  - Ensure the payment reaches destination in the expected output token;
     *  - Handle any token swap logic;
     *  - Add any relevant extra data related to payment in `purchase.paymentData` and document how to interpret it.
     * @dev Reverts in case of payment failure.
     * @param purchase The purchase conditions.
     */
    function _payment(PurchaseLifeCyclesStorage.Layout memory purchase) internal virtual override {
        if (purchase.token == TOKEN_ETH) {
            require(msg.value >= purchase.totalPrice, "Sale: insufficient ETH");

            PayoutWalletStorage.layout().payoutWallet().transfer(purchase.totalPrice);

            uint256 change = msg.value - purchase.totalPrice;

            if (change != 0) {
                purchase.purchaser.transfer(change);
            }
        } else {
            IWrappedERC20(purchase.token).wrappedTransferFrom(_msgSender(), PayoutWalletStorage.layout().payoutWallet(), purchase.totalPrice);
        }
    }

    /*                               Internal Utility Functions                                  */

    /**
     * Retrieves the unit price of a SKU for the specified payment token.
     * @dev Reverts if the specified payment token is unsupported.
     * @param purchase The purchase conditions specifying the payment token with which the unit price will be retrieved.
     * @param prices Storage pointer to a mapping of SKU token prices to retrieve the unit price from.
     * @return unitPrice The unit price of a SKU for the specified payment token.
     */
    function _unitPrice(PurchaseLifeCyclesStorage.Layout memory purchase, EnumMap.Map storage prices) internal view virtual returns (uint256 unitPrice) {
        unitPrice = uint256(prices.get(bytes32(abi.encode(purchase.token))));
        require(unitPrice != 0, "Sale: unsupported payment token");
    }
}
