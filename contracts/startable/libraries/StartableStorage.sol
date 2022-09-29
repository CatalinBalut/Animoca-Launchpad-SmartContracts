// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

//import {ProxyInitialization} from "./../../proxy/libraries/ProxyInitialization.sol";

library StartableStorage {
    using StartableStorage for StartableStorage.Layout;

    struct Layout {
        uint256 startedAt;
    }

    bytes32 internal constant LAYOUT_STORAGE_SLOT = bytes32(uint256(keccak256("animoca.core.lifecycle.Startable.storage")) - 1);
    // bytes32 internal constant PROXY_INIT_PHASE_SLOT = bytes32(uint256(keccak256("animoca.core.lifecycle.Startable.phasee")) - 1);

    event Started(address account);

    function layout() internal pure returns (Layout storage s) {
        bytes32 position = LAYOUT_STORAGE_SLOT;
        assembly {
            s.slot := position
        }
    }
}
