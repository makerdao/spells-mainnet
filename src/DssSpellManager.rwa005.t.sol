pragma solidity 0.6.12;

import {DssSpellTest, TinlakeManagerLike} from "./DssSpell.t.sol";
import "dss-interfaces/Interfaces.sol";

interface Hevm {
    function warp(uint) external;
    function store(address,bytes32,bytes32) external;
    function load(address,bytes32) external returns (bytes32);
}

interface Root {
    function relyContract(address, address) external;
}

interface MemberList {
    function updateMember(address, uint) external;
}

contract DssSpellManager is DssSpellTest {
    address self;

    DSTokenAbstract public drop;
    TinlakeManagerLike dropMgr;

    // RWA005/FF1
    Root constant root = Root(0x4B6CA198d257D755A5275648D471FE09931b764A);
    MemberList constant memberlist = MemberList(0x6e79770F8B57cAd29D29b1884563556B31E792b0);

    function managerInit() public {
        self = address(this);

        hevm.store(
            mgr_, keccak256(abi.encode(address(this), uint(0))), bytes32(uint(1))
        );
        assertEq(mgr.wards(self), 1);

        // setup manager dependencies
        mgr.file("urn", address(rwaurn));
        mgr.file("liq", address(oracle));
        mgr.file("owner", self);

        super.setUp();

        dropMgr = TinlakeManagerLike(address(mgr));
        drop = DSTokenAbstract(address(dropMgr.gem()));

        // welcome to hevm KYC
        hevm.store(address(root), keccak256(abi.encode(address(this), uint(0))), bytes32(uint(1)));

        root.relyContract(address(memberlist), address(this));
        memberlist.updateMember(address(this), uint(-1));
        memberlist.updateMember(address(dropMgr), uint(-1));

        assertEq(dropMgr.owner(), address(this));
        // give this address 1500 dai and 1000 drop

        hevm.store(address(dai), keccak256(abi.encode(address(this), uint(2))), bytes32(uint(1500 ether)));
        hevm.store(address(drop), keccak256(abi.encode(address(this), uint(8))), bytes32(uint(1000 ether)));
        assertEq(dai.balanceOf(address(this)), 1500 ether);
        assertEq(drop.balanceOf(address(this)), 1000 ether);

        // approve the manager
        drop.approve(address(dropMgr), uint(-1));
        dai.approve(address(dropMgr), uint(-1));

        //execute spell and lock rwa token
        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());
        lock();
    }

    function lock() public {
        uint rwaToken = 1 ether;
        dropMgr.lock(rwaToken);
    }

    function testJoinAndDraw() public {
        managerInit();

        assertEq(dai.balanceOf(address(this)), 1500 ether);
        assertEq(drop.balanceOf(address(this)), 1000 ether);

        dropMgr.join(400 ether);
        dropMgr.draw(200 ether);
        assertEq(dai.balanceOf(address(this)), 1700 ether);
        assertEq(drop.balanceOf(address(this)), 600 ether);
        assertEq(drop.balanceOf(address(dropMgr)), 400 ether);
    }

    function testWipeAndExit() public {
        testJoinAndDraw();
        dropMgr.wipe(10 ether);
        dropMgr.exit(10 ether);
        assertEq(dai.balanceOf(address(this)), 1690 ether);
        assertEq(drop.balanceOf(address(this)), 610 ether);
    }

    function cdptab() public view returns (uint) {
        // Calculate DAI cdp debt
        (, uint art) = vat.urns(ilk, address(dropMgr));
        (, uint rate, , ,) = vat.ilks(ilk);
        return art * rate;
    }
}
