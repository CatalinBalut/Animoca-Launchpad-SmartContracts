require("@nomicfoundation/hardhat-toolbox");
/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: {
    compilers: [
      {
        version: "0.8.9",
      },
      {
        version: "0.7.6",
        settings: {},
      },
    ],
    overrides: {
      "contracts/TokenLaunchpadVouchers.sol": {
        version: "0.7.6",
        settings: { }
      }
  },
},

    networks: {
        hardhat: {
            gas: 19000000,
            allowUnlimitedContractSize: true,
            timeout: 1800000
        },
        // rinkeby: {
        //     url: "",
        //     chainId: 4,
        //     accounts: { mnemonic: mnemonic },
        //     gas: 1200000000,
        //     blockGasLimit: 3000000000,
        //     allowUnlimitedContractSize: true,
        //     timeout: 1800000
        // },
        // goerli: {
        //     url: "",
        //     chainId: 5,
        //     accounts: { mnemonic: mnemonic },
        //     gas: 1200000000,
        //     blockGasLimit: 3000000000,
        //     allowUnlimitedContractSize: true,
        //     timeout: 1800000
        // }
    },
    gasReporter: {
      currency: 'CHF',
      gasPrice: 21
    }
};
