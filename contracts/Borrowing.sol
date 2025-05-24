// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Borrowing is Ownable {
    struct Loan {
        uint256 principal;
        uint256 interestAccrued;
        uint256 lastAccrualTimestamp;
    }

    IERC20 public stablecoin;
    uint256 public ltvRatio; // e.g. 75 means 75%
    mapping(address => Loan) public loans;

    event LoanIssued(address indexed borrower, uint256 amount);
    event LoanRepaid(address indexed borrower, uint256 amount);
    event InterestAccrued(address indexed borrower, uint256 amount);

    constructor(address stablecoinAddress, uint256 initialLtvRatio) {
        stablecoin = IERC20(stablecoinAddress);
        ltvRatio = initialLtvRatio;
    }

    // Issue a loan to borrower based on collateral value
    function issueLoan(address borrower, uint256 collateralValue) external onlyOwner {
        uint256 maxLoan = (collateralValue * ltvRatio) / 100;
        loans[borrower].principal += maxLoan;
        loans[borrower].lastAccrualTimestamp = block.timestamp;

        require(stablecoin.transfer(borrower, maxLoan), "Transfer failed");
        emit LoanIssued(borrower, maxLoan);
    }

    // Repay loan principal and interest
    function repayLoan(uint256 amount) external {
        Loan storage loan = loans[msg.sender];
        accrueInterest(msg.sender);

        require(amount <= loan.principal + loan.interestAccrued, "Repay amount too high");
        uint256 interestPayment = amount > loan.interestAccrued ? loan.interestAccrued : amount;
        uint256 principalPayment = amount - interestPayment;

        loan.interestAccrued -= interestPayment;
        loan.principal -= principalPayment;

        require(stablecoin.transferFrom(msg.sender, address(this), amount), "Transfer failed");
        emit LoanRepaid(msg.sender, amount);
    }

    // Accrue interest on loan
    function accrueInterest(address borrower) public {
        Loan storage loan = loans[borrower];
        uint256 timeElapsed = block.timestamp - loan.lastAccrualTimestamp;
        if (timeElapsed == 0) return;

        // Simple fixed interest rate for example (e.g., 5% annual)
        uint256 annualInterestRate = 5;
        uint256 interest = (loan.principal * annualInterestRate * timeElapsed) / (100 * 365 days);

        loan.interestAccrued += interest;
        loan.lastAccrualTimestamp = block.timestamp;

        emit InterestAccrued(borrower, interest);
    }

    // Update LTV ratio
    function setLtvRatio(uint256 newLtvRatio) external onlyOwner {
        ltvRatio = newLtvRatio;
    }
}
