// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "./interfaces/IMockCouncilOfKingz.sol";
import "./interfaces/IMockCouncilOfKingzMintPass.sol";
import "./libraries/TransferHelper.sol";

contract HighCouncilOfKingz is ERC721, Ownable, VRFConsumerBase {
    using SafeMath for uint256;
    using Strings for uint256;

    // Contract addresses for interfaces
    address public councilOfKingz;
    address public councilOfKingzMintPass;

    // Contract controls; defaults to false
    bool public revealed;
    bool public mintEnabled;
    bool public burnEnabled;

    // Sale variables
    uint16 public constant totalTokens = 500;

    // counter
    uint16 private _totalMintSupply = 0; // start with zero
    uint16 private _totalBurnSupply = 0; // start with zero

    // Burn variables
    uint16 public totalBurnTokens = 0;

    // metadata URIs
    string private _contractURI; // initially set at deploy
    string private _notRevealedURI; // initially set at deploy
    string private _currentBaseURI; // initially set at deploy
    string private _baseExtension = ".json";

    // Mapping Minter address to token count for mint controls
    mapping(address => uint16) public addressMints;
    // Mapping Burner address to token count
    mapping(address => uint16) public addressBurns;
    // Mapping token matrix
    mapping(uint16 => uint16) private tokenMatrix;

    // Chainlink
    bytes32 internal keyHash;
    uint256 internal fee;
    uint256 public randomResult;
    event LogWithdrawLink(address _link, uint256 _amount);
    
    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initContractURI,
        string memory _initBaseURI,
        string memory _initNotRevealedURI,
        address _councilOfKingz,
        address _councilOfKingzMintPass
    ) ERC721(_name, _symbol) VRFConsumerBase (
            0xb3dCcb4Cf7a26f6cf6B120Cf5A73875B7BBc655B, // VRF Coordinator
            0x01BE23585060835E02B77ef475b0Cc51aA1e0709  // LINK Token
        ) {
        require(_councilOfKingz != address(0), "ERR: zero CouncilOfKingz address");
        require(_councilOfKingzMintPass != address(0), "ERR: zero CouncilOfKingz address");
        setContractURI(_initContractURI);
        setCurrentBaseURI(_initBaseURI);
        setNotRevealedURI(_initNotRevealedURI);
        councilOfKingz = _councilOfKingz;
        councilOfKingzMintPass = _councilOfKingzMintPass;
        keyHash = 0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311;
        fee = 0.1 * 10 ** 18; // 0.1 LINK (Varies by network)
    }

    // TODO: Why did we not check for Exceeds supply?
    modifier onlyAllowMintEnabledAndValidCount(uint256 _mintAmount) {
        require(totalMinted() + _mintAmount <= totalTokens, "Exceeds supply");
        require(mintEnabled, "ERR: mint disabled");
        _;
    }

    /**
     * @dev Returns the total number of tokens in circulation
     */
    function totalSupply() external view returns (uint16) {
        return _totalMintSupply - _totalBurnSupply;
    }

    /**
     * @dev Returns the total number of tokens minted
     */
    function totalMinted() public view returns (uint16) {
        return _totalMintSupply;
    }

    /**
     * @dev Returns the total number of tokens burned
     */
    function totalBurned() public view returns (uint16) {
        return _totalBurnSupply;
    }


    /**
     * @dev Public mint
     */
    function publicMint(uint256 _mintPassTokenId, uint256[] memory _burnTokenIds, uint16 _mintAmount)
        external
        onlyAllowMintEnabledAndValidCount(_mintAmount)
    {
        // ensure they on the mint pass
        require(_msgSender() == IMockCouncilOfKingzMintPass(councilOfKingzMintPass).ownerOf(_mintPassTokenId),"Not owner of pass");
        // ensure the mint pass is not Used
        require(!IMockCouncilOfKingzMintPass(councilOfKingzMintPass).isUsed(_mintPassTokenId),"Pass is used");
        // ensure the mint pass has not Expired
        require(!IMockCouncilOfKingzMintPass(councilOfKingzMintPass).isExpired(_mintPassTokenId),"Pass has expired");
        require(_burnTokenIds.length == 5, "ERR: should provide 5 burn tokens");
        IMockCouncilOfKingz(councilOfKingz).burn(_burnTokenIds);
        _mintNFT(_msgSender(), _mintAmount);
        // mark the pass as used
        IMockCouncilOfKingzMintPass(councilOfKingzMintPass).setAsUsed(_mintPassTokenId);
    }

    /**
     * @dev Owner mint function
     */
    function ownerMint(uint16 _mintAmount)
        external
        onlyOwner
        onlyAllowMintEnabledAndValidCount(_mintAmount)
    {
        _mintNFT(_msgSender(), _mintAmount);
    }

    /**
     * @dev Internal mint function
     */
    function _mintNFT(address _to, uint16 _mintAmount) private {
        addressMints[_to] += _mintAmount;
        for (uint256 i = 0; i < _mintAmount; i++) {
            _safeMint(_to, _getTokenToBeMinted(totalMinted()));
            _totalMintSupply++;
        }
    }

        /**
     * @dev Burn tokens
     */
    function burn(uint256[] memory _tokenIds) external {
        require(burnEnabled, "Burn disabled");
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            require(
                _isApprovedOrOwner(_msgSender(), _tokenIds[i]),
                "ERC721Burnable: caller is not owner nor approved"
            );
        }
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            _burn(_tokenIds[i]);
            _totalBurnSupply++;
            addressBurns[_msgSender()] += 1;
        }
    }


    /**
     * @dev Returns a random available token to be minted
     */
    function _getTokenToBeMinted(uint16 _totalMintedTokens)
        private
        returns (uint16)
    {
        uint16 maxIndex = totalTokens - _totalMintedTokens;
        bytes32 requestId = _getRandomNumber();
        uint16 random = uint16(uint256(requestId)) % maxIndex;

        uint16 tokenId = tokenMatrix[random];
        if (tokenMatrix[random] == 0) {
            tokenId = random;
        }

        tokenMatrix[maxIndex - 1] == 0
            ? tokenMatrix[random] = maxIndex - 1
            : tokenMatrix[random] = tokenMatrix[maxIndex - 1];

        return tokenId + 1;
    }

    /**
     * @dev Generates a pseudo-random number
     */

    function _getRandomNumber() public returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");
        return requestRandomness(keyHash, fee);
    }

    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        randomResult = (randomness % totalTokens) + 1;
    }

    /**
     * @dev Returns list of token ids owned by address
     */
    function walletOfOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        uint256 k = 0;
        for (uint256 i = 1; i <= totalTokens; i++) {
            if (_exists(i) && _owner == ownerOf(i)) {
                tokenIds[k] = i;
                k++;
            }
        }
        delete ownerTokenCount;
        delete k;
        return tokenIds;
    }

    // /**
    //  * @dev Returns the number of seconds remaining until the next HighCouncilOfKingz NFT can be minted
    //  */
    // function timeUntilMint() external view returns (uint256) {
    //     return _timeUntilMint();
    // }

    // /**
    //  * @dev Returns the number of seconds remaining until the next HighCouncilOfKingz NFT can be minted
    //  */
    // function _timeUntilMint() private view returns (uint256) {
    //     if (block.timestamp - lastMintTime < mintCoolDown) {
    //         return block.timestamp - lastMintTime;
    //     } else {
    //         return 0;
    //     }
    // }

    /**
     * @dev Returns the URI to the contract metadata
     */
    function contractURI() external view returns (string memory) {
        return _contractURI;
    }

    /**
     * @dev Internal function to return the base uri for all tokens
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _currentBaseURI;
    }

    /**
     * @dev Returns the URI to the tokens metadata
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        if (revealed == false) {
            return _notRevealedURI;
        }

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(
                    abi.encodePacked(
                        baseURI,
                        tokenId.toString(),
                        _baseExtension
                    )
                )
                : "";
    }

    /**
     * Owner functions
     */

    /**
     * @dev Setter for the Council of Kingz contract address
     */
    function setCouncilOfKingz(address _councilOfKingz) external onlyOwner {
        require(_councilOfKingz != address(0), "ERR: zero councilOfKingz address");
        councilOfKingz = _councilOfKingz;
    }

    /**
     * @dev Setter for the Council of Kingz Mint Pass contract address
     */
    function setCouncilOfKingzMintPass(address _councilOfKingzMintPass) external onlyOwner {
        require(_councilOfKingzMintPass != address(0), "ERR: zero councilOfKingzMintPass address");
        councilOfKingzMintPass = _councilOfKingzMintPass;
    }

    /**
     * @dev Reveal the token metadata
     */
    function reveal() external onlyOwner {
        revealed = true;
    }

    /**
     * @dev Setter for the Contract URI
     */
    function setMintEnable(bool _enable) public onlyOwner {
        require(IMockCouncilOfKingz(councilOfKingz).burnEnabled(), "ERR: CouncilOfKingz burn disabled");
        mintEnabled = _enable;
    }

    /**
     * @dev enables the burn mechanism; can only be set once
     */
    function enableBurn() external onlyOwner {
        burnEnabled = true;
    }

    /**
     * @dev set the number of tokens that can be burned
     */
    function setTotalBurnTokens(uint16 _totalBurnTokens) external onlyOwner {
        totalBurnTokens = _totalBurnTokens;
    }

    // /**
    //  * @dev Setter for the Contract URI
    //  */
    // function setMintCoolDown(uint256 _mintCoolDown) public onlyOwner {
    //     mintCoolDown = _mintCoolDown;
    // }

    /**
     * @dev Setter for the Contract URI
     */
    function setContractURI(string memory _newContractURI) public onlyOwner {
        _contractURI = _newContractURI;
    }

    /**
     * @dev Setter for the Not Revealed URI
     */
    function setNotRevealedURI(string memory _newNotRevealedURI)
        public
        onlyOwner
    {
        _notRevealedURI = _newNotRevealedURI;
    }

    /**
     * @dev Setter for the Base URI
     */
    function setCurrentBaseURI(string memory _newBaseURI) public onlyOwner {
        _currentBaseURI = _newBaseURI;
    }

    /**
     * @dev Setter for the meta data base extension
     */
    function setBaseExtension(string memory _newBaseExtension)
        external
        onlyOwner
    {
        _baseExtension = _newBaseExtension;
    }

    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success);
    }

    function withdrawLink() external onlyOwner {
        uint256 linkBalance = LINK.balanceOf(address(this));
        if(linkBalance > 0) {
            TransferHelper.safeTransfer(address(LINK), _msgSender(), linkBalance);
        }
        emit LogWithdrawLink(address(LINK), linkBalance);
    }



    /**
     * @dev A fallback function in case someone sends ETH to the contract
     */
    fallback() external payable {}

    receive() external payable {}
}