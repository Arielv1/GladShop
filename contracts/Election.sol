pragma solidity ^0.5.0;

import "./ElectionToken.sol";

contract Election {
    // Model a Candidate
    struct Candidate {
        uint256 id;
        string name;
        uint256 voteCount;
        string link;
    }

    // Store accounts that have voted
    mapping(address => bool) public voters;
    // Store accounts that allowed to vote
    mapping(bytes32 => bool) public allowed_voters;
    // Read/write candidates
    mapping(uint256 => Candidate) public candidates;

    // Store Candidates Count
    uint256 public candidatesCount;
    // time for end of the election
    uint256 public timeblock = block.timestamp + 555 minutes;

    event votedEvent(uint256 indexed _candidateId);
    /// Token Handle
    address public admin;
    ElectionToken public tokenContract;

    constructor(ElectionToken _hamamiContracrtToken) public {
        admin = msg.sender;
        tokenContract = _hamamiContracrtToken;
        addCandidate(
            "Bibi",
            "https://he.wikipedia.org/wiki/%D7%91%D7%A0%D7%99%D7%9E%D7%99%D7%9F_%D7%A0%D7%AA%D7%A0%D7%99%D7%94%D7%95"
        );
        addCandidate(
            "Gantz",
            "https://he.wikipedia.org/wiki/%D7%91%D7%A0%D7%99_%D7%92%D7%A0%D7%A5"
        );
        addCandidate(
            "Ayman Odeh",
            "https://he.wikipedia.org/wiki/%D7%90%D7%99%D7%99%D7%9E%D7%9F_%D7%A2%D7%95%D7%93%D7%94"
        );
        addCandidate(
            "Amir Peretz",
            "https://he.wikipedia.org/wiki/%D7%A2%D7%9E%D7%99%D7%A8_%D7%A4%D7%A8%D7%A5"
        );
        addCandidate(
            "Yaakov Litzman",
            "https://he.wikipedia.org/wiki/%D7%99%D7%A2%D7%A7%D7%91_%D7%9C%D7%99%D7%A6%D7%9E%D7%9F"
        );
        addCandidate(
            "Aryeh Deri",
            "https://he.wikipedia.org/wiki/%D7%90%D7%A8%D7%99%D7%94_%D7%93%D7%A8%D7%A2%D7%99"
        );
        addCandidate(
            "Naftali Bennett",
            "https://he.wikipedia.org/wiki/%D7%A0%D7%A4%D7%AA%D7%9C%D7%99_%D7%91%D7%A0%D7%98"
        );
        addCandidate(
            "Avigdor Lieberman",
            "https://he.wikipedia.org/wiki/%D7%90%D7%91%D7%99%D7%92%D7%93%D7%95%D7%A8_%D7%9C%D7%99%D7%91%D7%A8%D7%9E%D7%9F"
        );
        setVoter();
    }

    function addCandidate(string memory _name, string memory link) private {
        candidatesCount++;
        candidates[candidatesCount] = Candidate(
            candidatesCount,
            _name,
            0,
            link
        );
    }

    function setVoter() private {
        // With hash // map should be bytes32
        allowed_voters[
            keccak256(
                abi.encodePacked(0xac9Ffd6ED95725965623354a416478c4aD5E236D)
            )
        ] = true; //0
        allowed_voters[
            keccak256(
                abi.encodePacked(0xbe44FAbCb03630BA316D106F442681D96C60f549)
            )
        ] = true; //1
        allowed_voters[
            keccak256(
                abi.encodePacked(0xAA720620E16ec1e43Caa85370607e34FEa437E2C)
            )
        ] = true; //2
        allowed_voters[
            keccak256(
                abi.encodePacked(0x5826747a6d26314eD3Ea4Ae22AF7AD99F6E34af4)
            )
        ] = true; //3
        allowed_voters[
            keccak256(
                abi.encodePacked(0x1009106EFF5346246829d7cf9939b6915B1529e5)
            )
        ] = true; //4
        allowed_voters[
            keccak256(
                abi.encodePacked(0x8ef6066Ba41f5CD44837C460440f76316572B02c)
            )
        ] = true; //5
        allowed_voters[
            keccak256(
                abi.encodePacked(0xCA24b10D7527763D2b56cb9bBeBdc738CFE0D790)
            )
        ] = true; //6
        allowed_voters[
            keccak256(
                abi.encodePacked(0x3A5A14d0fEA07623B857bdF6bb8D464b1BE78C1D)
            )
        ] = true; //7
        allowed_voters[
            keccak256(
                abi.encodePacked(0x8D028e7A4010f485777f382dF6C2a8f1F5e7ACe7)
            )
        ] = true; //8
        // allowed_voters[keccak256(abi.encodePacked(0x9C34ed638d5688177C0B9A573Fb6F2EDdf806637))] = true; //9
    }

    function vote(uint256 _candidateId) public {
        // require that they haven't voted before
        require(!voters[msg.sender], "already voted");

        // require a valid candidate
        require(
            _candidateId > 0 && _candidateId <= candidatesCount,
            "Not a valid candidate"
        );

        // require that time of votes not elapsed
        require(now <= timeblock, "Time to vote elapsed");

        // require that the voter allow to vote
        require(
            allowed_voters[keccak256(abi.encodePacked(msg.sender))],
            "Not allowed to vote"
        );
        // gift token to the account that vote.
        tokenContract.transferFrom(admin, msg.sender, 20);

        // record that voter has voted
        voters[msg.sender] = true;

        // update candidate vote Count
        candidates[_candidateId].voteCount++;

        // trigger voted event
        emit votedEvent(_candidateId);
    }
}
