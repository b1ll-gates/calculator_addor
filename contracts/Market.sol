// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.11;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
//import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract Market is IERC721Receiver, Ownable, ReentrancyGuard {

    using SafeMath for uint256;

    address payable private _devWallet;
    address public _stakeLiquidity = address( 0 );

    uint8 private _tax = 1;

    IERC20 private _nwBTCToken;
    IERC721[] public approvedContracts;
    uint256[] auctionIds;

    mapping (uint256 => Auction) auctionDetails;

    uint256 public auctionTimePeriod = 60*60*24*14;
    uint256 public maxBidChange = 2 * 10**9 * 10**9;

    struct Auction {
        IERC721 nftContract;
        bool bidIsComplete;
        address seller;
        uint256 highestBid;
        uint256 buyNow;
        uint256 timestamp;
        address winningBidder;
        uint256 tokenId;
    }

    event MarketTransaction(string TxType, address owner, uint256 tokenId);

    constructor( IERC20 tkn , IERC721 nft ) {
        _nwBTCToken = tkn;
        addApprovedContract( nft );
        _devWallet = msg.sender;
       // _stakeLiquidity = payable( _liquidity );
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
        uint256 auctionId = uint256(keccak256(abi.encode((msg.sender), tokenId)));
        auctionDetails[auctionId] = Auction({
            nftContract: IERC721(msg.sender),
            bidIsComplete: false,
            seller: from,
            highestBid: 0,
            buyNow: 0,
            timestamp: block.timestamp,
            winningBidder: address(0x0),
            tokenId: tokenId
        });

        auctionIds.push( auctionId );
        emit MarketTransaction("forSale", from, tokenId);
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }

    function setBuyNow( uint256 _auctionID , uint256 _buyNowPrice ) external {
        require( auctionDetails[ _auctionID ].seller == msg.sender, "You have to own the auction");
        require( auctionDetails[ _auctionID ].highestBid < _buyNowPrice ,"The price must be greater than the highest bid");
        auctionDetails[ _auctionID ].buyNow = _buyNowPrice;
    }

    function completeAuction(uint256 _auctionId) external {
        require( auctionDetails[ _auctionId ].winningBidder != address( 0 ), "There has to be a bid");
        require( auctionDetails[ _auctionId ].highestBid > 0 , "There has to be a bid");
        auctionDetails[_auctionId].bidIsComplete = true;
    }

    function withdrawAuction( uint256 _auctionID  )
        external
        nonReentrant
    {

        require( auctionDetails[ _auctionID ].seller == msg.sender, "You have to own the auction");
        require( ! auctionDetails[ _auctionID ].bidIsComplete, "You can't withdraw a complete action");
        require( block.timestamp - auctionDetails[ _auctionID ].timestamp < auctionTimePeriod
            || (  block.timestamp - auctionDetails[ _auctionID ].timestamp > auctionTimePeriod
&& auctionDetails[ _auctionID ].highestBid > 0) , "You can't withdraw a played out action");

        Auction storage details = auctionDetails[_auctionID];
        details.nftContract.safeTransferFrom(address(this), details.seller, details.tokenId);
        _deleteAuction( _auctionID );
        emit MarketTransaction("endSale", details.seller, details.tokenId);
    }

    function reNewAuction( uint256 _auctionID ) external {
        require( auctionDetails[ _auctionID ].seller == msg.sender, "You have to own the auction");
        auctionDetails[ _auctionID ].timestamp = block.timestamp;
    }

    ////////////////////////////////////////////////////////////BUYER FUNCTIONS
    function payNow( uint256 _auctionId )
        external
        nonReentrant
    {

        uint256 _taxAmount;
        Auction storage details = auctionDetails[ _auctionId ];
        require( details.buyNow > 0 && details.winningBidder == address(0),"Auction must be set as buy now");
        require( _nwBTCToken.allowance( msg.sender, address(this) ) >= details.buyNow,"Insuficient Allowance");
        _taxAmount = details.buyNow.mul( _tax).div( 100 ); 
        uint256 _amount = details.buyNow.sub( _taxAmount );
        if ( _stakeLiquidity != address( 0 ) ) {
            _amount = _amount.sub( _taxAmount );
            require(_nwBTCToken.transferFrom(msg.sender,_stakeLiquidity,_taxAmount),"transfer Failed");
        }        
        require(_nwBTCToken.transferFrom(msg.sender,_devWallet,_taxAmount),"transfer Failed");
        require(_nwBTCToken.transferFrom(msg.sender,details.seller,_amount),"transfer Failed");

        details.nftContract.safeTransferFrom(address(this), msg.sender, details.tokenId);
        _deleteAuction( _auctionId );

        emit MarketTransaction("buy", msg.sender, details.tokenId);
    }

    function payForWonAuction( uint256 _auctionID )
        external
        nonReentrant
    {

        uint256 _taxAmount;
        Auction storage details = auctionDetails[ _auctionID ];

        require( details.bidIsComplete || (block.timestamp - details.timestamp ) > auctionTimePeriod , "Auction must be over");
        require(  details.winningBidder == msg.sender,"You must be the aution winner");
        require( _nwBTCToken.allowance( msg.sender, address(this) ) >= details.highestBid,"Insuficient Allowance");

        _taxAmount = details.highestBid.mul( _tax).div( 100 ); 
        uint256 _amount = details.highestBid.sub( _taxAmount );
        if ( _stakeLiquidity != address( 0 ) ) {
            _amount = _amount.sub( _taxAmount );
            require(_nwBTCToken.transferFrom(msg.sender,_stakeLiquidity,_taxAmount),"transfer Failed");
        }        
        require(_nwBTCToken.transferFrom(msg.sender,_devWallet,_taxAmount),"transfer Failed");
        require(_nwBTCToken.transferFrom(msg.sender,details.seller,_amount),"transfer Failed");

        details.nftContract.safeTransferFrom(address(this), msg.sender, details.tokenId);
        _deleteAuction( _auctionID );

        emit MarketTransaction("buy", msg.sender, details.tokenId);

     }

    function setBid( uint256 _auctionID , uint256 _bidAmount) external {
        require( auctionDetails[ _auctionID ].seller != msg.sender, "You cannot own the auction item");
        require( ! auctionDetails[ _auctionID ].bidIsComplete, "The bidding is complete");
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
        bool bidIsComplete,
        address seller,
        uint256 highestBid,
        uint256 buyNow,
        uint256 timestamp,
        uint256 tokenId
         ) {

            Auction storage action = auctionDetails[_auctionID];
            return (
                    action.nftContract,
                    action.bidIsComplete,
                    action.seller,
                    action.highestBid,
                    action.buyNow,
                    action.timestamp,
                    action.tokenId
                   );
        }

    function getWonAuctions( address _addr ) public view returns(uint256[] memory listofTokens){
        if (auctionIds.length == 0) {
            return new uint256[](0);
        } else {
            uint256 count = 0;
            uint256 i;
            for (i = 0; i < auctionIds.length; i++) {
                if( auctionDetails[ auctionIds[ i ] ].winningBidder == _addr ) count++;
            }

            uint256[] memory result = new uint256[]( count );
            count = 0;
            for (i = 0; i < auctionIds.length; i++) {
                if( auctionDetails[ auctionIds[ i ] ].winningBidder == _addr ) result[ count++ ] = auctionIds[ i ];
            }
            return result;
        }
    }

  function getTokensOnSale( address _addr ) public view returns(uint256[] memory listOfToken){
        if (auctionIds.length == 0) {
            return new uint256[](0);
        } else {
            uint256 count = 0;
            uint256 i;
            for (i = 0; i < auctionIds.length; i++) {
                if( auctionDetails[ auctionIds[ i ] ].seller == _addr ) count++;
            }

            uint256[] memory result = new uint256[]( count );
            count = 0;
            for (i = 0; i < auctionIds.length; i++) {
                if( auctionDetails[ auctionIds[ i ] ].seller == _addr ) result[ count++ ] = auctionIds[ i ];
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
                if(
                   ( block.timestamp - auctionDetails[ auctionIds[ i ] ].timestamp ) < auctionTimePeriod &&
                   auctionDetails[ auctionIds[ i ] ].nftContract == _contract
                   && ! auctionDetails[ auctionIds[ i ] ].bidIsComplete
                    ) count++;
            }

            uint256[] memory result = new uint256[]( count );
            count = 0;
            for (i = 0; i < auctionIds.length; i++) {
                if(
                   ( block.timestamp - auctionDetails[ auctionIds[ i ] ].timestamp ) < auctionTimePeriod &&
                    auctionDetails[ auctionIds[ i ] ].nftContract == _contract
                   && !  auctionDetails[ auctionIds[ i ] ].bidIsComplete
                ) result[ count++ ] = auctionIds[ i ];
            }
            return result;
        }
    }

    ////////////////////////////////////////////////////////////OWNER FUNCTIONS

    function addApprovedContract( IERC721 _contract ) public onlyOwner {
        approvedContracts.push( _contract );
    }

    function rmvApprovedContract( IERC721 _contract ) external onlyOwner {
        require( approvedContracts.length > 0,"No approved contracts");
        for ( uint256 i = 0; i < approvedContracts.length ; i++ ) {
            if ( approvedContracts[ i ] == _contract ) {
                approvedContracts[ i ] = approvedContracts[ approvedContracts.length - 1 ];
                approvedContracts.pop();
            }
        }
    }

    function setDevWallet( address payable _addr ) external onlyOwner {
        _devWallet = _addr;
    }

    function setStakeLiquidity( address payable _addr ) external onlyOwner {
        _stakeLiquidity = _addr;
    }

    function setToken( IERC20 _tkn) external onlyOwner {
        _nwBTCToken = _tkn;
    }

    function setTax( uint8 _t ) external onlyOwner {
        _tax = _t;
    }

}


