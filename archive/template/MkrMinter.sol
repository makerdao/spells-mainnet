pragma solidity ^0.5.12;

import "lib/dss-interfaces/src/Interfaces.sol";

contract MKRMinter {
    function doMint(address gov, address dst, uint wad) public {
        DSTokenAbstract(gov).mint(dst, wad);
    }
}
