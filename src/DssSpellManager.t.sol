pragma solidity 0.6.12;

import {DssSpellTest, TinlakeManagerLike} from "./DssSpell.t.sol";
import "dss-interfaces/Interfaces.sol";

interface EpochCoordinatorLike {
    function closeEpoch() external;
    function currentEpoch() external returns(uint);
}

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

interface AssessorLike {
    function calcSeniorTokenPrice() external returns (uint);
}

contract DssSpellManager is DssSpellTest {
    DSTokenAbstract  public drop;
    TinlakeManagerLike dropMgr;

    // Tinlake
    Root constant root = Root(0x53b2d22d07E069a3b132BfeaaD275b10273d381E);
    MemberList constant memberlist = MemberList(0xD927F069faf59eD83A1072624Eeb794235bBA652);
    EpochCoordinatorLike constant coordinator = EpochCoordinatorLike(0xB51D3cbaa5CCeEf896B96091E69be48bCbDE8367);
    address constant seniorOperator_ = 0x6B902D49580320779262505e346E3f9B986e99e8;
    address constant seniorTranche_ = 0xfB30B47c47E2fAB74ca5b0c1561C2909b280c4E5;
    address constant assessor_ = 0x49527a20904aF41d1cbFc0ba77576B9FBd8ec9E5;

    function managerInit() public {
        super.setUp();
        dropMgr = TinlakeManagerLike(address(mgr));
        drop = DSTokenAbstract(address(dropMgr.gem()));

        // welcome to hevm KYC
        hevm.store(address(root), keccak256(abi.encode(address(this), uint(0))), bytes32(uint(1)));

        root.relyContract(address(memberlist), address(this));
        memberlist.updateMember(address(this), uint(-1));
        memberlist.updateMember(address(dropMgr), uint(-1));

        // set this contract as owner of dropMgr // override slot 1
        // check what's inside slot 1 with: bytes32 slot = hevm.load(address(dropMgr), bytes32(uint(1)));
        hevm.store(address(dropMgr), bytes32(uint(1)), bytes32(0x0000000000000000000101013bE95e4159a131E56A84657c4ad4D43eC7Cd865d));
        // ste this contract as ward on the mgr
        hevm.store(address(dropMgr), keccak256(abi.encode(address(this), uint(0))), bytes32(uint(1)));

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
        managerInit();

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
