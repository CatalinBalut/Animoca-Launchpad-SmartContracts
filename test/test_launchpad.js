// const { time, BN, ether, expectEvent, expectRevert} = require("@nomicfoundation/hardhat-network-helpers");
const {BN, ether, expectEvent, expectRevert} = require('@openzeppelin/test-helpers');
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");
const { ethers } = require("hardhat")

const {ZeroAddress, EmptyByte, Zero, One, Two, Three, MaxUInt256} = require("@animoca/ethereum-contracts/src/constants");

const {makeFungibleCollectionId, makeNonFungibleTokenId, makeNonFungibleCollectionId} =
  require('@animoca/blockchain-inventory_metadata').inventoryIds;

const nfMaskLength = 32;
const purchaserErc20Balance = ether('100000');
const erc20Price = ether('1');
const skusCapacity = One;
const tokensPerSkuCapacity = One;
const sku = "0x736b750000000000000000000000000000000000000000000000000000000000"; //"sku"
const totalSupply = new BN('10');
const maxQuantityPerPurchase = Three;
const tokenIds = [makeFungibleCollectionId(1), makeFungibleCollectionId(2), makeFungibleCollectionId(3), makeFungibleCollectionId(4)];
const nftId = makeNonFungibleTokenId(1, 1, nfMaskLength);
const nfcId = makeNonFungibleCollectionId(1, nfMaskLength);
const yesterday = Math.trunc(Date.now() / 1000) - 86400;
const tomorrow = Math.trunc(Date.now() / 1000) + 86400;

describe("Launchpad", () => {
  let deployer, payoutWallet, purchaser, recipient, other;
  let forwarderRegistry, universalForwarder, paymentERC20, vouchers, sale;
  
  beforeEach("Pre", async () => {
    [deployer, payoutWallet, purchaser, recipient, other] = await ethers.getSigners();

    console.log(payoutWallet.address)
    const ForwarderRegistry = await ethers.getContractFactory("ForwarderRegistry");
    forwarderRegistry = await ForwarderRegistry.deploy();
    //cred ca forwardRegistry si universalforwarder trebe sa fie 0.7 nu 0.8!!!
    const UniversalForwarder = await ethers.getContractFactory("UniversalForwarder");
    universalForwarder = await UniversalForwarder.deploy();
    console.log(forwarderRegistry.address)
    console.log(universalForwarder.address)

    const ERC20 = await ethers.getContractFactory("ERC20Mock");
    paymentERC20 = await ERC20.deploy(
      [purchaser.address],
      [purchaserErc20Balance.toString()],
      forwarderRegistry.address,
      universalForwarder.address
    );
    console.log(paymentERC20.address)
    await paymentERC20.deployed();

    const TokenLaunchpadVouchers = await ethers.getContractFactory("TokenLaunchpadVouchers");
    vouchers = await TokenLaunchpadVouchers.deploy(
      forwarderRegistry.address,
      universalForwarder.address
    );
    console.log(vouchers.address)
    const TokenLaunchpadVoucherPacksSale = await ethers.getContractFactory("TokenLaunchpadVoucherPacksSale");
    sale = await TokenLaunchpadVoucherPacksSale.deploy(
      vouchers.address,
      payoutWallet.address,
      skusCapacity,
      tokensPerSkuCapacity,
    );

    console.log("works")
  });

  it("simple buy", async () => { 
    const quantity = Two;
    // await this.paymentToken.approve(this.sale.address, MaxUInt256, {from: purchaser});
    // await this.sale.createSku(sku, totalSupply, maxQuantityPerPurchase, [tokenIds[0]], Zero, Zero, {from: deployer});
    // await this.sale.updateSkuPricing(sku, [this.paymentToken.address], [erc20Price], {from: deployer});
    // await this.sale.start({from: deployer});
    // this.receipt = await this.sale.purchaseFor(recipient, this.paymentToken.address, sku, quantity, EmptyByte, {
    //   from: purchaser,
    // });
    console.log("Aaa", paymentERC20)
    await paymentERC20.connect(purchaser).approve(sale.address, MaxUInt256);
    await sale.initContract(payoutWallet.address);
    console.log(totalSupply.toString())
    await sale.createSku(sku, 10, 3, [tokenIds[0]], 0, 0);
    console.log("aaaaa")
    console.log(erc20Price.toString(10));
    await sale.updateSkuPricing(sku, [paymentERC20.address], [erc20Price.toString(10)]);
    await sale.start();

    console.log("merge")
    console.log('empty byte', EmptyByte)
    console.log("paymentERC20.address,", paymentERC20.address)
    // await sale.connect(purchaser).purchaseFor(recipient.address, paymentERC20.address, sku, 
    //   quantity,EmptyByte, { value: erc20Price.toString(10) })

    // await sale.connect(purchaser).purchaseFor(recipient.address, paymentERC20.address, sku, 
    //   quantity, EmptyByte, { value: 1  })

    // await sale.connect(purchaser)["purchaseFor(address,address,bytes32,uint256,bytes,bytes32[])"]
    // (recipient.address, paymentERC20.address, sku, quantity,"0x", [EmptyByte], { value: "1" })

  });
});
