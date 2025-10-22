// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @title Utilities
/// @notice Collection of utility functions and a small multisig vault example.
contract Utilities {
    address public owner;
    mapping(address => bool) public guardians;
    uint256 public confirmCount;

    event GuardianAdded(address g);
    event GuardianRemoved(address g);

    constructor() {
        owner = msg.sender;
    }

    function addGuardian(address g) external {
        require(msg.sender == owner, "owner");
        guardians[g] = true;
        emit GuardianAdded(g);
    }

    function removeGuardian(address g) external {
        require(msg.sender == owner, "owner");
        guardians[g] = false;
        emit GuardianRemoved(g);
    }

    // simple time-locked transfer (vault)
    struct Vault {
        address token; // zero => ETH
        address to;
        uint256 amount;
        uint256 unlockTime;
        bool executed;
    }

    Vault[] public vaults;

    function scheduleTransfer(address token, address to, uint256 amount, uint256 delaySeconds) external {
        vaults.push(Vault({token: token, to: to, amount: amount, unlockTime: block.timestamp + delaySeconds, executed: false}));
    }

    function execute(uint256 idx) external {
        Vault storage v = vaults[idx];
        require(block.timestamp >= v.unlockTime, "locked");
        require(!v.executed, "done");
        v.executed = true;
        if(v.token == address(0)) {
            payable(v.to).transfer(v.amount);
        } else {
            // assume standard ERC20 transfer
            (bool success, bytes memory data) = v.token.call(abi.encodeWithSignature("transfer(address,uint256)", v.to, v.amount));
            require(success && (data.length==0 || abi.decode(data, (bool))), "transfer failed");
        }
    }

    receive() external payable {}
}
