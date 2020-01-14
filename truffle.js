module.exports = {
  // See <http://truffleframework.com/docs/advanced/configuration>
  // to customize your Truffle configuration!
  compilers: {
    solc: {
      version: "0.6.1"
    }
  },
  mocha: {
    reporter: "eth-gas-reporter",
    reporterOptions: {
      currency: "USD"
    }
  },

  networks: {
    development: {
      host: "localhost",
      network_id: "*",
      port: 8545
    },
    kovan: {
      confirmations: 2,
      gas: 4200000,
      gasPrice: 20000000000,
      network_id: 42
    }
  }
};
