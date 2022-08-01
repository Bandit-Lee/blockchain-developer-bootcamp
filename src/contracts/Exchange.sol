// Deposit & Withdraw Funds
// Manage Orders - Make Or Cancel
// Handle Trades - Charge fees
pragma solidity ^0.5.16;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./Token.sol";

contract Exchange {
    using SafeMath for uint256;

    // Variables
    address public feeAccount; // The account that recieves exchange fees
    uint256 public feePercent; // The fee percentage
    address constant ETHER = address(0); // Store Ether in tokens mapping with blank address
    /* token address => (user address => number of tokens held by user) */
    mapping(address => mapping(address => uint256)) public tokens;
    mapping(uint256 => _Order) public orders;
    /* just like the auto-increment id  */
    uint256 public orderCount;
    mapping(uint256 => bool) public orderCancelled;
    mapping(uint256 => bool) public orderFilled;

    // Events
    event Deposit(address token, address user, uint256 amount, uint256 balance);
    event Withdraw(
        address token,
        address user,
        uint256 amount,
        uint256 balance
    );
    event Order(
        uint256 id,
        address user,
        address tokenGet,
        uint256 amountGet,
        address tokenGive,
        uint256 amountGive,
        uint256 timestamp
    );
    event Cancel(
        uint256 id,
        address user,
        address tokenGet,
        uint256 amountGet,
        address tokenGive,
        uint256 amountGive,
        uint256 timestamp
    );
    event Trade(
        uint256 id,
        address user,
        address tokenGet,
        uint256 amountGet,
        address tokenGive,
        uint256 amountGive,
        address userFill,
        uint256 timestamp
    );

    // A way to model an order
    struct _Order {
        // Attributes of an order
        uint256 id;
        address user; // User who made the order
        address tokenGet; // Address of the token they want to purchase
        uint256 amountGet; // Amount they want to get
        address tokenGive; // Address of the token they want to give
        uint256 amountGive; // Amount they want to give
        uint256 timestamp; // When the order was created
    }

    constructor(address _feeAccount, uint256 _feePercent) public {
        feeAccount = _feeAccount;
        feePercent = _feePercent;
    }

    // fallback function: reverts if Ether is sent to this smart contract by mistake
    function() external {
        revert();
    }

    // ------------------------
    // DEPOSIT & WITHDRAW ETHER
    function depositEther() public payable {
        tokens[ETHER][msg.sender] = tokens[ETHER][msg.sender].add(msg.value);

        // Emit event
        emit Deposit(ETHER, msg.sender, msg.value, tokens[ETHER][msg.sender]);
    }

    function withdrawEther(uint256 _amount) public {
        // Ensure address as enough Ether
        require(tokens[ETHER][msg.sender] >= _amount);
        tokens[ETHER][msg.sender] = tokens[ETHER][msg.sender].sub(_amount);
        msg.sender.transfer(_amount);
        // Emit event
        emit Withdraw(ETHER, msg.sender, _amount, tokens[ETHER][msg.sender]);
    }

    // ------------------------
    // DEPOSIT & WITHDRAW TOKEN
    function depositToken(address _token, uint256 _amount) public {
        // 将token地址的代币转到 this:这个交易所里也就是这个智能合约里
        // 在此之前需要有Token的approve，否则就会失败
        require(Token(_token).transferFrom(msg.sender, address(this), _amount));
        // Managing deposits - update balance
        tokens[_token][msg.sender] = tokens[_token][msg.sender].add(_amount);
        // Emit event
        emit Deposit(_token, msg.sender, _amount, tokens[_token][msg.sender]);
    }

    function withdrawToken(address _token, uint256 _amount) public {
        // Make sure it is not an Ether address & they have enough tokens to withdraw
        require(_token != ETHER);
        require(tokens[_token][msg.sender] >= _amount);
        // 先扣再转
        tokens[_token][msg.sender] = tokens[_token][msg.sender].sub(_amount);
        // 当前合约转给消息发送者(调用withdraw的人)
        require(Token(_token).transfer(msg.sender, _amount));

        // Emit event
        emit Withdraw(_token, msg.sender, _amount, tokens[_token][msg.sender]);
    }

    // ------------------------
    // GET THE AMOUNT OF THOKENS
    function balanceOf(address _token, address _user)
        public
        view
        returns (uint256)
    {
        return tokens[_token][_user];
    }

    // ------------------------
    // MAKE & CANCEL & FILL ORDERS
    // 买家下订单 msg.sender 为买家
    function makeOrder(
        address _tokenGet, // 要买的token地址
        uint256 _amountGet, // 要买的token的数量
        address _tokenGive, // 支付这个token的地址
        uint256 _amountGive // 支付的数量
    ) public {
        // incr the id
        orderCount = orderCount.add(1);
        orders[orderCount] = _Order(
            orderCount,
            msg.sender,
            _tokenGet,
            _amountGet,
            _tokenGive,
            _amountGive,
            now
        );

        //emit the event
        emit Order(
            orderCount,
            msg.sender,
            _tokenGet,
            _amountGet,
            _tokenGive,
            _amountGive,
            now
        );
    }

    // 买卖双方都可以取消订单
    function cancelOrder(uint256 _id) public {
        // Fetch the order
        _Order storage _order = orders[_id];
        require(address(_order.user) == msg.sender);
        require(_order.id == _id);
        // cancel the order
        orderCancelled[_id] = true;
        emit Cancel(
            _order.id,
            msg.sender,
            _order.tokenGet,
            _order.amountGet,
            _order.tokenGive,
            _order.amountGive,
            now
        );
    }

    // 卖家确认，交付订单，msg.sender 为卖家
    function fillOrder(uint256 _id) public {
        // Ensure order is valid & isn't filled or canceled
        require(_id > 0 && _id <= orderCount);
        require(!orderFilled[_id]);
        require(!orderCancelled[_id]);
        // Fetch the Order
        _Order storage _order = orders[_id];
        // Execute the trade
        _trade(
            _order.id,
            _order.user,
            _order.tokenGet,
            _order.amountGet,
            _order.tokenGive,
            _order.amountGive
        );
        // Mark order as filled
        orderFilled[_order.id] = true;
    }

    // 交易 trade 内部细节
    function _trade(
        uint256 _orderId,
        address _user,
        address _tokenGet,
        uint256 _amountGet,
        address _tokenGive,
        uint256 _amountGive
    ) internal {
        // Fee is paid by the user who filled the order (msg.sender)
        uint256 _feeAmount = _amountGive.mul(feePercent).div(100);
        tokens[_tokenGet][msg.sender] = tokens[_tokenGet][msg.sender].sub(
            _amountGet.add(_feeAmount)
        );
        tokens[_tokenGet][_user] = tokens[_tokenGet][_user].add(_amountGet);
        // Charge fees
        tokens[_tokenGet][feeAccount] = tokens[_tokenGet][feeAccount].add(
            _feeAmount
        );
        tokens[_tokenGive][_user] = tokens[_tokenGive][_user].sub(_amountGive);
        tokens[_tokenGive][msg.sender] = tokens[_tokenGive][msg.sender].add(
            _amountGive
        );

        // Emit trade event
        emit Trade(
            _orderId,
            _user,
            _tokenGet,
            _amountGet,
            _tokenGive,
            _amountGive,
            msg.sender,
            now
        );
    }
}
