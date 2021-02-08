pragma solidity ^0.5.0;

import "./ERC721.sol";
import "./ERC20.sol";

contract CryptoGame is ERC721 {
    uint256 constant LEVEL_UP = 1;
    uint256 constant MIN_AMOUNT = 5;
    uint256 constant LOW_AMOUNT = 10;
    uint256 constant STANDARD_AMOUNT = 20;
    uint256 constant HIGH_AMOUNT = 25;

    uint256 constant MAX_LEVEL = 20;
    uint256 constant MAX_STAMINA = 50;
    uint256 constant MAX_STRENGTH = 50;
    uint256 constant MAX_DEXTERITY = 50;
    uint256 constant MAX_VIGOR = 100;
    uint256 constant MAX_SATIATION = 100;

    struct Gladiator {
        string name;
        uint256 level;
        uint256 hp;
        uint256 max_hp;
        uint256 stamina;
        uint256 strength;
        uint256 dexterity;
        uint256 vigor;
        uint256 satiation;
        address boss;
        uint256 cooldownTime;
    }

    uint256 randNonce = 0;
    uint256 public numGladiators = 0;
    address public owner;
    uint256 public arenaTime;

    Gladiator[] public gladiators;
    Gladiator[] public gladiatorsForArena;
    ERC20 public bank;

    mapping(uint256 => address) public gladiatorToOwner;
    mapping(address => uint256) public ownerToGladiator;

    event Winner(uint256 _winnerId);

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

    modifier isBusy(uint256 _id) {
        require(gladiators[_id].cooldownTime <= now);
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

    function getMyGladiator(address _owner) public returns (uint256) {
        return ownerToGladiator[_owner];
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
                    safeAdd(1, randMod(_maxHp)),
                    _maxHp,
                    _stamina,
                    _strength,
                    _dexterity,
                    randMod(100),
                    randMod(100),
                    _owner,
                    now
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
    function updateMaxHP(uint256 _gladiatorId) public {
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
        public
        canAfford(_gladiatorId, 10)
        isBusy(_gladiatorId)
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
        public
        canAfford(_gladiatorId, 10)
        isBusy(_gladiatorId)
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
        public
        canAfford(_gladiatorId, 10)
        isBusy(_gladiatorId)
    {
        // cost - ingame currency
        // time - add a hour for each use.

        gladiators[_gladiatorId].strength = checkLimits(
            gladiators[_gladiatorId].strength,
            LEVEL_UP,
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
        public
        canAfford(_gladiatorId, 10)
        isBusy(_gladiatorId)
    {
        // cost - ingame currency
        // time - add a hour for each use.

        gladiators[_gladiatorId].stamina = checkLimits(
            gladiators[_gladiatorId].stamina,
            LEVEL_UP,
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
        public
        canAfford(_gladiatorId, 10)
        isBusy(_gladiatorId)
    {
        // cost - ingame currency
        // time - add a hour for each use.
        gladiators[_gladiatorId].dexterity = checkLimits(
            gladiators[_gladiatorId].dexterity,
            LEVEL_UP,
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

    function hpStatusModifier(uint256 _gladiatorId) public returns (uint256) {
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

    function vigorStatus(uint256 _gladiatorId) public returns (uint256) {
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

    function satiationStatus(uint256 _gladiatorId) public returns (uint256) {
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

    function calcDef(uint256 _gladiatorId) public returns (uint256) {
        uint256 def =
            safeAdd(
                safeMul(gladiators[_gladiatorId].stamina, 3),
                safeMul(gladiators[_gladiatorId].dexterity, 2)
            );
        return def;
    }

    function calcAtt(uint256 _gladiatorId) public returns (uint256) {
        uint256 att =
            safeAdd(
                safeMul(gladiators[_gladiatorId].strength, 3),
                safeMul(gladiators[_gladiatorId].dexterity, 2)
            );
        return att;
    }

    function calcPower(uint256 _gladiatorId) public returns (uint256) {
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

    function fight(uint256 _gladiatorId1, uint256 _gladiatorId2) public {
        // Compare the power of both gladiators.
        if (calcPower(_gladiatorId1) < calcPower(_gladiatorId2)) {
            // player 2 wins!
            //delete gladiatorsForArena[_gladiatorId1];
            emit Winner(_gladiatorId2);
        } else {
            // // player 1 wins!

            emit Winner(_gladiatorId1);
        }
    }

    function signInForArena(uint256 _gladiatorId)
        public
        canAfford(_gladiatorId, 10)
        isBusy(_gladiatorId)
    {
        gladiatorsForArena.push(gladiators[_gladiatorId]);
        bank.transferFrom(gladiatorToOwner[_gladiatorId], owner, 10);
    }

    function prepArenaParticipants() public {
        // assume 8 gladiators participate
        // cost - ingame currency

        for (uint256 i = gladiatorsForArena.length + 1; i < 8; i++) {
            uint256 vigor = randMod(100);
            uint256 satiation = randMod(100);
            uint256 stamina = randMod(10);
            uint256 strength = randMod(10);
            uint256 dexterity = randMod(10);
            uint256 max_hp = randMod(100);
            uint256 hp = max_hp;
            gladiatorsForArena.push(
                Gladiator(
                    "Bot",
                    1,
                    hp,
                    max_hp,
                    stamina,
                    strength,
                    dexterity,
                    vigor,
                    satiation,
                    owner,
                    now
                )
            );
        }
    }

    function arenaRound(uint256 _round) public {
        if (_round == 1) {
            for (uint256 i = 0; i < gladiatorsForArena.length; i += 2) {
                fight(i, i + 1);
            }
        }
    }

    // testing stuff: will be deleted
    function uintToString(uint256 v, bool scientific)
        public
        pure
        returns (string memory str)
    {
        if (v == 0) {
            return "0";
        }

        uint256 maxlength = 100;
        bytes memory reversed = new bytes(maxlength);
        uint256 i = 0;

        while (v != 0) {
            uint256 remainder = v % 10;
            v = v / 10;
            reversed[i++] = bytes1(uint8(48 + remainder));
        }

        uint256 zeros = 0;
        if (scientific) {
            for (uint256 k = 0; k < i; k++) {
                if (reversed[k] == "0") {
                    zeros++;
                } else {
                    break;
                }
            }
        }

        uint256 len = i - (zeros > 2 ? zeros : 0);
        bytes memory s = new bytes(len);
        for (uint256 j = 0; j < len; j++) {
            s[j] = reversed[i - j - 1];
        }

        str = string(s);

        if (scientific && zeros > 2) {
            str = string(abi.encodePacked(s, "e", uintToString(zeros, false)));
        }
    }

    function test_safeAdd(uint256 a, uint256 b) public {
        string memory result = uintToString(safeAdd(a, b), true);
        require(false, result);
    }

    function test_safeSub(uint256 a, uint256 b) public {
        string memory result = uintToString(safeSub(a, b), true);
        require(false, result);
    }

    function test_safeMul(uint256 a, uint256 b) public {
        string memory result = uintToString(safeMul(a, b), true);
        require(false, result);
    }

    function test_safeDiv(uint256 a, uint256 b) public {
        string memory result = uintToString(safeDiv(a, b), true);
        require(false, result);
    }

    function test_calc_power(uint256 _gladiatorId) public {
        string memory result = uintToString(calcPower(_gladiatorId), true);
        require(false, result);
    }

    function test_delete() public {
        delete gladiatorsForArena[0];
    }
}
