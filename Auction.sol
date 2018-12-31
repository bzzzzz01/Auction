pragma solidity 0.4.22;

contract Auction {
    address public beneficiary; //拍主地址
    uint public auctionEnd; //拍卖时长
    address public highestBidder; //最高拍者
    uint public highestBid; //最高拍价

    mapping(address => uint) pendingReturns; //之前出价
    bool ended; //拍卖状态

	//事件
    event HighestBidIncreased(address bidder, uint amount);
    event AuctionEnded(address winner, uint amount);

	//拍卖
    constructor(
        uint _biddingTime,
        address _beneficiary
    ) public {
        beneficiary = _beneficiary;
        auctionEnd = now + _biddingTime;
    }

    //出价
    function bid() public payable {
		//出价前提
		//时间前提
        require(
            now <= auctionEnd,
            "Auction ended."
        );
		//价格前提
        require(
            msg.value > highestBid,
            "Low bid."
        );

		//储存之前出价
        if (highestBid != 0) {
            pendingReturns[highestBidder] += highestBid;
        }
        highestBidder = msg.sender;
        highestBid = msg.value;
        emit HighestBidIncreased(msg.sender, msg.value);
    }

    //取回出价
    function withdraw() public returns (bool) {
        uint amount = pendingReturns[msg.sender];
        if (amount > 0) {
            pendingReturns[msg.sender] = 0;
            if (!msg.sender.send(amount)) {
                pendingReturns[msg.sender] = amount;
                return false;
            }
        }
        return true;
    }

    //结束拍卖
    function auctionEnd() public {
        //结束前提
        require(now >= auctionEnd, "Time limit.");
        require(!ended, "Already ended.");

        //改变状态
        ended = true;
        emit AuctionEnded(highestBidder, highestBid);

        //拍主得钱
        beneficiary.transfer(highestBid);
    }
}
