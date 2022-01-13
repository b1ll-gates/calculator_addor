import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFTStaking is Ownable {

    using SafeMath for uint256;
    
    uint256 private _rewardsRate = 1;
    uint256 private _maxStaking = 5;
    uint256 private _stakePeriod = 60*60*24*7;
    
    mapping( address => uint256[] ) private addressToStakingIds;
    mapping( uint256 => uint256 ) private tokenIdToStake; 
    mapping( uint256 => uint256 ) private rewardTotal; 
   

  


    IERC20 private _nwBTCToken;

    IERC721[] public approvedContracts;

    function contractIsApproved( IERC721 _contract ) internal returns ( bool ) {
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


      function onERC721Received(
            address, 
            address from, 
            uint256 tokenId, 
            bytes calldata
        ) external override returns(bytes4) {
        
        require( contractIsApproved( IERC721(msg.sender) ) ,"Contract must be approved");
        
         require( addressToStakingIds[ from ].length <= _maxStaking , "Cannot stake any more");
        for (uint i = 0; i < addressToStakingIds[ from ].length ; i++ ) {
            if ( addressToStakingIds[ from ][ i ] == tokenId )
                revert("Token is already staked");
        }
        tokenIdToStake[ tokenId ] = block.timestamp;
        rewardTotal[ tokenId ] = 0;
        addressToStakingIds[ from ].push( tokenId );
         
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }

    function stakeAllStaked( address addr ) public virtual returns ( uint256[] memory ) {
        return addressToStakingIds[ addr];
    }

    function stakeTokenRewards( uint256 i ) public virtual returns ( uint256 ) {
        return block.timestamp.sub( tokenIdToStake[ i ] ).mul( _rewardsRate );
    }
   /* 
    function stakeRenew( address addr) public virtual {
        require( addressToStakingIds[ addr ].length > 0 , "No tokens staked");
        for (uint i = 0; i < addressToStakingIds[ addr ].length ; i++ ) {
            if ( block.timestamp.sub( tokenIdToStake[ addressToStakingIds[ addr ][ i ] ] ) > _stakePeriod ) {
                rewardTotal[ addressToStakingIds[addr][i] ] += _rewardsRate;
                tokenIdToStake[ i ] = block.timestamp;
            }
        } 
    } 

    function stakeTimeRemaining( address addr) public virtual returns (uint256[] memory  ) {
        require( addressToStakingIds[ addr ].length > 0 , "No tokens staked");
        uint256[] memory stakeTimeLeft = new uint256[]( addressToStakingIds[ addr ].length );
        for( uint256 i = 0 ; i < addressToStakingIds[ addr ].length ; i ++ ) {
            stakeTimeLeft[ i ] = ( ( tokenIdToStake[ addressToStakingIds[ addr ][ i ] ] > _stakePeriod ) ? 0 :
                _stakePeriod.sub( tokenIdToStake[ addressToStakingIds[ addr ][ i ] ] ) );
        }
        return stakeTimeLeft;
    }
*/
    function stakeTotalRewards( address addr ) public virtual returns ( uint256 ) {
        require( addressToStakingIds[ addr ].length > 0 , "No tokens staked");
        uint256 t = 0;
        for (uint i = 0; i < addressToStakingIds[ addr ].length ; i++ ) {
            t.add( block.timestamp.sub( tokenIdToStake[ addressToStakingIds[ addr ][ i ] ] ).mul( _rewardsRate ) );
        }
        return t;
    }

    function stakeClaimRewards( address addr, uint256 _tokenId ) public virtual returns ( uint256 ) {
        require( addressToStakingIds[ addr ].length > 0 , "No tokens staked");
        uint256 val = tokenIdToStake[ _tokenId ];       
        for (uint i = 0; i < addressToStakingIds[ addr ].length ; i++ ) {
            if (addressToStakingIds[ addr ][ i ] == _tokenId ) {
                addressToStakingIds[ addr ][ i ] = addressToStakingIds[ addr ][ addressToStakingIds[ addr ].length - 1 ];
                addressToStakingIds[ addr ].pop();
                i = _maxStaking +2;
            }
        }
 
        uint256 valueTotal = 0;
        if ( block.timestamp.sub( val ) > _stakePeriod ) {
            valueTotal = _stakePeriod.mul( _rewardsRate );
        } else valueTotal = block.timestamp.sub( val ).mul( _rewardsRate );
        if ( rewardTotal[ _tokenId ] > 0 ) valueTotal.add( rewardTotal[ _tokenId]);
 
        delete tokenIdToStake[ _tokenId ];
        delete rewardTotal[ _tokenId ];

        return valueTotal;
    }
  ////////////////////////////////////////////////////////////OWNER FUNCTIONS
    //TODO: change to onlyDev

    function addApprovedContract( IERC721 _contract ) onlyOwner {
        approvedContracts.push( _contract );
    }

    function rmvApprovedContract( IERC721 _contract ) external onlyOwner {
        require( approvedContracts.length > 0,"No approved contracts");
        for ( uint256 i = 0; i < approvedContracts.length ; i++ ) {
            if ( approvedContracts[ i ] == _contract ) {
                approvedContracts[ i ] = approvedContracts[ approvedContracts'length - 1 ];
                approvedContracts.pop();
            }
        }
    }

    function setToken( ECR20 _tkn) external onlyOwner {
        _nwBTCToken = _tkn;
    }

    function stakeSetMaxStaking( uint256 v ) public virtual onlyOwner() {
        _maxStaking = v;
    }

    function stakeSetRewardsRate( uint256 r ) public virtual onlyOwner() {
        _rewardsRate = r;
    } 
    





}
