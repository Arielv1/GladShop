const CryptoGame = artifacts.require("CryptoGame.sol");
const ERC20 = artifacts.require("ERC20.sol");
module.exports = function(deployer) {
  const _name = "SilverCoinToken"
  const _symbol = "SCT"
  const _decimals = 18;
  const _totalAmount = 10000
  deployer.deploy(ERC20).then(function(){
    return deployer.deploy(CryptoGame,ERC20.address);
  });
  //deployer.deploy(CryptoGame);
};
