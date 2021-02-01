var Election = artifacts.require("./Election.sol");
var ElectionToken = artifacts.require("./ElectionToken.sol");


module.exports = function(deployer) {
  // deployer.deploy(ElectionToken);
  // deployer.deploy(Election);
  deployer.deploy(ElectionToken).then(function(){
    return deployer.deploy(Election,ElectionToken.address);
  });
};