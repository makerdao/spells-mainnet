pragma solidity ^0.5.12;
pragma experimental ABIEncoderV2;

import "ds-test/test.sol";

import "dss/dai.sol";
import "dss/vat.sol";
import {Vow} from "dss/vow.sol";

contract VatLike {
    struct Ilk {
        uint256 Art;
        uint256 rate;
        uint256 spot;
        uint256 line;
        uint256 dust;
    }

    function ilks(bytes32) external view returns (Ilk memory);
}

contract DssLaunch is DSTest {
    Dai dai;
    Vat vat;
    Vow vow;
    VatLike.Ilk ethIlk;
    VatLike.Ilk batIlk;
    VatLike.Ilk saiIlk;

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
    }

    function test_eth_a_ilk_init() public {
        ethIlk = VatLike(address(vat)).ilks("ETH-A");
        assertTrue(ethIlk.rate > 0);
    }

    function test_eth_a_ilk_off() public {
        assertEq(ethIlk.Art, 0);
        assertEq(ethIlk.line, 0);
        assertEq(ethIlk.dust, 0);
    }

    function test_bat_a_ilk_init() public {
        batIlk = VatLike(address(vat)).ilks("BAT-A");
        assertEq(batIlk.Art, 0);
        assertTrue(batIlk.rate > 0);
    }

    function test_sai_ilk_init() public {
        saiIlk = VatLike(address(vat)).ilks("SAI");
        assertEq(saiIlk.Art, 0);
        assertTrue(saiIlk.rate > 0);
    }



    function test_vow() public {
        assertEq(vow.live(), 1);

        assertEq(vow.wait(), 172800);
        assertEq(vow.dump(), 250 ether);
        assertEq(vow.sump(), 50000 * 10 ** 45);
        assertEq(vow.bump(), 10000 * 10 ** 45);
        assertEq(vow.hump(), 500000 * 10 ** 45);
    }


}
