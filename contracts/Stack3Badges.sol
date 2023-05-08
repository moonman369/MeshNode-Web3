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

    string private s_baseUri;
    // Stack3 private immutable i_stack3;


    constructor (string memory _baseUri) ERC1155 (_baseUri) {
        // i_stack3 = Stack3(_stack3Address);
    }

    function mintUserBadge (address _user) external {
        _mint(_user, USER, 1, "");
    }
        

    function updateAndRewardBadges (uint8 _postType, uint256 _numPost, uint256 _numBest, address _user) external {
        if (_postType == 0) {
            // uint256 numQ = i_stack3.getUserByAddress(_user).questions.length;
            if (_numPost == 10) {
                _mint(_user, QUESTION_10, 1, "");
            }
            else if (_numPost == 25) {
                _mint(_user, QUESTION_25, 1, "");
            }
            else if (_numPost == 50) {
                _mint(_user, QUESTION_25, 1, "");
            }
            else if (_numPost == 100) {
                _mint(_user, QUESTION_100, 1, "");
            }
        }

        else if (_postType == 1) {
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

            if (_numBest == 10) {
                _mint(_user, BEST_ANSWER_10, 1, "");
            }
            else if (_numBest == 50) {
                _mint(_user, BEST_ANSWER_50, 1, "");
            }
            else if (_numBest == 250) {
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

}