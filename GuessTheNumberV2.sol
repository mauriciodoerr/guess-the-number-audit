// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "lib/openzeppelin-contracts/contracts/utils/Address.sol";
import "lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract GuessTheNumberChallengeV2 is ReentrancyGuard, Ownable {
    using Address for address payable;

    bytes32 private immutable answerHash;
    uint256 public gameBalance;

    uint256 public constant MAX_ATTEMPTS_PER_ADDRESS = 3;
    uint256 public constant GUESS_COOLDOWN = 60;
    mapping(address => uint256) public attempts;
    mapping(address => uint256) public lastGuessTime;

    event ContractDeployed(uint256 initialBalance);
    event GuessAttempted(address indexed player, uint256 guess, bool correct);
    event GameWon(address indexed winner, uint256 amount);
    event FundsWithdrawn(address indexed owner, uint256 amount);

    error MaxAttemptsReached();
    error CooldownNotExpired();
    error InsufficientPayment();

    /**
     * @param _answerHash keccak256(abi.encodePacked(answer)) - just hash the number
     */
    constructor(bytes32 _answerHash) payable Ownable(msg.sender) {
        require(msg.value == 1 ether, "Must send exactly 1 ether");
        answerHash = _answerHash;
        gameBalance = msg.value;
        emit ContractDeployed(msg.value);
    }

    function isComplete() public view returns (bool) {
        return gameBalance == 0;
    }

    /**
     * @notice Guess the number - costs 1 ether, win 2 ether if correct
     * @param n Your guess
     */
    function guess(uint256 n) public payable nonReentrant {
        if (msg.value != 1 ether) revert InsufficientPayment();

        if (attempts[msg.sender] >= MAX_ATTEMPTS_PER_ADDRESS) {
            revert MaxAttemptsReached();
        }
        if (block.timestamp < lastGuessTime[msg.sender] + GUESS_COOLDOWN) {
            revert CooldownNotExpired();
        }

        attempts[msg.sender]++;
        lastGuessTime[msg.sender] = block.timestamp;
        gameBalance += msg.value;

        bytes32 guessHash = keccak256(abi.encodePacked(n));

        if (guessHash == answerHash) {
            emit GuessAttempted(msg.sender, n, true);
            emit GameWon(msg.sender, 2 ether);

            gameBalance -= 2 ether;
            payable(msg.sender).sendValue(2 ether);
        } else {
            emit GuessAttempted(msg.sender, n, false);
        }
    }

    /**
     * @notice Owner can withdraw remaining funds
     */
    function withdrawFunds() external onlyOwner nonReentrant {
        require(gameBalance > 0, "No funds");

        uint256 amount = gameBalance;
        gameBalance = 0;

        emit FundsWithdrawn(owner(), amount);

        payable(owner()).sendValue(amount);
    }

    /**
     * @notice Helper to generate hash off-chain: keccak256(abi.encodePacked(42))
     */
    function generateAnswerHash(uint256 _answer) external pure returns (bytes32) {
        return keccak256(abi.encodePacked(_answer));
    }

    /**
    * @notice Get the remaining attempts for a player
    * @param _player The address of the player
    * @return The remaining attempts
    */
    function getRemainingAttempts(address _player) external view returns (uint256) {
        if (attempts[_player] >= MAX_ATTEMPTS_PER_ADDRESS) return 0;
        return MAX_ATTEMPTS_PER_ADDRESS - attempts[_player];
    }

    /**
     * @notice Get the cooldown remaining for a player
     * @param _player The address of the player
     * @return The cooldown remaining
     */
    function getCooldownRemaining(address _player) external view returns (uint256) {
        uint256 nextAllowed = lastGuessTime[_player] + GUESS_COOLDOWN;
        if (block.timestamp >= nextAllowed) return 0;
        return nextAllowed - block.timestamp;
    }
}
