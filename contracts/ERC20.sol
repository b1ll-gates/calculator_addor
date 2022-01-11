// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.11;
//pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract NwBTC is ERC20 
{
    
    uint256 private _tTotal = 100000 * 10**12 * 10**9;      
    uint8 private _decimals = 9; 
    
    constructor() ERC20("Generic Token", "TOKEN") {
        _mint( msg.sender, _tTotal );
    }
    
}
