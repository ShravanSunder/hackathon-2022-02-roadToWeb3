pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

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
    int256 nftCollateralId;
    uint8 collateralRatio;
    uint56 loanStartTime;
    uint32 loanDuration;
    address nftCollateralContract;
    address borrower;
    address lender;
  }

  // @notice A mapping from a loan's identifier to the loan's details,
  //         represted by the loan struct. To fetch the lender, call
  //         NFTfi.ownerOf(loanId).
  mapping(uint256 => Loan) public loanIdToLoan;

  // @notice A mapping tracking whether a loan has either been repaid or
  //         liquidated. This prevents an attacker trying to repay or
  //         liquidate the same loan twice.
  mapping(uint256 => bool) public loanStatus;

  constructor(IERC20 _lendingToken) ERC20("Reward", "REWARD") {
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
      nftCollateralId: -1,
      nftCollateralContract: address(0),
      borrower: address(0)
    });
    loanIdToLoan[totalNumLoans] = loan;
    loanStatus[totalNumLoans] = false;
    totalNumLoans += 1;
    lendingToken.transferFrom(msg.sender, address(this), _amount);
  }

  function borrow(
    uint256 _loanID,
    uint256 _nftCollateralId,
    address _nftCollateralContract,
    uint256 _borrowAmount
  ) external {
    // TODO Add custom errors for the input checks and to see if the loan is active i.e someone has already borrowed it
    // Add events
    // get nft price the borrow amount = collateralRatio % of the loanPrincipalAmount and if this amt is more than borrowedAmount then send borrowedAmount else send the newly calculated amount
    Loan memory loan = loanIdToLoan[_loanID];
    loan.nftCollateralId = int256(_nftCollateralId);
    loan.nftCollateralContract = _nftCollateralContract;
    loan.borrower = msg.sender;
    IERC721(_nftCollateralContract).safeTransferFrom(msg.sender, address(this), uint256(_nftCollateralId));
    // using _borrowAmount for now ***** TO BE UPDATED
    lendingToken.transfer(msg.sender, _borrowAmount);
  }

  function claimDeposit(uint256 _loanID) external {
    // TODO checks for if loan is active and the duration amount has passed in and the msg.sender is the lender
    // Add events
    Loan memory loan = loanIdToLoan[_loanID];
    // check if repaid or not if not **  TO BE UPDATED
    IERC721(loan.nftCollateralContract).safeTransferFrom(address(this), msg.sender, uint256(loan.nftCollateralId));
    // if yes
    lendingToken.transfer(msg.sender, loan.loanPrincipalAmount);
    // additionally the lender get's erc20 rewards i.e the reward token based on the loan start time and the claim time  **  TO BE UPDATED
  }

  function repay(uint256 _loanID) external {
    // for now we will will consider the borrower only will pay the borrowed amount and not the interest, will need to think of the interest logic a bit more
    // TODO checks for if loan is active and the duration amount has passed in and the msg.sender is the borrower
    // Add events
    Loan memory loan = loanIdToLoan[_loanID];
    loanStatus[_loanID] = true;
    IERC721(loan.nftCollateralContract).safeTransferFrom(address(this), msg.sender, uint256(loan.nftCollateralId));
    lendingToken.transferFrom(msg.sender, address(this), loan.borrowedAmount);
    // additionally the borrower also get's erc20 rewards i.e the reward token based on the loan start time and the claim time  **  TO BE UPDATED
  }
}
