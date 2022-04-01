// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.6.12;

import "./DssSpell.t.base.sol";
import "dss-interfaces/Interfaces.sol";

interface Gem6Like {
    function implementation() external view returns (address);
}

interface GemJoin6Like {
    function implementations(address) external view returns (uint256);
    function join(address, uint256) external;
    function exit(address, uint256) external;
}

interface AuthLike {
    function wards(address) external view returns (uint256);
}

contract DssSpellTest is DssSpellTestBase {

    // Custom Addresses
    address constant GOV_WALLET_1      = 0x01D26f8c5cC009868A4BF66E268c17B057fF7A73;
    address constant GOV_WALLET_2      = 0xC818Ae5f27B76b4902468C6B02Fd7a089F12c07b;
    address constant GOV_WALLET_3      = 0xbfDD0E744723192f7880493b66501253C34e1241;

    // Start Dates - Start of Day (00:00:00 GMT)
    uint256 constant FEB_08_2022 = 1644278400;
    uint256 constant MAR_01_2022 = 1646092800;
    uint256 constant APR_01_2022 = 1648771200;

    function testOneTimePaymentDistributions() public {
        uint256 prevSin         = vat.sin(address(vow));
        uint256 prevDaiGov1     = dai.balanceOf(GOV_WALLET_1);
        uint256 prevDaiIs       = dai.balanceOf(wallets.addr("IS_WALLET"));
        uint256 prevDaiRwf      = dai.balanceOf(wallets.addr("RWF_WALLET"));

        uint256 amountDaiGov1 = 30_000;
        uint256 amountDaiIs   = 348_453;
        uint256 amountDaiRwf  = 2_055_000;
        uint256 amountTotal   = amountDaiGov1 + amountDaiIs + amountDaiRwf;

        assertEq(vat.can(address(pauseProxy), address(daiJoin)), 1);

        vote(address(spell));
        spell.schedule();
        hevm.warp(spell.nextCastTime());
        spell.cast();
        assertTrue(spell.done());

        assertEq(vat.can(address(pauseProxy), address(daiJoin)), 1);

        assertEq(
            vat.sin(address(vow)) - prevSin,
            ( amountDaiGov1
            + amountDaiIs
            + amountDaiRwf
            ) * RAD
        );
        assertEq(vat.sin(address(vow)) - prevSin, amountTotal * RAD);
        assertEq(dai.balanceOf(GOV_WALLET_1) - prevDaiGov1, amountDaiGov1 * WAD);
        assertEq(dai.balanceOf(wallets.addr("IS_WALLET")) - prevDaiIs, amountDaiIs * WAD);
        assertEq(dai.balanceOf(wallets.addr("RWF_WALLET")) - prevDaiRwf, amountDaiRwf * WAD);
    }

    function testVestDAI() public {
        VestAbstract vest = VestAbstract(addr.addr("MCD_VEST_DAI"));

        assertEq(vest.ids(), 32);

        assertTrue(vest.valid(27));
        assertEq(vest.fin(27), 1672444800);

        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        assertEq(vest.ids(), 36);

        // // ----- Gov Wallet
        assertEq(vest.usr(33), GOV_WALLET_1);
        assertEq(vest.bgn(33), APR_01_2022);
        assertEq(vest.clf(33), APR_01_2022);
        assertEq(vest.fin(33), APR_01_2022 + 365 days);
        assertEq(vest.mgr(33), GOV_WALLET_1);
        assertEq(vest.res(33), 1);
        assertEq(vest.tot(33), 1_079_793 * WAD);
        assertEq(vest.rxd(33), 0);
        // // ----- ISCU
        assertEq(vest.usr(34), wallets.addr("IS_WALLET"));
        assertEq(vest.bgn(34), MAR_01_2022);
        assertEq(vest.clf(34), MAR_01_2022);
        assertEq(vest.fin(34), MAR_01_2022 + 153 days);
        assertEq(vest.mgr(34), wallets.addr("IS_WALLET"));
        assertEq(vest.res(34), 1);
        assertEq(vest.tot(34), 7_003_569 * 10**17);       // 700_356.9 * 10 * WAD / 10
        assertEq(vest.tot(34), 700356900000000000000000); // 700_356.9 * 10 * WAD / 10
        assertEq(vest.rxd(34), 0);
        // // ----- RWF New
        assertEq(vest.usr(35), wallets.addr("RWF_WALLET"));
        assertEq(vest.bgn(35), APR_01_2022);
        assertEq(vest.clf(35), APR_01_2022);
        assertEq(vest.fin(35), APR_01_2022 + 274 days);
        assertEq(vest.mgr(35), wallets.addr("RWF_WALLET"));
        assertEq(vest.res(35), 1);
        assertEq(vest.tot(35), 6_165_000 * WAD);
        assertEq(vest.rxd(35), 0);
        // // ----- RWF Old
        assertEq(vest.usr(27), wallets.addr("RWF_WALLET"));
        assertEq(vest.fin(27), block.timestamp);
        assertEq(vest.tot(27), vest.accrued(27));
        // // ----- Gelato
        assertEq(vest.usr(36), addr.addr("GELATO_VEST_STREAMING"));
        assertEq(vest.bgn(36), APR_01_2022);
        assertEq(vest.clf(36), APR_01_2022);
        assertEq(vest.fin(36), APR_01_2022 + 183 days);
        assertEq(vest.mgr(36), addr.addr("GELATO_VEST_STREAMING"));
        assertEq(vest.res(36), 1);
        assertEq(vest.tot(36), 183_000 * WAD);
        assertEq(vest.rxd(36), 0);
    }

    function testOneTimeMkrDistributions() public {
        uint256 prevMkrPP   = gov.balanceOf(pauseProxy);
        uint256 prevMkrGov2 = gov.balanceOf(GOV_WALLET_2);

        uint256 amountMkrGov2 =  60;

        vote(address(spell));
        spell.schedule();
        hevm.warp(spell.nextCastTime());
        spell.cast();
        assertTrue(spell.done());

        assertEq(gov.balanceOf(pauseProxy),  prevMkrPP   - (amountMkrGov2   * WAD));
        assertEq(gov.balanceOf(GOV_WALLET_2), prevMkrGov2 + (amountMkrGov2 * WAD));
    }

    function testVestMKR() public {
        VestAbstract vest = VestAbstract(addr.addr("MCD_VEST_MKR_TREASURY"));

        assertEq(vest.ids(), 19);

        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        assertEq(vest.ids(), 22);

        // ----- Gov Wallet 2
        assertEq(vest.usr(20), GOV_WALLET_2);
        assertEq(vest.bgn(20), FEB_08_2022);
        assertEq(vest.clf(20), FEB_08_2022 + 365 days);
        assertEq(vest.fin(20), FEB_08_2022 + 365 days);
        assertEq(vest.mgr(20), address(0));
        assertEq(vest.res(20), 1);
        assertEq(vest.tot(20), 737 * 10**17);         // 73.70 * 10 * WAD / 10
        assertEq(vest.tot(20), 73700000000000000000); // 73.70 * 10 * WAD / 10
        assertEq(vest.rxd(20), 0);
        // ----- Gov Wallet 3
        assertEq(vest.usr(21), GOV_WALLET_3);
        assertEq(vest.bgn(21), FEB_08_2022);
        assertEq(vest.clf(21), FEB_08_2022 + 365 days);
        assertEq(vest.fin(21), FEB_08_2022 + 365 days);
        assertEq(vest.mgr(21), address(0));
        assertEq(vest.res(21), 1);
        assertEq(vest.tot(21), 5274 * 10**16);        // 52.74 * 100 * WAD / 100
        assertEq(vest.tot(21), 52740000000000000000); // 52.74 * 100 * WAD / 100
        assertEq(vest.rxd(21), 0);
        // -----
        assertEq(vest.usr(22), GOV_WALLET_1);
        assertEq(vest.bgn(22), FEB_08_2022);
        assertEq(vest.clf(22), FEB_08_2022 + 365 days);
        assertEq(vest.fin(22), FEB_08_2022 + 365 days);
        assertEq(vest.mgr(22), address(0));
        assertEq(vest.res(22), 1);
        assertEq(vest.tot(22), 412 * 10**17);         // 41.20 * 10 * WAD / 10
        assertEq(vest.tot(22), 41200000000000000000); // 41.20 * 10 * WAD / 10
        assertEq(vest.rxd(22), 0);
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

    function testPayments() private { // make public to use
        uint256 prevSin = vat.sin(address(vow));

        // Insert new payments tests here

        uint256 amount = WAD;
        address WALLET = address(123);

        uint256 prevDai = dai.balanceOf(WALLET);

        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        assertEq(vat.sin(address(vow)) - prevSin, amount * RAY);
        assertEq(dai.balanceOf(WALLET) - prevDai, amount);

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

    function testNewChainlogValues() private { // make public to use
        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        // Insert new chainlog values tests here
        assertEq(chainLog.getAddress("XXX"), addr.addr("XXX"));

        assertEq(chainLog.version(), "1.X.X");
    }

    function testNewIlkRegistryValues() private { // make public to use
        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        // Insert new ilk registry values tests here
        assertEq(reg.pos("XXX-A"), 48);
        assertEq(reg.join("XXX-A"), addr.addr("MCD_JOIN_XXX_A"));
        assertEq(reg.gem("XXX-A"), addr.addr("XXX"));
        assertEq(reg.dec("XXX-A"), GemAbstract(addr.addr("XXX")).decimals());
        assertEq(reg.class("XXX-A"), 1);
        assertEq(reg.pip("XXX-A"), addr.addr("PIP_XXX"));
        assertEq(reg.xlip("XXX-A"), addr.addr("MCD_CLIP_XXX_A"));
        assertEq(reg.name("XXX-A"), "xxx xxx xxx");
        assertEq(reg.symbol("XXX-A"), "xxx");
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
        address READER_ADDR = address(spotter);

        // Track OSM authorizations here
        assertEq(OsmAbstract(addr.addr("PIP_XXX")).bud(READER_ADDR), 0);

        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        assertEq(OsmAbstract(addr.addr("PIP_XXX")).bud(READER_ADDR), 1);
    }

    function test_Medianizers() private { // make public to use
        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        // Track Median authorizations here
        address PIP     = addr.addr("PIP_XXX");
        address MEDIAN  = OsmAbstract(PIP).src();
        assertEq(MedianAbstract(MEDIAN).bud(PIP), 1);
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
