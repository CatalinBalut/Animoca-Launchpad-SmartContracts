// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

import "./SaleBase.sol";
// import {ForwarderRegistry} from "ethereum-universal-forwarder/solc_0.8/ForwarderRegistry.sol";
import {ForwarderRegistry} from "ethereum-universal-forwarder/solc_0.8/ForwarderRegistry.sol";
import {UniversalForwarder} from "ethereum-universal-forwarder/solc_0.8/UniversalForwarder.sol";



contract Facet is SaleBase{

    constructor(
        uint256 skusCapacity,
        uint256 tokensPerSkuCapacity
    ) SaleBase(skusCapacity, tokensPerSkuCapacity) {}

       function _pricing(PurchaseLifeCyclesStorage.Layout memory purchase) internal view virtual override {
        require(purchase.totalPrice > 0, "Sale: zero address recipient");
        console.log("_pricing works");
    }

    function _payment(PurchaseLifeCyclesStorage.Layout memory purchase) internal virtual override {
        purchase.totalPrice = 1;
        console.log("_pricing works", purchase.totalPrice);
        
    }

 


    

   
}
