// SPDX-License-Identifier: https://github.com/lendroidproject/Rightshare-contracts/blob/master/LICENSE.md
pragma solidity 0.6.12;

import "@openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";

import "./PayoutToken.sol";


interface IPayoutToken {
    function ownerOf(uint256 tokenId) external view returns (address);
    function currentTokenId() external view returns (uint256);
    function batchMintTo(address[] memory addresses, address poolSplitterAddress, string calldata imageUrl) external;
}


contract Payout is Initializable, OwnableUpgradeSafe {
    using SafeMath for uint256;

    event PayeeAdded(uint256 payoutTokenId, uint256 shares);
    event PaymentReleased(address to, uint256 amount);
    event PaymentReceived(address from, uint256 amount);

    uint256 private _totalShares;
    uint256 private _totalReleased;

    mapping(uint256 => uint256) private _shares;
    mapping(uint256 => uint256) private _released;
    uint256[] private _payees;
    // Payout tracker
    mapping(uint256 => uint256) public pendingPayouts;

    IPayoutToken public payoutToken;

    /**
     * @dev Creates an instance of `Payout` where each account in `payees` is assigned the number of shares at
     * the matching position in the `shares` array.
     *
     * All addresses in `payees` must be non-zero. Both arrays must have the same non-zero length, and there must be no
     * duplicates in `payees`.
     */
    function initialize(address payoutTokenAddress, uint256 currentPayoutTokenId, uint256[] memory shares) public initializer {
      __Ownable_init();
      payoutToken = IPayoutToken(payoutTokenAddress);

      for (uint256 i = 0; i < shares.length; i++) {
        currentPayoutTokenId = currentPayoutTokenId.add(1);
        _addPayee(currentPayoutTokenId, shares[i]);
      }
    }

    /**
     * @dev The Ether received will be logged with {PaymentReceived} events. Note that these events are not fully
     * reliable: it's possible for a contract to receive Ether without triggering this function. This only affects the
     * reliability of the events, and not the actual splitting of Ether.
     *
     * To learn more about this see the Solidity documentation for
     * https://solidity.readthedocs.io/en/latest/contracts.html#fallback-function[fallback
     * functions].
     */
    receive () external payable virtual {

        uint256 totalReceived = address(this).balance.add(_totalReleased);

        uint256 payoutAmount = 0;

        for (uint256 i = 0; i < _payees.length; i++) {
            payoutAmount = totalReceived.mul(_shares[_payees[i]]).div(_totalShares).sub(_released[_payees[i]]);
            pendingPayouts[_payees[i]] = pendingPayouts[_payees[i]].add(payoutAmount);
        }


        emit PaymentReceived(_msgSender(), msg.value);

    }

    /**
     * @dev Getter for the total shares held by payees.
     */
    function totalPayees() external view returns (uint256) {
        return _payees.length;
    }

    /**
     * @dev Getter for the total shares held by payees.
     */
    function totalShares() external view returns (uint256) {
        return _totalShares;
    }

    /**
     * @dev Getter for the total amount of Ether already released.
     */
    function totalReleased() external view returns (uint256) {
        return _totalReleased;
    }

    /**
     * @dev Getter for the amount of shares held by an account.
     */
    function shares(uint256 payoutTokenId) external view returns (uint256) {
        return _shares[payoutTokenId];
    }

    /**
     * @dev Getter for the amount of Ether already released to a payee.
     */
    function released(uint256 payoutTokenId) external view returns (uint256) {
        return _released[payoutTokenId];
    }

    /**
     * @dev Getter for the address of the payee number `index`.
     */
    function payee(uint256 index) external view returns (uint256) {
        return _payees[index];
    }

    /**
     * @dev Triggers a transfer to `account` of the amount of Ether they are owed, according to their percentage of the
     * total shares and their previous withdrawals.
     */
    function withdraw(uint256 payoutTokenId, uint256 amount) external {
        require(_shares[payoutTokenId] > 0, "Payout: account has no shares");

        require(pendingPayouts[payoutTokenId] > 0, "Payout: account is not due payment");

        pendingPayouts[payoutTokenId] = pendingPayouts[payoutTokenId].sub(amount);
        _released[payoutTokenId] = _released[payoutTokenId].add(amount);
        _totalReleased = _totalReleased.add(amount);

        address payable account = payable(payoutToken.ownerOf(payoutTokenId));
        account.transfer(amount);
        emit PaymentReleased(account, amount);
    }

    /**
     * @dev Add a new payee to the contract.
     * @param payoutTokenId The address of the payee to add.
     * @param shares_ The number of shares owned by the payee.
     */
    function _addPayee(uint256 payoutTokenId, uint256 shares_) private {
        require(payoutTokenId != 0, "Payout: payoutTokenId is zero");
        require(shares_ > 0, "Payout: shares are 0");
        require(_shares[payoutTokenId] == 0, "Payout: payoutTokenId already has shares");

        _payees.push(payoutTokenId);
        _shares[payoutTokenId] = shares_;
        _totalShares = _totalShares.add(shares_);
        emit PayeeAdded(payoutTokenId, shares_);
    }
}
