// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "lib/openzeppelin-contracts/contracts/utils/Address.sol";

contract GuessTheNumberChallenge {
    using Address for address payable;

    uint8 answer = 42;

    constructor() payable {
        require(msg.value == 1 ether, "Must send exactly 1 ether");
    }

    function isComplete() public view returns (bool) {
        return address(this).balance == 0;
    }

    function guess(uint8 n) public payable {
        require(msg.value == 1 ether, "Must send exactly 1 ether");

        if (n == answer) {
            payable(msg.sender).sendValue(2 ether);
        }
    }
}