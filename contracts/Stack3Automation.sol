// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Stack3.sol";
import "./Stack3RareMintNFT.sol";

contract Stack3Automation is VRFConsumerBaseV2, KeeperCompatibleInterface, Ownable {


    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    uint64 private immutable i_subscriptionId;
    bytes32 private immutable i_gasLane;
    uint32 private immutable i_callbackGasLimit;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 5;

    uint256 private immutable i_rareMintDropInterval;
    Stack3RareMintNFT private immutable i_rareNft;
    Stack3 private immutable i_stack3;
    uint256 private s_lastUpkeepTimestamp;
    uint256 private s_randomRewardsMaxSupply;
    mapping (address => bool) s_rareMintReceived;

    uint256 private s_randomRewardsCounter;
    

    constructor(
        address vrfCoordinatorV2,
        uint64 subscriptionId,
        bytes32 gasLane, // keyHash
        uint32 callbackGasLimit,
        uint256 _rareMintDropInterval,
        uint256 _randomRewardsMaxSupply,
        address _rareNftAddress,
        address _stack3Address
    ) VRFConsumerBaseV2(vrfCoordinatorV2) {
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        i_rareMintDropInterval = _rareMintDropInterval;
        i_rareNft = Stack3RareMintNFT(_rareNftAddress);
        i_stack3 = Stack3(_stack3Address);
        s_lastUpkeepTimestamp = block.timestamp;
        s_randomRewardsMaxSupply = _randomRewardsMaxSupply;
    }

    function checkUpkeep(
        bytes memory /* checkData */
    )
        public
        view
        override
        returns (bool upkeepNeeded, bytes memory /* performData */)
    {
        bool timePassed = block.timestamp > (s_lastUpkeepTimestamp + i_rareMintDropInterval);
        bool canDropRandom = s_randomRewardsCounter < s_randomRewardsMaxSupply;
        upkeepNeeded = timePassed && canDropRandom;
        return (upkeepNeeded, "0x0");
    }


    function performUpkeep(
        bytes calldata /* performData */
    ) external override {

        (bool upkeepNeeded, ) = checkUpkeep("");

        if(upkeepNeeded) {
            i_vrfCoordinator.requestRandomWords(
                i_gasLane,
                i_subscriptionId,
                REQUEST_CONFIRMATIONS,
                i_callbackGasLimit,
                NUM_WORDS
            );

            s_lastUpkeepTimestamp = block.timestamp;
        }
        

    }


    function fulfillRandomWords(
        uint256, /* requestId */
        uint256[] memory randomWords
    ) internal override {

        address [] memory topUsers = i_stack3.getTopUsers();
        
        for (uint256 i = 0; i < randomWords.length; i++) {
            address winner = topUsers[randomWords[i] % topUsers.length];

            if(!s_rareMintReceived[winner] && i_rareNft.balanceOf(winner) <= 3) {
                address collection = i_rareNft.collectionMintAddress();
                s_rareMintReceived[winner] = true;
                i_rareNft.transferFrom(collection, winner, s_randomRewardsCounter++);

            }
        }
    }


    

}