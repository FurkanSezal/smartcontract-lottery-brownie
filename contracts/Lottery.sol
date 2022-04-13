pragma solidity ^0.6.6;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.6/VRFConsumerBase.sol";

contract Lottery is VRFConsumerBase, Ownable {
    address payable[] public players;
    uint256 usdEntryFee = 50;
    uint256 public fee;
    bytes32 public keyhash;
    address payable public recentWinner;

    AggregatorV3Interface internal ethUsdPriceFeed;
    enum LOTTERY_STATE {
        OPEN,
        CLOSED,
        CALCULATING_WINNER
    }
    LOTTERY_STATE public lottery_state;

    constructor(
        address _priceFeedAddress,
        address _vrfCoordinator,
        address _link,
        bytes32 _keyHash,
        uint256 _fee
    ) public VRFConsumerBase(_vrfCoordinator, _link) {
        ethUsdPriceFeed = AggregatorV3Interface(_priceFeedAddress);
        lottery_state = LOTTERY_STATE.CLOSED;
        fee = _fee;
        keyhash = _keyHash;
    }

    function start_lottery() public {
        require(
            lottery_state == LOTTERY_STATE.CLOSED,
            "The Lottery hasnt start yet!"
        );
        lottery_state = LOTTERY_STATE.OPEN;
    }

    function getEnteranceFee() public returns (uint256) {
        (, int256 price, , , ) = ethUsdPriceFeed.latestRoundData();
        uint256 adjusted_price = uint256(price) * 10**10;
        uint256 costToEnter = (usdEntryFee * 10**18) / adjusted_price;
        return costToEnter;
    }

    function enter() public payable {
        require(
            lottery_state == LOTTERY_STATE.OPEN,
            "The Lottery doesnt start yet!"
        );
        require(msg.value >= getEnteranceFee(), "Not enough ETH!");
        players.push(msg.sender);
    }

    function end_lottery() public onlyOwner {
        lottery_state = LOTTERY_STATE.CALCULATING_WINNER;
        requestRandomness(keyhash, fee);
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness)
        internal
        override
    {
        require(
            lottery_state == LOTTERY_STATE.CALCULATING_WINNER,
            "You arent there yet!"
        );

        uint256 recentWinnerIndex = randomness % players.length;
        recentWinner = players[recentWinnerIndex];
        recentWinner.transfer(address(this).balance);
        players = new address payable[](0);
        lottery_state = LOTTERY_STATE.CLOSED;
    }
}
