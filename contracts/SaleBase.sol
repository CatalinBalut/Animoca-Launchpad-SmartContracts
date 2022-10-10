// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "hardhat/console.sol";

import {EnumMap} from "./algo/EnumMap.sol";
import {EnumSet} from "./algo/EnumSet.sol";

import {ContractOwnershipBase} from "@animoca/ethereum-contracts/contracts/access/base/ContractOwnershipBase.sol";
import {ContractOwnershipStorage} from "@animoca/ethereum-contracts/contracts/access/libraries/ContractOwnershipStorage.sol";

import {PayoutWalletBase} from "@animoca/ethereum-contracts/contracts/payment/base/PayoutWalletBase.sol";
import {PayoutWalletStorage} from "@animoca/ethereum-contracts/contracts/payment/libraries/PayoutWalletStorage.sol";

import {PauseBase} from "@animoca/ethereum-contracts/contracts/lifecycle/base/PauseBase.sol";
import {PauseStorage} from "@animoca/ethereum-contracts/contracts/lifecycle/libraries/PauseStorage.sol";

import {PurchaseLifeCyclesBase} from "./purchaseLifeCycle/base/PurchaseLifeCyclesBase.sol";
import {PurchaseLifeCyclesStorage} from "./purchaseLifeCycle/libraries/PurchaseLifeCyclesStorage.sol";

import {ISale} from "./sale/interfaces/ISale.sol";

import {IPurchaseNotificationsReceiver} from "./sale/interfaces/IPurchaseNotificationsReceiver.sol";

import {AddressIsContract} from "./AddressIsContract.sol";

import {StartableBase} from "./startable/base/StartableBase.sol";
import {StartableStorage} from "./startable/libraries/StartableStorage.sol";

abstract contract SaleBase is ContractOwnershipBase, PayoutWalletBase, PauseBase, PurchaseLifeCyclesBase, StartableBase, ISale, IPurchaseNotificationsReceiver {
    using ContractOwnershipStorage for ContractOwnershipStorage.Layout;
    using PayoutWalletStorage for PayoutWalletStorage.Layout;
    using PauseStorage for PauseStorage.Layout;
    using PurchaseLifeCyclesStorage for PurchaseLifeCyclesStorage.Layout;
    using StartableStorage for StartableStorage.Layout;

    using AddressIsContract for address;
    using EnumSet for EnumSet.Set;
    using EnumMap for EnumMap.Map;

    PauseBase cPauseBase;

    //////////////////////////////////////////////////

    struct SkuInfo {
        uint256 totalSupply;
        uint256 remainingSupply;
        uint256 maxQuantityPerPurchase;
        address notificationsReceiver;
        EnumMap.Map prices;
    }

    address public constant override TOKEN_ETH = address(0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee);
    uint256 public constant override SUPPLY_UNLIMITED = type(uint256).max;

    EnumSet.Set internal _skus;
    mapping(bytes32 => SkuInfo) internal _skuInfos;

    uint256 internal immutable _skusCapacity;
    uint256 internal immutable _tokensPerSkuCapacity;

    /**
     * Constructor.
     * @dev Emits the `MagicValues` event.
     * @dev Emits the `Paused` event.
     * @param skusCapacity the cap for the number of managed SKUs.
     * @param tokensPerSkuCapacity the cap for the number of tokens managed per SKU.
     */
    constructor(
        uint256 skusCapacity,
        uint256 tokensPerSkuCapacity
    ){
        _skusCapacity = skusCapacity;
        _tokensPerSkuCapacity = tokensPerSkuCapacity;
        bytes32[] memory names = new bytes32[](2);
        bytes32[] memory values = new bytes32[](2);
        (names[0], values[0]) = ("TOKEN_ETH", bytes32(abi.encode(TOKEN_ETH)));
        (names[1], values[1]) = ("SUPPLY_UNLIMITED", bytes32(abi.encode(SUPPLY_UNLIMITED)));
        emit MagicValues(names, values);

    }

     /*                                   Public Admin Functions                                  */

    function start() public virtual {
        require(msg.sender == owner());
        _start();
        PauseStorage.layout().unpause();
    }

    function updateSkuPricing(
        bytes32 sku,
        address[] memory tokens,
        uint256[] memory prices
    ) public virtual {
         require(msg.sender == owner());
        uint256 length = tokens.length;
        require(length == prices.length, "Sale: inconsistent arrays");
        SkuInfo storage skuInfo = _skuInfos[sku];
        require(skuInfo.totalSupply != 0, "Sale: non-existent sku");

        EnumMap.Map storage tokenPrices = skuInfo.prices;
        if (length == 0) {
            uint256 currentLength = tokenPrices.length();
            for (uint256 i = 0; i < currentLength; ++i) {
                // TODO add a clear function in EnumMap and EnumSet and use it
                (bytes32 token, ) = tokenPrices.at(0);
                tokenPrices.remove(token);
            }
        } else {
            _setTokenPrices(tokenPrices, tokens, prices);
        }

        emit SkuPricingUpdate(sku, tokens, prices);
    }

     /*                            Internal Life Cycle Step Functions                             */

    function purchaseFor(
        address payable recipient,
        address token,
        bytes32 sku,
        uint256 quantity,
        bytes calldata userData
    ) external payable virtual override whenStarted {
        PauseStorage.layout().enforceIsNotPaused();
        PurchaseLifeCyclesStorage.Layout memory purchase;
        //purchase.purchaser = _msgSender();
        purchase.purchaser = payable(_msgSender()); //needs double check
        purchase.recipient = recipient;
        purchase.token = token;
        purchase.sku = sku;
        purchase.quantity = quantity;
        purchase.userData = userData;

        _purchaseFor(purchase);
    }

    function estimatePurchase(
        address payable recipient,
        address token,
        bytes32 sku,
        uint256 quantity,
        bytes calldata userData
    ) external view virtual override whenStarted returns (uint256 totalPrice, bytes32[] memory pricingData) {
        PauseStorage.layout().enforceIsNotPaused();
        PurchaseLifeCyclesStorage.Layout memory purchase;
        //purchase.purchaser = _msgSender();
        purchase.purchaser = payable(_msgSender()); //needs double check
        purchase.recipient = recipient;
        purchase.token = token;
        purchase.sku = sku;
        purchase.quantity = quantity;
        purchase.userData = userData;

        return _estimatePurchase(purchase);
    }

    function getSkuInfo(bytes32 sku)
        external
        view
        override
        returns (
            uint256 totalSupply,
            uint256 remainingSupply,
            uint256 maxQuantityPerPurchase,
            address notificationsReceiver,
            address[] memory tokens,
            uint256[] memory prices
        )
    {
        SkuInfo storage skuInfo = _skuInfos[sku];
        uint256 length = skuInfo.prices.length();

        totalSupply = skuInfo.totalSupply;
        require(totalSupply != 0, "Sale: non-existent sku");
        remainingSupply = skuInfo.remainingSupply;
        maxQuantityPerPurchase = skuInfo.maxQuantityPerPurchase;
        notificationsReceiver = skuInfo.notificationsReceiver;

        tokens = new address[](length);
        prices = new uint256[](length);
        for (uint256 i = 0; i < length; ++i) {
            (bytes32 token, bytes32 price) = skuInfo.prices.at(i);
            //tokens[i] = address(uint256(token)); //!!!explicit type conversion not allwed from uint256 to address
            tokens[i] = address(msg.sender); //!must be refactored
            prices[i] = uint256(price);
        }
    }

    /**
     * Returns the list of created SKU identifiers.
     * @return skus the list of created SKU identifiers.
     */
    function getSkus() external view override returns (bytes32[] memory skus) {
        skus = _skus.values;
    }

     /*                               Internal Utility Functions                                  */

    function _createSku(
        bytes32 sku,
        uint256 totalSupply,
        uint256 maxQuantityPerPurchase,
        address notificationsReceiver
    ) internal virtual {
        require(totalSupply != 0, "Sale: zero supply");
        require(_skus.length() < _skusCapacity, "Sale: too many skus");
        require(_skus.add(sku), "Sale: sku already created");
        if (notificationsReceiver != address(0)) {
            require(notificationsReceiver.isContract(), "Sale: non-contract receiver");
        }
        SkuInfo storage skuInfo = _skuInfos[sku];
        skuInfo.totalSupply = totalSupply;
        skuInfo.remainingSupply = totalSupply;
        skuInfo.maxQuantityPerPurchase = maxQuantityPerPurchase;
        skuInfo.notificationsReceiver = notificationsReceiver;
        emit SkuCreation(sku, totalSupply, maxQuantityPerPurchase, notificationsReceiver);
    }

    function _setTokenPrices(
        EnumMap.Map storage tokenPrices,
        address[] memory tokens,
        uint256[] memory prices
    ) internal virtual {
        for (uint256 i = 0; i < tokens.length; ++i) {
            address token = tokens[i];
            require(token != address(0), "Sale: zero address token");
            uint256 price = prices[i];
            if (price == 0) {
                tokenPrices.remove(bytes32(abi.encode(token))); //!!!explicit type conversion not allwed from uint256 to address
            } else {
                tokenPrices.set(bytes32(abi.encode(token)), bytes32(price)); //!!!explicit type conversion not allwed from uint256 to address
            }
        }
        require(tokenPrices.length() <= _tokensPerSkuCapacity, "Sale: too many tokens");
    }

     /*                            Internal Life Cycle Step Functions                             */

    function _validation(PurchaseLifeCyclesStorage.Layout memory purchase) internal view virtual override {
        require(purchase.recipient != address(0), "Sale: zero address recipient");
        require(purchase.token != address(0), "Sale: zero address token");
        require(purchase.quantity != 0, "Sale: zero quantity purchase");
        SkuInfo storage skuInfo = _skuInfos[purchase.sku];
        require(skuInfo.totalSupply != 0, "Sale: non-existent sku");
        require(skuInfo.maxQuantityPerPurchase >= purchase.quantity, "Sale: above max quantity");
        if (skuInfo.totalSupply != SUPPLY_UNLIMITED) {
            require(skuInfo.remainingSupply >= purchase.quantity, "Sale: insufficient supply");
        }
        //TODO address to bytes32 was removed in 0.8.0 -> must find another solution
        bytes32 priceKey = bytes32(abi.encode(purchase.token));
        require(skuInfo.prices.contains(priceKey), "Sale: non-existent sku token");
    }

    function _delivery(PurchaseLifeCyclesStorage.Layout memory purchase) internal virtual override {
        SkuInfo storage skuInfo = _skuInfos[purchase.sku];
        if (skuInfo.totalSupply != SUPPLY_UNLIMITED) {
            _skuInfos[purchase.sku].remainingSupply = skuInfo.remainingSupply - purchase.quantity;
        }
    }

    function _notification(PurchaseLifeCyclesStorage.Layout memory purchase) internal virtual override {
        emit Purchase(
            purchase.purchaser,
            purchase.recipient,
            purchase.token,
            purchase.sku,
            purchase.quantity,
            purchase.userData,
            purchase.totalPrice,
            abi.encodePacked(purchase.pricingData, purchase.paymentData, purchase.deliveryData)
        );

        address notificationsReceiver = _skuInfos[purchase.sku].notificationsReceiver;
        if (notificationsReceiver != address(0)) {
            require(
                IPurchaseNotificationsReceiver(notificationsReceiver).onPurchaseNotificationReceived(
                    purchase.purchaser,
                    purchase.recipient,
                    purchase.token,
                    purchase.sku,
                    purchase.quantity,
                    purchase.userData,
                    purchase.totalPrice,
                    purchase.pricingData,
                    purchase.paymentData,
                    purchase.deliveryData
                ) == IPurchaseNotificationsReceiver(address(0)).onPurchaseNotificationReceived.selector, // TODO precompute return value
                "Sale: notification refused"
            );
        }
    }

    /////////////////////////////////////////////////////////////////////////////////////

    function checkAddress(address account) public view returns(bool) {
        return account.isContract();
    }

    function initContract(address payoutWallet_) whenNotStarted() public {
         ContractOwnershipStorage.layout().proxyInit(msg.sender);
         PayoutWalletStorage.layout().proxyInit(payable(payoutWallet_));
         PauseStorage.layout().proxyInit(true);
    }

    function checkLifeCycle() whenStarted() public{
       _payment(PurchaseLifeCyclesStorage.layout());
       _validation(PurchaseLifeCyclesStorage.layout());
       _pricing(PurchaseLifeCyclesStorage.layout());
       _delivery(PurchaseLifeCyclesStorage.layout());
       _notification(PurchaseLifeCyclesStorage.layout());
    }

    function startT() public {
         _start();
    }

     /*                            Internal Life Cycle Step Functions                             */


    // function _validation(PurchaseLifeCyclesStorage.Layout storage purchase) internal view virtual override {
    //     require(purchase.totalPrice > 0, "Sale: zero address recipient");
    //     console.log("validation works");
    // }


    // function _pricing(PurchaseLifeCyclesStorage.Layout memory purchase) internal view virtual override {
    //     require(purchase.totalPrice > 0, "Sale: zero address recipient");
    //     console.log("_pricing works");
    // }

    // function _payment(PurchaseLifeCyclesStorage.Layout memory purchase) internal virtual override {
    //     purchase.totalPrice = 1;
    //     console.log("_pricing works", purchase.totalPrice);
    // }


    // function _delivery(PurchaseLifeCyclesStorage.Layout memory purchase) internal virtual override {
    //     purchase.totalPrice = 2;
    //     console.log("_pricing works", purchase.totalPrice);

    // }

    // function _notification(PurchaseLifeCyclesStorage.Layout memory purchase) internal virtual override {
    //     purchase.totalPrice = 3;
    //     console.log("_pricing works", purchase.totalPrice);

    // }

    //Isale

    // function purchaseFor() public {}

    // function purchaseFor() public {}

    // function purchaseFor() public {}

    // function estimatePurchase() public {}

    // function getSkuInfo() external view {

    //             returns (
    //         uint256 totalSupply,
    //         uint256 remainingSupply,
    //         uint256 maxQuantityPerPurchase,
    //         address notificationsReceiver,
    //         address[] memory tokens,
    //         uint256[] memory prices
    //     );
    // }

    // function getSkus() external view returns (bytes32[] memory skus);

    
    

}
