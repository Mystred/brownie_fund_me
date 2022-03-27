// SPDX-License-Identifier: MIT

pragma solidity ^0.6.6;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "@chainlink/contracts/src/v0.6/vendor/SafeMathChainlink.sol";

/**
 * @title FundMe
 * @dev Implements functionality to fund this cotract.
 */
contract FundMe {
    using SafeMathChainlink for uint256;

    mapping(address => uint256) public addressToAmountFunded;
    address[] funders;
    address owner;
    AggregatorV3Interface public priceFeed;

    constructor(address _priceFeed) public {
        owner = msg.sender;
        priceFeed = AggregatorV3Interface(_priceFeed);
    }

    /**
     * @dev Function "fund me", that receives some amount that should be funded to this contract.
     */
    function fund() public payable {
        uint256 minimumUSD = 2;

        // Check if amount is above threshold. Otherwise return.
        require(
            getConversionRate(msg.value) >= minimumUSD,
            "You need to spend at least 50$!"
        );
        addressToAmountFunded[msg.sender] += msg.value;

        funders.push(msg.sender);
    }

    function getEntranceFee() public view returns (uint256) {
        //minimumUSD
        uint256 minimumUSD = 2 * 10**18;
        uint256 price = getPrice();
        uint256 precision = 1 * 10**8;
        return (minimumUSD * precision) / price;
    }

    /* @dev Get version of the priceFeed Api. */
    function getVersion() public view returns (uint256) {
        return priceFeed.version();
    }

    /* @dev Get present price via Chainlink priceFeed. */
    function getPrice() public view returns (uint256) {
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        return uint256(answer);
    }

    /* @dev Converts the given amount of Wei to USD. */
    function getConversionRate(uint256 weiAmount)
        public
        view
        returns (uint256)
    {
        return ((getPrice() * weiAmount) / (10**26));
    }

    /* @dev Modifier that requires that sender is owner of this contract. */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /* @dev Function that withdraws funds from the contract. Requires that sender is owner of the contract. */
    function withdraw() public payable onlyOwner {
        msg.sender.transfer(address(this).balance);
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        funders = new address[](0);
    }
}
