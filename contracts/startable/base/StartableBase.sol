// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {StartableStorage} from "../libraries/StartableStorage.sol";

/**
 * Contract module which allows derived contracts to implement a mechanism for
 * activating, or 'starting', a contract.
 *
 * This module is used through inheritance. It will make available the modifiers
 * `whenNotStarted` and `whenStarted`, which can be applied to the functions of
 * your contract. Those functions will only be 'startable' once the modifiers
 * are put in place.
 */
abstract contract StartableBase is Context {
    using StartableStorage for StartableStorage.Layout;
    
    /**
     * Modifier to make a function callable only when the contract has not started.
     */
    modifier whenNotStarted() {
        require(StartableStorage.layout().startedAt == 0, "Startable: started");
        _;
    }

    /**
     * Modifier to make a function callable only when the contract has started.
     */
    modifier whenStarted() {
        require(StartableStorage.layout().startedAt != 0, "Startable: not started");
        _;
    }

    /**
     * Constructor.
     */
    constructor() {}

    /**
     * Returns the timestamp when the contract entered the started state.
     * @return The timestamp when the contract entered the started state.
     */
    function startedAt() public view returns (uint256) {
        return StartableStorage.layout().startedAt;
    }

    /**
     * Triggers the started state.
     * @dev Emits the Started event when the function is successfully called.
     */
    function _start() internal virtual whenNotStarted {
        StartableStorage.layout().startedAt = block.timestamp;
        emit StartableStorage.Started(_msgSender());
    }
}