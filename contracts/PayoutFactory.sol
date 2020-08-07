// SPDX-License-Identifier: https://github.com/lendroidproject/Rightshare-contracts/blob/master/LICENSE.md
pragma solidity 0.6.12;

import "@openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol";
import "./Payout.sol";
import "./UpgradableChiWrapper.sol";


contract PayoutFactory is Initializable, ChiWrapperUpgradeSafe {

    event PayoutCreated(address payoutAddress);

    IPayoutToken public payoutToken;

    /* constructor (address payoutToken) public {
        payoutTokenAddress = payoutToken;
    } */

    function initialize(address payoutTokenAddress) public initializer {
      __Ownable_init();
      payoutToken = IPayoutToken(payoutTokenAddress);
    }


    /* constructor (string memory url) public {
        PayoutToken newPayoutToken = new PayoutToken();
        newPayoutToken.setApiBaseUrl(url);
        payoutTokenAddress = address(newPayoutToken);
    }

    function initialize(string memory url) public initializer {
      __Ownable_init();
      PayoutToken newPayoutToken = new PayoutToken();
      newPayoutToken.initialize();
      newPayoutToken.setApiBaseUrl(url);
      payoutTokenAddress = address(newPayoutToken);
    } */

    function create(address[] memory payees, uint256[] memory shares, string calldata imageUrl) external discountCHI {
        require(payees.length > 0, "PayoutFactory: no payees");
        require(payees.length == shares.length, "Payout: payees and shares length mismatch");

        uint256 currentPayoutTokenId = payoutToken.currentTokenId();

        Payout newPayout = new Payout();
        newPayout.initialize(address(payoutToken), currentPayoutTokenId, shares);

        payoutToken.batchMintTo(payees, address(newPayout), imageUrl);

        emit PayoutCreated(address(newPayout));
    }

}
