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
    }

    event recruitedGladiatorEvent(uint256 indexed gladiatorId);

    uint256 randNonce = 0;
    uint256 public numGladiators = 0;
    address public owner;
    ERC20 public tokens = new ERC20();
    Gladiator[] public gladiators;
    // GoldCoinToken public money = new GoldCoinToken();

    mapping(uint256 => address) public gladiatorToOwner;
    mapping(address => uint256) public ownerToGladiator;

    modifier onlyOwnerOf(uint256 _gladiatorId) {
        require(msg.sender == gladiatorToOwner[_gladiatorId]);
        _;
    }

    modifier onlyOwner(address _owner) {
        require(owner == _owner);
        _;
    }

    constructor(ERC20 _tokens) public {
        owner = msg.sender;
        tokens = _tokens;
    }

    /*function setWallet() public {
        money = new GoldCoinToken();
    }*/

    function randMod(uint256 _modulus) internal returns (uint256) {
        randNonce++;
        return
            uint256(keccak256(abi.encodePacked(now, msg.sender, randNonce))) %
            _modulus;
    }

    function recruiteGladiator(address _owner, string memory _name)
        public
    //onlyOwner(_owner)
    {
        uint256 vigor = randMod(100);
        uint256 satiation = randMod(100);
        uint256 stamina = randMod(10);
        uint256 strength = randMod(10);
        uint256 dexterity = randMod(10);
        uint256 max_hp = randMod(100);
        uint256 hp = max_hp;
        //gladiators[numGladiators] = Gladiator(1, _name, hp, stamina, att, def);
        uint256 id =
            gladiators.push(
                Gladiator(
                    _name,
                    1,
                    hp,
                    max_hp,
                    stamina,
                    strength,
                    dexterity,
                    vigor,
                    satiation
                )
            ) - 1;
        gladiatorToOwner[id] = _owner;
        ownerToGladiator[_owner] = id;
        _mint(_owner, id);
    }

    function compare_strings(string memory a, string memory b)
        public
        returns (bool)
    {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }

    function update_score(uint256 res, uint256 max) public returns (uint256) {
        if (res < 0) {
            return 0;
        } else if (res > max) {
            return max;
        } else {
            return res;
        }
    }

    function type_to_update(
        uint256 _gladiatorId,
        uint256 amount,
        string memory _name
    ) public returns (uint256) {
        uint256 res;
        uint256 max;
        if (compare_strings(_name, "hp")) {
            res = safeAdd(gladiators[_gladiatorId].hp, amount);
            max = gladiators[_gladiatorId].max_hp;
            return update_score(res, max);
        }
        if (compare_strings(_name, "stamina")) {
            res = safeAdd(gladiators[_gladiatorId].stamina, amount);
            return update_score(res, MAX_STAMINA);
        }
        if (compare_strings(_name, "strength")) {
            res = safeAdd(gladiators[_gladiatorId].strength, amount);
            return update_score(res, MAX_STRENGTH);
        }
        if (compare_strings(_name, "dexterity")) {
            res = safeAdd(gladiators[_gladiatorId].dexterity, amount);
            return update_score(res, MAX_DEXTERITY);
        }
        if (compare_strings(_name, "vigor")) {
            res = safeAdd(gladiators[_gladiatorId].vigor, amount);
            return update_score(res, MAX_VIGOR);
        } else {
            //satiation
            res = safeAdd(gladiators[_gladiatorId].satiation, amount);
            return update_score(res, MAX_SATIATION);
        }
    }

    function eat(uint256 _gladiatorId) public {
        //gladiators[_gladiatorId].hp = 2000;
        gladiators[_gladiatorId].satiation = safeAdd(
            HIGH_AMOUNT,
            gladiators[_gladiatorId].satiation
        );
        /*gladiators[_gladiatorId].satiation = type_to_update(
            _gladiatorId,
            HIGH_AMOUNT,
            "satiation"
        );
        gladiators[_gladiatorId].vigor = type_to_update(
            _gladiatorId,
            -LOW_AMOUNT,
            "vigor"
        );
        gladiators[_gladiatorId].hp = type_to_update(
            _gladiatorId,
            MIN_AMOUNT,
            "hp"
        );*/
    }

    /*  function recruitGladiator() public {
        uint256 id = gladiators.push(Gladiator(1, "Ivan", 1, 1, 1, 1, 1)) - 1;

        emit recruitedGladiatorEvent(id);
    }*/

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
}
