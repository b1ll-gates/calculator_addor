// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.11;
//pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract NwBTC is ERC20 
{
    
    uint256 private _tTotal = 100000 * 10**12 * 10**9;      
    uint256 private _handout = 10**21;      
    uint8 private _decimals = 9; 
    
    constructor() ERC20("Generic Token", "TOKEN") {
        _mint( msg.sender, _tTotal );
        _transfer( msg.sender , address(this) , _tTotal );         
    }

    function faucet() external payable {
        require( totalSupply() > _handout , "It's all gone");
        _transfer( address(this) , msg.sender , _handout );         
    }
    
}
