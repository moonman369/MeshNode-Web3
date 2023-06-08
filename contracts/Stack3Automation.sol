// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Stack3.sol";
import "./Stack3RareMintNFT.sol";

contract Stack3Automation is VRFConsumerBaseV2, KeeperCompatibleInterface, Ownable {

    event RewardClaimed (uint256 indexed timestamp, uint256 indexed id, address indexed winner);

    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;


    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    uint64 private immutable i_subscriptionId;
    bytes32 private immutable i_gasLane;
    uint32 private immutable i_callbackGasLimit;
    
    uint256 private immutable i_rareMintDropInterval;
    Stack3RareMintNFT private immutable i_rareNft;
    Stack3 private immutable i_stack3;
    uint256 private s_lastUpkeepTimestamp;
    uint256 private s_randomRewardsMaxSupply;
    mapping (address => bool) s_rareMintRewarded;
    mapping (address => bool) s_unclaimedPresent;
    mapping (address => uint256) public s_userToRareTokenId;
    // mapping (address => bool) s_claimed;
    address [] private s_winners;
    // bool s_allCurrentlyRewarded;
    uint256 [] s_randomWords;

    uint256 public s_randomRewardsCounter;

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
        address [] memory users = i_stack3.getAllUserAddresses();

        bool timePassed = block.timestamp > (s_lastUpkeepTimestamp + i_rareMintDropInterval);
        bool noUsers = users.length == 0;
        bool rareSupplyExists = s_randomRewardsCounter < i_rareNft.getTotalSupply() - 1;
        bool maxDropExceeded = s_randomRewardsCounter < s_randomRewardsMaxSupply;
        bool allCurrentlyRewarded = true;

        for (uint256 i=0; i < users.length; i++) {
            if (i_rareNft.balanceOf(users[i]) < 1) {
                allCurrentlyRewarded = false;
                break;
            }
        }

        upkeepNeeded = timePassed && 
                        maxDropExceeded && 
                        !allCurrentlyRewarded && 
                        !noUsers && 
                        rareSupplyExists;

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

        uint256 random = randomWords[0];

        address [] memory users = i_stack3.getAllUserAddresses();
        uint256 index = uint256(keccak256(abi.encodePacked(random, block.timestamp))) % users.length;
        
        unchecked {
            for (uint256 i = 0; i < 10; ) {
                random /= 10;
                index = uint256(keccak256(abi.encodePacked(random, i, block.timestamp))) % users.length;
                if (!s_rareMintRewarded[users[index]] && i_rareNft.balanceOf(users[index]) < 1) {
                    break;
                }
                i++;
            }
        }
        
        if (i_rareNft.balanceOf(users[index]) < 1) {
            s_winners.push(users[index]);
            s_unclaimedPresent[users[index]] = true;
            s_rareMintRewarded[users[index]] = true;
            s_userToRareTokenId[users[index]] = s_randomRewardsCounter + 1;
            s_randomRewardsCounter++;
        }
    }


    function checkForUnclaimedRewards (address _user) public view returns (bool) {
        require (_user != address(0), "Stack3RareMintNFT: Cannot reward null address");   
        return s_unclaimedPresent[_user];
    }

    function claimReward(address _user) external {
        require (checkForUnclaimedRewards(_user), "Stack3RareMintNFT: No claimable rewards found.");

        s_unclaimedPresent[_user] = false;

        s_rareMintRewarded[_user] = true;
        // s_userToRareTokenId[_user] = s_randomRewardsCounter;
        i_rareNft.transferFrom(
            i_rareNft.collectionMintAddress(), 
            _user, 
            s_userToRareTokenId[_user]
        );

        emit RewardClaimed(block.timestamp, s_randomRewardsCounter, _user);
    }

    function getLatestWinners () public view returns (address [] memory) {
        return s_winners;
    }

    function getTimeTillNextUpkeep () public view returns (int256) {
        return int256(i_rareMintDropInterval - (block.timestamp - s_lastUpkeepTimestamp));
    }
}