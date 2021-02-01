pragma solidity ^0.5.0;

contract SafeMath {
    function safeAdd(uint256 a, uint256 b) public pure returns (uint256 c) {
        c = a + b;
        require(c >= a, "safe add");
    }

    function safeSub(uint256 a, uint256 b) public pure returns (uint256 c) {
        require(b <= a, "safe sub");
        c = a - b;
    }

    function safeMul(uint256 a, uint256 b) public pure returns (uint256 c) {
        c = a * b;
        require(a == 0 || c / a == b, "safe Mul");
    }

    function safeDiv(uint256 a, uint256 b) public pure returns (uint256 c) {
        require(b > 0, "safe div");
        c = a / b;
    }
}
