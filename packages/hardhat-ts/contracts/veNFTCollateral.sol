pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract veNFTCollateral is ERC20 {
  IERC20 public lendingToken;

  constructor(IERC20 _lendingToken) ERC20("Reward", "REWARD") {
    lendingToken = _lendingToken;
  }

  function deposit() external {}

  function borrow() external {}

  function claimDeposit() external {}

  function repay() external {}
}
