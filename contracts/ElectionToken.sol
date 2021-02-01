pragma solidity ^0.5.0;

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
//
// ----------------------------------------------------------------------------
contract ERC20Interface {
    function totalSupply() public view returns (uint);
    function thebalanceOf(address _owner) public view returns (uint256 balance);
    function allowance(address _owner, address _spender) public view returns (uint remaining);
    function transfer(address _to, uint256 _tokens) public returns (bool success);
    function approve(address _spender,uint256 _tokens) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _tokens) public returns (bool success);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

// ----------------------------------------------------------------------------
// Safe Math Library
// ----------------------------------------------------------------------------
contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a,"safe add");
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
    require(b <= a,"safe sub");
        c = a - b;
         }
        function safeMul(uint a, uint b) public pure returns (uint c) {
             c = a * b;
             require(a == 0 || c / a == b,"safe Mul");
             }
        function safeDiv(uint a, uint b) public pure returns (uint c) {
            require(b > 0,"safe div");
        c = a / b;
    }
}


contract ElectionToken is ERC20Interface, SafeMath {
    string public name;
    string public symbol;
    uint8 public decimals; // 18 decimals is the strongly suggested default, avoid changing it
    uint256 public _totalSupply;
    mapping(address => uint256) balanceOf;
    mapping(address => mapping(address => uint256)) allowed;
    /**
     * Constrctor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    constructor() public {
        name = "electionToken";
        symbol = "ET";
        decimals = 18;
        _totalSupply = 1000;
        balanceOf[msg.sender] = _totalSupply;
    }
    function totalSupply() public view returns (uint) {
        return _totalSupply - balanceOf[address(0)];
    }
    function thebalanceOf(address tokenOwner) public view returns (uint256 balance) {
        return balanceOf[tokenOwner];
    }
    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value,"error transfer");

        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;

        emit Transfer(msg.sender, _to, _value);

        return true;
    }
    function transferFrom(address from, address to, uint256 tokens) public returns (bool success) {
        balanceOf[from] = safeSub(balanceOf[from], tokens);
        balanceOf[to] = safeAdd(balanceOf[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }
}