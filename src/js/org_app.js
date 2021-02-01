App = {
  web3Provider: null,
  inselecetion: null,
  contracts: {},
  account: '0x0',
  hasVoted: false,
  accountsganach: [],
  candidates: [],
  candidatesLastQuestion: [],


  init: function() {
    document.getElementById('remainingStats').innerHTML = Math.floor(Math.random() * 5) + 5
    App.getallAcounts();
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
    $.getJSON("Election.json", function(election) 
    {
      App.contracts.Election = TruffleContract(election);
      App.contracts.Election.setProvider(App.web3Provider);
      App.contracts.Election.deployed().then(function(election) 
      {
        console.log("Token Address:", election.address);
      });
    }).done(function()
     {
      $.getJSON("ElectionToken.json", function(electionToken) 
      {
        App.contracts.ElectionToken = TruffleContract(electionToken);
        App.contracts.ElectionToken.setProvider(App.web3Provider);
        App.contracts.ElectionToken.deployed().then(function(electionToken)
         {
          console.log("Election Token Address:", electionToken.address);
         });
      });
    }).done(function () 
    {
       $.getJSON("CryptoGame.json", function(game) 
      {
        App.contracts.CryptoGame = TruffleContract(game);
        App.contracts.CryptoGame.setProvider(App.web3Provider);
        App.contracts.CryptoGame.deployed().then(function(game)
         {
          console.log("Game Token Address:", game.address);
         });
      });
     
    }).done(function () 
    {
        $.getJSON("ERC20.json", function(tokens) 
      {
        App.contracts.ERC20 = TruffleContract(tokens);
        App.contracts.ERC20.setProvider(App.web3Provider);
        App.contracts.ERC20.deployed().then(function(tokens)
         {
          console.log("Gold Coin Tokens Address:", tokens.address);
         });
      });
      App.listenForEvents();
      return App.render();
    })
  },

  // Listen for events emitted from the contract
  listenForEvents: function() {
    App.contracts.Election.deployed().then(function(instance) {
      
      instance.votedEvent({}, {
        // fromBlock: latest,
       // toBlock: 'latest'
      }).watch(function(error, event) {
        console.log("event triggered", event)
        // Reload when a new vote is recorded
        App.render();
      });
    });
  },

  showWinner: function()
  {
        App.contracts.Election.deployed().then(function(instance) {
          electionInstance = instance;
          return electionInstance.candidatesCount();
        }).then(function(candidatesCount) {
          var candidatesResults = $("#candidatesResults");
          candidatesResults.empty();
            var sorted = [];
          for (var i = 1; i <= candidatesCount; i++) {
            electionInstance.candidates(i).then(function(candidate) {
              sorted.push(candidate);
              if(sorted.length == candidatesCount)
              {
                 sorted.sort(function(a,b){return b[2]-a[2]});
                for(i=0;i< candidatesCount;i++)
                {
                  var image = "<img src=\"./images/"+(sorted[i][0])+".jpg\" width=\"30\" height=\"30\">";
                  var candidateTemplate = "<tr><th>" + (i+1) + "</th><td>" + image + "</td><td>" + sorted[i][1] + "</td><td>" + sorted[i][2] + "</td></tr>"
                  candidatesResults.append(candidateTemplate);
                }
                 if(sorted[0][2] <= sorted[1][2])
               {
                   $("#TheWinner").html("There is no singular winner");
               }
                else
                {
                  $("#TheWinner").html("The Winner is: "+sorted[0][1]);
                }
                }
            });
          }
        });
  },
  getallAcounts: function()
  {
    App.web3ProviderAllaccounts = new Web3.providers.HttpProvider('http://localhost:7545');
    web3allAccounts = new Web3(App.web3ProviderAllaccounts);
    web3allAccounts.eth.getAccounts(function(err, accounts) {
      App.accountsganach = accounts;
    });
  },
  questionnaire: function()
  {
    var content = $("#content");
      content.hide();
    var recomends = $("#recomends");
    recomends.show();
    var button = $("#castrecomndesButton");
    button.show();
    var button = $("#questionnaireButton");
    button.hide();
  },
  castrecomndes: function()
  {
    var button = $("#castrecomndesButton");
    button.hide();
    var canididatsSeker = [
      ["Bibi", 0],
      ["Gantz", 0],
      ["Ayman_Odeh", 0],
      ["Naftali_Bennett", 0],
      ["Amir_Peretz", 0],
      ["Yaakov_Litzman", 0],
      ["Aryeh_Deri", 0],
      ["Avigdor_Lieberman", 0]
    ];
    var Gantz = 0;
    var Bibi = 0;Ayman_Odeh = 0;Amir_Peretz  =0;Yaakov_Litzman =0;
    var Aryeh_Deri = 0;
    var Naftali_Bennett =0;Avigdor_Lieberman = 0;
    // q1 xxxx
    if($('input[name=q1]:checked').val() == 1)
    {
      Gantz++;Ayman_Odeh ++; Amir_Peretz++;Avigdor_Lieberman++;
    }
    else if($('input[name=q1]:checked').val() == 0)
    {
      Bibi++;Aryeh_Deri++;Yaakov_Litzman++;Naftali_Bennett++;
    }
        // q2 xxxx
    if($('input[name=q2]:checked').val() == 1)
    {
      Naftali_Bennett++;Avigdor_Lieberman++;
    }
    else if($('input[name=q2]:checked').val() == 0)
    {
      Gantz++;Ayman_Odeh ++; Amir_Peretz++;
    }
    else
    {
      Bibi++;Aryeh_Deri++;Yaakov_Litzman++;
    }   
    // q3 xxxx
    if($('input[name=q3]:checked').val() == 1)
    {
      Gantz++;Ayman_Odeh ++;Amir_Peretz++;Avigdor_Lieberman++;
    }
    else if($('input[name=q3]:checked').val() == 0)
    {
      Aryeh_Deri++;Yaakov_Litzman++;Naftali_Bennett++;
    } 
    // q4 xxxx
      if($('input[name=q4]:checked').val() == 1)
    {
      Bibi++;Aryeh_Deri++;Yaakov_Litzman++;Naftali_Bennett++;Avigdor_Lieberman++;
    }
    else if($('input[name=q4]:checked').val() == 0)
    {
      Gantz++;Ayman_Odeh++; Amir_Peretz++;
    }
    //q5   xxxx
    if($('input[name=q5]:checked').val() == 1)
    {
      Gantz++;Bibi++;Amir_Peretz++;Avigdor_Lieberman++;
    }
    else if($('input[name=q5]:checked').val() == 0)
    {
      Aryeh_Deri++;Yaakov_Litzman++;Naftali_Bennett++;Ayman_Odeh++;
    }
    //q6   xxxx
    if($('input[name=q6]:checked').val() == 1)
    {
      Bibi++;Aryeh_Deri++;Yaakov_Litzman++;Naftali_Bennett++;Avigdor_Lieberman++;
    }
    else if($('input[name=q6]:checked').val() == 0)
    {
      Gantz++;Ayman_Odeh++;Amir_Peretz++;
    }
    //q7   xxxx
    if($('input[name=q7]:checked').val() == 1)
    {
      Gantz++;Ayman_Odeh++;Amir_Peretz++;Avigdor_Lieberman++;
    }
    else if($('input[name=q7]:checked').val() == 0)
    {
      Bibi++;Aryeh_Deri++;Yaakov_Litzman++;Naftali_Bennett++;
    }
     canididatsSeker[0][1] = Bibi;canididatsSeker[1][1] = Gantz;
     canididatsSeker[2][1] = Ayman_Odeh;canididatsSeker[3][1] = Naftali_Bennett;
     canididatsSeker[4][1] = Amir_Peretz; canididatsSeker[5][1] = Yaakov_Litzman;
     canididatsSeker[6][1] = Aryeh_Deri;  canididatsSeker[7][1] = Avigdor_Lieberman;

    var max  = Math.max(canididatsSeker[0][1],canididatsSeker[1][1],
      canididatsSeker[2][1], canididatsSeker[3][1], canididatsSeker[4][1], 
      canididatsSeker[5][1],canididatsSeker[6][1], canididatsSeker[7][1]);
  var neededLastQuestion = [];

    for(var i=0; i<canididatsSeker.length;i++)
    {
      if (canididatsSeker[i][1] == max)
      {
        neededLastQuestion.push(canididatsSeker[i][0]);
      }
    }
    if(neededLastQuestion.length > 1)
    {
      App.candidatesLastQuestion = neededLastQuestion;
      App.lastQuestion(neededLastQuestion);
    }
    else{
      alert("Recomended is:"+neededLastQuestion[0]);
    }
  },
  lastQuestion: function(neededLastQuestion) {
    var recomendlastQuestion = $("#recomendlastQuestion");
    recomendlastQuestion.show();
    var bodyQuestions = $("#RecomendedRows");
    bodyQuestions.empty();
    var rowTemplate = "<tr><th>" + (1) + "</th><td>" + "מי אתם חושב שהכי אמין בין המועמדים" + "</td><td>"
      for(var i=0; i<neededLastQuestion.length;i++)
      {
          rowTemplate = rowTemplate+
          " <label><input type=\"radio\"+ \" id=\ 'regular8' name=q8 value="+i+"> "+neededLastQuestion[i]+" </label>"
      }
      var finishTemplate = rowTemplate+" </td></tr>"
      bodyQuestions.append(finishTemplate);

  },
  lastVote: function() {
    var value = $('input[name=q8]:checked').val();
    alert("The Recomended is : "+App.candidatesLastQuestion[value]);
    location.reload();
  },
 
  render: function() {
    var electionInstance;
    var loader = $("#loader");
    var content = $("#content");
    var recomendlastQuestion = $("#recomendlastQuestion");
    loader.show();
    content.hide();
    recomendlastQuestion.hide();
    var recomends = $("#recomends");
    recomends.hide();
    var button = $("#castrecomndesButton");
    button.hide();

    // Load account data
    web3.eth.getCoinbase(function(err, account) {
      if (err === null) {
        App.account = account;
        $("#accountAddress").html("Your Account: " + account);
        App.contracts.ElectionToken.deployed().then(function(instance){
          ElectionTokenInstance = instance;
          return ElectionTokenInstance.thebalanceOf(App.account);
        }).then(function(balance){
          $("#accountNumberOfTokens").html("You Currently have: " + balance + " Tokens");
        });

      }
    });

    // Load contract data
    App.contracts.Election.deployed().then(function(instance) {
      electionInstance = instance;
      return electionInstance.candidatesCount();
    }).then(function(candidatesCount) {

      var candidatesResults = $("#candidatesResults");
      candidatesResults.empty();
  
      var candidatesSelect = $('#candidatesSelect');
      candidatesSelect.empty();
      for (var i = 1; i <= candidatesCount; i++) {
        electionInstance.candidates(i).then(function(candidate) {
          var id = candidate[0];
          var name = candidate[1];
          var voteCount = candidate[2];
          var link = candidate[3];
          link = link+ " target=_blank";

          var image = "<img src=\"./images/"+id+".jpg\" width=\"30\" height=\"30\">";
          // Render candidate Result
          var candidateTemplate = "<tr><th>" + id + "</th><td> <a href="+ link +">" + image + "</a></td><td>" + name + "</td><td>" + voteCount + "</td></tr>"
          candidatesResults.append(candidateTemplate);

          // Render candidate ballot option
          var candidateOption = "<option value='" + id + "' >" + name + "</ option>"
          candidatesSelect.append(candidateOption);
        });
      }
      return electionInstance.timeblock();
    }).then(function(timeblock) {
      var endtime_in_seconds = timeblock;
      var endtimeformat = new Date(timeblock * 1000);
      let dd = endtimeformat.getDate();
      let mm = endtimeformat.getMonth()+1;
      let hh = endtimeformat.getHours();
      let min = endtimeformat.getMinutes();
      let ss = endtimeformat.getSeconds();
      const yyyy = endtimeformat.getFullYear();
      endtimeformat = `${dd}/${mm}/${yyyy} - ${hh}:${min}:${ss}`;

      // $("#endtime").html("endtime: "+endtime_in_seconds);
      // $("#endtimeformat").html("endtimeformat: "+endtimeformat);

      var myVar = setInterval(myTimer, 1000);
      function myTimer() {
    let now = new Date();
    let dd = now.getDate();
    let mm = now.getMonth()+1;
    let hh = now.getHours();
    let min = now.getMinutes();
    let ss = now.getSeconds();
    const yyyy = now.getFullYear();

      nowformat = `${dd}/${mm}/${yyyy} - ${hh}:${min}:${ss}`;
      timeleft = Math.floor((endtime_in_seconds * 1000 - now) / 1000) ;
      if(endtime_in_seconds* 1000 <= now)
      {
        // vote time finished
        clearInterval(myVar);
        $("#times").hide();
        App.showWinner();
      }
      else
      {
      var timeleftformat = new Date(timeleft *1000);
      let seconds = Math.floor((timeleftformat / 1000) % 60);
      let minutes = Math.floor((timeleftformat / (1000 * 60)) % 60);
      let hours = Math.floor((timeleftformat / (1000 * 60 * 60)) % 24);
      timeleftformat = `${hours}:${minutes}:${seconds}`;
      $("#timerleftformat").html("The Election will end in: "+timeleftformat);
      }
}

      return electionInstance.voters(App.account);
    }).then(function(hasVoted) {
      // Do not allow a user to vote
      if(hasVoted) {
        $('form').hide();
      }
      loader.hide();
      content.show();
      // App.render();
    }).catch(function(error) {
      console.warn(error);
    });
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

    App.contracts.CryptoGame.deployed().then(function(instance) {
      console.log("here")
      return instance.recruitGladiator("0x16544637a00724Abe9571AE0662624cB69B26596");
    }).then(function(result) {
      // Wait for votes to update
      $("#content").hide();
      $("#loader").show();
    }).catch(function(err) {
      console.error(err);
    });

    },

  castVote: function() {

    // we can handle who can vote in the App.js too
    // if(!App.accountsganach.includes(App.account))
    // {
    //   alert("you cant vote");
    //   return false;
    // }

    var candidateId = $('#candidatesSelect').val();
    App.contracts.Election.deployed().then(function(instance) {
      return instance.vote(candidateId, { from: App.account });
    }).then(function(result) {
      // Wait for votes to update
      $("#content").hide();
      $("#loader").show();
    }).catch(function(err) {
      console.error(err);
    });
  }
};

$(function() {
  $(window).load(function() {
    App.init();
    // location.reload();
    // return false;
  });
});