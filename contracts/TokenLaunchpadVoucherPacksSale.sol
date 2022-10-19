// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;
import "hardhat/console.sol";
import {FixedPricesSale} from "./FixedPricesSale.sol";
import {TokenRecoveryBase} from "@animoca/ethereum-contracts/contracts/security/base/TokenRecoveryBase.sol";
//TODO merkle proof
// import "@openzeppelin/contracts/cryptography/MerkleProof.sol";

import {PurchaseLifeCyclesStorage} from "./purchaseLifeCycle/libraries/PurchaseLifeCyclesStorage.sol";
import {PauseStorage} from "@animoca/ethereum-contracts/contracts/lifecycle/libraries/PauseStorage.sol";
import {ContractOwnershipBase} from "@animoca/ethereum-contracts/contracts/access/base/ContractOwnershipBase.sol";
import {ContractOwnershipStorage} from "@animoca/ethereum-contracts/contracts/access/libraries/ContractOwnershipStorage.sol";

/**
 * @title TokenLaunchpad Vouchers Sale
 * A FixedPricesSale contract that handles the purchase and delivery of TokenLaunchpad vouchers.
 */
contract TokenLaunchpadVoucherPacksSale is FixedPricesSale, TokenRecoveryBase {
    IVouchersContract public immutable vouchersContract;
    using PauseStorage for PauseStorage.Layout;
    using PurchaseLifeCyclesStorage for PurchaseLifeCyclesStorage.Layout;

    struct SkuAdditionalInfo {
        uint256[] tokenIds;
        uint256 startTimestamp;
        uint256 endTimestamp;
    }

    mapping(bytes32 => SkuAdditionalInfo) internal _skuAdditionalInfo;

    /**
     * Constructor.
     * @dev Emits the `MagicValues` event.
     * @dev Emits the `Paused` event.
     * @param vouchersContract_ The inventory contract from which the sale supply is attributed from.
     * @param payoutWallet the payout wallet.
     * @param skusCapacity the cap for the number of managed SKUs.
     * @param tokensPerSkuCapacity the cap for the number of tokens managed per SKU.
     */
    constructor(
        IVouchersContract vouchersContract_,
        address payable payoutWallet,
        uint256 skusCapacity,
        uint256 tokensPerSkuCapacity
    ) FixedPricesSale(payoutWallet, skusCapacity, tokensPerSkuCapacity) {
        vouchersContract = vouchersContract_;
    }

    //SKU => merkleRoot
    mapping(bytes32 => bytes32) public MerkleRoots;

    //SKU -> user address => block number
    mapping(bytes32 => mapping(address => uint256)) public CoolOff;

    function purchaseFor(
        address payable recipient,
        address token,
        bytes32 sku,
        uint256 quantity,
        bytes calldata userData
        // bytes32[] calldata merkleProof
    ) public payable whenStarted override {
        // require(MerkleProof.verify(merkleProof, MerkleRoots[sku], keccak256(abi.encodePacked(msg.sender))), "invalid merkle proof");
        // require(CoolOff[sku][msg.sender] < block.number, "cool off period is not over");
        // CoolOff[sku][msg.sender] += block.number + coolOffPeriod;
        PauseStorage.layout().enforceIsNotPaused();
        PurchaseLifeCyclesStorage.Layout memory purchase;
        purchase.purchaser = payable(_msgSender()); //needs double check
        purchase.recipient = recipient;
        purchase.token = token;
        purchase.sku = sku;
        purchase.quantity = quantity;
        purchase.userData = userData;
        console.log("inainte de _purchase");
        _purchaseFor(purchase);
    }

    // function purchaseFor(
        // address payable recipient,
        // address token,
        // // bytes32 sku,
        // // uint256 quantity,
        // // bytes calldata userData
    // // ) public payable override whenStarted {
        // // require(false, "Deprecated function");
    // }

    // uint256 public coolOffPeriod;

    // function setCoolOffTime(uint256 _coolOffPeriod) public {
    //     _requireOwnership(_msgSender());
    //     coolOffPeriod = _coolOffPeriod;
    // }

    // function setMerkleRoot(bytes32 _sku, bytes32 _merkleRoot) public {
    //     _requireOwnership(_msgSender());
    //     MerkleRoots[_sku] = _merkleRoot;
    // }

    /**
     * Creates an SKU.
     * @dev Reverts if `totalSupply` is zero.
     * @dev Reverts if `sku` already exists.
     * @dev Reverts if the update results in too many SKUs.
     * @dev Reverts if one of `tokenIds` is not a fungible token identifier.
     * @dev Emits the `SkuCreation` event.
     * @param sku The SKU identifier.
     * @param totalSupply The initial total supply.
     * @param maxQuantityPerPurchase The maximum allowed quantity for a single purchase.
     * @param tokenIds The inventory contract token IDs to associate with the SKU, used for purchase delivery.
     * @param startTimestamp The start timestamp of the sale.
     * @param endTimestamp The end timestamp of the sale, or zero to indicate there is no end.
     */
    function createSku(
        bytes32 sku,
        uint256 totalSupply,
        uint256 maxQuantityPerPurchase,
        uint256[] calldata tokenIds,
        uint256 startTimestamp,
        uint256 endTimestamp
        // bytes32 _merkleRoot
    ) external {
        console.log("owner ", owner());
        require(msg.sender == owner());
        uint256 length = tokenIds.length;
        require(length != 0, "Sale: empty tokens");
        console.log("a");
        for (uint256 i; i != length; ++i) {
            console.log("a");
            require(
                vouchersContract.isFungible(tokenIds[i]),
                "Sale: not a fungible token"
            );
        }
        console.log("a");
        _skuAdditionalInfo[sku] = SkuAdditionalInfo(
            tokenIds,
            startTimestamp,
            endTimestamp
        );
        console.log("a");
        _createSku(sku, totalSupply, maxQuantityPerPurchase, address(0));

        // MerkleRoots[sku] = _merkleRoot;
    }

    /**
     * Updates start and end timestamps of a SKU.
     * @dev Reverts if not sent by the contract owner.
     * @dev Reverts if the SKU does not exist.
     * @param sku the SKU identifier.
     * @param startTimestamp The start timestamp of the sale.
     * @param endTimestamp The end timestamp of the sale, or zero to indicate there is no end.
     */
    function updateSkuTimestamps(
        bytes32 sku,
        uint256 startTimestamp,
        uint256 endTimestamp
    ) external {
        require(msg.sender == owner());
        require(_skuInfos[sku].totalSupply != 0, "Sale: non-existent sku");
        SkuAdditionalInfo storage info = _skuAdditionalInfo[sku];
        info.startTimestamp = startTimestamp;
        info.endTimestamp = endTimestamp;
    }

    /**
     * Gets the additional sku info.
     * @dev Reverts if the SKU does not exist.
     * @param sku the SKU identifier.
     * @return tokenIds The identifiers of the tokens delivered via this SKU.
     * @return startTimestamp The start timestamp of the SKU sale.
     * @return endTimestamp The end timestamp of the SKU sale (zero if there is no end).
     */
    function getSkuAdditionalInfo(bytes32 sku)
        external
        view
        returns (
            uint256[] memory tokenIds,
            uint256 startTimestamp,
            uint256 endTimestamp
        )
    {
        require(_skuInfos[sku].totalSupply != 0, "Sale: non-existent sku");
        SkuAdditionalInfo memory info = _skuAdditionalInfo[sku];
        return (info.tokenIds, info.startTimestamp, info.endTimestamp);
    }

    /**
     * Returns whether a SKU is currently within the sale time range.
     * @dev Reverts if the SKU does not exist.
     * @param sku the SKU identifier.
     * @return true if `sku` is currently within the sale time range, false otherwise.
     */
    function canPurchaseSku(bytes32 sku) external view returns (bool) {
        require(_skuInfos[sku].totalSupply != 0, "Sale: non-existent sku");
        SkuAdditionalInfo memory info = _skuAdditionalInfo[sku];
        return
            block.timestamp > info.startTimestamp &&
            (info.endTimestamp == 0 || block.timestamp < info.endTimestamp);
    }

    /// inheritdoc SaleBase
    function _delivery(PurchaseLifeCyclesStorage.Layout memory purchase)
        internal
        override
    {
        super._delivery(purchase);
        SkuAdditionalInfo memory info = _skuAdditionalInfo[purchase.sku];
        uint256 startTimestamp = info.startTimestamp;
        uint256 endTimestamp = info.endTimestamp;
        require(block.timestamp > startTimestamp, "Sale: not started yet");
        require(
            endTimestamp == 0 || block.timestamp < endTimestamp,
            "Sale: already ended"
        );
        console.log("AJUNGE PANA IN DELIVERY");
        uint256 length = info.tokenIds.length;
        if (length == 1) {
            console.log("AJUNGE PANA IN DELIVERY");
            vouchersContract.safeMint(
                purchase.recipient,
                info.tokenIds[0],
                purchase.quantity,
                ""
            );console.log("AJUNGE PANA IN DELIVERY");
        } else {
            uint256 purchaseQuantity = purchase.quantity;
            uint256[] memory quantities = new uint256[](length);
            for (uint256 i; i != length; ++i) {
                quantities[i] = purchaseQuantity;
            }
            vouchersContract.safeBatchMint(
                purchase.recipient,
                info.tokenIds,
                quantities,
                ""
            );console.log("AJUNGE PANA IN DELIVERY");
        }
    console.log("AJUNGE PANA IN DELIVERY trece");

    }
}

interface IVouchersContract {
    function isFungible(uint256 id) external pure returns (bool);

    function safeMint(
        address to,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external;

    function safeBatchMint(
        address to,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external;
}
