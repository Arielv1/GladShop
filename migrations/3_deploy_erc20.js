const ERC20 = artifacts.require("ERC20.sol");

module.exports = function(deployer) {
  const _name = "GoldCoinToken"
  const _symbol = "GCT"
  const _decimals = 18;
  const _totalAmount = 10000
  deployer.deploy(ERC20);
};
