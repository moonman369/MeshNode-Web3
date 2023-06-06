// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./Stack3.sol";

contract Stack3Badges is ERC1155, Ownable {
    using Strings for uint256;

    uint256 public constant USER = 0;
    uint256 public constant QUESTION_5 = 1;
    uint256 public constant QUESTION_10 = 2;
    uint256 public constant QUESTION_15 = 3;

    uint256 public constant ANSWER_5 = 4;
    uint256 public constant ANSWER_10 = 5;
    uint256 public constant ANSWER_15 = 6;

    uint256 public constant BEST_ANSWER_5 = 7;
    uint256 public constant BEST_ANSWER_10 = 8;
    uint256 public constant BEST_ANSWER_15 = 9;

    uint256 public constant COMMENTS_5 = 10;
    uint256 public constant COMMENTS_10 = 11;
    uint256 public constant COMMENTS_15 = 12;

    uint256 public constant UPVOTE_QUESTION_5 = 13;
    uint256 public constant UPVOTE_QUESTION_10 = 14;
    uint256 public constant UPVOTE_QUESTION_15 = 15;

    uint256 public constant UPVOTE_ANSWER_5 = 16;
    uint256 public constant UPVOTE_ANSWER_10 = 17;
    uint256 public constant UPVOTE_ANSWER_15 = 18;

    uint256 public constant TAG_REWARDS_START = 19;

    string private s_baseUri;
    uint256 private s_maxTagId;
    // Stack3 private immutable i_stack3;
    address public s_stack3Address;

    constructor(uint256 _maxTagId, string memory _baseUri) ERC1155(_baseUri) {
        // i_stack3 = Stack3(_stack3Address);
        s_maxTagId = _maxTagId;
        s_baseUri = _baseUri;
    }

    function setStack3Address(address _stack3Address) external onlyOwner {
        s_stack3Address = _stack3Address;
    }

    function mintUserBadge(address _user) external {
        require(
            _verifyCaller(msg.sender),
            "Stack3Badges: Caller is not Stack3 contract"
        );
        _mint(_user, USER, 1, "");
    }

    function updateAndRewardBadges(
        uint8 _reqType,
        uint256 _numPost,
        address _user
    ) external {
        require(
            _verifyCaller(msg.sender),
            "Stack3Badges: Caller is not Stack3 contract"
        );
        if (_reqType == 0) {
            // uint256 numQ = i_stack3.getUserByAddress(_user).questions.length;
            if (_numPost == 5) {
                // Q posts
                _mint(_user, QUESTION_5, 1, "");
            } else if (_numPost == 10) {
                _mint(_user, QUESTION_10, 1, "");
            } else if (_numPost == 15) {
                _mint(_user, QUESTION_15, 1, "");
            }
        } else if (_reqType == 1) {
            // Q vote
            if (_numPost == 5) {
                _mint(_user, UPVOTE_QUESTION_5, 1, "");
            } else if (_numPost == 10) {
                _mint(_user, UPVOTE_QUESTION_10, 1, "");
            } else if (_numPost == 15) {
                _mint(_user, UPVOTE_QUESTION_15, 1, "");
            }
        } else if (_reqType == 2) {
            // A post
            // uint256 numA = i_stack3.getUserByAddress(_user).answers.length;
            // uint256 bestAnswerCount = i_stack3.getUserByAddress(_user).bestAnswerCount;
            if (_numPost == 5) {
                _mint(_user, ANSWER_5, 1, "");
            } else if (_numPost == 10) {
                _mint(_user, ANSWER_10, 1, "");
            } else if (_numPost == 15) {
                _mint(_user, ANSWER_15, 1, "");
            }
        } else if (_reqType == 3) {
            // A vote
            if (_numPost == 5) {
                _mint(_user, UPVOTE_ANSWER_5, 1, "");
            } else if (_numPost == 10) {
                _mint(_user, UPVOTE_ANSWER_10, 1, "");
            } else if (_numPost == 15) {
                _mint(_user, UPVOTE_ANSWER_15, 1, "");
            }
        } else if (_reqType == 4) {
            if (_numPost == 5) {
                _mint(_user, BEST_ANSWER_5, 1, "");
            } else if (_numPost == 10) {
                _mint(_user, BEST_ANSWER_10, 1, "");
            } else if (_numPost == 15) {
                _mint(_user, BEST_ANSWER_15, 1, "");
            }
        } else {
            // uint256 numC = i_stack3.getUserByAddress(_user).comments.length;
            if (_numPost == 5) {
                _mint(_user, COMMENTS_5, 1, "");
            } else if (_numPost == 10) {
                _mint(_user, COMMENTS_10, 1, "");
            } else if (_numPost == 15) {
                _mint(_user, COMMENTS_15, 1, "");
            }
        }
    }

    function updateAndRewardTagBadges(
        uint256 _tagId,
        uint256 _numTag,
        address _user /*, bytes32 _secret*/
    ) external {
        // require(_verifySecret(_secret), "Stack3Badges: Unverified source of call");
        require(
            _verifyCaller(msg.sender),
            "Stack3Badges: Caller is not Stack3 contract"
        );
        require(_tagId < s_maxTagId, "Stack3Badges: Invalid tag id");
        if (_numTag == 3) {
            _mint(_user, TAG_REWARDS_START + (_tagId * 4), 1, "");
        } else if (_numTag == 5) {
            _mint(_user, TAG_REWARDS_START + (_tagId * 4) + 1, 1, "");
        } else if (_numTag == 10) {
            _mint(_user, TAG_REWARDS_START + (_tagId * 4) + 2, 1, "");
        } else if (_numTag == 15) {
            _mint(_user, TAG_REWARDS_START + (_tagId * 4) + 3, 1, "");
        }
    }

    function _verifyCaller(address _caller) internal view returns (bool) {
        return _caller == s_stack3Address;
    }

    function uri(uint256 _id) public view override returns (string memory) {
        require(
            _id <= TAG_REWARDS_START + s_maxTagId * 4,
            "Stack3Badges: Invalid token id"
        );
        return string(abi.encodePacked(s_baseUri, _id.toString(), ".json"));
    }

    function tokenURI(uint256 _id) public view returns (string memory) {
        require(
            _id <= TAG_REWARDS_START + s_maxTagId * 4,
            "Stack3Badges: Invalid token id"
        );
        return string(abi.encodePacked(s_baseUri, _id.toString(), ".json"));
    }

    function getUserBadges(
        address _user
    ) public view returns (uint256[] memory) {
        require(_user != address(0), "Stack3Badges: Null address passed");
        uint256[] memory owned = new uint256[](
            TAG_REWARDS_START + s_maxTagId * 4
        );

        for (uint256 i = 0; i < (TAG_REWARDS_START + s_maxTagId * 4); i++) {
            owned[i] = balanceOf(_user, i);
        }

        return owned;
    }
}
