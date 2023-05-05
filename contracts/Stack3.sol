// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract Stack3 is Ownable, ERC1155 {

    enum PostType {
        QUESTION,
        ANSWER
    }

    event NewUser (
        uint256 timestamp, 
        uint256 indexed id, 
        address indexed user
    );

    event NewQuestion (
        uint256 timestamp, 
        uint256 indexed id, 
        address indexed user
    );

    event NewAnswer (
        uint256 timestamp, 
        uint256 indexed id, 
        uint256 indexed qId, 
        address indexed user
    );

    event NewComment (
        uint256 timestamp,
        uint256 indexed id,
        PostType parentPostType,
        uint256 indexed postId,
        address indexed user
    );


    struct User {
        uint256 tokenId;
        address userAddress;
        uint256 [] questions;
        uint256 [] answers;
        uint256 [] comments;
    }


    struct Question {
        uint256 id;
        uint256 upvotes;
        uint256 downvotes;
        address author;
        uint256 [] comments;
        uint256 [] answers;
        string uri;
    }

    struct Answer {
        uint256 id;
        uint256 qid;
        uint256 upvotes;
        uint256 downvotes;
        address author;
        uint256 [] comments;
        string uri;
    }

    struct Comment {
        uint256 id;
        PostType parentPostType;
        uint256 parentPostId;
        address author;
        string uri;
    }


    uint256 private s_userIdCounter;
    uint256 private s_questionIdCounter;
    uint256 private s_answerIdCounter;
    uint256 private s_commentIdCounter;
    // uint256 private i_reservedTokensCount;

    ERC1155 token;

    mapping (address => User) private s_users;
    mapping (uint256 => Question) private s_questions;
    mapping (uint256 => Answer) private s_answers;
    mapping (uint256 => Comment) private s_comments;

    function _initCounters (uint256 _initValue) private {
        s_questionIdCounter = _initValue;
        s_answerIdCounter = _initValue;
        s_commentIdCounter = _initValue;
    }

    constructor (address _tokenAddress, string memory _baseUri, uint256 _reservedTokensCount) ERC1155 (_baseUri) {
        token = ERC1155(_tokenAddress);
        s_userIdCounter = _reservedTokensCount;
        _initCounters(1);
    }

    
    function registerUser () external {
        uint256 newId = s_userIdCounter++;
        
        s_users[msg.sender].tokenId = newId;
        s_users[msg.sender].userAddress = msg.sender;

        _mint(msg.sender, newId, 1, "0x0");

        emit NewUser (block.timestamp, newId, msg.sender);
    }


    function postQuestion () external {
        uint256 newId = s_questionIdCounter++;
        s_users[msg.sender].questions.push(newId);

        s_questions[newId].id = newId;
        s_questions[newId].author = msg.sender;

        emit NewQuestion(block.timestamp, newId, msg.sender);
    }


    function postAnswer (uint256 _qid) external {
        uint256 newId = s_answerIdCounter++;
        s_users[msg.sender].answers.push(newId);

        s_questions[_qid].answers.push(newId);
        
        s_answers[newId].id = newId;
        s_answers[newId].qid = _qid;
        s_answers[newId].author = msg.sender;

        emit NewAnswer(block.timestamp, newId, _qid, msg.sender);

    }

    function postCommentOnQuestion (uint256 _postId) external {
        uint256 newId = s_commentIdCounter++;

        s_users[msg.sender].comments.push(newId);

        s_questions[_postId].comments.push(newId);

        s_comments[newId].id = newId;
        s_comments[newId].parentPostType = PostType.QUESTION;
        s_comments[newId].parentPostId = _postId;
        s_comments[newId].author = msg.sender;

        emit NewComment (block.timestamp, newId, PostType.QUESTION, _postId, msg.sender);
    }


    function postCommentOnAnswer (uint256 _postId) external {
        uint256 newId = s_commentIdCounter++;

        s_users[msg.sender].comments.push(newId);

        s_answers[_postId].comments.push(newId);

        s_comments[newId].id = newId;
        s_comments[newId].parentPostType = PostType.ANSWER;
        s_comments[newId].parentPostId = _postId;
        s_comments[newId].author = msg.sender;

        emit NewComment (block.timestamp, newId, PostType.ANSWER, _postId, msg.sender);
    }



    function getUserByAddress (address _userAddress) public view returns (User memory) {
        require (_userAddress != address(0), "Stack3: Cannot fetch data for null address.");
        return s_users[_userAddress];
    }

    function getQuestionById (uint256 _id) public view returns (Question memory) {
        require (_id > 0 && _id < s_questionIdCounter, "Stack3: Invalid question id supplied.");
        return s_questions[_id];
    }

    function getAnswerById (uint256 _id) public view returns (Answer memory) {
        require (_id > 0 && _id < s_answerIdCounter, "Stack3: Invalid answer id supplied.");
        return s_answers[_id];
    }

    function getCommentById (uint256 _id) public view returns (Comment memory) {
        require (_id > 0 && _id < s_commentIdCounter, "Stack3: Invalid comment id supplied.");
        return s_comments[_id];
    }

    
}