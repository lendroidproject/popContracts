// SPDX-License-Identifier: https://github.com/lendroidproject/Rightshare-contracts/blob/master/LICENSE.md
pragma solidity 0.6.12;

import '@openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol';
import '@openzeppelin/contracts-ethereum-package/contracts/utils/Counters.sol';
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC721/ERC721.sol";
import './ExtendedStrings.sol';


/** @title Right
 * @author Lendroid Foundation
 * @notice A smart contract for NFT Rights
 * @dev Audit certificate : https://github.com/lendroidproject/Rightshare-contracts/blob/master/audit-report.pdf
 */
abstract contract RightUpgradeSafe is ERC721UpgradeSafe, OwnableUpgradeSafe {

  using ExtendedStrings for string;
  using Counters for Counters.Counter;

  Counters.Counter private _tokenIdTracker;

  function _mintTo(address to) internal {
    uint256 newTokenId = _getNextTokenId();
    _mint(to, newTokenId);
    _incrementTokenId();
  }

  /**
    * @notice Displays the id of the latest token that was minted
    * @return uint256 : latest minted token id
    */
  function currentTokenId() public view returns (uint256) {
    return _tokenIdTracker.current();
  }

  /**
    * @notice Displays the id of the next token that will be minted
    * @dev Calculates the next token ID based on value of _currentTokenId
    * @return uint256 : id of the next token
    */
  function _getNextTokenId() private view returns (uint256) {
    return _tokenIdTracker.current().add(1);
  }

  /**
    * @notice Increments the value of _currentTokenId
    * @dev Internal function that increases the value of _currentTokenId by 1
    */
  function _incrementTokenId() private  {
    _tokenIdTracker.increment();
  }

}
