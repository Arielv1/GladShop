App = {
  web3Provider: null,
  contracts: {},
  account: '0x0',
  owner: '0x0',
  initStats() {
      document.getElementById('remainingStats').innerHTML = Math.floor(Math.random() * 5) + 5
  },

  init: function() {

      App.initStats();
  //  App.getallAcounts();
    return App.initWeb3();
  },

 initWeb3: function() {
    if (typeof web3 !== 'undefined') {
      App.web3Provider = web3.currentProvider;
      ethereum.enable();
      web3 = new Web3(web3.currentProvider);
    } else {
            
      App.web3Provider = new Web3.providers.HttpProvider('http://localhost:7545');
      ethereum.enable();
      web3 = new Web3(App.web3Provider);
    }

    return App.initContracts();
  },

 

  initContracts: function() {
    $.getJSON("CryptoGame.json", function(game) {
      App.contracts.CryptoGame = TruffleContract(game);
      App.contracts.CryptoGame.setProvider(App.web3Provider);
      App.contracts.CryptoGame.deployed().then(function(game) {
        console.log("CryptoGame Address:", game.address);
      });
    }).done(function() {
      $.getJSON("ERC20.json", function(tokens) {
        App.contracts.ERC20 = TruffleContract(tokens);
        App.contracts.ERC20.setProvider(App.web3Provider);
        App.contracts.ERC20.deployed().then(function(tokens) {
          console.log("All Coin Token Address:", tokens.address);
        });

      });
    })
  },



  valueModifier: function(id, name) {
    var vig = 0,sat = 0,sta = 0, str = 0 , dex = 0
    var remainingStatsToAllocate = Number(document.getElementById("remainingStats").innerHTML)
    if (id === "increase" && remainingStatsToAllocate > 0) {
        remainingStatsToAllocate--;
        document.getElementById('remainingStats').innerHTML = remainingStatsToAllocate
        if (name === "vigor") {
          vig = Number(document.getElementById("vigor").value) + 1;
          document.getElementById('vigor').value=vig
        }
        else if (name === "satiation") {
          sat = Number(document.getElementById("satiation").value) + 1; 
          document.getElementById('satiation').value=sat
        }
        else if (name === "stamina") {
          sta = Number(document.getElementById("stamina").value) + 1;
          document.getElementById('stamina').value=sta
        }
        else if (name === "str") {
          str = Number(document.getElementById("str").value) + 1;
          document.getElementById('str').value=str
        }
        else if (name === "dex") {
          dex = Number(document.getElementById("dex").value) + 1;
          document.getElementById('dex').value=dex
        }
    }
    else if (id === "decrease"){
       if (name === "vigor") {
          vig= Number(document.getElementById("vigor").value);
          if (vig > 0) {
            vig--;
            document.getElementById('vigor').value=vig
            remainingStatsToAllocate++;
            document.getElementById('remainingStats').innerHTML = remainingStatsToAllocate
          }
        }
        else if (name === "satiation") {
          sat= Number(document.getElementById("satiation").value);
           if (sat > 0) {
            sat--;
            document.getElementById('satiation').value=sat
            remainingStatsToAllocate++;
            document.getElementById('remainingStats').innerHTML = remainingStatsToAllocate
          }
        }
        else if (name === "stamina") {
          sta= Number(document.getElementById("stamina").value);
           if (sta > 0) {
            sta--;
            document.getElementById('stamina').value=sta
            remainingStatsToAllocate++;
            document.getElementById('remainingStats').innerHTML = remainingStatsToAllocate
           }
        }
        else if (name === "str") {
          str= Number(document.getElementById("str").value);
           if (str > 0) {
            str--;
            document.getElementById('str').value=str
            remainingStatsToAllocate++;
            document.getElementById('remainingStats').innerHTML = remainingStatsToAllocate
          }
        }
        else if (name === "dex") {
          dex= Number(document.getElementById("dex").value) ;
           if (dex > 0) {
            dex--;
            document.getElementById('dex').value=dex
            remainingStatsToAllocate++;
            document.getElementById('remainingStats').innerHTML = remainingStatsToAllocate
          }
        }
    }
  },
  

  recruitGladiator: function() {

    var vig = document.getElementById("vigor").value;
    var sat = document.getElementById("satiation").value;
    var sta = document.getElementById("stamina").value;
    var str = document.getElementById("str").value;
    var dex = document.getElementById("dex").value;
    console.log(vig, sat, sta, str, dex)


    App.contracts.CryptoGame.deployed().then(function(gameInstance) {
      gameInstance.recruitGladiator(App.account);
    })
  }
};

$(function() {
  $(window).load(function() {
    App.init();
  });
});
