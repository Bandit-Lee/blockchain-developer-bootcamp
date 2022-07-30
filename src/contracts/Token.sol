pragma solidity ^0.5.16;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";

// Based on EIP-20 standard
// -------------------------------------------------------
// totalSupply - get the total token supply
// balanceOf - get the account balance of account address
// transfer - send amount of tokens
// transferFrom - define where the tokens are transfering from
// approve - allow tokens to be withdrawn from sending address
// allowance - returns the remaining tokens of the address
// --------------------------------------------------------
contract Token {
    using SafeMath for uint256;
    // Variables
    string public name = "DApp Token";
    string public symbol = "DApp";
    uint256 public decimals = 18;
    uint256 public totalSupply;
    // mapping solidty 会生成一个与这个名字一样的函数
    mapping(address => uint256) public balanceOf; // 账户余额
    mapping(address => mapping(address => uint256)) public allowance; // 用户能让交易所代理转账的金额

    // Events
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    constructor() public {
        totalSupply = 1000000 * (10**decimals);
        balanceOf[msg.sender] = totalSupply;
    }

    // Internal tranfer function
    function _transfer(
        address _from,
        address _to,
        uint256 _value
    ) internal {
        require(_to != address(0));
        balanceOf[_from] = balanceOf[_from].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        // trigger the event
        emit Transfer(_from, _to, _value);
    }

    // msg.sender transfer by himself/herself
    function transfer(address _to, uint256 _value)
        public
        returns (bool success)
    {
        require(balanceOf[msg.sender] >= _value);
        _transfer(msg.sender, _to, _value);
        return true;
    }

    // Allows _spender to withdraw from your account
    function approve(address _spender, uint256 _value)
        public
        returns (bool success)
    {
        require(_spender != address(0));
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    // transfer tokens by an exchange
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool success) {
        require(_value <= balanceOf[_from]);
        require(_value <= allowance[_from][msg.sender]);
        // the from account sub the value that transfer to the to account
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        _transfer(_from, _to, _value);
        return true;
    }
}
