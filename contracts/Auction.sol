// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0 <0.9.0;
contract Auction{
    address payable public auctioneer;
    uint public StartTime;  // Start time of the block
    uint public EndTime;   //  End time of the block
    enum AuctionStatus{Started,Running,Ended,Cancelled}
    AuctionStatus public auctionState;
    // uint public HighestBid;
    uint public HighestPayableBid;
    uint public BidIncrement;
    constructor(){
        auctioneer=payable(msg.sender);
        StartTime=block.number;     // Time is denoted in terms of block number
        EndTime=StartTime+240;     //  15 seconds = 1 block so 1 hour = 4*60=240
        auctionState = AuctionStatus.Running;
        BidIncrement = 1 ether;
    }
    address payable public HighestBidder;
    mapping (address=> uint) public bids;
    modifier OnlyAucioneer(){
        require(msg.sender == auctioneer,"Only auctioneer can call this function");
        _;
    }
    modifier Started(){
        require(block.number>StartTime);
        _;
    }
    modifier BeforeEnding(){
        require(block.number<EndTime);
        _;
    }
    function AuctionCancel() public OnlyAucioneer{
        auctionState = AuctionStatus.Cancelled;
    }
    function min(uint n1,uint n2) internal pure returns(uint){
        if(n1>n2) return n2;
        return n1;
    }
    function Bid() payable public BeforeEnding Started {
        require(auctionState == AuctionStatus.Running,"Auction is not in running process");
        require(msg.value>=1);
        uint currentBid = bids[msg.sender]+msg.value;
        require(currentBid>HighestPayableBid);
        bids[msg.sender ]= currentBid;
        if(currentBid<bids[HighestBidder]){
            HighestPayableBid=min(currentBid+BidIncrement,bids[HighestBidder]);
        }
        else{
            HighestPayableBid=min(currentBid,bids[HighestBidder]+BidIncrement);
            HighestBidder=payable(msg.sender);
        }
    }
    function finalizeAuction()public{
        require(auctionState == AuctionStatus.Cancelled ||block.number>EndTime);
        require(msg.sender ==auctioneer || bids[msg.sender]>0);
        address payable person;
        uint value;
        if(auctionState==AuctionStatus.Cancelled){
            person=payable(msg.sender);
            value=bids[msg.sender];
        }
        else{
            if(msg.sender==auctioneer){
                person = auctioneer;
                value = HighestPayableBid;
            }
            else{
                if(msg.sender==HighestBidder){
                    person=HighestBidder;
                    value=bids[HighestBidder]-HighestPayableBid;
                }
                else{
                    person=payable(msg.sender);
                    value=bids[msg.sender];
                }
            }
        }
        bids[msg.sender]=0;
        person.transfer(value);
    }
 
}