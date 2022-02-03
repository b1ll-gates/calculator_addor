// SPDX-License-Identifier: MIT
pragma abicoder v2;
pragma solidity >=0.6.0 <0.8.11;

//import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./NFTLibrary.sol";

contract NFT is ERC721,  Ownable, ReentrancyGuard {


    struct Body {
        string name;
        uint256 start;
        uint256 amount;
        bytes pixels;
        bytes[] eyes;
        bytes[] mouth;
    }
  
    IERC20 private _nwBTCToken;
    address public _stakeAddress;
    
    function setTokenAddress( IERC20 _token ) public onlyOwner {
        _nwBTCToken = _token;
    }
    function setStakeAddress( address addr ) public onlyOwner {
        _stakeAddress = addr;
    }
 
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    Counters.Counter private _traitsIds;
    Counters.Counter public _bodyCount;
   
    //Mappings
    mapping(uint256 => Body) public indexToBodyType;
    mapping(uint256 => bool) hashToMinted;
    mapping(uint256 => uint256) tokenIdToHash;
    //uint256s
    uint256 MAX_SUPPLY = 0xFFFFFFFFFF;

    uint8 public _userCreatedOffset = 1;
    
    constructor( IERC20 _token  ) ERC721("NFTs ", "NFTS") {
        _nwBTCToken = _token;
    
    }
    
    function getRating( uint256 _tkn ) external returns ( uint256 ) {
        uint256 h = tokenIdToHash[ _tkn ];
        return (  h >> 24 ) & 0xFFFFFF;
    }


    /**
     * @dev Returns the SVG and metadata for a token Id
     * @param _tokenId The tokenId to return the SVG and metadata for.
     */
    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(_tokenId), "The token does not exist");

        string memory svgString;
        uint8[24][24] memory placedPixels;
        string memory metaString = string(
                                abi.encodePacked(
                                    '"attributes":','{"Character":"', indexToBodyType[ _tokenId ].name,'"}'
                                 ) );
                          
        uint256 hash = tokenIdToHash[ _tokenId ];

        //BG COLOUR
        uint8 bgR = uint8( (hash>>24)&0xff );
        uint8 bgB = uint8( (hash>>32)&0xff );
        uint8 bgG = uint8( (hash>>40)&0xff );

        uint256 _indexBody = hash & 0xff;
        uint256 _indexEye = ( ( hash >> 8 ) & 0xff ) % uint8( indexToBodyType[ _indexBody ].eyes.length );
        uint256 _indexMouth = ( ( hash >> 16 ) & 0xff ) % uint8( indexToBodyType[ _indexBody ].mouth.length );

        //BODY
        for ( uint16 j = 0; j < indexToBodyType[ _indexBody ].pixels.length; j+=3 ) {
            uint8 x = uint8( indexToBodyType[ _indexBody ].pixels[ j ] );
            uint8 y = uint8( indexToBodyType[ _indexBody ].pixels[ j + 1 ] );
            placedPixels[x][y] = uint8( indexToBodyType[ _indexBody ].pixels[ j + 2 ] );
        }
        
        uint256 pixelCount = indexToBodyType[ _indexBody ].eyes[ _indexEye ].length;              
        for ( uint16 j = 0; j < pixelCount; j+=3 ) {
            uint8 x = uint8( indexToBodyType[ _indexBody ].eyes[ _indexEye ][j] );
            uint8 y = uint8( indexToBodyType[ _indexBody ].eyes[ _indexEye ][j + 1] );
            placedPixels[x][y] = uint8( indexToBodyType[ _indexBody ].eyes[ _indexEye ][j + 2] );
        }
        
        pixelCount = indexToBodyType[ _indexBody ].mouth[ _indexMouth ].length;              
        for ( uint16 j = 0; j < pixelCount; j+=3 ) {
            uint8 x = uint8( indexToBodyType[ _indexBody ].mouth[ _indexMouth ][j] );
            uint8 y = uint8( indexToBodyType[ _indexBody ].mouth[ _indexMouth ][j + 1] );
            placedPixels[x][y] = uint8( indexToBodyType[ _indexBody ].mouth[ _indexMouth ][j + 2] );
        }
         
        for ( uint16 y = 0; y < 24; y++){
            for ( uint16 x = 0; x < 24; x++){
                if ( placedPixels[x][y] > 0 ) { 
                    svgString = string(
                        abi.encodePacked(
                            svgString,
                            "<rect class='c",NFTLibrary.toString(placedPixels[x][y]),
                            "' x='",
                            NFTLibrary.toString( x ),
                            "' y='",
                            NFTLibrary.toString( y ),
                            "'/>"
                        )
                    );
                }
            }
        } 

        svgString = string(
            abi.encodePacked(
                '<svg id="sperm-svg" xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 24 24" style="background-color: rgba('
                , NFTLibrary.toString( bgR ) ,',', NFTLibrary.toString( bgB ) ,',', NFTLibrary.toString( bgG ) ,',0.2);"> ',
                svgString,
                "<style>rect{width:1px;height:1px;} #sperm-svg{shape-rendering: crispedges;} .c0{fill:none}.c1{fill:#131313}.c2{fill:#1B1B1B}.c3{fill:#272727}.c4{fill:#3D3D3D}.c5{fill:#5D5D5D}.c6{fill:#858585}.c7{fill:#B4B4B4}.c8{fill:#FFFFFF}.c9{fill:#C7CfDD}.c10{fill:#92A1B9}.c11{fill:#657392}.c12{fill:#424C6E}.c13{fill:#2A2F4E}.c14{fill:#1A1932}.c15{fill:#0E071B}.c16{fill:#1C121C}.c17{fill:#0391F21}.c18{fill:#5D2C28}.c19{fill:#8A4836}.c20{fill:#BF6F4A}.c21{fill:#E69C69}.c22{fill:#F6CA9F}.c23{fill:#F9E6CF}.c24{fill:#EDAB50}.c25{fill:#E07438}.c26{fill:#C64524}.c27{fill:#8E251D}.c28{fill:#FF5000}.c29{fill:#ED7614}.c30{fill:#FFA214}.c31{fill:#FFC825}.c32{fill:#FFEB57}.c33{fill:#D3FC7E}.c34{fill:#99E65F}.c35{fill:#5AC54F}.c36{fill:#33984B}.c37{fill:#1E6F50}.c38{fill:#134C4C}.c39{fill:#0C2E44}.c40{fill:#00396D}.c41{fill:#0069AA}.c42{fill:#0098DC}.c43{fill:#00CDF9}.c44{fill:#0CF1FF}.c45{fill:#94FDFF}.c46{fill:#FDD2ED}.c47{fill:#F389F5}.c48{fill:#DB3FFD}.c49{fill:#7A09FA}.c50{fill:#3003D9}.c51{fill:#0C0293}.c52{fill:#03193F}.c53{fill:#3B1443}.c54{fill:#622461}.c55{fill:#93388F}.c56{fill:#CA52C9}.c57{fill:#C85086}.c58{fill:#F68187}.c59{fill:#F5555D}.c60{fill:#EA323C}.c61{fill:#C42430}.c62{fill:#891E2B}.c63{fill:#571C27}</style></svg>"
            )
        );

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    NFTLibrary.encode(
                        bytes(
                            string(
                                abi.encodePacked(
                                    '{"name": "SPERM+ ',
                                        NFTLibrary.toString( _tokenId - indexToBodyType[ _indexBody ].start ),'/',
                                        NFTLibrary.toString( indexToBodyType[ _indexBody ].amount),
                                        '","description": "Healthy.", "image": "data:image/svg+xml;base64,',
                                        NFTLibrary.encode( bytes( svgString)),'",',
                                    metaString,"}"
                                )
                            )
                        )
                    )
                )
            );
    }


    /**
     * @dev Returns the wallet of a given wallet. Mainly for ease for frontend devs.
     * @param _wallet The wallet to get the tokens of.
     */
    function walletOfOwner(address _wallet)
        public
        view
        returns (uint256[] memory ) 
    {
        uint256 tokenCount = balanceOf(_wallet);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_wallet, i);
        }
        return tokensId;
    }

    function getHash(uint256 season,  uint256 _t ,address _a , uint256 _c )
        internal view returns (uint256) {
        
        require(_c < 10);

        uint256 _hash = season;
        uint256 tmp;
        for (uint8 i = 1; i < 8; i++) {
            tmp = 
                uint256(
                    keccak256(
                        abi.encodePacked(
                            block.timestamp,
                            block.difficulty,
                            _t,
                            _a,
                            ( _c + i )
                        )
                    )
                ) % 0xFF;
            _hash |= uint256((tmp << ( i * 8 ) ));
        }
        return _hash;
    }

    function setArtwork( uint256 _amount, bytes memory _bodyPixels, string memory _name, bytes[] memory _eyes, bytes[] memory _mouth )
        external onlyOwner returns (uint256) {
        
        _bodyCount.increment();

        Body memory _body  = Body({
            name : _name,
            start: _tokenIds.current(),
            amount: _amount,
            pixels : _bodyPixels,
            eyes: _eyes,
            mouth: _mouth
        });

        indexToBodyType[ _bodyCount.current() ] = _body;
        return _bodyCount.current();
    }

    uint256 public _price = 120000000000000000;

   function setPrice( uint256 v) external onlyOwner {
        _price = v;
    }

    uint256 public _mintEnd = 1200;

    function setMintSend( uint256 v ) external {
        _mintEnd = v;
    }

    function mint()
        public
        payable
        nonReentrant
    {
        require( ( indexToBodyType[ _bodyCount.current() ].start + indexToBodyType[ _bodyCount.current() ].amount )  > (_tokenIds.current() + 1) , "Season has ended");
        require(_bodyCount.current() > 0, "No default art");
        //require(msg.value >= _price, "Not enough tokens");
        
        require( _nwBTCToken.allowance( msg.sender, address(this) ) >= _price,"Insuficient Allowance");
        require(_nwBTCToken.transferFrom(msg.sender,_stakeAddress,_price),"transfer Failed");

        _tokenIds.increment();
        _traitsIds.increment();
        uint256 thisTokenId = _tokenIds.current();
 
        tokenIdToHash[thisTokenId] = getHash( _bodyCount.current() , thisTokenId, msg.sender, 0);
        
        hashToMinted[ tokenIdToHash[thisTokenId] ] = true;
        _mint(msg.sender, thisTokenId);
        //emits: Transfer(from,to,tokenID)
    }


}
