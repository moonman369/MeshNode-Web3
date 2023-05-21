// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Stack3.sol";

contract Stack3Badges is ERC1155, Ownable {

    uint256 public constant USER = 0;
    uint256 public constant QUESTION_10 = 1;
    uint256 public constant QUESTION_25 = 2;
    uint256 public constant QUESTION_50 = 3;
    uint256 public constant QUESTION_100 = 4;
    uint256 public constant ANSWER_10 = 5;
    uint256 public constant ANSWER_25 = 6;
    uint256 public constant ANSWER_50 = 7;
    uint256 public constant ANSWER_100 = 8;
    uint256 public constant ANSWER_200 = 9;
    uint256 public constant ANSWER_500 = 10;
    uint256 public constant BEST_ANSWER_10 = 11;
    uint256 public constant BEST_ANSWER_50 = 12;
    uint256 public constant BEST_ANSWER_250 = 13;
    uint256 public constant COMMENTS_100 = 14;
    uint256 public constant COMMENTS_500 = 15;
    uint256 public constant UPVOTE_ANSWER_10 = 16;
    uint256 public constant UPVOTE_ANSWER_50 = 17;
    uint256 public constant UPVOTE_ANSWER_100 = 18;
    uint256 public constant UPVOTE_ANSWER_200 = 19;
    uint256 public constant UPVOTE_ANSWER_500 = 20;
    uint256 public constant UPVOTE_QUESTION_10 = 21;
    uint256 public constant UPVOTE_QUESTION_50 = 22;
    uint256 public constant UPVOTE_QUESTION_250 = 23;
    uint256 public constant TAG_REWARDS_START = 24;

    string private s_baseUri;
    uint256 private s_maxTagCount;
    // Stack3 private immutable i_stack3;
    address public s_stack3Address;


    constructor (uint256 _maxTagCount, string memory _baseUri) ERC1155 (_baseUri) {
        // i_stack3 = Stack3(_stack3Address);
        s_maxTagCount = _maxTagCount;
    }

    function setStack3Address(address _stack3Address) external onlyOwner {
        s_stack3Address = _stack3Address;
    } 

    function mintUserBadge (address _user) external {
        require (_verifyCaller(msg.sender), "Stack3Badges: Caller is not Stack3 contract");
        _mint(_user, USER, 1, "");
    }
        

    function updateAndRewardBadges (uint8 _reqType, uint256 _numPost, address _user) external {
        require (_verifyCaller(msg.sender), "Stack3Badges: Caller is not Stack3 contract");
        if (_reqType == 0) {
            // uint256 numQ = i_stack3.getUserByAddress(_user).questions.length;
            if (_numPost == 10) { // Q posts
                _mint(_user, QUESTION_10, 1, "");
            }
            else if (_numPost == 25) {
                _mint(_user, QUESTION_25, 1, "");
            }
            else if (_numPost == 50) {
                _mint(_user, QUESTION_50, 1, "");
            }
            else if (_numPost == 100) {
                _mint(_user, QUESTION_100, 1, "");
            }
        }

        else if (_reqType == 1) { // Q vote
            if (_numPost == 10) {
                _mint(_user, UPVOTE_QUESTION_10, 1, "");
            }
            else if (_numPost == 50) {
                _mint(_user, UPVOTE_QUESTION_50, 1, "");
            }
            else if (_numPost == 250) {
                _mint(_user, UPVOTE_QUESTION_250, 1, "");
            }
        }

        else if (_reqType == 2) { // A post
            // uint256 numA = i_stack3.getUserByAddress(_user).answers.length;
            // uint256 bestAnswerCount = i_stack3.getUserByAddress(_user).bestAnswerCount;
            if (_numPost == 10) {
                _mint(_user, ANSWER_10, 1, "");
            }
            else if (_numPost == 25) {
                _mint(_user, ANSWER_25, 1, "");
            }
            else if (_numPost == 50) {
                _mint(_user, ANSWER_50, 1, "");
            }
            else if (_numPost == 100) {
                _mint(_user, ANSWER_100, 1, "");
            }
            else if (_numPost == 200) {
                _mint(_user, ANSWER_200, 1, "");
            }
            else if (_numPost == 500) {
                _mint(_user, ANSWER_500, 1, "");
            }    
        }

        else if (_reqType == 3) { // A vote
            if (_numPost == 10) {
                _mint(_user, UPVOTE_ANSWER_10, 1, "");
            }
            else if (_numPost == 50) {
                _mint(_user, UPVOTE_ANSWER_50, 1, "");
            }
            else if (_numPost == 100) {
                _mint(_user, UPVOTE_ANSWER_100, 1, "");
            }
            else if (_numPost == 200) {
                _mint(_user, UPVOTE_ANSWER_200, 1, "");
            }
            else if (_numPost == 500) {
                _mint(_user, UPVOTE_ANSWER_500, 1, "");
            }
        }

        else if (_reqType == 4) {
            if (_numPost == 10) {
                _mint(_user, BEST_ANSWER_10, 1, "");
            }
            else if (_numPost == 50) {
                _mint(_user, BEST_ANSWER_50, 1, "");
            }
            else if (_numPost == 250) {
                _mint(_user, BEST_ANSWER_250, 1, "");
            }
        }

        else {
            // uint256 numC = i_stack3.getUserByAddress(_user).comments.length;
            if (_numPost == 100) {
                _mint(_user, COMMENTS_100, 1, "");
            }
            else if (_numPost == 50) {
                _mint(_user, COMMENTS_500, 1, "");
            }
        }
    }

    function updateAndRewardTagBadges (uint256 _tagId, uint256 _numTag, address _user/*, bytes32 _secret*/) external {
        // require(_verifySecret(_secret), "Stack3Badges: Unverified source of call");
        require (_verifyCaller(msg.sender), "Stack3Badges: Caller is not Stack3 contract");
        require (_tagId < s_maxTagCount, "Stack3Badges: Invalid tag id");
        if (_numTag == 100) {
            _mint(_user, TAG_REWARDS_START + _tagId, 1, "");
        }
    }

    function _verifyCaller (address _caller) internal view returns (bool) {
        return _caller == s_stack3Address;
    }

    function getUserBadges (address _user) public view returns (uint256 [] memory) {
        uint256 [] memory owned = new uint256 [] (TAG_REWARDS_START + s_maxTagCount);
        uint256 count = 0;
        for (uint256 i = 1; i <= (TAG_REWARDS_START + s_maxTagCount); i++) {
            if (balanceOf(_user, i) > 0) {
                owned[count++] = i;
                // count++;
            }
        }

        return owned;
    }

    // function devMint() public onlyOwner {
    //     _mint(msg.sender, 1, 1, "");
    //     _mint(msg.sender, 5, 1, "");
    //     _mint(msg.sender, 10, 1, "");
    //     _mint(msg.sender, 20, 1, "");
    //     _mint(msg.sender, 25, 1, "");
    // } 

    // function getSender() public view returns (address) {
    //     return msg.sender;
    // }


}