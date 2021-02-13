App = {
  namepool: [],
  web3Provider: null,
  contracts: {},
  account: '0x0',
  bank: '0x0',
  web3: '',

  

  init: function() {
     
      App.initNamepool();
      App.initStats();
  //  App.getallAcounts();
    return App.initWeb3();
  },

  initNamepool() {
    App.namepool = ["Tertius Fulcinius Martialis","Publius Maecilius Plautis","Caeso Balventius Iovinus","Publius Canutius Belletor","Arruns Cispius Vitulus","Titus Lusius Augustus","Decius Verginius Senna","Tiberius Mucius Dardanius","Manius Lollius Figulus","Aulus Falerius Ahala",
    "Titus Caprenius Siricus","Quintus Laelius Diocourides","Secundus Vesuvius Drusus","Agrippa Galerius Hilaris","Paulus Messienus Eugenius","Sextus Quirinius Tremorinus","Marcus Caeparius Patiens","Vel Aurius Vitalion","Spurius Maelius Sisinnius","Maximus Hortensius Majus"]
  },

  initStats() {
      document.getElementById('remainingStats').innerHTML = Math.floor(Math.random() * 5) + 5
  },

 initWeb3() {
    if (typeof web3 !== 'undefined') {
      App.web3Provider = web3.currentProvider;
      ethereum.enable();
      web3 = new Web3(web3.currentProvider);
      web3.eth.defaultAccount = web3.eth.accounts[0]
      document.getElementById("recruit").style.display = "block"
        
    } else {
            
      App.web3Provider = new Web3.providers.HttpProvider('http://localhost:7545');
      ethereum.enable();
      web3 = new Web3(App.web3Provider);
    
    }

    return App.initContracts();
  },

 

  initContracts() {
    $.getJSON("CryptoGame.json", function(game) {
      App.contracts.CryptoGame = TruffleContract(game);
      App.contracts.CryptoGame.setProvider(App.web3Provider);
      App.contracts.CryptoGame.deployed().then(function(game) {
        console.log("CryptoGame Address:", game.address);
      });
    }).done(function() {
      $.getJSON("GoldCoinToken.json", function(tokens) {
        App.contracts.GoldCoinToken = TruffleContract(tokens);
        App.contracts.GoldCoinToken.setProvider(App.web3Provider);
        App.contracts.GoldCoinToken.deployed().then(function(tokens) {
          console.log("All Gold Coins Token Address:", tokens.address);
        });
        App.render()
      });
    })

  },

  convertMSToTime : function (milliseconds) {
      seconds = Math.floor((milliseconds / 1000) % 60),
      minutes = Math.floor((milliseconds / (1000 * 60)) % 60),
      hours = Math.floor((milliseconds / (1000 * 60 * 60)) % 24);

      hours = (hours < 10) ? "0" + hours : hours;
      minutes = (minutes < 10) ? "0" + minutes : minutes;
      seconds = (seconds < 10) ? "0" + seconds : seconds;  
      
      return hours + ":" + minutes + ":" + seconds
  },

  render() {
    web3.eth.getCoinbase(function(err, account) {
      if (err === null) {
      
      App.web3ProviderAllaccounts = new Web3.providers.HttpProvider('http://localhost:7545');
      web3allAccounts = new Web3(App.web3ProviderAllaccounts);
      web3allAccounts.eth.getAccounts(function(err, accounts) {
        App.ganacheAccounts = accounts
        App.bank = App.ganacheAccounts[0]
        console.log("bank address " + App.bank)
      });

        App.account = account;
        document.getElementById("accountAddress").innerHTML = "Your Address/Account Is: " + account
        App.contracts.GoldCoinToken.deployed().then(function(instance){
          GoldCoinTokenInstance = instance;
          return GoldCoinTokenInstance.thebalanceOf(App.account);
        }).then(function(balance){
          document.getElementById("accountNumberOfTokens").innerHTML = "You Currently have: " + balance + " Gold Coins"
        }).then(function(){
          return GoldCoinTokenInstance.thebalanceOf(App.bank)
        }).then(function(totalSupply){
            document.getElementById("loader").style.display = "none"
            document.getElementById("accountStats").style.display = "block"
            document.getElementById("challenge").style.display = "none"
            document.getElementById("name").innerHTML = App.namepool[Math.floor(Math.random() * App.namepool.length)]
            console.log("The Bank has " + totalSupply + " tokens")
        })
      }

      App.contracts.CryptoGame.deployed().then(function(gameInstance){
        CryptoGameInstance = gameInstance
        return CryptoGameInstance.ownerToGladiator(App.account)
      }).then(function(result){
        return CryptoGameInstance.gladiators(result.toNumber())
      }).then(function(gladiatorResult){
         if (gladiatorResult[9] === App.account) {
            App.showGladiatorStats(gladiatorResult);
      
            var cooldownTime = new Date(gladiatorResult[10] * 1000);
            var cooldownTimerInterval = setInterval(cooldownTimerHandler, 1000)
            function cooldownTimerHandler() {
                var now = new Date();
                var timeDifference = (cooldownTime - now.getTime())
                if (timeDifference <= 0) {
                  document.getElementById("cooldownBlock").style.display = "none"
                  document.getElementById("actions").style.display = "block"
                  document.getElementById("challenge").style.display = "block"
                  document.getElementById("aiWin").style.display = "none"
                  document.getElementById("playerWin").style.display = "none"
                  document.getElementById("playerLose").style.display = "none"
                  clearInterval(cooldownTimerInterval)
                }
                else {
                    timeRemaining = App.convertMSToTime(timeDifference)
                    document.getElementById("cooldownBlock").style.display = "block"
                    document.getElementById("cooldown").innerHTML = gladiatorResult[0] + " is in a resting from an action and will finish in " + timeRemaining
                    document.getElementById("actions").style.display = "none"
                    document.getElementById("challenge").style.display = "none"
                    

                }
            }
          }
      })
    });
  },

  displayTokens() {
      App.contracts.GoldCoinToken.deployed().then(function(instance){
          return instance.thebalanceOf(App.account);
        }).then(function(balance){
          console.log("updating number of tokens to " + balance)
          document.getElementById("accountNumberOfTokens").innerHTML = "You Currently have: " + (balance - 10) + " Tokens"
      })
  },

  valueModifier(id, name) {
    var hp = 0, sta = 0, str = 0 , dex = 0
    var remainingStatsToAllocate = Number(document.getElementById("remainingStats").innerHTML)
    if (id === "increase" && remainingStatsToAllocate > 0) {
        remainingStatsToAllocate--;
        document.getElementById('remainingStats').innerHTML = remainingStatsToAllocate
        if (name === "maxHP") {
          hp = Number(document.getElementById("maxHP").value) + 10;
          document.getElementById("maxHP").value=hp
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
       if (name === "maxHP") {
          hp= Number(document.getElementById("maxHP").value);
          if (hp > 50) {
            hp-=10;
            document.getElementById('maxHP').value=hp
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


  recruitGladiator() {
    var name = document.getElementById("name").innerHTML
    var maxHP = document.getElementById("maxHP").value
    var sta = document.getElementById("stamina").value
    var str = document.getElementById("str").value
    var dex = document.getElementById("dex").value

    remainingStatsToAllocate = Number(document.getElementById("remainingStats").innerHTML)
    if (remainingStatsToAllocate == 0) {
      App.contracts.CryptoGame.deployed().then(function(gameInstance){
        return gameInstance.recruitGladiator(App.account, name, sta, str, dex, maxHP)
      }).then(function(){
          return App.render()
          }).then(function(){  
        })
    }
    else {
        alert("You have " + remainingStatsToAllocate + " stats left to allocate")
    } 
    
  },
  arenaSignUp() {
    App.contracts.CryptoGame.deployed().then(function(gameInstance){
      cryptoGameInstance = gameInstance
      return cryptoGameInstance.ownerToGladiator(App.account)
    }).then(function(gladiatorId){
        cryptoGameInstance.signInForArena(Number(gladiatorId))
      /*  App.contracts.CryptoGame.deployed().then(function(gameInstance){
            gameInstance.signInForArena(Number(gladiatorId))
        }).then(function(){
          App.render()
        })*/
    }).then(function(){
          App.render()
        })
  },

  fightAgainstAI() {  
     App.contracts.CryptoGame.deployed().then(function(gameInstance){
        cryptoGameInstance = gameInstance
        return cryptoGameInstance.ownerToGladiator(App.account)
      }).then(function(gladId){
        myId = Number(gladId)
        console.log("my glad id " + gladId)
        return cryptoGameInstance.fightAI(myId);
      }).then(function(winnerId){
       // console.log(winnerId.logs)
      console.log("power ai " + winnerId.logs[1].args._aiPower + " my power " + winnerId.logs[1].args._myPower)  
      if (Number(winnerId.logs[1].args._aiPower) < Number(winnerId.logs[1].args._myPower)) { 
          document.getElementById("playerWin").style.display = "block"
          cryptoGameInstance.gladiators(myId).then(function(myGlad){
              document.getElementById("winningGladiatorName").innerHTML = myGlad[0]
          })
      }
      else {
          document.getElementById("aiWin").style.display = "block"  
          document.getElementById("aiPower").innerHTML =winnerId.logs[1].args._aiPower  
      }
      return App.render()
    })
   
  },

  challenge() {
    App.contracts.CryptoGame.deployed().then(function(gameInstance){
      cryptoGameInstance = gameInstance;
      return cryptoGameInstance.ownerToGladiator(App.account)
    }).then(function(myId){
      myGladId = Number(myId)
      console.log(document.getElementById("opponentAddress").value)
      return cryptoGameInstance.ownerToGladiator(document.getElementById("opponentAddress").value)
    }).then(function(enemyGladId){
      console.log("me " + Number(myGladId))
      console.log("enemy " + Number(enemyGladId))
      return cryptoGameInstance.fight(myGladId, Number(enemyGladId))
    }).then(function(winnerId){
      console.log(winnerId.logs)
      console.log(Number(winnerId.logs[winnerId.logs.length-1].args._winnerId) == myGladId)

      cryptoGameInstance.gladiators(myGladId).then(function(myGlad){
          if(Number(winnerId.logs[winnerId.logs.length-1].args._winnerId) == myGladId){
            document.getElementById("playerWin").style.display = "block"
            document.getElementById("winningGladiatorName").innerHTML = myGlad[0]
          }
          else {
            document.getElementById("playerLose").style.display = "block"
            document.getElementById("losingGladiatorName").innerHTML = myGlad[0]
          }
          return App.render()
      })
    })
  },

  eatTraining() {

    App.contracts.CryptoGame.deployed().then(function(gameInstance){
        cryptoGameInstance = gameInstance;
        return cryptoGameInstance.ownerToGladiator(App.account)
    }).then(function(gladiatorId){
        return cryptoGameInstance.eat(gladiatorId.toNumber())
    }).then(function(){
        return App.render()
    })
    
  },

  sleepTraining() {
    App.contracts.CryptoGame.deployed().then(function(gameInstance){
        cryptoGameInstance = gameInstance;
        return cryptoGameInstance.ownerToGladiator(App.account)
    }).then(function(gladiatorId){
        return cryptoGameInstance.sleep(gladiatorId.toNumber())
    }).then(function(){
        return App.render()
    })
  },

  muscleTraining() {
    App.contracts.CryptoGame.deployed().then(function(gameInstance){
        cryptoGameInstance = gameInstance;
        return cryptoGameInstance.ownerToGladiator(App.account)
    }).then(function(gladiatorId){
        return cryptoGameInstance.muscleTraining(gladiatorId.toNumber())
    }).then(function(){
        return App.render()
    })
  },

  enduranceTraining() {
    App.contracts.CryptoGame.deployed().then(function(gameInstance){
        cryptoGameInstance = gameInstance;
        return cryptoGameInstance.ownerToGladiator(App.account)
    }).then(function(gladiatorId){
        return cryptoGameInstance.enduranceTraining(gladiatorId.toNumber())
    }).then(function(){
        return App.render()
    })
  },

  flexibilityTraining() {

   App.contracts.CryptoGame.deployed().then(function(gameInstance){
        cryptoGameInstance = gameInstance;
        return cryptoGameInstance.ownerToGladiator(App.account)
    }).then(function(gladiatorId){
        return cryptoGameInstance.flexibilityTraining(gladiatorId.toNumber())
    }).then(function(){
        return App.render()
    })
  },
  
  showGladiatorStats(gladiator){

        document.getElementById("gladiatorName").innerHTML = gladiator[0]
        document.getElementById("gladiatorTier").innerHTML = gladiator[1]
        document.getElementById("gladiatorWinsRemaining").innerHTML = Number(gladiator[1])-Number(gladiator[12]);

        document.getElementById("gladiatorSta").innerHTML = gladiator[4];
        document.getElementById("gladiatorStr").innerHTML = gladiator[5];
        document.getElementById("gladiatorDex").innerHTML = gladiator[6];
        
        document.getElementById("recruit").style.display = "none"
        document.getElementById("loader").style.display = "none"
        document.getElementById("gladiatorStats").style.display = "block"

        document.getElementById("pbHP").innerHTML = gladiator[2] + " HP"
        document.getElementById("pbHP").style.width = ((gladiator[2] / gladiator[3]) * 100) + "%"

        document.getElementById("pbVigor").innerHTML = gladiator[7] + " Vigor"
        document.getElementById("pbVigor").style.width = gladiator[7] + "%"

        document.getElementById("pbSatiation").innerHTML = gladiator[8] + " Satiation"
        document.getElementById("pbSatiation").style.width = gladiator[8] + "%"

  },
};

$(function() {
  $(window).load(function() {
    App.init();
  });
});
