pragma solidity ^0.5.12;

import "ds-test/test.sol";

import {Dai} from "dss/dai.sol";
import {Vat} from "dss/vat.sol";
import {Vow} from "dss/vow.sol";
import {ERC20} from "erc20/erc20.sol";

import {DssLaunchSpell} from "./DssLaunchSpell.sol";

contract ChiefLike {
    function hat() public view returns (address);
    function lock(uint) public; 
    function vote(address[] memory) public;
    function lift(address) public;
}

contract RegistryLike {
    function build() public returns (ProxyLike);
}

contract ProxyLike {
    function execute(address, bytes memory) public payable;
}

contract TokenLike {
    function balanceOf(address) public view returns (uint);
    function approve(address, uint) public;
}

contract ManagerLike {
    function urns(uint) public view returns (address);
}

contract TubLike {
    function ink(bytes32) public view returns (uint);
    function per() public view returns (uint);
    function rap(bytes32) public returns (uint);
    function tab(bytes32) public returns (uint);
}

contract ValueLike {
    function peek() public view returns (uint, bool);
}

contract OtcLike {
    function getPayAmount(address, address, uint) public view returns (uint);
}

contract Hevm {
    function warp(uint) public;
}

contract DssLaunchAfterSpell is DSTest {
    Hevm hevm;

    Dai dai = Dai(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    Vat vat = Vat(0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B);
    Vow vow = Vow(0xA950524441892A31ebddF91d3cEEFa04Bf454466);
    ERC20 gov = ERC20(0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2);
    ChiefLike chief = ChiefLike(0x9eF05f7F6deB616fd37aC3c959a2dDD25A54E4F5);
    ProxyLike proxy;
    address proxyActions = 0x82ecD135Dce65Fbc6DbdD0e4237E0AF93FFD5038;
    address migrationPActions = 0xe4B22D484958E582098A98229A24e8A43801b674;
    address migration = 0xc73e0383F3Aff3215E6f04B0331D58CeCf0Ab849;
    address manager = 0x5ef30b9986345249bc32d8928B7ee64DE9435E39;
    address jug = 0x19c0976f590D67707E62397C87829d896Dc0f1F1;
    address ethJoin = 0x2F0b23f53734252Bda2277357e97e1517d6B042A;
    address daiJoin = 0x9759A6Ac90977b93B58547b4A71c78317f391A28;

    address saiPActions = 0x526af336D614adE5cc252A407062B8861aF998F5;
    TubLike tub = TubLike(0x448a5065aeBB8E423F0896E6c5D525C040f59af3);
    TokenLike sai = TokenLike(0x89d24A6b4CcB1B6fAA2625fE562bDD9a23260359);
    ValueLike pep = ValueLike(0x99041F808D598B782D5a3e498681C2452A31da08);

    OtcLike otc = OtcLike(0x39755357759cE0d7f32dC8dC45414CCa409AE24e);

    DssLaunchSpell spell = DssLaunchSpell(0xF44113760c4f70aFeEb412C63bC713B13E6e202E);

    uint constant RAD = 10 ** 45;

    function setUp() public {
        RegistryLike registry = RegistryLike(0x4678f0a6958e4D2Bc4F1BAF7Bc52E8F3564f3fE4);
        // spell = new DssLaunchSpell();

        hevm = Hevm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
        hevm.warp(1574092700);

        proxy = registry.build();
    }

    function vote() private {
        gov.approve(address(chief), uint256(-1));
        chief.lock(gov.balanceOf(address(this)));

        assertTrue(!spell.done());

        address[] memory vote = new address[](1);
        vote[0] = address(spell);

        chief.vote(vote);
        chief.lift(address(spell));
        assertEq(chief.hat(), address(spell));
    }

    function waitAndCast() public {
        // Let's push the time to the launch moment
        hevm.warp(1574092800);
        spell.cast();
    }

    function testSpellIsCasted() public {
        assertEq(vat.Line(), 0);
        (,,, uint line,) = vat.ilks("ETH-A");
        assertEq(line, 0);
        (,,, line,) = vat.ilks("BAT-A");
        assertEq(line, 0);
        (,,, line,) = vat.ilks("SAI");
        assertEq(line, 0);

        vote();
        waitAndCast();

        assertTrue(spell.done());
        assertEq(vat.Line(), 153000000 * RAD);
        (,,, line,) = vat.ilks("ETH-A");
        assertEq(line, 50000000 * RAD);
        (,,, line,) = vat.ilks("BAT-A");
        assertEq(line, 3000000 * RAD);
        (,,, line,) = vat.ilks("SAI");
        assertEq(line, 100000000 * RAD);
    }

    function testFailSpellCast() public {
        vote();
        // It can not be spelled if the time for launch hasn't passed
        spell.cast();
    }

    function openCdpAndGenerateDai(uint ilkAmt, uint daiAmt) private returns (uint cdp) {
        uint value = ilkAmt;
        address target = address(proxy);
        bytes memory data = abi.encodeWithSignature(
            "execute(address,bytes)",
            proxyActions,
            abi.encodeWithSignature(
                "openLockETHAndDraw(address,address,address,address,bytes32,uint256)",
                manager,
                jug,
                ethJoin,
                daiJoin,
                bytes32("ETH-A"),
                daiAmt
            )
        );
        assembly {
            let succeeded := call(sub(gas, 5000), target, value, add(data, 0x20), mload(data), 0, 0)
            let size := returndatasize
            let response := mload(0x40)
            mstore(0x40, add(response, and(add(add(size, 0x20), 0x1f), not(0x1f))))
            mstore(response, size)
            returndatacopy(add(response, 0x20), 0, size)

            cdp := mload(add(response, 0x20))

            switch iszero(succeeded)
            case 1 {
                // throw if delegatecall failed
                revert(add(response, 0x20), size)
            }
        }
    }

    function testCreateETHVault() public {
        vote();
        waitAndCast();

        uint cdp = openCdpAndGenerateDai(10 ether, 1000 ether);

        address urn = ManagerLike(manager).urns(cdp);

        (uint ink, uint art) = vat.urns("ETH-A", urn);
        (, uint rate,,,) = vat.ilks("ETH-A");

        assertEq(ink, 10 ether);
        assertEq(art, 1000 ether * 10 ** 27 / rate + 1);
    }

    function openCupAndGenerateSai(uint ethAmt, uint saiAmt) private returns (bytes32 cup) {
        uint value = ethAmt;
        address target = address(proxy);
        bytes memory data = abi.encodeWithSignature(
            "execute(address,bytes)",
            saiPActions,
            abi.encodeWithSignature(
                "lockAndDraw(address,uint256)",
                address(tub),
                saiAmt
            )
        );
        assembly {
            let succeeded := call(sub(gas, 5000), target, value, add(data, 0x20), mload(data), 0, 0)
            let size := returndatasize
            let response := mload(0x40)
            mstore(0x40, add(response, and(add(add(size, 0x20), 0x1f), not(0x1f))))
            mstore(response, size)
            returndatacopy(add(response, 0x20), 0, size)

            cup := mload(add(response, 0x20))

            switch iszero(succeeded)
            case 1 {
                // throw if delegatecall failed
                revert(add(response, 0x20), size)
            }
        }
    }

    function swapSaiToDai(uint amt) private {
        sai.approve(address(proxy), amt);
        proxy.execute(
            migrationPActions,
            abi.encodeWithSignature(
                "swapSaiToDai(address,uint256)",
                migration,
                amt
            )
        );
    }

    function testSwapSaiToDaiAndBack() public {
        vote();
        waitAndCast();

        assertEq(sai.balanceOf(address(this)), 0);
        // Generates SAI
        openCupAndGenerateSai(10 ether, 1000 ether);
        assertEq(sai.balanceOf(address(this)), 1000 ether);
        assertEq(dai.balanceOf(address(this)), 0);

        // Swaps 1000 SAI for 1000 DAI
        swapSaiToDai(1000 ether);

        assertEq(sai.balanceOf(address(this)), 0);
        assertEq(dai.balanceOf(address(this)), 1000 ether);

        dai.approve(address(proxy), 1000 ether);

        // Swaps 1000 SAI for 1000 DAI
        proxy.execute(
            migrationPActions,
            abi.encodeWithSignature(
                "swapDaiToSai(address,uint256)",
                migration,
                1000 ether
            )
        );

        assertEq(sai.balanceOf(address(this)), 1000 ether);
        assertEq(dai.balanceOf(address(this)), 0);
    }

    function migrateCdp(bytes memory _data) private returns (uint cdp) {
        bytes memory data = abi.encodeWithSignature(
            "execute(address,bytes)",
            migrationPActions,
            _data
        );
        address target = address(proxy);
        assembly {
            let succeeded := call(sub(gas, 5000), target, 0, add(data, 0x20), mload(data), 0, 0)
            let size := returndatasize
            let response := mload(0x40)
            mstore(0x40, add(response, and(add(add(size, 0x20), 0x1f), not(0x1f))))
            mstore(response, size)
            returndatacopy(add(response, 0x20), 0, size)

            cdp := mload(add(response, 0x20))

            switch iszero(succeeded)
            case 1 {
                // throw if delegatecall failed
                revert(add(response, 0x20), size)
            }
        }
    }

    function testCDPMigrationPayWithMKR() public {
        vote();
        waitAndCast();

        bytes32 cup = openCupAndGenerateSai(20 ether, 1000 ether);

        assertEq(tub.ink(cup), 20 ether * 10 ** 27 / tub.per());
        assertEq(tub.tab(cup), 1000 ether);

        openCupAndGenerateSai(0.1 ether, 10 ether);

        swapSaiToDai(1010 ether);

        hevm.warp(now + 864000); // 10 days of fees

        (uint val, bool ok) = pep.peek();
        assertTrue(ok);
        uint govFee = tub.rap(cup) * 10 ** 18 / val;

        assertTrue(govFee > 0);

        uint prevGovBalance = gov.balanceOf(address(this));

        // Migrate CDP
        gov.approve(address(proxy), govFee);
        uint cdp = migrateCdp(
            abi.encodeWithSignature(
                "migrate(address,bytes32)",
                migration,
                cup
            )
        );

        assertEq(gov.balanceOf(address(this)), prevGovBalance - govFee);

        assertEq(tub.ink(cup), 0);
        assertEq(tub.tab(cup), 0);

        address urn = ManagerLike(manager).urns(cdp);

        (uint ink, uint art) = vat.urns("ETH-A", urn);
        (, uint rate,,,) = vat.ilks("ETH-A");

        assertEq(ink, 20 ether * 10 ** 27 / tub.per());
        assertEq(art, 1000 ether * 10 ** 27 / rate + 1);
    }

    function testCDPMigrationPayWithDebt() public {
        vote();
        waitAndCast();

        bytes32 cup = openCupAndGenerateSai(20 ether, 1000 ether);

        assertEq(tub.ink(cup), 20 ether * 10 ** 27 / tub.per());
        assertEq(tub.tab(cup), 1000 ether);

        openCupAndGenerateSai(0.1 ether, 10 ether);

        swapSaiToDai(1010 ether);

        hevm.warp(now + 864000); // 10 days of fees

        (uint val, bool ok) = pep.peek();
        assertTrue(ok);

        uint govFee = tub.rap(cup) * 10 ** 18 / val;

        uint payAmt = otc.getPayAmount(address(sai), address(gov), govFee + 1);

        assertTrue(govFee > 0);

        // Migrate CDP
        uint cdp = migrateCdp(
            abi.encodeWithSignature(
                "migratePayFeeWithDebt(address,bytes32,address,uint256,uint256)",
                migration,
                cup,
                address(otc),
                99999 ether,
                0
            )
        );

        assertEq(tub.ink(cup), 0);
        assertEq(tub.tab(cup), 0);

        address urn = ManagerLike(manager).urns(cdp);

        (uint ink, uint art) = vat.urns("ETH-A", urn);
        (, uint rate,,,) = vat.ilks("ETH-A");

        assertEq(ink, 20 ether);
        assertEq(art, (1000 ether + payAmt) * 10 ** 27 / rate + 1);
    }
}
