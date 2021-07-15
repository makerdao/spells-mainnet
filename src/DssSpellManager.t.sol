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

contract KovanManagerRPC is DSTest, DSMath {

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
            ROOT: 0x792164b3e10a3CE1efafF7728961aD506c433c18,
            COORDINATOR: 0xb9575aD050263cC0A9E65B8bd6041DbF5e02bf1F,
            DROP: 0x931C3Ff1F5aC377137d3AaFD80F601BD76cE106e,
            MEMBERLIST: 0xb7ee04cb62bFD87862e56E2E880b9EeB87aDf20F,
            MGR: 0x2A9798c6F165B6D60Cfb923Fe5BFD6f338695D9B
        }));

        collaterals.push(CentrifugeCollateralTestValues({
            ilk: "RWA004",
            LIQ: 0x2881c5dF65A8D81e38f7636122aFb456514804CC,
            URN: 0xeF1699548717aa4Cf47aD738316280b56814C821,
            ROOT: 0xe4E649e8D591748d7D3031d8001990FCD3E4eba6,
            COORDINATOR: 0xC7379e106aCE86762060860697a918a11A6CaF1A,
            DROP: 0xe99fb3ec1Ae8f3D7222CcBb83239B30928776c5b,
            MEMBERLIST: 0x07edd094A10dBa8D01ad880b843A388747F4E020,
            MGR: 0xe1ed3F588A98bF8a3744f4BF74Fd8540e81AdE3f
        }));

        collaterals.push(CentrifugeCollateralTestValues({
            ilk: "RWA005",
            LIQ: 0x5b702e1fEF3F556cbe219eE697D7f170A236cc66,
            URN: 0xc40907545C57dB30F01a1c2acB242C7c7ACB2B90,
            ROOT: 0x68CA1a0411a8137d8505303A5745aa3Ead87ba6C,
            COORDINATOR: 0x38721a32dDa9d6EC6a5c135243C93e7ca56Bde86,
            DROP: 0x0f763b4d5032f792fA39eE54BE5422592eC8329B,
            MEMBERLIST: 0x8a9C850D7214ca626f4B12a04759dF9A2a9A51b9,
            MGR: 0x17E5954Cdd3611Dd84e444F0ed555CC3a06cB319
        }));

        // collaterals.push(CentrifugeCollateralTestValues({
        //     ilk: "RWA006",
        //     LIQ: 0x2881c5dF65A8D81e38f7636122aFb456514804CC,
        //     URN: 0x6fa6F9C11f5F129f6ECA4B391D9d32038A9666cD,
        //     ROOT: 0x09E5b61a15526753b8aF01e21Bd3853146472080,
        //     COORDINATOR: 0x671954B36350D6B3f1427f1a3CD64C8eb6845913,
        //     DROP: 0x0bDAA77Ba1cb0E7dAf18963A8f202Da077e867bA,
        //     MEMBERLIST: 0x1b8413C9b1B93aFfa2fC04637778b810a9E2a8b2,
        //     MGR: 0x652A3B3b91459504A8D1d785B0c923A34D638218
        // }));

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
