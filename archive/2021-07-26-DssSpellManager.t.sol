pragma solidity 0.6.12;

import "ds-math/math.sol";
import "ds-test/test.sol";
import "dss-interfaces/Interfaces.sol";
import "./test/addresses_mainnet.sol";
import "./CentrifugeCollateralValues.sol";

import {DssSpell} from "./DssSpell.sol";

interface Hevm {
    function warp(uint) external;
    function store(address,bytes32,bytes32) external;
    function load(address,bytes32) external view returns (bytes32);
}

interface EpochCoordinatorLike {
    function closeEpoch() external;
    function currentEpoch() external returns(uint);
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

interface FileLike {
    function file(bytes32 what, address data) external;
}

interface ERC20Like {
    function mint(address, uint256) external;
}

interface TinlakeManagerLike {
    function gem() external view returns (address);
    function wards(address) external view returns (uint);
    function lock(uint256 wad) external;
    function join(uint256 wad) external;
    function draw(uint256 wad) external;
    function wipe(uint256 wad) external;
    function exit(uint256 wad) external;
}

contract DssSpellManagerTest is DSTest, DSMath {

    Hevm hevm;
    DssSpell spell;
    Addresses addr  = new Addresses();

    DSChiefAbstract chief = DSChiefAbstract(addr.addr("MCD_ADM"));
    DaiAbstract dai = DaiAbstract(addr.addr("MCD_DAI"));
    DSTokenAbstract gov = DSTokenAbstract(addr.addr("MCD_GOV"));

    uint constant initialSpellDaiBalance = 10000 ether;
    uint constant initialSpellDropBalance = 1000 ether;

    CentrifugeCollateralTestValues[] collaterals;

    function setUp() public {
        hevm = Hevm(HEVM_ADDRESS);
        spell = new DssSpell();

        collaterals.push(CentrifugeCollateralTestValues({
            ilk: "RWA003",
            LIQ: 0x2881c5dF65A8D81e38f7636122aFb456514804CC,
            URN: 0x7bF825718e7C388c3be16CFe9982539A7455540F,
            ROOT: 0xdB3bC9fB1893222d266762e9fF857EB74D75c7D6,
            COORDINATOR: 0xFc224d40Eb9c40c85c71efa773Ce24f8C95aAbAb,
            DROP: 0x5b2F0521875B188C0afc925B1598e1FF246F9306,
            MEMBERLIST: 0x26129802A858F3C28553f793E1008b8338e6aEd2,
            MGR: 0x2A9798c6F165B6D60Cfb923Fe5BFD6f338695D9B
        }));

        collaterals.push(CentrifugeCollateralTestValues({
            ilk: "RWA004",
            LIQ: 0x2881c5dF65A8D81e38f7636122aFb456514804CC,
            URN: 0xeF1699548717aa4Cf47aD738316280b56814C821,
            ROOT: 0x4cA805cE8EcE2E63FfC1F9f8F2731D3F48DF89Df,
            COORDINATOR: 0xE2a04a4d4Df350a752ADA79616D7f588C1A195cF,
            DROP: 0xd511397f79b112638ee3B6902F7B53A0A23386C4,
            MEMBERLIST: 0x1Bc55bcAf89f514CE5a8336bEC7429a99e804910,
            MGR: 0xe1ed3F588A98bF8a3744f4BF74Fd8540e81AdE3f
        }));

        collaterals.push(CentrifugeCollateralTestValues({
            ilk: "RWA005",
            LIQ: 0x5b702e1fEF3F556cbe219eE697D7f170A236cc66,
            URN: 0xc40907545C57dB30F01a1c2acB242C7c7ACB2B90,
            ROOT: 0x4B6CA198d257D755A5275648D471FE09931b764A,
            COORDINATOR: 0xD7965D41c37B9F8691F0fe83878f6FFDbCb90996,
            DROP: 0x44718d306a8Fa89545704Ae38B2B97c06bF11FC1,
            MEMBERLIST: 0x6e79770F8B57cAd29D29b1884563556B31E792b0,
            MGR: 0x5b702e1fEF3F556cbe219eE697D7f170A236cc66
        }));

        // give this address 10000 dai
        hevm.store(address(dai), keccak256(abi.encode(address(this), uint(2))), bytes32(uint(initialSpellDaiBalance)));
        assertEq(dai.balanceOf(address(this)), initialSpellDaiBalance);

        // setup each collateral
        for (uint i = 0; i < collaterals.length; i++) {
            setupCollateral(collaterals[i]);
        }

        // execute spell and lock rwa token
        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        // lock each rwa token
        for (uint i = 0; i < collaterals.length; i++) {
            lock(collaterals[i]);
        }
    }

    function setupCollateral(CentrifugeCollateralTestValues memory collateral) internal {
        emit log_named_bytes32("setting up collateral", collateral.ilk);

        Root root = Root(collateral.ROOT);
        TinlakeManagerLike mgr = TinlakeManagerLike(collateral.MGR);
        DSTokenAbstract drop = DSTokenAbstract(address(mgr.gem()));
        MemberList memberlist = MemberList(collateral.MEMBERLIST);

        // welcome to hevm KYC
        hevm.store(collateral.ROOT, keccak256(abi.encode(address(this), uint(0))), bytes32(uint(1)));
        root.relyContract(collateral.MEMBERLIST, address(this));

        memberlist.updateMember(address(this), type(uint256).max);
        memberlist.updateMember(collateral.MGR, type(uint256).max);

        // set this contract as ward on the mgr
        hevm.store(collateral.MGR, keccak256(abi.encode(address(this), uint(0))), bytes32(uint(1)));
        assertEq(mgr.wards(address(this)), 1);

        // file MIP21 contracts 
        FileLike(collateral.MGR).file("liq", collateral.LIQ);
        FileLike(collateral.MGR).file("urn", collateral.URN);

        // give the spell 1000 drop
        hevm.store(collateral.DROP, keccak256(abi.encode(address(this), uint(0))), bytes32(uint(1)));
        ERC20Like(collateral.DROP).mint(address(this), initialSpellDropBalance);

        assertEq(mgr.wards(address(this)), 1);
        assertEq(drop.balanceOf(address(this)), initialSpellDropBalance);

        // approve the managers
        drop.approve(collateral.MGR, type(uint256).max);
        dai.approve(collateral.MGR, type(uint256).max);
    }

    function lock(CentrifugeCollateralTestValues memory collateral) internal {
        TinlakeManagerLike mgr = TinlakeManagerLike(collateral.MGR);
        uint rwaToken = 1 ether;
        mgr.lock(rwaToken);
    }

    function testJoinAndDraw() public {
        for (uint i = 0; i < collaterals.length; i++) {
            _testJoinAndDraw(collaterals[i]);
        }
    }

    function _testJoinAndDraw(CentrifugeCollateralTestValues memory collateral) internal {
        TinlakeManagerLike mgr = TinlakeManagerLike(collateral.MGR);
        DSTokenAbstract drop = DSTokenAbstract(address(mgr.gem()));

        uint preSpellDaiBalance = dai.balanceOf(address(this));
        uint preMgrDropBalance = drop.balanceOf(collateral.MGR);
        assertEq(drop.balanceOf(address(this)), initialSpellDropBalance);

        mgr.join(400 ether);
        mgr.draw(200 ether);

        assertEq(dai.balanceOf(address(this)), preSpellDaiBalance + 200 ether);
        assertEq(drop.balanceOf(address(this)), initialSpellDropBalance - 400 ether);
        assertEq(drop.balanceOf(address(mgr)), preMgrDropBalance + 400 ether);
    }

    function testWipeAndExit() public {
        for (uint i = 0; i < collaterals.length; i++) {
            _testWipeAndExit(collaterals[i]);
        }
    }

    function _testWipeAndExit(CentrifugeCollateralTestValues memory collateral) internal {
        _testJoinAndDraw(collateral);

        TinlakeManagerLike mgr = TinlakeManagerLike(collateral.MGR);
        DSTokenAbstract drop = DSTokenAbstract(address(mgr.gem()));

        uint preSpellDaiBalance = dai.balanceOf(address(this));
        uint preSpellDropBalance = drop.balanceOf(address(this));

        mgr.wipe(10 ether);
        mgr.exit(10 ether);

        assertEq(dai.balanceOf(address(this)), preSpellDaiBalance - 10 ether);
        assertEq(drop.balanceOf(address(this)), preSpellDropBalance + 10 ether);
    }

    function vote(address spell_) internal {
        if (chief.hat() != spell_) {
            hevm.store(
                address(gov),
                keccak256(abi.encode(address(this), uint256(1))),
                bytes32(uint256(999999999999 ether))
            );
            gov.approve(address(chief), uint256(-1));
            chief.lock(999999999999 ether);

            address[] memory slate = new address[](1);

            assertTrue(!DssSpell(spell_).done());

            slate[0] = spell_;

            chief.vote(slate);
            chief.lift(spell_);
        }
        assertEq(chief.hat(), spell_);
    }

    function scheduleWaitAndCast(address spell_) internal {
        DssSpell(spell_).schedule();
        hevm.warp(DssSpell(spell_).nextCastTime());

        DssSpell(spell_).cast();
    }
}
