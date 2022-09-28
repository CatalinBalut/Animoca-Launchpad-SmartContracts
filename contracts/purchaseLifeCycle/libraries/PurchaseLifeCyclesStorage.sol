// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

//import {ProxyInitialization} from "./../../proxy/libraries/ProxyInitialization.sol";

library PurchaseLifeCyclesStorage {
    using PurchaseLifeCyclesStorage for PurchaseLifeCyclesStorage.Layout;

    struct Layout {
        address payable purchaser;
        address payable recipient;
        address token;
        bytes32 sku;
        uint256 quantity;
        bytes userData;
        uint256 totalPrice;
        bytes32[] pricingData;
        bytes32[] paymentData;
        bytes32[] deliveryData;
    }

    bytes32 internal constant LAYOUT_STORAGE_SLOT = bytes32(uint256(keccak256("animoca.sale.purchaseLifecycle.PurchaseLifecycle.storage")) - 1);
    // bytes32 internal constant PROXY_INIT_PHASE_SLOT = bytes32(uint256(keccak256("animoca.sale.purchaseLifecycle.PurchaseLifecycle.phase")) - 1);

    event PurchaseLifecycle();

    function layout() internal pure returns (Layout storage s) {
        bytes32 position = LAYOUT_STORAGE_SLOT;
        assembly {
            s.slot := position
        }
    }
}
