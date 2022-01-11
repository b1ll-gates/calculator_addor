// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.11;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
//import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "./NFTLibrary.sol";

contract Market is IERC721Receiver, Ownable, ReentrancyGuard {

    using SafeMath for uint256;

    address payable private _devWallet;
    uint8 private _tax = 1;

    IERC20 private _nwBTCToken;
    IERC721 private _nft;

    uint256[] autionIds;

    mapping (uint256 => Auction) auctionDetails;

    constructor( IERC20 tkn , IERC721 nft ) {
        _nwBTCToken = tkn;
        _nft = nft;
    }

    function onERC721Received(
            address, 
            address from, 
            uint256 tokenId, 
            bytes calldata
            )external override returns(bytes4) {
        

        uint256 auctionId = uint256(keccak256(abi.encode(uint256(msg.sender), tokenId)));
        auctionDetails[auctionId] = Auction({
            nftContract: IERC721(msg.sender),
            bidIsComplete: false,
            seller: from,
            price: 0,
            buyNow: 0,
            timestamp: block.timestamp,
            winningBidder: address(0),
            tokenId: tokenId
        });

            return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    } 

    struct Auction {
        IERC721 nftContract;
        bool bidIsComplete;
        address seller;
        uint256 price;
        uint256 buyNow;
        uint256 timestamp;
        address payable winningBidder;
        uint256 tokenId;
    }

    function houseKeeping() internal {
        //remove old auctions
    }


    Auction[] offers;

    mapping (uint256 => Auction) tokenIdToOffer;
    mapping (uint256 => uint256) tokenIdToOfferId;

    event MarketTransaction(string TxType, address owner, uint256 tokenId);



     function completeAuction(uint256 auctionId) external {
        auctionDetails[auctionId].bidIsComplete = true;
    }

     function completeAuction(uint256 auctionId) external {
        auctionDetails[auctionId].bidIsComplete = true;
    }


    function getOffer(uint256 _tokenId)
        public
        view
        returns
        (
         address seller,
         uint256 price,
         uint256 tokenId
        ) {
            Auction storage offer = tokenIdToOffer[_tokenId];
            return (
                    offer.seller,
                    offer.price,
                    offer.tokenId
                   );
        }

    function getWonAuctions( address addr ) public view returns(uint256[] memory listofTokens){
            return new uint256[](0);
        
        
    }

    uint256 _aution_period = 60*60*24*14;

    function setAutionTimePeriod( uint256 v ) external onlyOwner {
        _aution_period = v;
    }

  function getTokensOnSale( address addr ) public view returns(uint256[] memory listOfToken){
        uint256 totalOffers = offers.length;

        if (totalOffers == 0) {
            return new uint256[](0);
        } else {
            uint256 offerCount = 0;

            uint256 i;
            uint256 count;

            for (i = 0; i < totalOffers; i++) {
                if( offers[ i].tokenId != 0 && addr == offers[i].seller) count++;
            }
 
            uint256[] memory result = new uint256[]( count  );
            count = 0;
            for (i = 0; i < totalOffers; i++) {
                if(offers[i].tokenId != 0 && addr == offers[i].seller ) result[ count++ ] = offers[ i ].tokenId;
            }
            return result;
        }
    }

/*
    function getAllTokensOnSale( ECR721 nftContract ) public view returns(uint256[] memory listOfToken){
        uint256 totalOffers = offers.length;

        if (totalOffers == 0) {
            return new uint256[](0);
        } else {

            uint256[] memory resultOfToken = new uint256[](totalOffers);

            uint256 offerId;

            for (offerId = 0; offerId < totalOffers; offerId++) {
                if(offers[offerId].price != 0 && offers[offerId].tokenId != 0){
                    resultOfToken[offerId] = offers[offerId].tokenId;
                }
            }
            return resultOfToken;
        }
    }

    function setOffer(uint256 _price, uint256 _tokenId)
        public
        nonReentrant
        {
            require(_price > 0.009 ether , "price should be greater than 0.01");
            require(tokenIdToOffer[_tokenId].price == 0, "You can't sell twice the same offers ");
            require(_nft.ownerOf(_tokenId) != msg.sender , "The user doesn't own the token");

            //_nft.approve( address(this), _tokenId);
            _nft.safeTransferFrom(msg.sender, address(this) , _tokenId);

            Offer memory _offer = Offer({
                seller: msg.sender,
                price: _price,
                tokenId: _tokenId
                });

            tokenIdToOffer[_tokenId] = _offer;
            offers.push(_offer);
            uint256 index = offers.length - 1;
            
            tokenIdToOfferId[_tokenId] = index;

            emit MarketTransaction("Create offer", msg.sender, _tokenId);
    }

    function removeOffer(uint256 _tokenId)
        public
        nonReentrant
    {

        Offer memory offer = tokenIdToOffer[_tokenId];

        require(msg.sender == offer.seller , "The user doesn't own the token");
        
        //_transfer(address(this), offer.seller, _tokenId);
        _nft.safeTransferFrom( address(this) , msg.sender, _tokenId );

        offers[ tokenIdToOfferId[_tokenId] ] = offers[offers.length-1];
        offers.pop();
        delete tokenIdToOfferId[_tokenId];
        delete tokenIdToOffer[_tokenId];

        emit MarketTransaction("Remove offer", msg.sender, _tokenId);
    }

    function buyNFT(uint256 _tokenId)
        public
        payable
        nonReentrant
    {
        Offer memory offer = tokenIdToOffer[_tokenId];
        require(msg.value == offer.price, "The price is not correct");
        require(msg.sender != address(0), "transfer to the zero address"); 
        require(msg.value > 0, "Transfer amount must be greater than zero"); 
       
        //TODO: change to be priced in the ECR20 
        uint256 _taxForDev = msg.value;
        _taxForDev = msg.value.mul( _tax).div( 100 ); 
        uint256 _amount = msg.value.sub( _taxForDev );
        
        offer.seller.transfer( _amount );
        _devWallet.transfer( _taxForDev );
        
        _nft.safeTransferFrom( address(this) , msg.sender , _tokenId );

        offers[ tokenIdToOfferId[_tokenId] ] = offers[offers.length-1];
        offers.pop();
        delete tokenIdToOfferId[_tokenId];
        delete tokenIdToOffer[_tokenId];

        emit MarketTransaction("Buy", msg.sender, _tokenId);
    }
*/
    function setDevAddress(address payable dev) public onlyOwner() {
        _devWallet = dev;
    }
    
    function setTokenAddress( IERC20 _token ) public onlyOwner {
        _nwBTCToken = _token;
    }
    
    function setNFTAddress( IERC721 addr ) public onlyOwner {
        _nft = addr;
    }
 
    function setTax( uint8 i) public onlyOwner() {
        _tax = i;
    }
}
