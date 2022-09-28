// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import {ContractOwnershipBase} from "@animoca/ethereum-contracts/contracts/access/base/ContractOwnershipBase.sol";
import {ContractOwnershipStorage} from "@animoca/ethereum-contracts/contracts/access/libraries/ContractOwnershipStorage.sol";

contract SaleFacet is ContractOwnershipBase {
    using ContractOwnershipStorage for ContractOwnershipStorage.Layout;

    constructor(){
    }

    function initContract() public {
         ContractOwnershipStorage.layout().proxyInit(msg.sender);

    } 

}
