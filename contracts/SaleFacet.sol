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

abstract contract SaleFacet is ContractOwnershipBase, PayoutWalletBase, PauseBase, PurchaseLifeCyclesBase, StartableBase, ISale, IPurchaseNotificationsReceiver {
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
        //TODO address to bytes32 was removed in 0.8.0 -> must find another solution
        //(names[0], values[0]) = ("TOKEN_ETH", bytes32(uint256(TOKEN_ETH)));
        (names[0], values[0]) = ("TOKEN_ETH", bytes32(uint256(1))); //temporary solution
        (names[1], values[1]) = ("SUPPLY_UNLIMITED", bytes32(uint256(SUPPLY_UNLIMITED)));
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
            // _setTokenPrices(tokenPrices, tokens, prices); //can be uncomment after _setTokenPrices is setted
        }

        emit SkuPricingUpdate(sku, tokens, prices);
    }

     /*                            Internal Life Cycle Step Functions                             */

    // function purchaseFor(
    //     address payable recipient,
    //     address token,
    //     bytes32 sku,
    //     uint256 quantity,
    //     bytes calldata userData
    // ) external payable virtual override whenStarted {
    //     //_requireNotPaused();
    //     PurchaseLifeCyclesStorage.Layout storage purchase;
    //     //purchase.purchaser = _msgSender();
    //     purchase.purchaser = payable(_msgSender()); //needs double check
    //     purchase.recipient = recipient;
    //     purchase.token = token;
    //     purchase.sku = sku;
    //     purchase.quantity = quantity;
    //     purchase.userData = userData;

    //     _purchaseFor(purchase);
    // }























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
        //bytes32 priceKey = bytes32(uint256(purchase.token));
        bytes32 priceKey = bytes32(purchase.sku);
        require(skuInfo.prices.contains(priceKey), "Sale: non-existent sku token");
    }


    

    














    /////////////////////////////////////////////////

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


    function _pricing(PurchaseLifeCyclesStorage.Layout memory purchase) internal view virtual override {
        require(purchase.totalPrice > 0, "Sale: zero address recipient");
        console.log("_pricing works");
    }

    function _payment(PurchaseLifeCyclesStorage.Layout memory purchase) internal virtual override {
        purchase.totalPrice = 1;
        console.log("_pricing works", purchase.totalPrice);
    }


    function _delivery(PurchaseLifeCyclesStorage.Layout memory purchase) internal virtual override {
        purchase.totalPrice = 2;
        console.log("_pricing works", purchase.totalPrice);

    }

    function _notification(PurchaseLifeCyclesStorage.Layout memory purchase) internal virtual override {
        purchase.totalPrice = 3;
        console.log("_pricing works", purchase.totalPrice);

    }

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
