//SPDX-License-Identifier: BSD 
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";



contract RemillioMaker is Ownable, ReentrancyGuard, ERC721A {

    bytes32 public merkleRoot;
    mapping(address => bool) public whitelistClaimed;
    mapping (uint256 => address) private _tokenApprovals;

    string private _URI;
    string public hiddenMetadataUri;

    bool private _halt_mint = false;
    bool private _is_revealed;
    uint256 constant MAX_MINT = 30;
    uint256 constant TOTAL_TOKEN_SUPPLY = 2000;
    uint256 private MINT_PRICE;

    address public MiladyAddress;
    address public FlurkAddress;
    address public RemillioAddress;

    mapping(address => uint256) private _num_minted;

    constructor(string memory _hiddenMetadataUri) ERC721A("RemillioMaker", "REM") {
        setMiladyAddress(0x5Af0D9827E0c53E4799BB226655A1de152A425a5);
        setFlurkAddress(0xDe6B6090D32eB3eeae95453eD14358819Ea30d33);
        setRemillioAddress(0xD3D9ddd0CF0A5F0BFB8f7fcEAe075DF687eAEBaB);
        setHiddenMetadataUri(_hiddenMetadataUri);
    }

    

    function mint(uint256 numTokens) payable external nonReentrant {
        require(_halt_mint == false, "paused");
        require(numTokens > 0 && numTokens <= 30, "mint up to 30");
        require(totalSupply() + numTokens < TOTAL_TOKEN_SUPPLY, "ran out - you were slow");

        if (numTokens == 30) {
            MINT_PRICE = 0.008 ether;
        }
        else if ( numTokens >= 15) {
            MINT_PRICE = 0.009 ether;
        }
         else if ( numTokens >= 5) {
            MINT_PRICE = 0.0095 ether;
        }
         else {
            MINT_PRICE = 0.01 ether;
        }
        
        uint256 totalPrice = _computePrice(numTokens);

        require(msg.value == totalPrice, "incorrect price");  

        _num_minted[msg.sender] += numTokens;

        _safeMint(msg.sender, numTokens); 
    }

    function MiladyFreeMint(uint256 numTokens, bytes32[] calldata _merkleProof) public nonReentrant {
        require(_halt_mint == false, "paused");
        require(numTokens == 1, "mint up to 30");
        require(totalSupply() + numTokens < TOTAL_TOKEN_SUPPLY, "ran out - you were slow");
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "not on the list");

        whitelistClaimed[_msgSender()] = true;
        _num_minted[msg.sender] += numTokens;
        _safeMint(msg.sender, numTokens);
    }

    function FlurkFreeMint(uint256 numTokens, bytes32[] calldata _merkleProof) public nonReentrant {
        require(_halt_mint == false, "paused");
        require(numTokens == 1, "mint up to 30");
        require(totalSupply() + numTokens < TOTAL_TOKEN_SUPPLY, "ran out - you were slow");
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "not on the list");

        whitelistClaimed[_msgSender()] = true;
        _num_minted[msg.sender] += numTokens;
        _safeMint(msg.sender, numTokens);
    }


    function adminMint(uint256 numTokens) external onlyOwner {
        _safeMint(msg.sender, numTokens);
    }

    function mintForAddress(uint256 numTokens, address _receiver) public onlyOwner
    {
        _safeMint(_receiver, numTokens);
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
    merkleRoot = _merkleRoot;
    }

    function _computePrice(uint256 numTokens) public view returns (uint256) {
        return (MINT_PRICE * numTokens);
    }

    function setMiladyAddress(address _newAddress) public onlyOwner {
        MiladyAddress = _newAddress;
    }
    function setFlurkAddress(address _newAddress) public onlyOwner {
        FlurkAddress = _newAddress;
    }
    function setRemillioAddress(address _newAddress) public onlyOwner {
        RemillioAddress = _newAddress;
    }

    function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
    hiddenMetadataUri = _hiddenMetadataUri;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), 'tokenId?');

        // include the token index if revealed
        if (_is_revealed) {
            return string(abi.encodePacked(_URI, toString(tokenId)));
        } 

        // otherwise return the URI
        return string(_URI);
    }

    /**
     * @dev Halt minting 
    */
    function setHaltMint(bool v) public onlyOwner() {
        _halt_mint = v;
    }

    /**
     * @dev Withdraw ether from this contract (Callable by owner)
    **/
    function withdraw() public onlyOwner {
    (bool os, ) = payable(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266).call{value: address(this).balance * 50 / 100}("");
    require(os);

    (bool hs, ) = payable(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266).call{value: address(this).balance * 50 / 100}("");
    require(hs);
  }

    /**
     * @dev Set URI 
    */
    function setURI(string memory v) public onlyOwner() {
        _URI = v;
    }

    /**
     * @dev Set reveal 
    */
    function setIsReveal(bool v) public onlyOwner() {
        _is_revealed = v;
    }

	/////////////////////////////////////////////
	function toString(uint256 value) internal pure returns (string memory) {
		// Inspired by OraclizeAPI's implementation - MIT licence
		// https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

		if (value == 0) {
			return "0";
		}
		uint256 temp = value;
		uint256 digits;
		while (temp != 0) {
			digits++;
			temp /= 10;
		}
		bytes memory buffer = new bytes(digits);
		while (value != 0) {
			digits -= 1;
			buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
			value /= 10;
		}
		return string(buffer);
	}

    function _receiveNFTs(uint256 numTokens) public view returns (uint256) {
        return (MINT_PRICE * numTokens);
    }

    function mintWithNFT () external nonReentrant {
        require(_halt_mint == false, "paused");
        require(totalSupply() < TOTAL_TOKEN_SUPPLY, "ran out - you were slow");
        
        _num_minted[msg.sender] += 1;

        _safeMint(msg.sender, 1); 
    }
    
}