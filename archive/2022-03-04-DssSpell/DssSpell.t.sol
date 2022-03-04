// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.6.12;

import "./DssSpell.t.base.sol";
import "dss-interfaces/Interfaces.sol";

contract DssSpellTest is DssSpellTestBase {

    // Recognized Delegates Wallets
    address immutable FLIPFLOPFLAP   = wallets.addr("FLIPFLOPFLAP");
    address immutable FEEDBLACKLOOPS = wallets.addr("FEEDBLACKLOOPS");
    address immutable ULTRASCHUPPI   = wallets.addr("ULTRASCHUPPI");
    address immutable MAKERMAN       = wallets.addr("MAKERMAN");
    address immutable ACREINVEST     = wallets.addr("ACREINVEST");
    address immutable MONETSUPPLY    = wallets.addr("MONETSUPPLY");
    address immutable JUSTINCASE     = wallets.addr("JUSTINCASE");
    address immutable GFXLABS        = wallets.addr("GFXLABS");

    // Core Units Wallets
    address immutable CES_WALLET     = wallets.addr("CES_WALLET");
    address immutable IS_WALLET      = wallets.addr("IS_WALLET");

    // Recognized Delegates Payout
    uint256 constant amountFlipFlopFlap  = 12_000;
    uint256 constant amountFeedBlack     = 12_000;
    uint256 constant amountUltraSchuppi  = 12_000;
    uint256 constant amountMakerMan      =  8_512;
    uint256 constant amountAcreInvest    =  6_494;
    uint256 constant amountMonetSupply   =  5_072;
    uint256 constant amountJustinCase    =    927;
    uint256 constant amountGfxLabs       =    660;

    // Core Units Budget Transfers
    uint256 constant amountCES     = 259_184;
    uint256 constant amountIS      = 138_000;

    function testPayments() public {

        uint256 prevSin              = vat.sin(address(vow));

        // Recognized Delegates
        uint256 prevDaiFlipFlopFlap  = dai.balanceOf(FLIPFLOPFLAP);
        uint256 prevDaiFeedBlack     = dai.balanceOf(FEEDBLACKLOOPS);
        uint256 prevDaiUltraSchuppi  = dai.balanceOf(ULTRASCHUPPI);
        uint256 prevDaiMakerMan      = dai.balanceOf(MAKERMAN);
        uint256 prevDaiAcreInvest    = dai.balanceOf(ACREINVEST);
        uint256 prevDaiMonetSupply   = dai.balanceOf(MONETSUPPLY);
        uint256 prevDaiJustinCase    = dai.balanceOf(JUSTINCASE);
        uint256 prevDaiGfxLabs       = dai.balanceOf(GFXLABS);

        // Core Units
        uint256 prevDaiCES           = dai.balanceOf(CES_WALLET);
        uint256 prevDaiIS            = dai.balanceOf(IS_WALLET);

        uint256 amountTotal = amountFlipFlopFlap + amountFeedBlack + amountUltraSchuppi
        + amountMakerMan + amountAcreInvest + amountMonetSupply  + amountJustinCase
        + amountGfxLabs + amountCES + amountIS;

        assertEq(amountTotal, 57_665 + 259_184 + 138_000);

        assertEq(vat.can(address(pauseProxy), address(daiJoin)), 1);

        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        assertEq(vat.can(address(pauseProxy), address(daiJoin)), 1);

        assertEq(vat.sin(address(vow))         - prevSin,            amountTotal        * RAD);

        // Recognized Delegates
        assertEq(dai.balanceOf(FLIPFLOPFLAP)   - prevDaiFlipFlopFlap, amountFlipFlopFlap * WAD);
        assertEq(dai.balanceOf(FEEDBLACKLOOPS) - prevDaiFeedBlack,    amountFeedBlack    * WAD);
        assertEq(dai.balanceOf(ULTRASCHUPPI)   - prevDaiUltraSchuppi, amountUltraSchuppi * WAD);
        assertEq(dai.balanceOf(MAKERMAN)       - prevDaiMakerMan,     amountMakerMan     * WAD);
        assertEq(dai.balanceOf(ACREINVEST)     - prevDaiAcreInvest,   amountAcreInvest   * WAD);
        assertEq(dai.balanceOf(MONETSUPPLY)    - prevDaiMonetSupply,  amountMonetSupply  * WAD);
        assertEq(dai.balanceOf(JUSTINCASE)     - prevDaiJustinCase,   amountJustinCase   * WAD);
        assertEq(dai.balanceOf(GFXLABS)        - prevDaiGfxLabs,      amountGfxLabs      * WAD);

        // Core Units
        assertEq(dai.balanceOf(CES_WALLET)     - prevDaiCES,         amountCES          * WAD);
        assertEq(dai.balanceOf(IS_WALLET)      - prevDaiIS,          amountIS           * WAD);
    }


    uint256 constant MAR_01_2022            = 1646092800; // 2022-03-01
    uint256 constant APR_01_2022            = 1648771200; // 2022-04-01
    function testDaiStreams() public {
        uint256 streams = vestDai.ids();
        assertEq(streams, 29);

        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        assertEq(vestDai.cap(), 1 * MILLION * WAD / 30 days);
        assertEq(vestDai.ids(), streams + 3);


        assertTrue(vestDai.valid(30)); // check for valid contract
        checkDaiVest({
            _index:      30,                          // id
            _wallet:     wallets.addr("RISK_WALLET"), // usr
            _start:      MAR_01_2022,                 // bgn
            _cliff:      MAR_01_2022,                 // clf
            _end:        MAR_01_2022 + 364 days,      // fin
            _manager:    address(0),                  // mgr
            _restricted: 1,                           // res
            _reward:     2_760_000 * WAD,             // tot
            _claimed:    0                            // rxd
        });
        assertTrue(vestDai.valid(31)); // check for valid contract
        checkDaiVest({
            _index:      31,                          // id
            _wallet:     wallets.addr("CES_WALLET"),  // usr
            _start:      APR_01_2022,                 // bgn
            _cliff:      APR_01_2022,                 // clf
            _end:        APR_01_2022 + 364 days,      // fin
            _manager:    address(0),                  // mgr
            _restricted: 1,                           // res
            _reward:     2_780_562 * WAD,             // tot
            _claimed:    0                            // rxd
        });
        assertTrue(vestDai.valid(32)); // check for valid contract
        checkDaiVest({
            _index:      32,                          // id
            _wallet:     wallets.addr("IS_WALLET"),   // usr
            _start:      MAR_01_2022,                 // bgn
            _cliff:      MAR_01_2022,                 // clf
            _end:        MAR_01_2022 + 275 days,      // fin
            _manager:    address(0),                  // mgr
            _restricted: 1,                           // res
            _reward:     207_000 * WAD,               // tot
            _claimed:    0                            // rxd
        });
    }

    // https://github.com/makerdao/spells-mainnet/tree/master/archive/2021-09-03-DssSpell
    address immutable RISK_OLD_WALLET = 0xd98ef20520048a35EdA9A202137847A62120d2d9;
    uint256 constant SEP_01_2021    = 1630454400;
    uint256 constant SEP_01_2022    = 1661990400;
    uint256 constant VEST_AMOUNT    = 2_184_000 * WAD;
    uint256 constant CLAIMED_AMOUNT = 1_092_000 * WAD;

    function testYankedDaiStreams() public {

        assertTrue(vestDai.valid(8)); // check for valid contract
        checkDaiVest({
            _index:      8,                  // id
            _wallet:     RISK_OLD_WALLET,    // usr
            _start:      SEP_01_2021,        // bgn
            _cliff:      SEP_01_2021,        // clf
            _end:        SEP_01_2022,        // fin
            _manager:    address(0),         // mgr
            _restricted: 1,                  // res
            _reward:     VEST_AMOUNT,        // tot
            _claimed:    CLAIMED_AMOUNT      // rxd
        });

        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        assertTrue(vestDai.valid(8)); // check for valid contract
        checkDaiVest({
            _index:      8,                  // id
            _wallet:     RISK_OLD_WALLET,    // usr
            _start:      SEP_01_2021,        // bgn
            _cliff:      SEP_01_2021,        // clf
            _end:        block.timestamp,    // fin
            _manager:    address(0),         // mgr
            _restricted: 1,                  // res
            _reward:     vestDai.accrued(8), // tot
            _claimed:    CLAIMED_AMOUNT      // rxd
        });

        // // Give admin powers to Test contract address and make the vesting unrestricted for testing
        hevm.store(
            address(vestDai),
            keccak256(abi.encode(address(this), uint256(1))),
            bytes32(uint256(1))
        );
        vestDai.unrestrict(8);
        // //

        vestDai.vest(8);

        assertTrue(!vestDai.valid(8));

        assertEqApprox(vestDai.rxd(8), CLAIMED_AMOUNT, 30_000 * WAD); // claimable delta on cast time (estimate)
    }

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

    function testAAVEDirectBarChange() public {
        DirectDepositLike join = DirectDepositLike(addr.addr("MCD_JOIN_DIRECT_AAVEV2_DAI"));
        assertEq(join.bar(), 3.5 * 10**27 / 100);

        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        assertEq(join.bar(), 2.85 * 10**27 / 100);
    }

    function testCollateralIntegrations() private { // make public to use
        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        // Insert new collateral tests here
        checkIlkIntegration(
            "TOKEN-X",
            GemJoinAbstract(addr.addr("MCD_JOIN_TOKEN_X")),
            ClipAbstract(addr.addr("MCD_CLIP_TOKEN_X")),
            addr.addr("PIP_TOKEN"),
            true,
            true,
            false
        );
    }

    function testLerpSurplusBuffer() private { // make public to use
        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        // Insert new SB lerp tests here

        LerpAbstract lerp = LerpAbstract(lerpFactory.lerps("NAME"));

        uint256 duration = 210 days;
        hevm.warp(block.timestamp + duration / 2);
        assertEq(vow.hump(), 60 * MILLION * RAD);
        lerp.tick();
        assertEq(vow.hump(), 75 * MILLION * RAD);
        hevm.warp(block.timestamp + duration / 2);
        lerp.tick();
        assertEq(vow.hump(), 90 * MILLION * RAD);
        assertTrue(lerp.done());
    }

    function testNewChainlogValues() private { // make public to use
        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        // Insert new chainlog values tests here
        assertEq(chainLog.getAddress("MCD_JOIN_TOKEN_X"), addr.addr("MCD_JOIN_TOKEN_X"));
        assertEq(chainLog.getAddress("MCD_CLIP_TOKEN_X"), addr.addr("MCD_CLIP_TOKEN_X"));
        assertEq(chainLog.getAddress("MCD_CLIP_CALC_TOKEN_X"), addr.addr("MCD_CLIP_CALC_TOKEN_X"));
        assertEq(chainLog.version(), "X.X.X");
    }

    function testNewIlkRegistryValues() private { // make public to use
        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        // Insert new ilk registry values tests here
        assertEq(reg.pos("TOKEN-X"), 48);
        assertEq(reg.join("TOKEN-X"), addr.addr("MCD_JOIN_TOKEN_X"));
        assertEq(reg.gem("TOKEN-X"), addr.addr("TOKEN"));
        assertEq(reg.dec("TOKEN-X"), DSTokenAbstract(addr.addr("TOKEN")).decimals());
        assertEq(reg.class("TOKEN-X"), 1);
        assertEq(reg.pip("TOKEN-X"), addr.addr("PIP_TOKEN"));
        assertEq(reg.xlip("TOKEN-X"), addr.addr("MCD_CLIP_TOKEN_X"));
        assertEq(reg.name("TOKEN-X"), "NAME");
        assertEq(reg.symbol("TOKEN-X"), "SYMBOL");
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

    function test_OSMs() private { // make public to use
        address READER_ADDR = address(0);

        // Track OSM authorizations here
        assertEq(OsmAbstract(addr.addr("PIP_TOKEN")).bud(READER_ADDR), 0);

        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        assertEq(OsmAbstract(addr.addr("PIP_TOKEN")).bud(READER_ADDR), 1);
    }

    function test_Medianizers() private { // make public to use
        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        // Track Median authorizations here
        address SET_TOKEN    = address(0);
        address TOKENUSD_MED = OsmAbstract(addr.addr("PIP_TOKEN")).src();
        assertEq(MedianAbstract(TOKENUSD_MED).bud(SET_TOKEN), 1);
    }

    function test_auth() private { // make public to use
        checkAuth(false);
    }

    function test_auth_in_sources() private { // make public to use
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
}
