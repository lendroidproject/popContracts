// SPDX-License-Identifier: https://github.com/lendroidproject/Rightshare-contracts/blob/master/LICENSE.md
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;


import "@openzeppelin/contracts-ethereum-package/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/utils/EnumerableSet.sol";
import "./UpgradableRight.sol";


/**
 * @title PayoutToken
 * @notice ERC721 contract that can withdraw
 */
contract PayoutToken is Initializable, RightUpgradeSafe, AccessControlUpgradeSafe {

  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

  // This stores metadata about a PayoutToken
  struct Metadata {
    uint256 tokenId; // id of the PayoutToken
    uint256 startTime; // timestamp when the PayoutToken was created
    address poolSplitterAddress; // address of Pool Splitter Contract
    string text; // text on the PayoutToken image
    string imageUrl; // surce of the PayoutToken image
  }

  // stores a `Metadata` struct for each IRight.
  mapping(uint256 => Metadata) public metadata;

  function initialize(string memory url, address payoutFactoryAddress) public initializer {
    __ERC721_init("Payout Token", "PYT");
    __Ownable_init();
    __AccessControl_init();
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    _setupRole(MINTER_ROLE, payoutFactoryAddress);
    _setBaseURI(url);
  }

  function _createMetadata(address poolSplitterAddress, string calldata imageUrl) private  {
    Metadata storage _meta = metadata[currentTokenId()];
    _meta.tokenId = currentTokenId();
    _meta.startTime = now;
    _meta.poolSplitterAddress = poolSplitterAddress;
    _meta.text = "Payout Token";
    _meta.imageUrl = imageUrl;

    string memory _tokenURI = ExtendedStrings.strConcat(
        ExtendedStrings.strConcat("payout/", ExtendedStrings.address2str(address(this)), "/", ExtendedStrings.uint2str(_meta.tokenId), "/"),
        ExtendedStrings.strConcat(_meta.text, "/", _meta.imageUrl)
    );
    _setTokenURI(_meta.tokenId, _tokenURI);
  }

  function update(uint256 tokenId, string calldata text, string calldata imageUrl) external {
    require(tokenId > 0, "invalid token id");
    Metadata storage _meta = metadata[tokenId];
    require(_meta.tokenId == tokenId, "IRT: token does not exist");
    _meta.text = text;
    _meta.imageUrl = imageUrl;

    string memory _tokenURI = ExtendedStrings.strConcat(
        ExtendedStrings.strConcat("payout/", ExtendedStrings.address2str(address(this)), "/", ExtendedStrings.uint2str(_meta.tokenId), "/"),
        ExtendedStrings.strConcat(_meta.text, "/", _meta.imageUrl)
    );
    _setTokenURI(_meta.tokenId, _tokenURI);
  }

  function batchMintTo(address[] memory addresses, address poolSplitterAddress, string calldata imageUrl) external {
    require(hasRole(MINTER_ROLE, _msgSender()), "PayoutToken: must have minter role to mint");
    for (uint8 i=0; i<addresses.length; i++) {
      _mintTo(addresses[i]);
      _createMetadata(poolSplitterAddress, imageUrl);
    }
  }

}
