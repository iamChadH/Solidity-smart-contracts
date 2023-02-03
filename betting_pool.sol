// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        _previousOwner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function changeAdmin(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract PoolFactory is Context, Ownable {
    address payable[] internal deployedPools;
    mapping(address => bool) public isPoolManager;

    event PoolDeployed(string teamOne, string teamTwo, uint256 entryFeeInWei);
    event ManagerAdded(address newManager);
    event ManagerDismissed(address oldManager);

    modifier restricted() {
        require(
            isPoolManager[msg.sender],
            "Must be a Pool Manager to call this function."
        );
        _;
    }

    constructor() {
        isPoolManager[msg.sender] = true;

        emit OwnershipTransferred(address(0), msg.sender);
    }

    function createPool(string memory teamOne, string memory teamTwo, uint256 entryFeeInWei)
        public
        restricted
    {
        address newPool = address(
            new Pool(teamOne, teamTwo, entryFeeInWei, msg.sender)
        );
        deployedPools.push(payable(newPool));

        emit PoolDeployed(teamOne, teamTwo, entryFeeInWei);
    }

    function getDeployedPools() public view returns (address payable[] memory) {
        return deployedPools;
    }

    function addManager(address newManager) external onlyOwner {
        isPoolManager[newManager] = true;

        emit ManagerAdded(newManager);
    }

    function dismissManager(address oldManager) external onlyOwner {
        isPoolManager[oldManager] = false;

        emit ManagerDismissed(oldManager);
    }
}

contract Pool {
    address public manager;
    uint256 public entryFee;
    uint256 public participantsCount;
    string public teamOne;
    string public teamTwo;
    uint256 public maxPoolValue;
    address payable[] internal participants;
    uint[] internal taken;
    mapping(address => uint) public entryNumber;
    mapping(uint => bool) public takenNumbers;

    event enteredPool(address poolParticipant);
    event winner(address poolWinner, uint256 winnings);

    modifier restricted() {
        require(msg.sender == manager);
        _;
    }

    constructor(
        string memory _teamOne,
        string memory _teamTwo,
        uint256 entryFeeInWei,
        address creator
    ) {
        teamOne = _teamOne;
        teamTwo = _teamTwo;
        entryFee = entryFeeInWei;
        maxPoolValue = 100 * entryFeeInWei;
        manager = creator;
    }

    function enterPool(uint _entryNumber) public payable {
        require(msg.value == entryFee, "Incorrect entry amount");
        require(address(this).balance < maxPoolValue, "Pool is filled");
        require(participantsCount < 100, "Pool is filled");
        require(_entryNumber >= 1 && _entryNumber <= 100, "Must be between 1 and 100");
        require(takenNumbers[_entryNumber] != true, "This number is already taken");

        participantsCount++;
        participants.push(payable(msg.sender));
        taken.push(_entryNumber);
        entryNumber[msg.sender] = _entryNumber;
        takenNumbers[_entryNumber] = true;

        emit enteredPool(msg.sender);
    }

    function finalizePool(address poolWinner) public restricted {
        payable(poolWinner).transfer(address(this).balance);

        emit winner(poolWinner, address(this).balance);
    }

    function getPoolEntrants() public view returns (address payable[] memory) {
        return participants;
    }

    function getTakenNumbers() public view returns (uint[] memory) {
        return taken;
    }

    function getSummary()
        public
        view
        returns (uint256, uint256, string memory, string memory, uint256, address)
    {
        return (
            entryFee,
            address(this).balance,
            teamOne,
            teamTwo,
            participantsCount,
            manager
        );
    }
}
