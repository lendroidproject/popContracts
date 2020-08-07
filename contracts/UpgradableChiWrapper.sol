// SPDX-License-Identifier: https://github.com/lendroidproject/Rightshare-contracts/blob/master/LICENSE.md
pragma solidity 0.6.12;


import '@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol';
import '@openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol';


interface IfreeUpTo {
    function freeUpTo(uint256 value) external returns (uint256 freed);
    function balanceOf(address account) external view returns (uint256);
}


contract ChiWrapperUpgradeSafe is OwnableUpgradeSafe {
  IfreeUpTo public chi;

  // stores whether discounted gas costs using Chi tokens is allowed
  bool public discountChiActivated = false;

  modifier discountCHI {
    if (discountChiActivated) {
      require(address(chi) != address(0), "chi address is not set");
      uint256 gasStart = gasleft();
      _;
      uint256 gasSpent = 21000 + gasStart - gasleft() + 16 * msg.data.length;
      if (chi.balanceOf(address(this)) >= gasSpent) {
        chi.freeUpTo((gasSpent + 14154) / 41130);
      }
    }
    else {
      _;
    }
  }

  function setChi(address chiAddress) external onlyOwner {
    chi = IfreeUpTo(chiAddress);
  }

  /**
    * @notice Internal function to record if gas costs can be discounted
    * @dev set discountChiActivated value as true or false
    * @param activate : bool indicating the toggle value
    */
  function toggleDiscountChi(bool activate) external onlyOwner {
    if (activate) {
      require(!discountChiActivated, "discount chi is already activated");
    }
    else {
      require(discountChiActivated, "discount chi is already deactivated");
    }
    discountChiActivated = activate;
  }

}
