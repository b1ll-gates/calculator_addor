pragma solidity >=0.6.0 <0.8.11;

interface NwBTCNFT {

    function getPrice() external returns(uint256);

    function canMint() external returns(bool);

    function mint() external;

    function walletOfOwner(address addr) external view returns (uint256[] memory );

}
