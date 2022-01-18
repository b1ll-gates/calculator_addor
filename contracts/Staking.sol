import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract Staking is IERC721Receiver, Ownable {

    using SafeMath for uint256;
    
    uint256 private _rewardsRate = 1;
    uint256 private _maxStaking = 5;
    uint256 private _stakePeriod = 60*60*24*7;
    
    mapping( address => uint256[] ) private addressToStakingIds;
    mapping( uint256 => Stake ) private stakeIdToStake; 

    struct Stake {
        IERC721 nftContract;
        address owner;
        uint256 tokenId;
        uint256 start;
        uint256 accumulatedRewards;
    }  

    IERC20 private _nwBTCToken;

    IERC721[] public approvedContracts;

    constructor( IERC20 tkn , IERC721 nft ) {
        _nwBTCToken = tkn;
        addApprovedContract( nft );
    }

    function contractIsApproved( IERC721 _contract ) internal returns ( bool ) {
        for ( uint256 i = 0; i < approvedContracts.length; i++ ) {
            if ( _contract == approvedContracts[ i ] ) return true;
        }
        return false;
    }

    function onERC721Received(
            address, 
            address from, 
            uint256 _tokenId, 
            bytes calldata
        ) external override returns(bytes4) {
        
        require( contractIsApproved( IERC721(msg.sender) ) ,"Contract must be approved");
        require( addressToStakingIds[ from ].length <= _maxStaking , "Cannot stake any more");
        uint256 stakeId = uint256(keccak256(abi.encode((msg.sender), _tokenId)));
        
        for (uint i = 0; i < addressToStakingIds[ from ].length ; i++ ) {
            if ( addressToStakingIds[ from ][ i ] == stakeId )
                revert("Token is already staked");
        }
        
        stakeIdToStake[ stakeId ] = Stake({
            nftContract : IERC721( msg.sender ),
            owner : from,
            tokenId: _tokenId, 
            start : block.timestamp,
            accumulatedRewards : 0
        });
        
        addressToStakingIds[ from ].push( stakeId );
         
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }

    function allStaked( address addr ) public returns ( uint256[] memory ) {
        uint256[] memory staked =  addressToStakingIds[ addr];
        return staked;
    }

    function stakeTokenRewards( uint256 _stakeId ) public virtual returns ( uint256 ) {
          require( contractIsApproved( stakeIdToStake[ _stakeId ].nftContract ) , "No token staked");
          uint256 t = block.timestamp.sub( stakeIdToStake[ _stakeId ].start ).add( stakeIdToStake[ _stakeId ].accumulatedRewards );
          return t.mul( _rewardsRate );
    }
    
    function stakeRenew( uint256 _stakeId ) public virtual {
        require( contractIsApproved( stakeIdToStake[ _stakeId ].nftContract ) , "No token staked");
        require( block.timestamp.sub( stakeIdToStake[ _stakeId ].start ) > _stakePeriod, "Stake period has not ended");
        require( msg.sender == stakeIdToStake[ _stakeId ].owner, "Must own the staked token");
        stakeIdToStake[ _stakeId ].accumulatedRewards = stakeIdToStake[ _stakeId ].accumulatedRewards.add( _stakePeriod.mul(_rewardsRate) );
        stakeIdToStake[ _stakeId ].start = block.timestamp; 
    }

    function getStakeDetails( uint256 _stakeId ) external view returns (
            IERC721 nftContract,
            uint256 tokenId,
            uint256 timeRemaining,
            uint256 accumulatedRewards
        ){
        Stake storage _stake = stakeIdToStake[ _stakeId ];
        require( msg.sender == _stake.owner, "Must own the staked token");
        uint256 t =  ( block.timestamp.sub( _stake.start ) > _stakePeriod ) ?
                0 : _stakePeriod.sub(  block.timestamp.sub( _stake.start ) );
          return (
            _stake.nftContract,
            _stake.tokenId,
            t,
            _stake.accumulatedRewards.add( t.mul( _rewardsRate ) )
        );        
    }
    

    function stakeClaimRewards( uint256 _stakeId ) public virtual returns ( uint256 ) {
        require( msg.sender == stakeIdToStake[ _stakeId ].owner, "Must own the staked token");
        
        Stake storage _stake = stakeIdToStake[ _stakeId ];
        uint256 valueTotal  =  ( block.timestamp.sub( _stake.start ) > _stakePeriod ) ? 0 : _stakePeriod.sub(  block.timestamp.sub( _stake.start ) );
        valueTotal = 2; _stake.accumulatedRewards.add( valueTotal.mul( _rewardsRate ) );
            
        _stake.nftContract.safeTransferFrom(address(this), msg.sender, _stake.tokenId);
        
        require(_nwBTCToken.approve(address(this),valueTotal ) ,"Approval Failed");
        //_nwBTCToken.allowance(address(this) , payable(_stake.owner));
        require(_nwBTCToken.transferFrom(address(this),payable(_stake.owner),valueTotal ) ,"transfer Failed");

        for (uint i = 0; i < addressToStakingIds[ _stake.owner ].length ; i++ ) {
            if (addressToStakingIds[ _stake.owner ][ i ] == _stakeId ) {
                addressToStakingIds[ _stake.owner ][ i ] = addressToStakingIds[ _stake.owner ][ addressToStakingIds[ _stake.owner ].length - 1 ];
                addressToStakingIds[ _stake.owner ].pop();
                i = addressToStakingIds[ _stake.owner ].length;
            }
        }
 
        delete stakeIdToStake[ _stakeId ];

        return valueTotal;
    }
  ////////////////////////////////////////////////////////////OWNER FUNCTIONS
    //TODO: change to onlyDev

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

    function setToken( IERC20 _tkn) external onlyOwner {
        _nwBTCToken = _tkn;
    }

    function stakeSetMaxStaking( uint256 v ) public virtual onlyOwner() {
        _maxStaking = v;
    }

    function stakeSetRewardsRate( uint256 r ) public virtual onlyOwner() {
        _rewardsRate = r;
    } 
    





}
