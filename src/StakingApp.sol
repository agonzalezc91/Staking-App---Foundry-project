// SPDX-License-Identifier: MIT

// solidity version
pragma solidity 0.8.30;

import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

// Staking fixed amount. E.J. 10 tokens

contract StakingApp is Ownable {
    // Variables
    address public stakingToken;
    uint256 public stakingPeriod;
    uint256 public fixedStakingAmount;
    uint256 public rewardPerPeriod;
    mapping(address => uint256) public userBalance;
    mapping(address => uint256) public elapsePeriod;

    event ChangeStakingPeriod(uint256 newStakingPeriod_);
    event DepositTokens(address userAddress_, uint256 depositAmount);
    event WithdrawTokens(address userAddress_, uint256 withdrawAmount_);
    event TokenSent(uint256 amount_);

    constructor(
        address stakingToken_,
        address owner_,
        uint256 stakingPeriod_,
        uint256 fixedStakingAmount_,
        uint256 rewardPerPeriod_
    ) Ownable(owner_) {
        stakingToken = stakingToken_;
        stakingPeriod = stakingPeriod_;
        fixedStakingAmount = fixedStakingAmount_;
        rewardPerPeriod = rewardPerPeriod_;
    }

    function depositTokens(uint256 tokenAmountToDeposit_) external {
        require(
            tokenAmountToDeposit_ == fixedStakingAmount,
            "Incorrect Amount"
        );
        require(userBalance[msg.sender] == 0, "User already deposited");

        IERC20(stakingToken).transferFrom(
            msg.sender,
            address(this),
            tokenAmountToDeposit_
        );
        userBalance[msg.sender] += tokenAmountToDeposit_;
        elapsePeriod[msg.sender] = block.timestamp;

        emit DepositTokens(msg.sender, tokenAmountToDeposit_);
    }

    function withdrawTokens() external {
        // CEI pattern

        uint256 userBalance_ = userBalance[msg.sender];
        userBalance[msg.sender] = 0;
        IERC20(stakingToken).transfer(msg.sender, userBalance_);

        emit WithdrawTokens(msg.sender, userBalance_);
    }

    function claimRewards() external {
        // 1. Check balance
        require(userBalance[msg.sender] == fixedStakingAmount, "Not staking");

        // 2. Calculate reward amount
        uint256 elapsePeriod_ = block.timestamp - elapsePeriod[msg.sender];
        require(elapsePeriod_ >= stakingPeriod, "need to wait");

        // 3. Update state
        elapsePeriod[msg.sender] = block.timestamp;

        // 4. transfer rewards
        (bool success, ) = msg.sender.call{value: rewardPerPeriod}("");
        require(success, "Transfer failed");
    }

    receive() external payable onlyOwner {
        emit TokenSent(msg.value);
    }

    function changeStakingPeriod(uint256 newStakingPeriod_) external onlyOwner {
        stakingPeriod = newStakingPeriod_;
        emit ChangeStakingPeriod(newStakingPeriod_);
    }
}
