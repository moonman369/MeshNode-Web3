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
        bool bestAnswerChosen;
        uint256 id;
        uint256 upvotes;
        uint256 downvotes;
        address author;
        uint256 [] tags;
        uint256 [] comments;
        uint256 [] answers;
        // string uri;
    }

    struct Answer {
        bool isBestAnswer;
        uint256 id;
        uint256 qid;
        uint256 upvotes;
        uint256 downvotes;
        address author;
        uint256 [] comments;
        // string uri;
    }

    struct Comment {
        uint256 id;
        PostType parentPostType;
        uint256 parentPostId;
        address author;
        // string uri;
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
    
    mapping (address => mapping (uint256 => bool)) public s_userVotedQuestion;
    mapping (address => mapping (uint256 => bool)) public s_userVotedAnswer;
    mapping (address => mapping (uint256 => uint256)) public s_userQuestionTagCounts;
    mapping (address => mapping (uint256 => uint256)) public s_userAnswerTagCounts;


    

    constructor (address _tokenAddress, string memory _baseUri) ERC1155 (_baseUri) {
        token = ERC1155(_tokenAddress);
        _initCounters(1);
    }

    
    function registerUser () external {
        require (_callerIsWallet(msg.sender));
        require (!_userExists(msg.sender), "Stack3: User already registered");
        uint256 newId = s_userIdCounter++;
        
        s_users[msg.sender].tokenId = newId;
        s_users[msg.sender].userAddress = msg.sender;

        _mint(msg.sender, newId, 1, "0x0");

        emit NewUser (block.timestamp, newId, msg.sender);
    }


    function postQuestion (uint256 [] memory _tags) external {
        require (_callerIsWallet(msg.sender));
        require (_userExists(msg.sender), "Stack3: User not registered");
        require (_tags.length <= 10, "Stack3: Max tag count is 10");
        
        uint256 newId = s_questionIdCounter++;
        s_users[msg.sender].questions.push(newId);

        s_questions[newId].id = newId;
        s_questions[newId].author = msg.sender;
        s_questions[newId].tags = _tags;

        for (uint256 i=0; i < _tags.length; i++) {
            s_userQuestionTagCounts[msg.sender][_tags[i]] += 1;
        }

        emit NewQuestion(block.timestamp, newId, msg.sender);
    }

    function voteQuestion (uint256 _qid, int8 _vote) external {
        require (_callerIsWallet(msg.sender));
        require (_userExists(msg.sender), "Stack3: User not registered");
        require (_questionExists(_qid), "Stack3: Invalid question id");
        require (!s_userVotedQuestion[msg.sender][_qid], "Stack3: User has voted");
        require (_vote == 1 || _vote == -1, "Stack3: Invalid vote param");
        
        _vote == 1
            ? s_questions[_qid].upvotes += 1
            : s_questions[_qid].downvotes += 1;

        s_userVotedQuestion[msg.sender][_qid] = true;    

    }


    function postAnswer (uint256 _qid) external {
        require (_callerIsWallet(msg.sender));
        require (_userExists(msg.sender), "Stack3: User not registered");
        require (_questionExists(_qid), "Stack3: Invalid question id");

        uint256 newId = s_answerIdCounter++;
        s_users[msg.sender].answers.push(newId);

        s_questions[_qid].answers.push(newId);
        
        s_answers[newId].id = newId;
        s_answers[newId].qid = _qid;
        s_answers[newId].author = msg.sender;

        for (uint256 i=0; i < s_questions[_qid].tags.length; i++) {
            s_userAnswerTagCounts[msg.sender][s_questions[_qid].tags[i]] += 1;
        }

        emit NewAnswer(block.timestamp, newId, _qid, msg.sender);
    }

    function voteAnswer (uint256 _aid, int8 _vote) external {
        require (_callerIsWallet(msg.sender));
        require (_userExists(msg.sender), "Stack3: User not registered");
        require (_answerExists(_aid), "Stack3: Invalid answer id");
        require (!s_userVotedAnswer[msg.sender][_aid], "Stack3: User has already casted their vote.");
        require (_vote == 1 || _vote == -1, "Stack3: Invalid vote parameter");
        
        _vote == 1
            ? s_questions[_aid].upvotes += 1
            : s_questions[_aid].downvotes += 1;

        s_userVotedAnswer[msg.sender][_aid] = true;    

    }


    function chooseAsBestAnswer (uint256 _aid) external {
        require (_callerIsWallet(msg.sender));
        require (_userExists(msg.sender), "Stack3: User not registered");
        require (_answerExists(_aid), "Stack3: Invalid answer id");
        uint256 qid = s_answers[_aid].qid;
        require (s_questions[qid].author == msg.sender, "Stack3: Caller is not author");
        require (!s_questions[qid].bestAnswerChosen, "Stack3: Best answer for question already chosen");
        require (!s_answers[_aid].isBestAnswer, "Stack3: This answer is chosen as the best");

        s_questions[qid].bestAnswerChosen = true;
        s_answers[_aid].isBestAnswer = true;
    }



    function postComment (uint8 _postType, uint256 _postId) external {
        require (_callerIsWallet(msg.sender));
        require (_userExists(msg.sender), "Stack3: User not registered");
        require (_questionExists(_postId) || _answerExists(_postId), "Stack3: Invalid post id");
        require (_validPostType(_postType), "Stack3: Invalid post type");
        

        uint256 newId = s_commentIdCounter++;

        s_users[msg.sender].comments.push(newId);

        PostType(_postType) == PostType.QUESTION 
            ? s_questions[_postId].comments.push(newId)
            : s_answers[_postId].comments.push(newId);

        s_comments[newId].id = newId;
        s_comments[newId].parentPostType = PostType(_postType);

        s_comments[newId].parentPostId = _postId;
        s_comments[newId].author = msg.sender;

        emit NewComment (block.timestamp, newId, PostType(_postType), _postId, msg.sender);
    }


    function _callerIsWallet (address _addr) internal view returns (bool) {
        return tx.origin == _addr;
    }

    function _userExists (address _addr) internal view returns (bool) {
        return s_users[_addr].userAddress != address(0);
    }

    function _validPostType (uint8 _type) internal pure returns (bool) {
        return _type == 0 || _type == 1;
    }

    function _questionExists (uint256 _id) internal view returns (bool) {
        return _id > 0 && _id < s_questionIdCounter;
    }

    function _answerExists (uint256 _id) internal view returns (bool) {
        return _id > 0 && _id < s_answerIdCounter;
    }

    function _commentExists (uint256 _id) internal view returns (bool) {
        return _id > 0 && _id < s_commentIdCounter;
    }

    function _initCounters (uint256 _initValue) internal {
        s_userIdCounter = _initValue;
        s_questionIdCounter = _initValue;
        s_answerIdCounter = _initValue;
        s_commentIdCounter = _initValue;
    }



    function getUserByAddress (address _userAddress) 
    public 
    view 
    returns (User memory)
    {
        require (_userExists(_userAddress), "Stack3: User not registered");
        return s_users[_userAddress];
    }

    function getQuestionById (uint256 _id) 
    public 
    view 
    returns (Question memory) 
    {
        require (_questionExists(_id), "Stack3: Invalid question id");
        return s_questions[_id];
    }

    function getAnswerById (uint256 _id) 
    public 
    view 
    returns (Answer memory) 
    {
        require (_answerExists(_id), "Stack3: Invalid answer id");
        return s_answers[_id];
    }

    function getCommentById (uint256 _id) 
    public 
    view 
    returns (Comment memory) 
    {
        require (_commentExists(_id), "Stack3: Invalid comment id");
        return s_comments[_id];
    }

    function getAnswersByQuestionId (uint256 _qid)
    public
    view
    returns (uint256 [] memory) 
    {
        return s_questions[_qid].answers;
    }

    function getCommentsByQuestionId (uint256 _qid)
    public
    view
    returns (uint256 [] memory)
    {
        return s_questions[_qid].comments;
    }

    function getCommentsByAnswerId (uint256 _aid)
    public
    view
    returns (uint256 [] memory)
    {
        return s_answers[_aid].comments;
    }

    function getQuestionsByUserAddress (address _user)
    public
    view
    returns (uint256 [] memory)
    {
        return s_users[_user].questions;
    }

    function getAnswersByUserAddress (address _user)
    public
    view
    returns (uint256 [] memory)
    {
        return s_users[_user].answers;
    }

    function getCommentsByUserAddress (address _user)
    public
    view
    returns (uint256 [] memory)
    {
        return s_users[_user].comments;
    }

    function getTotalCounts () 
    public 
    view 
    returns 
    (uint256, uint256, uint256, uint256) 
    {
        return (
            s_userIdCounter - 1,
            s_questionIdCounter - 1,
            s_answerIdCounter - 1,
            s_commentIdCounter - 1
        );
    }
    
}