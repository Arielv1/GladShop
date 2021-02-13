pragma solidity ^0.5.0;

import "./ERC721.sol";
import "./GoldCoinToken.sol";

contract CryptoGame is ERC721 {
    // constants
    uint256 constant MIN_AMOUNT = 5;
    uint256 constant LOW_AMOUNT = 10;
    uint256 constant STANDARD_AMOUNT = 20;
    uint256 constant HIGH_AMOUNT = 25;

    uint256 constant MAX_STAMINA = 50;
    uint256 constant MAX_STRENGTH = 50;
    uint256 constant MAX_DEXTERITY = 50;
    uint256 constant MAX_VIGOR = 100;
    uint256 constant MAX_SATIATION = 100;

    // every action cooldown is the same for the sake of simplicity
    uint256 constant ACTION_COOLDOWN = 1 minutes;
    uint256 constant TRAINING_COST = 10;

    struct Gladiator {
        string name;
        uint256 tier; // gladiators can fight other players' gladiators whose on the same tier
        uint256 hp;
        uint256 max_hp;
        uint256 stamina;
        uint256 strength;
        uint256 dexterity;
        uint256 vigor;
        uint256 satiation;
        address owner; // needed for mapping issues when there're 0 or 1 gladiator recruited
        uint256 cooldownTime; // keeps track when the gladiator can perform a new action
        uint256 safetyNetCooldown; // safety net so loosing gladiator wont be able to be abused by other players
        uint256 wins; // number of wins the gladiators has in the current tier
    }

    uint256 randNonce = 0;
    uint256 public numGladiators = 0;
    address public owner;

    Gladiator[] public gladiators;
    GoldCoinToken public bank;

    mapping(uint256 => address) public gladiatorToOwner;
    mapping(address => uint256) public ownerToGladiator;

    event BusyEvent(string _messege); // when the gladiator is performing an action
    event Winner(uint256 _winnerId); // invoked when a player challenges another player
    event AIFightStatistics(uint256 _myPower, uint256 _aiPower); // when challenging the AI

    // checks if the gladiators' boss has enough funds to perform an action
    modifier canAfford(uint256 _id, uint256 _cost) {
        require(bank.thebalanceOf(gladiatorToOwner[_id]) >= _cost);
        _;
    }

    // checks if a gladiator is resting from an action
    modifier isBusy(uint256 _id, string memory _message) {
        require(gladiators[_id].cooldownTime <= now);
        emit BusyEvent(_message);
        _;
    }

    constructor(GoldCoinToken tokens) public {
        owner = msg.sender;
        bank = tokens;
    }

    function randMod(uint256 _modulus) internal returns (uint256) {
        randNonce = safeAdd(randNonce, 1);
        return
            uint256(keccak256(abi.encodePacked(now, msg.sender, randNonce))) %
            _modulus;
    }

    function randomInRange(uint256 _low, uint256 _high)
        internal
        returns (uint256)
    {
        uint256 randomnumber =
            uint256(keccak256(abi.encodePacked(now, msg.sender, randNonce))) %
                safeSub(_high, _low);
        randomnumber = safeAdd(randomnumber, _low);
        randNonce = safeAdd(randNonce, 1);
        return randomnumber;
    }

    // get statistics from frontend by the user and create a new gladiator instance, then map it
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
                    randomInRange(safeDiv(_maxHp, 2), _maxHp),
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

    // new functions:
    function updateMaxHP(uint256 _gladiatorId) internal {
        gladiators[_gladiatorId].max_hp = safeAdd(
            gladiators[_gladiatorId].max_hp,
            2
        );
    }

    // makes sure that when gladiators' attribute is about to be updates - it won't go over the set limit
    function checkLimitsOfStat(
        uint256 stat,
        uint256 amount,
        uint256 max,
        bool isAddition
    ) internal view returns (uint256) {
        if (isAddition) {
            uint256 res = safeAdd(stat, amount);
            if (res > max) {
                return max;
            } else {
                return res;
            }
        } else {
            if (stat < amount) {
                return 0;
            } else {
                return safeSub(stat, amount);
            }
        }
    }

    // eat action: +satiation +hp -vigor
    function eat(uint256 _gladiatorId)
        external
        canAfford(_gladiatorId, TRAINING_COST)
        isBusy(_gladiatorId, "Busy Eating")
        returns (bool)
    {
        gladiators[_gladiatorId].satiation = checkLimitsOfStat(
            gladiators[_gladiatorId].satiation,
            HIGH_AMOUNT,
            MAX_SATIATION,
            true
        );

        gladiators[_gladiatorId].vigor = checkLimitsOfStat(
            gladiators[_gladiatorId].vigor,
            LOW_AMOUNT,
            MAX_VIGOR,
            false
        );

        gladiators[_gladiatorId].hp = checkLimitsOfStat(
            gladiators[_gladiatorId].hp,
            MIN_AMOUNT,
            gladiators[_gladiatorId].max_hp,
            true
        );

        gladiators[_gladiatorId].cooldownTime = safeAdd(now, ACTION_COOLDOWN);
        bank.transferFrom(gladiatorToOwner[_gladiatorId], owner, TRAINING_COST);
        return true;
    }

    // sleep action +vigor +hp -satiation
    function sleep(uint256 _gladiatorId)
        external
        canAfford(_gladiatorId, TRAINING_COST)
        isBusy(_gladiatorId, "Busy Sleeping")
    {
        gladiators[_gladiatorId].vigor = checkLimitsOfStat(
            gladiators[_gladiatorId].vigor,
            HIGH_AMOUNT,
            MAX_VIGOR,
            true
        );

        gladiators[_gladiatorId].satiation = checkLimitsOfStat(
            gladiators[_gladiatorId].satiation,
            LOW_AMOUNT,
            MAX_SATIATION,
            false
        );

        gladiators[_gladiatorId].hp = checkLimitsOfStat(
            gladiators[_gladiatorId].hp,
            STANDARD_AMOUNT,
            gladiators[_gladiatorId].max_hp,
            true
        );

        gladiators[_gladiatorId].cooldownTime = safeAdd(now, ACTION_COOLDOWN);
        bank.transferFrom(gladiatorToOwner[_gladiatorId], owner, TRAINING_COST);
    }

    // +strength +maxhp -vigor -satiation -hp
    function muscleTraining(uint256 _gladiatorId)
        external
        canAfford(_gladiatorId, TRAINING_COST)
        isBusy(_gladiatorId, "Busy Training")
    {
        gladiators[_gladiatorId].strength = checkLimitsOfStat(
            gladiators[_gladiatorId].strength,
            1,
            MAX_STRENGTH,
            true
        );

        gladiators[_gladiatorId].vigor = checkLimitsOfStat(
            gladiators[_gladiatorId].vigor,
            STANDARD_AMOUNT,
            MAX_VIGOR,
            false
        );

        gladiators[_gladiatorId].satiation = checkLimitsOfStat(
            gladiators[_gladiatorId].satiation,
            STANDARD_AMOUNT,
            MAX_SATIATION,
            false
        );

        gladiators[_gladiatorId].hp = checkLimitsOfStat(
            gladiators[_gladiatorId].hp,
            MIN_AMOUNT,
            gladiators[_gladiatorId].max_hp,
            false
        );

        updateMaxHP(_gladiatorId);
        gladiators[_gladiatorId].cooldownTime = safeAdd(now, ACTION_COOLDOWN);
        bank.transferFrom(gladiatorToOwner[_gladiatorId], owner, TRAINING_COST);
    }

    // +stamina +maxhp -vigor -satiation -hp
    function enduranceTraining(uint256 _gladiatorId)
        external
        canAfford(_gladiatorId, TRAINING_COST)
        isBusy(_gladiatorId, "Busy Training")
    {
        gladiators[_gladiatorId].stamina = checkLimitsOfStat(
            gladiators[_gladiatorId].stamina,
            1,
            MAX_STAMINA,
            true
        );

        gladiators[_gladiatorId].vigor = checkLimitsOfStat(
            gladiators[_gladiatorId].vigor,
            STANDARD_AMOUNT,
            MAX_VIGOR,
            false
        );

        gladiators[_gladiatorId].satiation = checkLimitsOfStat(
            gladiators[_gladiatorId].satiation,
            STANDARD_AMOUNT,
            MAX_SATIATION,
            false
        );

        gladiators[_gladiatorId].hp = checkLimitsOfStat(
            gladiators[_gladiatorId].hp,
            MIN_AMOUNT,
            gladiators[_gladiatorId].max_hp,
            false
        );

        updateMaxHP(_gladiatorId);

        gladiators[_gladiatorId].cooldownTime = safeAdd(now, ACTION_COOLDOWN);
        bank.transferFrom(gladiatorToOwner[_gladiatorId], owner, TRAINING_COST);
    }

    // +dexterity +maxhp -vigor -satiation -hp
    function flexibilityTraining(uint256 _gladiatorId)
        external
        canAfford(_gladiatorId, TRAINING_COST)
        isBusy(_gladiatorId, "Busy Training")
    {
        gladiators[_gladiatorId].dexterity = checkLimitsOfStat(
            gladiators[_gladiatorId].dexterity,
            1,
            MAX_DEXTERITY,
            true
        );

        gladiators[_gladiatorId].vigor = checkLimitsOfStat(
            gladiators[_gladiatorId].vigor,
            STANDARD_AMOUNT,
            MAX_VIGOR,
            false
        );

        gladiators[_gladiatorId].satiation = checkLimitsOfStat(
            gladiators[_gladiatorId].satiation,
            STANDARD_AMOUNT,
            MAX_SATIATION,
            false
        );

        gladiators[_gladiatorId].hp = checkLimitsOfStat(
            gladiators[_gladiatorId].hp,
            MIN_AMOUNT,
            gladiators[_gladiatorId].max_hp,
            false
        );
        updateMaxHP(_gladiatorId);
        gladiators[_gladiatorId].cooldownTime = safeAdd(now, ACTION_COOLDOWN);
        bank.transferFrom(gladiatorToOwner[_gladiatorId], owner, 10);
    }

    // when calculating power of gladiator, apply modifier based on health
    function hpStatusModifier(uint256 _gladiatorId)
        internal
        view
        returns (uint256)
    {
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

    // when calculating power of gladiator, apply modifier based on vigor
    // maximum benefit when 50 < vigor < 75
    function vigorStatus(uint256 _gladiatorId) internal view returns (uint256) {
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

    // when calculating power of gladiator, apply modifier based on vigor
    // maximum benefit 60 6050 < satiation < 80
    function satiationStatus(uint256 _gladiatorId)
        internal
        view
        returns (uint256)
    {
        if (gladiators[_gladiatorId].satiation < 10) {
            // The Gladiator is famished -> no benefit to power.
            return 0;
        } else if (
            (gladiators[_gladiatorId].satiation >= 10 &&
                gladiators[_gladiatorId].satiation < 60) ||
            (gladiators[_gladiatorId].satiation > 80 &&
                gladiators[_gladiatorId].satiation <= 100)
        ) {
            // undereating or overeating
            return 1;
        } else {
            // optimal food consumption
            return 2;
        }
    }

    // defence is calulated from stamina and dexterity
    function calcDef(uint256 _gladiatorId) internal view returns (uint256) {
        uint256 def =
            safeAdd(
                safeMul(gladiators[_gladiatorId].stamina, 3),
                safeMul(gladiators[_gladiatorId].dexterity, 2)
            );
        return def;
    }

    // attack is calulated from strength and dexterity
    function calcAtt(uint256 _gladiatorId) internal view returns (uint256) {
        uint256 att =
            safeAdd(
                safeMul(gladiators[_gladiatorId].strength, 3),
                safeMul(gladiators[_gladiatorId].dexterity, 2)
            );
        return att;
    }

    // power is calculater from combination of defence, attack, hp, satiation and vigor values
    function calcPower(uint256 _gladiatorId) internal view returns (uint256) {
        uint256 power =
            safeAdd(
                safeMul(
                    gladiators[_gladiatorId].hp,
                    hpStatusModifier(_gladiatorId)
                ),
                safeAdd(
                    safeMul(calcDef(_gladiatorId), vigorStatus(_gladiatorId)),
                    safeMul(
                        calcAtt(_gladiatorId),
                        satiationStatus(_gladiatorId)
                    )
                )
            );
        return power;
    }

    // reduce stats of gladiator when winning against another players' gladiator
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

    // reduce stats of gladiator when losing against another players' gladiator
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

    // challenging an AI with a simulated gladiators' power value based on the players' gladiator tier
    function fightAI(uint256 _gladiatorId) external {
        uint256 aiPower =
            safeAdd(safeMul(100, gladiators[_gladiatorId].tier), randMod(100));

        uint256 gladPower = calcPower(_gladiatorId);
        // Compare the power of both gladiators.
        if (gladPower > aiPower) {
            bank.transferFrom(owner, gladiators[_gladiatorId].owner, 25);
        } else {
            bank.transferFrom(gladiators[_gladiatorId].owner, owner, 10);
        }
        gladiators[_gladiatorId].cooldownTime = safeAdd(now, ACTION_COOLDOWN);
        emit AIFightStatistics(gladPower, aiPower);
    }

    // invoked when challenging another players' gladiator
    function fight(uint256 _gladiatorId1, uint256 _gladiatorId2)
        external
        isBusy(_gladiatorId2, "Opponent Is Busy")
    {
        // check if both are in the same tier and if opponents' gladiator recently lost
        require(
            gladiators[_gladiatorId2].safetyNetCooldown <= now &&
                gladiators[_gladiatorId1].tier <= gladiators[_gladiatorId2].tier
        );

        // Compare the power of both gladiators.
        if (calcPower(_gladiatorId1) > calcPower(_gladiatorId2)) {
            // invoking players' gladiator won
            gladiators[_gladiatorId2].safetyNetCooldown = safeAdd(
                now,
                ACTION_COOLDOWN
            );

            // increase num of wins, if equal to current tier - advance in tier and reset num of wins, give extra reward when rising in tiers
            // to advance in tiers numWins == current_tier, i.e 3 wins in tier 3 are needed to advance to tier 4
            uint256 numWins = safeAdd(gladiators[_gladiatorId1].wins, 1);
            if (numWins == gladiators[_gladiatorId1].tier) {
                gladiators[_gladiatorId1].wins = 0;
                gladiators[_gladiatorId1].tier = safeAdd(
                    gladiators[_gladiatorId1].tier,
                    1
                );
                bank.transferFrom(
                    owner,
                    gladiators[_gladiatorId1].owner,
                    safeMul(gladiators[_gladiatorId1].tier, 5)
                );
            } else {
                gladiators[_gladiatorId1].wins = numWins;
            }

            handleStatsFromVictory(_gladiatorId1);
            bank.transferFrom(owner, gladiators[_gladiatorId1].owner, 10);
            emit Winner(_gladiatorId1);
        } else {
            // opponent wins

            // if num of wins in the tier is 0 and player losses, demoted to lower tier and doesn't lose gold coins
            // otherwise reduce the num of wins in current tier and lose gold coins
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
                gladiators[_gladiatorId1].owner,
                owner,
                lossAmount
            );
            emit Winner(_gladiatorId2);
        }
        gladiators[_gladiatorId1].cooldownTime = safeAdd(now, ACTION_COOLDOWN);
    }
}
