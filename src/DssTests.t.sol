pragma solidity ^0.5.12;

import "ds-test/test.sol";

import "dss/dai.sol";
import "dss/vat.sol";
import "dss/vow.sol";

contract DssTests is DSTest {
    Dai dai;
    Vat vat;
    Vow vow;

    function setUp() public {
        dai = Dai(0x6B175474E89094C44Da98b954EedeAC495271d0F);
        vat = Vat(0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B);
        vow = Vow(0xA950524441892A31ebddF91d3cEEFa04Bf454466);
    }

    function test_dai_token() public {
        assertEq(dai.totalSupply(), 0);
    }

    function test_vat() public {
        assertEq(vat.live(), 1);

        (uint256 Art,,,,) = vat.ilks("ETH-A");
        assertEq(Art, 0);
    }

    function test_vow() public {
        assertEq(vow.live(), 1);

        assertEq(vow.wait(), 172800);
        assertEq(vow.dump(), 250 ether);
        assertEq(vow.sump(), 50000 ether);
        assertEq(vow.bump(), 10000 ether);
        assertEq(vow.hump(), 500000 ether);
    }


}
