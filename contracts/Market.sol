// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.11;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
//import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract Market is IERC721Receiver, Ownable, ReentrancyGuard {

    using SafeMath for uint256;

    address payable private _devWallet;
    address payable private _marketWallet;
    address public _stakeLiquidity = address( 0 );

    uint8 private _tax = 1;

    IERC721[] public approvedContracts;
    uint256[] auctionIds;

    mapping (uint256 => Auction) auctionDetails;

    uint256 public auctionTimePeriod = 60*60*24*14;
    uint256 public maxBidChange = 200000000000000000000;

    using Counters for Counters.Counter;
    Counters.Counter private _auctionIds;
 
    struct Auction {
        IERC721 nftContract;
        address seller;
        uint256 highestBid;
        uint256 buyNow;
        uint256 timestamp;
        address winningBidder;
        uint256 tokenId;
    }

    event MarketTransaction(string TxType, address owner, IERC721 nftContract, uint256 auctionId, uint256 tokenId);

    constructor( IERC721 nft ) {
        approvedContracts.push( nft );
        _devWallet = msg.sender;
    }

    function contractIsApproved( IERC721 _contract ) internal view returns ( bool ) {
        for ( uint256 i = 0; i < approvedContracts.length; i++ ) {
            if ( _contract == approvedContracts[ i ] ) return true;
        }
        return false;
    }

    function _deleteAuction( uint256 _auctionID ) internal returns (bool) {
        delete auctionDetails[ _auctionID ];
        for (uint256 i = 0; i < auctionIds.length ; i++ ) {
            if ( auctionIds[ i ] == _auctionID ) {
                auctionIds[ i ] = auctionIds[ auctionIds.length - 1 ];
                auctionIds.pop();
                return true;
            }
        } 
        return false;
    }

    ////////////////////////////////////////////////////////////SELLER FUNCTIONS
    function onERC721Received(
            address, 
            address from, 
            uint256 tokenId, 
            bytes calldata
        ) external override returns(bytes4) {
        
        require( contractIsApproved( IERC721(msg.sender) ) ,"Contract must be approved");
        _auctionIds.increment();

        auctionDetails[ _auctionIds.current()  ] = Auction({
            nftContract: IERC721(msg.sender),
            seller: from,
            highestBid: 0,
            buyNow: 0,
            timestamp: block.timestamp,
            winningBidder: address(0x0),
            tokenId: tokenId
        });

        auctionIds.push( _auctionIds.current() );
        emit MarketTransaction("forSale", from, IERC721( msg.sender ) , _auctionIds.current(), tokenId);
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }

    function setBuyNow( uint256 _auctionID , uint256 _buyNowPrice ) external {
        require( auctionDetails[ _auctionID ].seller == msg.sender, "You have to own the auction");
        require( auctionDetails[ _auctionID ].highestBid < _buyNowPrice ,"The price must be greater than the highest bid");
        auctionDetails[ _auctionID ].buyNow = _buyNowPrice;
    }

    function withdrawAuction( uint256 _auctionID  )
        external
        nonReentrant
    {

        require( auctionDetails[ _auctionID ].seller == msg.sender, "You have to own the auction");
        require( auctionDetails[ _auctionID ].buyNow > 0 ||
            ( 
                ( ( block.timestamp - auctionDetails[ _auctionID ].timestamp ) < auctionTimePeriod ||
                    ( block.timestamp - auctionDetails[ _auctionID ].timestamp ) <  2*auctionTimePeriod )
            && auctionDetails[ _auctionID ].highestBid > 0 ), "You can't withdraw a played out action, till auctionPeriod");

        Auction storage details = auctionDetails[_auctionID];
        details.nftContract.safeTransferFrom(address(this), details.seller, details.tokenId);
        emit MarketTransaction("endSale", details.seller, IERC721( details.nftContract ), _auctionID, details.tokenId );
        _deleteAuction( _auctionID );
    }

    function reNewAuction( uint256 _auctionID ) external {
        require( auctionDetails[ _auctionID ].seller == msg.sender, "You have to own the auction");
        if ( auctionDetails[ _auctionID ].buyNow == 0 ) { 
            if ( auctionDetails[ _auctionID ].highestBid == 0 ||  block.timestamp - auctionDetails[ _auctionID ].timestamp >  2*auctionTimePeriod ) auctionDetails[ _auctionID ].timestamp = block.timestamp;
            else revert("Cannot renew an auction before its end, if there is a bid");
        } else revert("Sale is set to buy now");
    }

    ////////////////////////////////////////////////////////////BUYER FUNCTIONS
    function payNow( uint256 _auctionId )
        external
        payable
        nonReentrant
    {

        uint256 _taxAmount;
        Auction storage details = auctionDetails[ _auctionId ];
        require( details.buyNow > 0 && details.winningBidder == address(0),"Auction must be set as buy now");
        require( msg.value >= details.buyNow,"Insufficient amount");
        //require( _nwBTCToken.allowance( msg.sender, address(this) ) >= details.buyNow,"Insuficient Allowance");

        _taxAmount = details.buyNow.mul( _tax).div( 100 ); 
        uint256 _amount = details.buyNow.sub( _taxAmount );
        if ( _marketWallet != address( 0 ) ) {
            _amount = _amount.sub( _taxAmount );
            _marketWallet.transfer( _taxAmount );
        }
     
        _devWallet.transfer(_taxAmount);
        payable( details.seller ).transfer(_amount);

        details.nftContract.safeTransferFrom(address(this), msg.sender, details.tokenId);

        emit MarketTransaction("buy", msg.sender, IERC721( details.nftContract ) , _auctionId, details.tokenId );
        _deleteAuction( _auctionId );
    }

    function payForWonAuction( uint256 _auctionID )
        external
        payable
        nonReentrant
    {

        uint256 _taxAmount;
        Auction storage details = auctionDetails[ _auctionID ];

        require( (block.timestamp - details.timestamp ) > auctionTimePeriod , "Auction must be over");
        require(  details.winningBidder == msg.sender,"You must be the aution winner");
        require( msg.value >= details.highestBid,"Insuficient Amount");

        _taxAmount = details.highestBid.mul( _tax).div( 100 ); 
        uint256 _amount = details.highestBid.sub( _taxAmount );
        if ( _stakeLiquidity != address( 0 ) ) {
            _amount = _amount.sub( _taxAmount );
            _marketWallet.transfer( _taxAmount );
        }        
        _devWallet.transfer( _taxAmount );
        payable( details.seller ).transfer( _amount );

        details.nftContract.safeTransferFrom(address(this), msg.sender, details.tokenId);

        emit MarketTransaction("buy", msg.sender, IERC721( details.nftContract ), _auctionID, details.tokenId);

        _deleteAuction( _auctionID );
     }

    function setBid( uint256 _auctionID , uint256 _bidAmount) external {
        require( auctionDetails[ _auctionID ].seller != msg.sender, "You cannot own the auction item");

        require( auctionDetails[ _auctionID ].seller != msg.sender, "You cannot own the auction item");

        require( auctionDetails[ _auctionID ].highestBid < _bidAmount, "You must place a higher bid");

        require( auctionDetails[ _auctionID ].highestBid + maxBidChange >= _bidAmount, "You cannot exceed the max bid change");
        auctionDetails[ _auctionID ].highestBid = _bidAmount;
        auctionDetails[ _auctionID ].winningBidder = msg.sender;
    }

    ///////////////////////////////////////////////////////////UI FUNCTIONS

    function getAuction( uint256 _auctionID ) external view
        returns
        (
        IERC721 nftContract,
        address seller,
        uint256 highestBid,
        uint256 buyNow,
        uint256 timestamp,
        uint256 tokenId
         ) {

            Auction storage _auction = auctionDetails[_auctionID];
            return (
                    _auction.nftContract,
                    _auction.seller,
                    _auction.highestBid,
                    _auction.buyNow,
                    _auction.timestamp,
                    _auction.tokenId
                   );
        }

    function getAuctionByToken( address _contract , uint256 _tokenId ) external view
        returns (
            uint256 auctionId,
            address seller,
            uint256 highestBid,
            uint256 buyNow,
            uint256 timestamp
        ) {
            for (uint256 i = 0; i < auctionIds.length; i++) {
                if( auctionDetails[ auctionIds[ i ] ].nftContract == IERC721(_contract) 
                    && auctionDetails[ auctionIds[ i ] ].tokenId == _tokenId ){
                        Auction storage _auction = auctionDetails[ auctionIds[ i ] ];
                        return (
                            auctionIds[ i ],
                            _auction.seller,
                            _auction.highestBid,
                            _auction.buyNow,
                            _auction.timestamp
                        );
                }
            }
        revert("Token not found");
    }

    function getWonAuctions( IERC721 _contract , address _addr ) public view returns(uint256[] memory listofTokens){
        if (auctionIds.length == 0) {
            return new uint256[](0);
        } else {
            uint256 count = 0;
            uint256 i;
            for (i = 0; i < auctionIds.length; i++) {
                if( auctionDetails[ auctionIds[ i ] ].winningBidder == _addr 
                    && ( block.timestamp - auctionDetails[ auctionIds[ i ] ].timestamp ) > auctionTimePeriod
                    && auctionDetails[ auctionIds[ i ] ].nftContract == _contract ) count++;
            }

            uint256[] memory result = new uint256[]( count );
            count = 0;
            for (i = 0; i < auctionIds.length; i++) {
                if( auctionDetails[ auctionIds[ i ] ].winningBidder == _addr
                    && ( block.timestamp - auctionDetails[ auctionIds[ i ] ].timestamp ) > auctionTimePeriod
                    && auctionDetails[ auctionIds[ i ] ].nftContract == _contract ) result[ count++ ] = auctionIds[ i ];
            }
            return result;
        }
    }

  function getTokensOnSale( IERC721 _contract , address _addr ) public view returns(uint256[] memory listOfToken){
        if (auctionIds.length == 0) {
            return new uint256[](0);
        } else {
            uint256 count = 0;
            uint256 i;
            for (i = 0; i < auctionIds.length; i++) {
                if( auctionDetails[ auctionIds[ i ] ].seller == _addr
                    && auctionDetails[ auctionIds[ i ] ].nftContract == _contract ) count++;
            }

            uint256[] memory result = new uint256[]( count );
            count = 0;
            for (i = 0; i < auctionIds.length; i++) {
                if( auctionDetails[ auctionIds[ i ] ].seller == _addr
                    && auctionDetails[ auctionIds[ i ] ].nftContract == _contract ) result[ count++ ] = auctionIds[ i ];
            }
            return result;
        }
    }

    function getAllTokensOnSale( IERC721 _contract ) public view returns(uint256[] memory listOfToken){

        if (auctionIds.length == 0) {
            return new uint256[](0);
        } else {
            uint256 count = 0;
            uint256 i;
            for (i = 0; i < auctionIds.length; i++) {
                if ( auctionDetails[ auctionIds[ i ] ].nftContract == _contract &&
                     ( auctionDetails[ auctionIds[ i ] ].buyNow > 0 || 
                        ( block.timestamp - auctionDetails[ auctionIds[ i ] ].timestamp ) < auctionTimePeriod ) ) count++;
            }

            uint256[] memory result = new uint256[]( count );
            count = 0;
            for (i = 0; i < auctionIds.length; i++) {
                if ( auctionDetails[ auctionIds[ i ] ].nftContract == _contract &&
                    ( auctionDetails[ auctionIds[ i ] ].buyNow > 0 || 
                        ( block.timestamp - auctionDetails[ auctionIds[ i ] ].timestamp ) < auctionTimePeriod ) ) result[ count++ ] = auctionIds[ i ];
            }
            return result;
        }
    }

    ////////////////////////////////////////////////////////////OWNER FUNCTIONS

    function addApprovedContract( IERC721 _contract ) public {
        require( owner() == _msgSender() || _devWallet == _msgSender(),"Must be owner or dev");
        approvedContracts.push( _contract );
    }

    function rmvApprovedContract( IERC721 _contract ) external {
        require( owner() == _msgSender() || _devWallet == _msgSender(),"Must be owner or dev");
        require( approvedContracts.length > 0,"No approved contracts");
        for ( uint256 i = 0; i < approvedContracts.length ; i++ ) {
            if ( approvedContracts[ i ] == _contract ) {
                approvedContracts[ i ] = approvedContracts[ approvedContracts.length - 1 ];
                approvedContracts.pop();
            }
        }
    }

    function setDevWallet( address payable _addr ) external {
        require( owner() == _msgSender() || _devWallet == _msgSender(),"Must be owner or dev");
        _devWallet = _addr;
    }

    function setMarketWallet( address payable _addr ) external {
        require( owner() == _msgSender() || _devWallet == _msgSender(),"Must be owner or dev");
        _stakeLiquidity = _addr;
    }

    function setMaxBidChange( uint256 v ) external {
        require( owner() == _msgSender() || _devWallet == _msgSender(),"Must be owner or dev");
        maxBidChange = v;        
    }

    function setAuctionTimePeriod( uint256 t ) external {
        require( owner() == _msgSender() || _devWallet == _msgSender(),"Must be owner or dev");
        auctionTimePeriod = t;
    }

    function setTax( uint8 _t ) external {
        require( owner() == _msgSender() || _devWallet == _msgSender(),"Must be owner or dev");
        _tax = _t;
    }
}


