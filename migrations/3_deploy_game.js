const CryptoGame = artifacts.require("CryptoGame.sol");
const GoldCoinToken = artifacts.require("GoldCoinToken.sol");
module.exports = function(deployer) {
  deployer.deploy(GoldCoinToken).then(function(){
    return deployer.deploy(CryptoGame,GoldCoinToken.address);
  });
};
