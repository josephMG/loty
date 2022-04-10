pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "erc721a/contracts/ERC721A.sol";

contract LotyMembership is ERC721A, Ownable, ReentrancyGuard {
    using ECDSA for bytes32;

    enum Status {
        Paused,
        WhitelistSale,
        PublicSale,
        Finished
    }

    Status public status;
    string public baseURI;
    bool public burnLocked = true;

    uint256 public tokensReserved;

    uint256 public RESERVED_AMOUNT = 32;
    uint256 public MAX_SUPPLY = 888;
    uint256 public PRICE = 0.03 * 10**18; // 0.03 ETH
    address public signer = 0x3c407eE60928a9b4F64fbF3eFB093C74F2A2D9A1;
    address public marketingWallet = 0x55D0790Bc0Fb64d9fE4DC100986B0E7e9Ebce389;

    event Minted(address minter, uint256 amount);
    event StatusChanged(Status status);
    event SignerChanged(address signer);
    event ReservedToken(address minter, address recipient, uint256 amount);
    event BaseURIChanged(string newBaseURI);

    // Constructor
    // ------------------------------------------------------------------------
    constructor()
    ERC721A("LotyMembership", "LOTY")
    {}

    function _hash(uint256 maxAllowed, address _address)
    public
    view
    returns (bytes32)
    {
        return keccak256(abi.encode(Strings.toString(maxAllowed), address(this), _address));
    }

    function _verify(bytes32 hash, bytes memory signature)
    internal
    view
    returns (bool)
    {
        return (_recover(hash, signature) == signer);
    }

    function _recover(bytes32 hash, bytes memory signature)
    internal
    pure
    returns (address)
    {
        return hash.toEthSignedMessageHash().recover(signature);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function reserve(address recipient, uint256 amount) external onlyOwner {
        require(amount > 0, "Amount too low");
        require(
            totalSupply() + amount <= MAX_SUPPLY,
            "Max supply exceeded"
        );
        require(
            tokensReserved + amount <= RESERVED_AMOUNT,
            "Max reserve amount exceeded"
        );

        _safeMint(recipient, amount);
        tokensReserved += amount;
        emit ReservedToken(msg.sender, recipient, amount);
    }

    function whitelistMint(uint256 amount, uint256 maxAllowed, bytes calldata signature)
    external
    payable
    {
        require(status == Status.WhitelistSale, "WhitelistSale is not active.");
        require(
            _verify(_hash(maxAllowed, msg.sender), signature),
            "Invalid signature."
        );
        require(PRICE * amount == msg.value, "Price incorrect.");
        require(
            numberMinted(msg.sender) + amount <= maxAllowed,
            "Max mint amount per wallet exceeded."
        );
        require(
            totalSupply() + amount + RESERVED_AMOUNT - tokensReserved <=
            MAX_SUPPLY,
            "Max supply exceeded."
        );
        require(tx.origin == msg.sender, "Contract is not allowed to mint.");

        _safeMint(msg.sender, amount);
        emit Minted(msg.sender, amount);
    }


    function mint() external payable {
        require(status == Status.PublicSale, "Public sale is not active.");
        require(tx.origin == msg.sender, "Contract is not allowed to mint.");
        require(
            totalSupply() + 1 + RESERVED_AMOUNT - tokensReserved <=
            MAX_SUPPLY,
            "Max supply exceeded."
        );
        require(PRICE == msg.value, "Price incorrect.");

        _safeMint(msg.sender, 1);
        emit Minted(msg.sender, 1);
    }

    function _startTokenId() internal view override virtual returns (uint256) {
        return 1;
    }

    function withdraw() external nonReentrant onlyOwner {
        uint256 balance = address(this).balance;
        (bool success1, ) = payable(marketingWallet).call{value: balance}("");
        require(success1, "Transfer failed.");
    }

    function setPRICE(uint256 newPRICE) external onlyOwner {
        PRICE = newPRICE;
    }

    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
        emit BaseURIChanged(newBaseURI);
    }

    function setStatus(Status _status) external onlyOwner {
        status = _status;
        emit StatusChanged(_status);
    }

    function setBurnLocked(bool locked) external onlyOwner {
        burnLocked = locked;
    }

    function setSigner(address newSigner) external onlyOwner {
        signer = newSigner;
        emit SignerChanged(signer);
    }

    function setMarketingWallet(address newMarketingWallet) external onlyOwner {
        marketingWallet = newMarketingWallet;
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function getOwnershipData(uint256 tokenId)
    external
    view
    returns (TokenOwnership memory)
    {
        return _ownershipOf(tokenId);
    }

    function burn(uint256 tokenId) public virtual {
        require(burnLocked == false, "Burning is not enabled.");
        require(ownerOf(tokenId) == _msgSender(), "Not owner.");
        _burn(tokenId);
    }
}
