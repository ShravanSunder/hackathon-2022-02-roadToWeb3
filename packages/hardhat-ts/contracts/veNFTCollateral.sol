pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

error LOAN_ACTIVE();
error LOAN_DURATION_NOT_COMPLETE();
error NOT_LENDER();
error LOAN_DURATION_COMPLETE();
error NOT_BORROWER();
error LOAN_INACTIVE();

contract veNFTCollateral is ERC20 {
  IERC20 public lendingToken;

  // @notice A continuously increasing counter that simultaneously allows
  //         every loan to have a unique ID and provides a running count of
  //         how many loans have been started by this contract.
  uint256 public totalNumLoans = 0;

  struct Loan {
    uint256 loanId;
    uint256 loanPrincipalAmount;
    uint256 borrowedAmount;
    uint8 collateralRatio;
    uint56 loanStartTime;
    uint32 loanDuration;
    address borrower;
    address lender;
    bytes nftCollateralParams;
    // reward related params for the lender
    uint256 lastUpdateTime;
    uint256 rewardRate;
    uint256 rewardPerTokenStored;
    uint256 userRewardPerTokenPaid;
    uint256 rewards;
  }

  // @notice A mapping from a loan's identifier to the loan's details,
  mapping(uint256 => Loan) public loanIdToLoan;

  // @notice A mapping tracking whether a loan is active or not, thet status changes to inactive if the borrower doesn't payback uptill the duration or if the loan is paid
  mapping(uint256 => bool) public loanStatus;

  //*********************************************************************//
  // ------------------------- reward calculation methods -------------------------- //
  //*********************************************************************//

  function updateReward(Loan memory loan) public {
    loan.rewardPerTokenStored = uint128(rewardPerToken(loan));
    loan.lastUpdateTime = lastTimeRewardApplicable(loan);
    if (loan.lender != address(0)) {
      loan.rewards = uint128(earned(loan));
      loan.userRewardPerTokenPaid = loan.rewardPerTokenStored;
    }
  }

  function earned(Loan memory loan) public view returns (uint256) {
    return (loan.loanPrincipalAmount * (rewardPerToken(loan) - (loan.userRewardPerTokenPaid))) / (1e18) + (loan.rewards);
  }

  function lastTimeRewardApplicable(Loan memory loan) public view returns (uint256) {
    return block.timestamp < loan.loanDuration ? block.timestamp : loan.loanDuration;
  }

  function rewardPerToken(Loan memory loan) public view returns (uint256) {
    if (lendingToken.balanceOf(address(this)) == 0) {
      return loan.rewardPerTokenStored;
    }
    return
      loan.rewardPerTokenStored +
      (lastTimeRewardApplicable(loan) - ((loan.lastUpdateTime) * (loan.rewardRate) * (1e18)) / (lendingToken.balanceOf(address(this))));
  }

  //*********************************************************************//
  // ------------------------- constuctor -------------------------- //
  //*********************************************************************//
  constructor(IERC20 _lendingToken) ERC20("Reward", "REWARD") {
    // minting rewards
    _mint(address(this), 1000 ether);
    lendingToken = _lendingToken;
  }

  function depositLoanCapital(
    uint256 _amount,
    uint32 _duration,
    uint8 _collateralRatio
  ) external {
    // TODO Add custom errors for the input checks and event
    Loan memory loan = Loan({
      loanId: totalNumLoans,
      loanPrincipalAmount: _amount,
      loanStartTime: uint56(block.timestamp),
      loanDuration: _duration,
      collateralRatio: _collateralRatio,
      lender: msg.sender,
      borrowedAmount: 0,
      nftCollateralParams: abi.encode(-1, address(0)),
      borrower: address(0),
      rewardRate: uint128(IERC20(address(this)).balanceOf(address(this)) / (_duration)),
      lastUpdateTime: block.timestamp,
      rewardPerTokenStored: 0,
      userRewardPerTokenPaid: 0,
      rewards: 0
    });
    loanIdToLoan[totalNumLoans] = loan;
    totalNumLoans += 1;
    updateReward(loan);
    lendingToken.transferFrom(msg.sender, address(this), _amount);
  }

  function borrow(
    uint256 _loanID,
    uint256 _nftCollateralId,
    address _nftCollateralContract,
    uint256 _borrowAmount
  ) external {
    // TODO Add custom errors for the input checks and Add events
    if (loanStatus[_loanID]) {
      revert LOAN_ACTIVE();
    }
    Loan memory loan = loanIdToLoan[_loanID];
    // *** NEEDS TO BE FETCHED FROM THE ORACLE ***
    uint256 nftPrice = 30 ether;
    // calculate the borrow amount
    uint256 maxBorrowAmount = (nftPrice * loan.collateralRatio) / 100;
    if (_borrowAmount < maxBorrowAmount) {
      maxBorrowAmount = _borrowAmount;
    }
    loan.nftCollateralParams = abi.encode(int256(_nftCollateralId), _nftCollateralContract);
    loan.borrower = msg.sender;
    // defualt value is false
    loanStatus[_loanID] = true;
    // locking in the nft
    IERC721(_nftCollateralContract).safeTransferFrom(msg.sender, address(this), uint256(_nftCollateralId));
    // sending the borrowed amount
    lendingToken.transfer(msg.sender, maxBorrowAmount);
  }

  function claimDeposit(uint256 _loanID) external {
    // TODO Add events
    Loan memory loan = loanIdToLoan[_loanID];
    if (block.timestamp <= loan.loanDuration) {
      revert LOAN_DURATION_NOT_COMPLETE();
    }
    if (msg.sender != loan.lender) {
      revert NOT_LENDER();
    }
    if (!loanStatus[_loanID]) {
      revert LOAN_INACTIVE();
    }
    (int256 tokenID, address nftContract) = abi.decode(loan.nftCollateralParams, (int256, address));
    bool _loanStatus = loanStatus[_loanID];
    uint256 _loanPrincipalAmount = loan.loanPrincipalAmount;
    uint256 _rewards = loan.rewards;
    delete loanIdToLoan[_loanID];
    // check if repaid or not if not **  TO BE UPDATED
    if (_loanStatus) {
      IERC721(nftContract).safeTransferFrom(address(this), msg.sender, uint256(tokenID));
    } else {
      lendingToken.transfer(msg.sender, _loanPrincipalAmount);
    }
    // sending the accured rewards
    IERC20(address(this)).transfer(msg.sender, _rewards);
  }

  function repay(uint256 _loanID) external {
    // for now we will will consider the borrower only will pay the borrowed amount and not the interest
    // TODO Add events
    Loan memory loan = loanIdToLoan[_loanID];
    if (block.timestamp > loan.loanDuration) {
      revert LOAN_DURATION_COMPLETE();
    }
    if (msg.sender != loan.borrower) {
      revert NOT_BORROWER();
    }
    if (!loanStatus[_loanID]) {
      revert LOAN_INACTIVE();
    }
    (int256 tokenID, address nftContract) = abi.decode(loan.nftCollateralParams, (int256, address));
    uint256 _borrowedAmount = loan.borrowedAmount;
    delete loanIdToLoan[_loanID];
    IERC721(nftContract).safeTransferFrom(address(this), msg.sender, uint256(tokenID));
    lendingToken.transferFrom(msg.sender, address(this), _borrowedAmount);
  }
}
