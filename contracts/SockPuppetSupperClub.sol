// Sock Puppet Supper Club
//
// Ever wonder where your lost socks go?
//
// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract SockPuppetSupperClub is Ownable, ERC721Enumerable {
    using SafeMath for uint256;
    using SafeMath for uint8;

    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
    uint256 public constant ROYALTY_PRECISION = 10000;

    uint256 public artsAndCraftsStartBlock = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    uint256 public maxSocks;
    uint256 public price;
    uint256 public royalty;
    address public vault;
    string public baseUri;

    constructor(
        uint256 _maxSocks,
        uint256 _price,
        uint256 _royalty,
        address _vault,
        string memory _baseUri)
        ERC721('Sock Puppet Supper Club', 'SPSC')
    {
        maxSocks = _maxSocks;
        price = _price;
        royalty = _royalty;
        vault = _vault;

        setBaseUri(_baseUri);
    }

    modifier hasntStarted() {
        require(!artsAndCraftsStarted(), 'Already crafting ya dingus');
        _;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseUri;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Enumerable) returns (bool) {
        if (interfaceId == _INTERFACE_ID_ERC2981) {
            return true;
        }

        return super.supportsInterface(interfaceId);
    }

    function royaltyInfo(uint256 , uint256 _salePrice) external view returns (address receiver, uint256 royaltyAmount) {
        uint256 amount = _salePrice.mul(royalty).div(ROYALTY_PRECISION);
        return (vault, amount);
    }

    function artsAndCraftsStarted() public view returns (bool) {
        return block.number >= artsAndCraftsStartBlock;
    }

    function craft(uint256 numSocks) public payable {
        require(artsAndCraftsStarted(), "It's still nap time. Settle down");
        require(totalSupply() < maxSocks, 'We ran out of socks! Bummer');
        require(totalSupply().add(numSocks) <= maxSocks, "Mmmm this is a nice edge case");
        require(numSocks > 0 && numSocks <= 12, "Don't be greedy! Only 10 socks at a time");
        require(msg.value >= price.mul(numSocks), 'Ether value sent is not sufficient. Socks aint cheap!');

        for (uint256 i = 0; i < numSocks; i++) {
            uint256 craftIndex = totalSupply();
            _safeMint(msg.sender, craftIndex + 1);
        }
    }

    function setBaseUri(string memory _newBaseUri) public onlyOwner {
        baseUri = _newBaseUri;
    }

    function setStartBlock(uint256 _newStartBlock) public onlyOwner {
        artsAndCraftsStartBlock = _newStartBlock;
    }

    function setRoyalty(uint256 _newRoyalty) public onlyOwner hasntStarted {
        royalty = _newRoyalty;
    }

    function setPrice(uint256 _newPrice) public onlyOwner hasntStarted {
        price = _newPrice;
    }

    function setVault(address _newVault) public onlyOwner {
        vault = _newVault;
    }

    function withdraw(uint256 _amount) public onlyOwner {
        require(address(vault) != address(0), 'no vault');
        require(payable(vault).send(_amount));
    }

    function withdrawAll() public payable onlyOwner {
        require(address(vault) != address(0), 'no vault');
        require(payable(vault).send(address(this).balance));
    }

    function forwardERC20s(IERC20 _token, uint256 _amount) public onlyOwner {
        require(address(vault) != address(0));
        _token.transfer(vault, _amount);
    }

    function reserve(uint256 numSocks) public onlyOwner hasntStarted {
        require(totalSupply() < maxSocks, 'We ran out of socks! Bummer');
        require(totalSupply().add(numSocks) <= maxSocks, "Mmmm this is a nice edge case");
        
        uint256 currentSupply = totalSupply();

        for (uint index = 0; index < numSocks; index++) {
            _safeMint(owner(), currentSupply + index);
        }
    }
}