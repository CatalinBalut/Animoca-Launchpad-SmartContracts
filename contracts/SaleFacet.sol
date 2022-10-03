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

// import {ISale} from "./sale/interfaces/ISale.sol";

// import {IPurchaseNotificationsReceiver} from "./sale/interfaces/IPurchaseNotificationsReceiver.sol";

import {AddressIsContract} from "./AddressIsContract.sol";

import {StartableBase} from "./startable/base/StartableBase.sol";
import {StartableStorage} from "./startable/libraries/StartableStorage.sol";

contract SaleFacet is ContractOwnershipBase, PayoutWalletBase, PauseBase, PurchaseLifeCyclesBase, StartableBase {
    using ContractOwnershipStorage for ContractOwnershipStorage.Layout;
    using PayoutWalletStorage for PayoutWalletStorage.Layout;
    using PauseStorage for PauseStorage.Layout;
    using PurchaseLifeCyclesStorage for PurchaseLifeCyclesStorage.Layout;
    using StartableStorage for StartableStorage.Layout;

    using AddressIsContract for address;
    using EnumSet for EnumSet.Set;
    using EnumMap for EnumMap.Map;

    constructor(){
    }

    function checkAddress(address account) public view returns(bool) {
        return account.isContract();
    }

    function initContract() whenNotStarted() public {
         ContractOwnershipStorage.layout().proxyInit(msg.sender);
         PayoutWalletStorage.layout().proxyInit(payable(msg.sender));
         PauseStorage.layout().proxyInit(true);
    }

    function checkLifeCycle() whenStarted() public{
       _payment(PurchaseLifeCyclesStorage.layout());
       _validation(PurchaseLifeCyclesStorage.layout());
       _pricing(PurchaseLifeCyclesStorage.layout());
       _delivery(PurchaseLifeCyclesStorage.layout());
       _notification(PurchaseLifeCyclesStorage.layout());
    }

    function start() public {
         _start();
    }

     /*                            Internal Life Cycle Step Functions                             */


    function _validation(PurchaseLifeCyclesStorage.Layout storage purchase) internal view virtual override {
        require(purchase.totalPrice > 0, "Sale: zero address recipient");
        console.log("validation works");
    }


    function _pricing(PurchaseLifeCyclesStorage.Layout storage purchase) internal view virtual override {
        require(purchase.totalPrice > 0, "Sale: zero address recipient");
        console.log("_pricing works");
    }

    function _payment(PurchaseLifeCyclesStorage.Layout storage purchase) internal virtual override {
        purchase.totalPrice = 1;
        console.log("_pricing works", purchase.totalPrice);
    }


    function _delivery(PurchaseLifeCyclesStorage.Layout storage purchase) internal virtual override {
        purchase.totalPrice = 2;
        console.log("_pricing works", purchase.totalPrice);

    }

    function _notification(PurchaseLifeCyclesStorage.Layout storage purchase) internal virtual override {
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
