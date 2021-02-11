pragma solidity ^0.5.0;

import "./ERC721.sol";
import "./ERC20.sol";

contract CryptoGame is ERC721 {
    uint256 constant MIN_AMOUNT = 5;
    uint256 constant LOW_AMOUNT = 10;
    uint256 constant STANDARD_AMOUNT = 20;
    uint256 constant HIGH_AMOUNT = 25;

    uint256 constant MAX_STAMINA = 50;
    uint256 constant MAX_STRENGTH = 50;
    uint256 constant MAX_DEXTERITY = 50;
    uint256 constant MAX_VIGOR = 100;
    uint256 constant MAX_SATIATION = 100;

    struct Gladiator {
        string name;
        uint256 tier;
        uint256 hp;
        uint256 max_hp;
        uint256 stamina;
        uint256 strength;
        uint256 dexterity;
        uint256 vigor;
        uint256 satiation;
        address boss;
        uint256 cooldownTime;
        uint256 safetyNetCooldown;
        uint256 wins;
    }

    uint256 randNonce = 0;
    uint256 public numGladiators = 0;
    address public owner;
    uint256 public arenaTime;

    Gladiator[] public gladiators;
    Gladiator[] public gladiatorsForArena;
    Gladiator public gladiatorBot;
    ERC20 public bank;

    mapping(uint256 => address) public gladiatorToOwner;
    mapping(address => uint256) public ownerToGladiator;

    event BusyEvent(string _messege);
    event Winner(uint256 _winnerId);
    event AIFightStatistics(uint256 _myPower, uint256 _aiPower);

    modifier onlyOwnerOf(address _owner) {
        require(msg.sender == _owner);
        _;
    }

    modifier onlyOwner(address _owner) {
        require(owner == _owner);
        _;
    }

    modifier canAfford(uint256 _id, uint256 _cost) {
        require(bank.thebalanceOf(gladiatorToOwner[_id]) >= _cost);
        _;
    }

    modifier isBusy(uint256 _id, string memory _message) {
        require(gladiators[_id].cooldownTime <= now);
        emit BusyEvent(_message);
        _;
    }

    constructor(ERC20 tokens) public {
        owner = msg.sender;
        bank = tokens;
        arenaTime = now + 2 minutes;
    }

    function randMod(uint256 _modulus) internal returns (uint256) {
        randNonce++;
        return
            uint256(keccak256(abi.encodePacked(now, msg.sender, randNonce))) %
            _modulus;
    }

    function recruitGladiator(
        address _owner,
        string memory _name,
        uint256 _stamina,
        uint256 _strength,
        uint256 _dexterity,
        uint256 _maxHp
    ) public {
        uint256 id =
            gladiators.push(
                Gladiator(
                    _name,
                    1,
                    safeAdd(safeDiv(_maxHp, 2), _maxHp),
                    _maxHp,
                    _stamina,
                    _strength,
                    _dexterity,
                    randMod(100),
                    randMod(100),
                    _owner,
                    now,
                    now,
                    0
                )
            ) - 1;
        gladiatorToOwner[id] = _owner;
        ownerToGladiator[_owner] = id;
        bank.transferFrom(owner, _owner, 50);
        _mint(_owner, id);
    }

    function getGladiatorsByOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory result = new uint256[](gladiators.length);
        uint256 counter = 0;
        for (uint256 i = 0; i < gladiators.length; i = safeAdd(i, 1)) {
            if (gladiatorToOwner[i] == _owner) {
                result[counter] = i;
                counter = safeAdd(counter, 1);
            }
        }
        return result;
    }

    // new functions:
    function updateMaxHP(uint256 _gladiatorId) internal {
        gladiators[_gladiatorId].max_hp = safeAdd(
            100,
            safeAdd(
                gladiators[_gladiatorId].dexterity,
                safeAdd(
                    gladiators[_gladiatorId].strength,
                    safeMul(gladiators[_gladiatorId].stamina, 3)
                )
            )
        );
    }

    function checkLimits(
        uint256 score,
        uint256 amount,
        uint256 max,
        bool isAddition
    ) public returns (uint256) {
        if (isAddition) {
            uint256 res = safeAdd(score, amount);
            if (res > max) {
                return max;
            } else {
                return res;
            }
        } else {
            if (score < amount) {
                return 0;
            } else {
                return safeSub(score, amount);
            }
        }
    }

    function eat(uint256 _gladiatorId)
        external
        canAfford(_gladiatorId, 10)
        isBusy(_gladiatorId, "Busy Eating")
        returns (bool)
    {
        // cost - ingame currency
        // time - add a hour for each use.
        //require(gladiators[_gladiatorId].cooldownTime <= now);
        gladiators[_gladiatorId].satiation = checkLimits(
            gladiators[_gladiatorId].satiation,
            HIGH_AMOUNT,
            MAX_SATIATION,
            true
        );

        gladiators[_gladiatorId].vigor = checkLimits(
            gladiators[_gladiatorId].vigor,
            LOW_AMOUNT,
            MAX_VIGOR,
            false
        );

        gladiators[_gladiatorId].hp = checkLimits(
            gladiators[_gladiatorId].hp,
            MIN_AMOUNT,
            gladiators[_gladiatorId].max_hp,
            true
        );

        gladiators[_gladiatorId].cooldownTime = now + 1 minutes;
        bank.transferFrom(gladiatorToOwner[_gladiatorId], owner, 10);
        return true;
    }

    function sleep(uint256 _gladiatorId)
        external
        canAfford(_gladiatorId, 10)
        isBusy(_gladiatorId, "Busy Sleeping")
    {
        // cost - ingame currency
        // time - add a hour for each use.

        gladiators[_gladiatorId].vigor = checkLimits(
            gladiators[_gladiatorId].vigor,
            HIGH_AMOUNT,
            MAX_VIGOR,
            true
        );

        gladiators[_gladiatorId].satiation = checkLimits(
            gladiators[_gladiatorId].satiation,
            LOW_AMOUNT,
            MAX_SATIATION,
            false
        );

        gladiators[_gladiatorId].hp = checkLimits(
            gladiators[_gladiatorId].hp,
            STANDARD_AMOUNT,
            gladiators[_gladiatorId].max_hp,
            true
        );

        gladiators[_gladiatorId].cooldownTime = now + 1 minutes + 30 seconds;
        bank.transferFrom(gladiatorToOwner[_gladiatorId], owner, 10);
    }

    // Strength
    function muscleTraining(uint256 _gladiatorId)
        external
        canAfford(_gladiatorId, 10)
        isBusy(_gladiatorId, "Busy Training")
    {
        // cost - ingame currency
        // time - add a hour for each use.

        gladiators[_gladiatorId].strength = checkLimits(
            gladiators[_gladiatorId].strength,
            1,
            MAX_STRENGTH,
            true
        );

        gladiators[_gladiatorId].vigor = checkLimits(
            gladiators[_gladiatorId].vigor,
            STANDARD_AMOUNT,
            MAX_VIGOR,
            false
        );

        gladiators[_gladiatorId].satiation = checkLimits(
            gladiators[_gladiatorId].satiation,
            STANDARD_AMOUNT,
            MAX_SATIATION,
            false
        );

        gladiators[_gladiatorId].hp = checkLimits(
            gladiators[_gladiatorId].hp,
            MIN_AMOUNT,
            gladiators[_gladiatorId].max_hp,
            false
        );

        gladiators[_gladiatorId].cooldownTime = now + 3 minutes + 15 seconds;
        bank.transferFrom(gladiatorToOwner[_gladiatorId], owner, 10);
    }

    // Stamina
    function enduranceTraining(uint256 _gladiatorId)
        external
        canAfford(_gladiatorId, 10)
        isBusy(_gladiatorId, "Busy Training")
    {
        // cost - ingame currency
        // time - add a hour for each use.

        gladiators[_gladiatorId].stamina = checkLimits(
            gladiators[_gladiatorId].stamina,
            1,
            MAX_STAMINA,
            true
        );

        gladiators[_gladiatorId].vigor = checkLimits(
            gladiators[_gladiatorId].vigor,
            STANDARD_AMOUNT,
            MAX_VIGOR,
            false
        );

        gladiators[_gladiatorId].satiation = checkLimits(
            gladiators[_gladiatorId].satiation,
            STANDARD_AMOUNT,
            MAX_SATIATION,
            false
        );

        gladiators[_gladiatorId].hp = checkLimits(
            gladiators[_gladiatorId].hp,
            MIN_AMOUNT,
            gladiators[_gladiatorId].max_hp,
            false
        );

        gladiators[_gladiatorId].cooldownTime = now + 5 minutes;
        bank.transferFrom(gladiatorToOwner[_gladiatorId], owner, 10);
    }

    // Dexterity
    function flexibilityTraining(uint256 _gladiatorId)
        external
        canAfford(_gladiatorId, 10)
        isBusy(_gladiatorId, "Busy Training")
    {
        // cost - ingame currency
        // time - add a hour for each use.
        gladiators[_gladiatorId].dexterity = checkLimits(
            gladiators[_gladiatorId].dexterity,
            1,
            MAX_DEXTERITY,
            true
        );

        gladiators[_gladiatorId].vigor = checkLimits(
            gladiators[_gladiatorId].vigor,
            STANDARD_AMOUNT,
            MAX_VIGOR,
            false
        );

        gladiators[_gladiatorId].satiation = checkLimits(
            gladiators[_gladiatorId].satiation,
            STANDARD_AMOUNT,
            MAX_SATIATION,
            false
        );

        gladiators[_gladiatorId].hp = checkLimits(
            gladiators[_gladiatorId].hp,
            MIN_AMOUNT,
            gladiators[_gladiatorId].max_hp,
            false
        );

        gladiators[_gladiatorId].cooldownTime = now + 2 minutes;
        bank.transferFrom(gladiatorToOwner[_gladiatorId], owner, 10);
    }

    function hpStatusModifier(uint256 _gladiatorId) internal returns (uint256) {
        if (gladiators[_gladiatorId].hp < 10) {
            // below 10 -> no benefit to power.
            return 0;
        } else if (
            gladiators[_gladiatorId].hp == gladiators[_gladiatorId].max_hp
        ) {
            // double benefit
            return 2;
        } else {
            // normal benefit
            return 1;
        }
    }

    function vigorStatus(uint256 _gladiatorId) internal returns (uint256) {
        if (gladiators[_gladiatorId].vigor < 5) {
            // The Gladiator is exhausted -> no benefit to power.
            return 0;
        } else if (
            (gladiators[_gladiatorId].vigor >= 5 &&
                gladiators[_gladiatorId].vigor < 50) ||
            (gladiators[_gladiatorId].vigor > 75 &&
                gladiators[_gladiatorId].vigor <= 100)
        ) {
            // fatigue or hypersomnia/oversleeping
            return 1;
        } else {
            // optimal wakefulness
            return 2;
        }
    }

    function satiationStatus(uint256 _gladiatorId) internal returns (uint256) {
        if (gladiators[_gladiatorId].hp < 10) {
            // The Gladiator is famished -> no benefit to power.
            return 0;
        } else if (
            (gladiators[_gladiatorId].vigor >= 10 &&
                gladiators[_gladiatorId].vigor < 60) ||
            (gladiators[_gladiatorId].vigor > 80 &&
                gladiators[_gladiatorId].vigor <= 100)
        ) {
            // undereating or overeating
            return 1;
        } else {
            // optimal food consumption
            return 2;
        }
    }

    function calcDef(uint256 _gladiatorId) internal returns (uint256) {
        uint256 def =
            safeAdd(
                safeMul(gladiators[_gladiatorId].stamina, 3),
                safeMul(gladiators[_gladiatorId].dexterity, 2)
            );
        return def;
    }

    function calcAtt(uint256 _gladiatorId) internal returns (uint256) {
        uint256 att =
            safeAdd(
                safeMul(gladiators[_gladiatorId].strength, 3),
                safeMul(gladiators[_gladiatorId].dexterity, 2)
            );
        return att;
    }

    function calcPower(uint256 _gladiatorId) internal returns (uint256) {
        uint256 power =
            safeAdd(
                safeMul(
                    gladiators[_gladiatorId].hp,
                    hpStatusModifier(_gladiatorId)
                ),
                safeAdd(calcDef(_gladiatorId), calcAtt(_gladiatorId))
            );
        return power;
    }

    function handleStatsFromVictory(uint256 _gladiatorId) internal {
        gladiators[_gladiatorId].hp = safeDiv(gladiators[_gladiatorId].hp, 4);
        gladiators[_gladiatorId].satiation = safeDiv(
            gladiators[_gladiatorId].satiation,
            3
        );
        gladiators[_gladiatorId].vigor = safeDiv(
            gladiators[_gladiatorId].vigor,
            3
        );
    }

    function handleStatsFromLoss(uint256 _gladiatorId) internal {
        gladiators[_gladiatorId].hp = safeDiv(
            safeDiv(gladiators[_gladiatorId].hp, 2),
            2
        );
        gladiators[_gladiatorId].satiation = safeDiv(
            safeDiv(gladiators[_gladiatorId].satiation, 2),
            3
        );
        gladiators[_gladiatorId].vigor = safeDiv(
            safeDiv(gladiators[_gladiatorId].vigor, 2),
            2
        );
    }

    function fightAI(uint256 _gladiatorId) external {
        uint256 aiPower = 100 * gladiators[_gladiatorId].tier + randMod(100);
        uint256 gladPower = calcPower(_gladiatorId);
        // Compare the power of both gladiators.
        if (gladPower > aiPower) {
            bank.transferFrom(owner, gladiators[_gladiatorId].boss, 25);
        } else {
            bank.transferFrom(gladiators[_gladiatorId].boss, owner, 10);
        }
        gladiators[_gladiatorId].cooldownTime = now + 20 seconds;
        emit AIFightStatistics(gladPower, aiPower);
    }

    function fight(uint256 _gladiatorId1, uint256 _gladiatorId2)
        external
        isBusy(_gladiatorId2, "Opponent Is Busy")
    {
        require(
            gladiators[_gladiatorId2].safetyNetCooldown <= now &&
                gladiators[_gladiatorId1].tier <= gladiators[_gladiatorId2].tier
        );

        // Compare the power of both gladiators.
        if (calcPower(_gladiatorId1) > calcPower(_gladiatorId2)) {
            gladiators[_gladiatorId2].safetyNetCooldown = now + 30 seconds;

            uint256 numWins = safeAdd(gladiators[_gladiatorId1].wins, 1);
            if (numWins == gladiators[_gladiatorId1].tier) {
                gladiators[_gladiatorId1].wins = 0;
                gladiators[_gladiatorId1].tier++;
                bank.transferFrom(
                    owner,
                    gladiators[_gladiatorId1].boss,
                    safeMul(gladiators[_gladiatorId1].tier, 5)
                );
            } else {
                gladiators[_gladiatorId1].wins = numWins;
            }

            handleStatsFromVictory(_gladiatorId1);
            bank.transferFrom(owner, gladiators[_gladiatorId1].boss, 10);
            emit Winner(_gladiatorId1);
        } else {
            // player 2 wins!
            uint256 lossAmount = 10;
            if (gladiators[_gladiatorId1].wins == 0) {
                if (gladiators[_gladiatorId1].tier != 1) {
                    gladiators[_gladiatorId1].tier = safeSub(
                        gladiators[_gladiatorId1].tier,
                        1
                    );
                    lossAmount = 0;
                }
            } else {
                gladiators[_gladiatorId1].wins = safeSub(
                    gladiators[_gladiatorId1].wins,
                    1
                );
            }

            handleStatsFromLoss(_gladiatorId1);
            bank.transferFrom(
                gladiators[_gladiatorId1].boss,
                owner,
                lossAmount
            );
            emit Winner(_gladiatorId2);
        }
        gladiators[_gladiatorId1].cooldownTime = now + 20 seconds;
    }

    function randomInRange(uint256 _low, uint256 _high)
        internal
        returns (uint256)
    {
        uint256 randomnumber =
            uint256(keccak256(abi.encodePacked(now, msg.sender, randNonce))) %
                (_high - _low);
        randomnumber = randomnumber + _low;
        randNonce++;
        return randomnumber;
    }
}
