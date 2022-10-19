// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.7.6;
// pragma solidity ^0.8.9;
import "hardhat/console.sol";

import {ERC20Mock} from "@animoca/ethereum-contracts-assets-2.0.0/contracts/mocks/token/ERC20/ERC20Mock.sol";

contract Test {

    address public constant TOKEN_ETH = address(0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee);

    constructor(){
        // console.log("this  sender", msg.sender);
        // bytes32 testVar = bytes32(abi.encode(msg.sender));
        // console.logBytes(abi.encode(testVar));
        // string b = "Blue";
        bytes32 token = 0x111122223333444455556666777788889999AAAABBBBCCCCDDDDEEEEFFFFCCCC;
        // console.log(uint256(token));
        // console.log(uint256(token));
        // console.log(uint160(uint256(token)));

        console.log(address(uint256(token)));


    }

}