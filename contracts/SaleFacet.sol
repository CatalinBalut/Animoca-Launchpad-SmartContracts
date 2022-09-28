// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {ContractOwnershipBase} from "@animoca/ethereum-contracts/contracts/access/base/ContractOwnershipBase.sol";
import {ContractOwnershipStorage} from "@animoca/ethereum-contracts/contracts/access/libraries/ContractOwnershipStorage.sol";

import {PayoutWalletBase} from "@animoca/ethereum-contracts/contracts/payment/base/PayoutWalletBase.sol";
import {PayoutWalletStorage} from "@animoca/ethereum-contracts/contracts/payment/libraries/PayoutWalletStorage.sol";

import {PauseBase} from "@animoca/ethereum-contracts/contracts/lifecycle/base/PauseBase.sol";
import {PauseStorage} from "@animoca/ethereum-contracts/contracts/lifecycle/libraries/PauseStorage.sol";

contract SaleFacet is ContractOwnershipBase, PayoutWalletBase, PauseBase {
    using ContractOwnershipStorage for ContractOwnershipStorage.Layout;
    using PayoutWalletStorage for PayoutWalletStorage.Layout;
    using PauseStorage for PauseStorage.Layout;

    constructor(){
    }

    function initContract() public {
         ContractOwnershipStorage.layout().proxyInit(msg.sender);
         PayoutWalletStorage.layout().proxyInit(payable(msg.sender));
         PauseStorage.layout().proxyInit(true);
    } 

}
