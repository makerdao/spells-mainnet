// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.6.12;

import "./DssSpell.t.base.sol";
import "dss-interfaces/Interfaces.sol";

contract DssSpellTest is DssSpellTestBase {

    // Recognized Delegates Wallets
    address immutable FLIPFLOPFLAP   = wallets.addr("FLIPFLOPFLAP");
    address immutable ULTRASCHUPPI   = wallets.addr("ULTRASCHUPPI");
    address immutable FEEDBLACKLOOPS = wallets.addr("FEEDBLACKLOOPS");
    address immutable MAKERMAN       = wallets.addr("MAKERMAN");
    address immutable ACREINVEST     = wallets.addr("ACREINVEST");
    address immutable MONETSUPPLY    = wallets.addr("MONETSUPPLY");
    address immutable JUSTINCASE     = wallets.addr("JUSTINCASE");
    address immutable GFXLABS        = wallets.addr("GFXLABS");
    address immutable DOO            = wallets.addr("DOO");
    address immutable FLIPSIDE       = wallets.addr("FLIPSIDE");

    // Recognized Delegates Payout
    uint256 constant amountFlipFlopFlap  = 12_000;
    uint256 constant amountUltraSchuppi  = 12_000;
    uint256 constant amountFeedBlack     = 12_000;
    uint256 constant amountMakerMan      = 10_929;
    uint256 constant amountAcreInvest    =  9_347;
    uint256 constant amountMonetSupply   =  8_626;
    uint256 constant amountJustinCase    =  7_522;
    uint256 constant amountGfxLabs       =  6_607;
    uint256 constant amountDoo           =    351;
    uint256 constant amountFlipside      =    265;

    function testSpellIsCast_GENERAL() public {
        string memory description = new DssSpell().description();
        assertTrue(bytes(description).length > 0, "TestError/spell-description-length");
        // DS-Test can't handle strings directly, so cast to a bytes32.
        assertEq(stringToBytes32(spell.description()),
                stringToBytes32(description), "TestError/spell-description");

        if(address(spell) != address(spellValues.deployed_spell)) {
            assertEq(spell.expiration(), block.timestamp + spellValues.expiration_threshold, "TestError/spell-expiration");
        } else {
            assertEq(spell.expiration(), spellValues.deployed_spell_created + spellValues.expiration_threshold, "TestError/spell-expiration");

            // If the spell is deployed compare the on-chain bytecode size with the generated bytecode size.
            // extcodehash doesn't match, potentially because it's address-specific, avenue for further research.
            address depl_spell = spellValues.deployed_spell;
            address code_spell = address(new DssSpell());
            assertEq(getExtcodesize(depl_spell), getExtcodesize(code_spell), "TestError/spell-codesize");
        }

        assertTrue(spell.officeHours() == spellValues.office_hours_enabled, "TestError/spell-office-hours");

        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done(), "TestError/spell-not-done");

        checkSystemValues(afterSpell);

        checkCollateralValues(afterSpell);
    }

    function testPayments() public { // make public to use
        uint256 prevSin = vat.sin(address(vow));

        // Recognized Delegates
        uint256 prevDaiFlipFlopFlap  = dai.balanceOf(FLIPFLOPFLAP);
        uint256 prevDaiUltraSchuppi  = dai.balanceOf(ULTRASCHUPPI);
        uint256 prevDaiFeedBlack     = dai.balanceOf(FEEDBLACKLOOPS);
        uint256 prevDaiMakerMan      = dai.balanceOf(MAKERMAN);
        uint256 prevDaiAcreInvest    = dai.balanceOf(ACREINVEST);
        uint256 prevDaiMonetSupply   = dai.balanceOf(MONETSUPPLY);
        uint256 prevDaiJustinCase    = dai.balanceOf(JUSTINCASE);
        uint256 prevDaiGfxLabs       = dai.balanceOf(GFXLABS);
        uint256 prevDaiDoo           = dai.balanceOf(DOO);
        uint256 prevDaiFlipside      = dai.balanceOf(FLIPSIDE);

        uint256 amount = amountFlipFlopFlap + amountUltraSchuppi + amountFeedBlack
        + amountMakerMan + amountAcreInvest + amountMonetSupply  + amountJustinCase
        + amountGfxLabs + amountDoo + amountFlipside;

        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        assertEq(vat.sin(address(vow)) - prevSin, amount * RAD);

        // Recognized Delegates
        assertEq(dai.balanceOf(FLIPFLOPFLAP)   - prevDaiFlipFlopFlap, amountFlipFlopFlap * WAD);
        assertEq(dai.balanceOf(FEEDBLACKLOOPS) - prevDaiFeedBlack,    amountFeedBlack    * WAD);
        assertEq(dai.balanceOf(ULTRASCHUPPI)   - prevDaiUltraSchuppi, amountUltraSchuppi * WAD);
        assertEq(dai.balanceOf(MAKERMAN)       - prevDaiMakerMan,     amountMakerMan     * WAD);
        assertEq(dai.balanceOf(ACREINVEST)     - prevDaiAcreInvest,   amountAcreInvest   * WAD);
        assertEq(dai.balanceOf(MONETSUPPLY)    - prevDaiMonetSupply,  amountMonetSupply  * WAD);
        assertEq(dai.balanceOf(JUSTINCASE)     - prevDaiJustinCase,   amountJustinCase   * WAD);
        assertEq(dai.balanceOf(GFXLABS)        - prevDaiGfxLabs,      amountGfxLabs      * WAD);
        assertEq(dai.balanceOf(DOO)            - prevDaiDoo,          amountDoo          * WAD);
        assertEq(dai.balanceOf(FLIPSIDE)       - prevDaiFlipside,     amountFlipside     * WAD);
    }

    function testCollateralIntegrations() public { // make public to use
        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        // Insert new collateral tests here
        checkIlkIntegration(
             "WSTETH-B",
             GemJoinAbstract(addr.addr("MCD_JOIN_WSTETH_B")),
             ClipAbstract(addr.addr("MCD_CLIP_WSTETH_B")),
             addr.addr("PIP_WSTETH"),
             true,
             true,
             false
        );
    }

    function testIlkClipper() private { // make public to use
        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        // Insert new ilk clipper tests here
        checkIlkClipper(
            "TOKEN-X",
            GemJoinAbstract(addr.addr("MCD_JOIN_TOKEN_X")),
            ClipAbstract(addr.addr("MCD_CLIP_TOKEN_X")),
            addr.addr("MCD_CLIP_CALC_TOKEN_X"),
            OsmAbstract(addr.addr("PIP_TOKEN")),
            20_000 * WAD
        );
    }

    function testNewChainlogValues() public { // make public to use
        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        // Insert new chainlog values tests here
        assertEq(chainLog.getAddress("MCD_JOIN_WSTETH_B"), addr.addr("MCD_JOIN_WSTETH_B"));
        assertEq(chainLog.getAddress("MCD_CLIP_WSTETH_B"), addr.addr("MCD_CLIP_WSTETH_B"));
        assertEq(chainLog.getAddress("MCD_CLIP_CALC_WSTETH_B"), addr.addr("MCD_CLIP_CALC_WSTETH_B"));
        assertEq(chainLog.version(), "1.12.1");
    }

    function testNewIlkRegistryValues() public { // make public to use
        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        // Insert new ilk registry values tests here
        assertEq(reg.pos("WSTETH-B"), 49);
        assertEq(reg.join("WSTETH-B"), addr.addr("MCD_JOIN_WSTETH_B"));
        assertEq(reg.gem("WSTETH-B"), addr.addr("WSTETH"));
        assertEq(reg.dec("WSTETH-B"), GemAbstract(addr.addr("WSTETH")).decimals());
        assertEq(reg.class("WSTETH-B"), 1);
        assertEq(reg.pip("WSTETH-B"), addr.addr("PIP_WSTETH"));
        assertEq(reg.xlip("WSTETH-B"), addr.addr("MCD_CLIP_WSTETH_B"));
        assertEq(reg.name("WSTETH-B"), "Wrapped liquid staked Ether 2.0");
        assertEq(reg.symbol("WSTETH-B"), "wstETH");
    }

    function testFailWrongDay() public {
        require(spell.officeHours() == spellValues.office_hours_enabled);
        if (spell.officeHours()) {
            vote(address(spell));
            scheduleWaitAndCastFailDay();
        } else {
            revert("Office Hours Disabled");
        }
    }

    function testFailTooEarly() public {
        require(spell.officeHours() == spellValues.office_hours_enabled);
        if (spell.officeHours()) {
            vote(address(spell));
            scheduleWaitAndCastFailEarly();
        } else {
            revert("Office Hours Disabled");
        }
    }

    function testFailTooLate() public {
        require(spell.officeHours() == spellValues.office_hours_enabled);
        if (spell.officeHours()) {
            vote(address(spell));
            scheduleWaitAndCastFailLate();
        } else {
            revert("Office Hours Disabled");
        }
    }

    function testOnTime() public {
        vote(address(spell));
        scheduleWaitAndCast(address(spell));
    }

    function testCastCost() public {
        vote(address(spell));
        spell.schedule();

        castPreviousSpell();
        hevm.warp(spell.nextCastTime());
        uint256 startGas = gasleft();
        spell.cast();
        uint256 endGas = gasleft();
        uint256 totalGas = startGas - endGas;

        assertTrue(spell.done());
        // Fail if cast is too expensive
        assertTrue(totalGas <= 10 * MILLION);
    }

    // The specific date doesn't matter that much since function is checking for difference between warps
    function test_nextCastTime() public {
        hevm.warp(1606161600); // Nov 23, 20 UTC (could be cast Nov 26)

        vote(address(spell));
        spell.schedule();

        uint256 monday_1400_UTC = 1606744800; // Nov 30, 2020
        uint256 monday_2100_UTC = 1606770000; // Nov 30, 2020

        // Day tests
        hevm.warp(monday_1400_UTC);                                    // Monday,   14:00 UTC
        assertEq(spell.nextCastTime(), monday_1400_UTC);               // Monday,   14:00 UTC

        if (spell.officeHours()) {
            hevm.warp(monday_1400_UTC - 1 days);                       // Sunday,   14:00 UTC
            assertEq(spell.nextCastTime(), monday_1400_UTC);           // Monday,   14:00 UTC

            hevm.warp(monday_1400_UTC - 2 days);                       // Saturday, 14:00 UTC
            assertEq(spell.nextCastTime(), monday_1400_UTC);           // Monday,   14:00 UTC

            hevm.warp(monday_1400_UTC - 3 days);                       // Friday,   14:00 UTC
            assertEq(spell.nextCastTime(), monday_1400_UTC - 3 days);  // Able to cast

            hevm.warp(monday_2100_UTC);                                // Monday,   21:00 UTC
            assertEq(spell.nextCastTime(), monday_1400_UTC + 1 days);  // Tuesday,  14:00 UTC

            hevm.warp(monday_2100_UTC - 1 days);                       // Sunday,   21:00 UTC
            assertEq(spell.nextCastTime(), monday_1400_UTC);           // Monday,   14:00 UTC

            hevm.warp(monday_2100_UTC - 2 days);                       // Saturday, 21:00 UTC
            assertEq(spell.nextCastTime(), monday_1400_UTC);           // Monday,   14:00 UTC

            hevm.warp(monday_2100_UTC - 3 days);                       // Friday,   21:00 UTC
            assertEq(spell.nextCastTime(), monday_1400_UTC);           // Monday,   14:00 UTC

            // Time tests
            uint256 castTime;

            for(uint256 i = 0; i < 5; i++) {
                castTime = monday_1400_UTC + i * 1 days; // Next day at 14:00 UTC
                hevm.warp(castTime - 1 seconds); // 13:59:59 UTC
                assertEq(spell.nextCastTime(), castTime);

                hevm.warp(castTime + 7 hours + 1 seconds); // 21:00:01 UTC
                if (i < 4) {
                    assertEq(spell.nextCastTime(), monday_1400_UTC + (i + 1) * 1 days); // Next day at 14:00 UTC
                } else {
                    assertEq(spell.nextCastTime(), monday_1400_UTC + 7 days); // Next monday at 14:00 UTC (friday case)
                }
            }
        }
    }

    function testFail_notScheduled() public view {
        spell.nextCastTime();
    }

    function test_use_eta() public {
        hevm.warp(1606161600); // Nov 23, 20 UTC (could be cast Nov 26)

        vote(address(spell));
        spell.schedule();

        uint256 castTime = spell.nextCastTime();
        assertEq(castTime, spell.eta());
    }

    function testOSMs() private { // make public to use
        address OASIS_APP_OSM_READER = 0x55Dc2Be8020bCa72E58e665dC931E03B749ea5E0;

        // Track OSM authorizations here
        assertEq(OsmAbstract(addr.addr("PIP_ETH")).bud(OASIS_APP_OSM_READER), 0);
        assertEq(OsmAbstract(addr.addr("PIP_WSTETH")).bud(OASIS_APP_OSM_READER), 0);
        assertEq(OsmAbstract(addr.addr("PIP_WBTC")).bud(OASIS_APP_OSM_READER), 0);
        assertEq(OsmAbstract(addr.addr("PIP_RENBTC")).bud(OASIS_APP_OSM_READER), 0);
        assertEq(OsmAbstract(addr.addr("PIP_YFI")).bud(OASIS_APP_OSM_READER), 0);
        assertEq(OsmAbstract(addr.addr("PIP_UNI")).bud(OASIS_APP_OSM_READER), 0);
        assertEq(OsmAbstract(addr.addr("PIP_LINK")).bud(OASIS_APP_OSM_READER), 0);
        assertEq(OsmAbstract(addr.addr("PIP_MANA")).bud(OASIS_APP_OSM_READER), 0);

        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        assertEq(OsmAbstract(addr.addr("PIP_ETH")).bud(OASIS_APP_OSM_READER), 1);
        assertEq(OsmAbstract(addr.addr("PIP_WSTETH")).bud(OASIS_APP_OSM_READER), 1);
        assertEq(OsmAbstract(addr.addr("PIP_WBTC")).bud(OASIS_APP_OSM_READER), 1);
        assertEq(OsmAbstract(addr.addr("PIP_RENBTC")).bud(OASIS_APP_OSM_READER), 1);
        assertEq(OsmAbstract(addr.addr("PIP_YFI")).bud(OASIS_APP_OSM_READER), 1);
        assertEq(OsmAbstract(addr.addr("PIP_UNI")).bud(OASIS_APP_OSM_READER), 1);
        assertEq(OsmAbstract(addr.addr("PIP_LINK")).bud(OASIS_APP_OSM_READER), 1);
        assertEq(OsmAbstract(addr.addr("PIP_MANA")).bud(OASIS_APP_OSM_READER), 1);
    }

    function testRemoveOldOSM() private { // make public to use
        address PIP_CRVV1ETHSTETH_OLD = chainLog.getAddress("PIP_CRVV1ETHSTETH");

        // Wards
        assertEq(WardsAbstract(PIP_CRVV1ETHSTETH_OLD).wards(addr.addr("OSM_MOM")), 1);

        // Buds
        assertEq(MedianAbstract(CurveLPOsmLike(PIP_CRVV1ETHSTETH_OLD).orbs(0)).bud(PIP_CRVV1ETHSTETH_OLD), 1);
        assertEq(MedianAbstract(CurveLPOsmLike(PIP_CRVV1ETHSTETH_OLD).orbs(1)).bud(PIP_CRVV1ETHSTETH_OLD), 1);

        assertEq(OsmAbstract(PIP_CRVV1ETHSTETH_OLD).bud(addr.addr("MCD_SPOT")), 1);
        assertEq(OsmAbstract(PIP_CRVV1ETHSTETH_OLD).bud(addr.addr("MCD_CLIP_CRVV1ETHSTETH_A")), 1);
        assertEq(OsmAbstract(PIP_CRVV1ETHSTETH_OLD).bud(addr.addr("CLIPPER_MOM")), 1);
        assertEq(OsmAbstract(PIP_CRVV1ETHSTETH_OLD).bud(addr.addr("MCD_END")), 1);


        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        // Wards
        assertEq(WardsAbstract(PIP_CRVV1ETHSTETH_OLD).wards(addr.addr("OSM_MOM")), 0);

        // Buds
        assertEq(MedianAbstract(CurveLPOsmLike(PIP_CRVV1ETHSTETH_OLD).orbs(0)).bud(PIP_CRVV1ETHSTETH_OLD), 0);
        assertEq(MedianAbstract(CurveLPOsmLike(PIP_CRVV1ETHSTETH_OLD).orbs(1)).bud(PIP_CRVV1ETHSTETH_OLD), 0);

        assertEq(OsmAbstract(PIP_CRVV1ETHSTETH_OLD).bud(addr.addr("MCD_SPOT")), 0);
        assertEq(OsmAbstract(PIP_CRVV1ETHSTETH_OLD).bud(addr.addr("MCD_CLIP_CRVV1ETHSTETH_A")), 0);
        assertEq(OsmAbstract(PIP_CRVV1ETHSTETH_OLD).bud(addr.addr("CLIPPER_MOM")), 0);
        assertEq(OsmAbstract(PIP_CRVV1ETHSTETH_OLD).bud(addr.addr("MCD_END")), 0);
    }

    function testMedianizers() private { // make public to use
        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        // Track Median authorizations here
        address PIP     = addr.addr("PIP_XXX");
        address MEDIAN  = OsmAbstract(PIP).src();
        assertEq(MedianAbstract(MEDIAN).bud(PIP), 1);
    }

    function test_auth() public {
        checkAuth(false);
    }

    function test_auth_in_sources() public {
        checkAuth(true);
    }

    // Verifies that the bytecode of the action of the spell used for testing
    // matches what we'd expect.
    //
    // Not a complete replacement for Etherscan verification, unfortunately.
    // This is because the DssSpell bytecode is non-deterministic because it
    // deploys the action in its constructor and incorporates the action
    // address as an immutable variable--but the action address depends on the
    // address of the DssSpell which depends on the address+nonce of the
    // deploying address. If we had a way to simulate a contract creation by
    // an arbitrary address+nonce, we could verify the bytecode of the DssSpell
    // instead.
    //
    // Vacuous until the deployed_spell value is non-zero.
    function test_bytecode_matches() public {
        address expectedAction = (new DssSpell()).action();
        address actualAction   = spell.action();
        uint256 expectedBytecodeSize;
        uint256 actualBytecodeSize;
        assembly {
            expectedBytecodeSize := extcodesize(expectedAction)
            actualBytecodeSize   := extcodesize(actualAction)
        }

        uint256 metadataLength = getBytecodeMetadataLength(expectedAction);
        assertTrue(metadataLength <= expectedBytecodeSize);
        expectedBytecodeSize -= metadataLength;

        metadataLength = getBytecodeMetadataLength(actualAction);
        assertTrue(metadataLength <= actualBytecodeSize);
        actualBytecodeSize -= metadataLength;

        assertEq(actualBytecodeSize, expectedBytecodeSize);
        uint256 size = actualBytecodeSize;
        uint256 expectedHash;
        uint256 actualHash;
        assembly {
            let ptr := mload(0x40)

            extcodecopy(expectedAction, ptr, 0, size)
            expectedHash := keccak256(ptr, size)

            extcodecopy(actualAction, ptr, 0, size)
            actualHash := keccak256(ptr, size)
        }
        assertEq(expectedHash, actualHash);
    }

    // Validate addresses in test harness match chainlog
    function test_chainlog_values() public {
        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        for(uint256 i = 0; i < chainLog.count(); i++) {
            (bytes32 _key, address _val) = chainLog.get(i);
            assertEq(_val, addr.addr(_key), concat("TestError/chainlog-addr-mismatch-", _key));
        }
    }

    // Ensure version is updated if chainlog changes
    function test_chainlog_version_bump() public {

        uint256                   _count = chainLog.count();
        string    memory        _version = chainLog.version();
        address[] memory _chainlog_addrs = new address[](_count);

        for(uint256 i = 0; i < _count; i++) {
            (, address _val) = chainLog.get(i);
            _chainlog_addrs[i] = _val;
        }

        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        if (keccak256(abi.encodePacked(_version)) == keccak256(abi.encodePacked(chainLog.version()))) {
            // Fail if the version is not updated and the chainlog count has changed
            if (_count != chainLog.count()) {
                emit log_named_string("Error", concat("TestError/chainlog-version-not-updated-count-change-", _version));
                fail();
                return;
            }
            // Fail if the chainlog is the same size but local keys don't match the chainlog.
            for(uint256 i = 0; i < _count; i++) {
                (, address _val) = chainLog.get(i);
                if (_chainlog_addrs[i] != _val) {
                    emit log_named_string("Error", concat("TestError/chainlog-version-not-updated-address-change-", _version));
                    fail();
                    return;
                }
            }
        }
    }

    function tryVest(address vest, uint256 id) internal returns (bool ok) {
        (ok,) = vest.call(abi.encodeWithSignature("vest(uint256)", id));
    }

    uint256 constant MAY_01_2022 = 1651363200;
    uint256 constant JUL_01_2022 = 1656633600;

    function testVestDAI() private {
        VestAbstract vest = VestAbstract(addr.addr("MCD_VEST_DAI"));

        assertEq(vest.ids(), 0);

        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        assertEq(vest.ids(), 4);

        assertEq(vest.cap(), 1 * MILLION * WAD / 30 days);

        assertEq(vest.usr(1), wallets.addr("PE_WALLET"));
        assertEq(vest.bgn(1), MAY_01_2022);
        assertEq(vest.clf(1), MAY_01_2022);
        assertEq(vest.fin(1), MAY_01_2022 + 365 days);
        assertEq(vest.mgr(1), address(0));
        assertEq(vest.res(1), 1);
        assertEq(vest.tot(1), 7_590_000 * WAD);
        assertEq(vest.rxd(1), 0);

        assertEq(vest.usr(2), wallets.addr("COM_WALLET"));
        assertEq(vest.bgn(2), JUL_01_2022);
        assertEq(vest.clf(2), JUL_01_2022);
        assertEq(vest.fin(2), JUL_01_2022 + 184 days);
        assertEq(vest.mgr(2), address(0));
        assertEq(vest.res(2), 1);
        assertEq(vest.tot(2), 336_672 * WAD);
        assertEq(vest.rxd(2), 0);

        assertEq(vest.usr(3), wallets.addr("DIN_WALLET"));
        assertEq(vest.bgn(3), MAY_01_2022);
        assertEq(vest.clf(3), MAY_01_2022);
        assertEq(vest.fin(3), MAY_01_2022 + 365 days);
        assertEq(vest.mgr(3), address(0));
        assertEq(vest.res(3), 1);
        assertEq(vest.tot(3), 1_083_000 * WAD);
        assertEq(vest.rxd(3), 0);

        assertEq(vest.usr(4), wallets.addr("EVENTS_WALLET"));
        assertEq(vest.bgn(4), MAY_01_2022);
        assertEq(vest.clf(4), MAY_01_2022);
        assertEq(vest.fin(4), MAY_01_2022 + 365 days);
        assertEq(vest.mgr(4), address(0));
        assertEq(vest.res(4), 1);
        assertEq(vest.tot(4), 748_458 * WAD);
        assertEq(vest.rxd(4), 0);

        // Give admin powers to Test contract address and make the vesting unrestricted for testing
        giveAuth(address(vest), address(this));
        vest.unrestrict(1);

        hevm.warp(MAY_01_2022 + 365 days);
        uint256 prevBalance = dai.balanceOf(wallets.addr("PE_WALLET"));
        assertTrue(tryVest(address(vest), 1));
        assertEq(dai.balanceOf(wallets.addr("PE_WALLET")), prevBalance + 7_590_000 * WAD);
    }
}
