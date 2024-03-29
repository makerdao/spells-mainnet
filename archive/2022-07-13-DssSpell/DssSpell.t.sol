// SPDX-FileCopyrightText: © 2021 Dai Foundation <www.daifoundation.org>
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity 0.6.12;

import "./DssSpell.t.base.sol";
import "dss-interfaces/Interfaces.sol";

contract DssSpellTest is DssSpellTestBase {

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

    struct Payee {
        address addr;
        uint256 amount;
    }

    function testPayments() private { // make public to use
        uint256 prevSin = vat.sin(address(vow));

        // For each payment, create a Payee object with
        //    the Payee address,
        //    the amount to be paid in whole Dai units
        // Initialize the array with the number of payees
        Payee[15] memory payees = [
            Payee(wallets.addr("GRO_WALLET"),       648_134),
            Payee(wallets.addr("FEEDBLACKLOOPS"),    11_573),
            Payee(wallets.addr("FLIPFLOPFLAP"),      11_528),
            Payee(wallets.addr("ULTRASCHUPPI"),      11_292),
            Payee(wallets.addr("MAKERMAN"),           9_366),
            Payee(wallets.addr("ACREINVEST"),         8_813),
            Payee(wallets.addr("JUSTINCASE"),         8_158),
            Payee(wallets.addr("GFXLABS"),            6_679),
            Payee(wallets.addr("DOO"),                5_075),
            Payee(wallets.addr("PENNBLOCKCHAIN"),     3_795),
            Payee(wallets.addr("FLIPSIDE"),           3_186),
            Payee(wallets.addr("CHRISBLEC"),          2_739),
            Payee(wallets.addr("BLOCKCHAINCOLUMBIA"), 2_150),
            Payee(wallets.addr("MHONKASALOTEEMULAU"),   704),
            Payee(wallets.addr("GOVERNANCEHOUSE"),      127)
        ];

        uint256 prevBalance;
        uint256 totAmount;
        uint256[] memory prevAmounts = new uint256[](payees.length);

        for (uint256 i = 0; i < payees.length; i++) {
            totAmount += payees[i].amount;
            prevAmounts[i] = dai.balanceOf(payees[i].addr);
            prevBalance += prevAmounts[i];
        }

        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        assertEq(vat.sin(address(vow)) - prevSin, totAmount * RAD);

        for (uint256 i = 0; i < payees.length; i++) {
            assertEq(
                dai.balanceOf(payees[i].addr) - prevAmounts[i],
                payees[i].amount * WAD
            );
        }
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

    function testNewChainlogValues() private { // make public to use
        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        // Insert new chainlog values tests here
        // checkChainlogKey("CONTRACT_KEY");
        // checkChainlogVersion("X.XX.X");

    }

    function testNewIlkRegistryValues() private { // make public to use
        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        // Insert new ilk registry values tests here
        assertEq(reg.pos("TOKEN-X"), 49);
        assertEq(reg.join("TOKEN-X"), addr.addr("MCD_JOIN_TOKEN_X"));
        assertEq(reg.gem("TOKEN-X"), addr.addr("TOKEN"));
        assertEq(reg.dec("TOKEN-X"), GemAbstract(addr.addr("TOKEN")).decimals());
        assertEq(reg.class("TOKEN-X"), 1);
        assertEq(reg.pip("TOKEN-X"), addr.addr("PIP_TOKEN"));
        assertEq(reg.xlip("TOKEN-X"), addr.addr("MCD_CLIP_TOKEN_X"));
        assertEq(reg.name("TOKEN-X"), "");
        assertEq(reg.symbol("TOKEN-X"), "TOKEN");
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
        address READER = address(0);

        // Track OSM authorizations here
        assertEq(OsmAbstract(addr.addr("PIP_TOKEN")).bud(READER), 0);

        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        assertEq(OsmAbstract(addr.addr("PIP_TOKEN")).bud(READER), 1);
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

    function testVestDAI() private {
        VestAbstract vest = VestAbstract(addr.addr("MCD_VEST_DAI"));

        address SF_WALLET              = wallets.addr("SF_WALLET");
        address GRO_WALLET             = wallets.addr("GRO_WALLET");
        address KEEP3R_VEST_STREAMING = wallets.addr("KEEP3R_VEST_STREAMING");

        // Friday, 1 July 2022 00:00:00
        uint256 JUL_01_2022 = 1656633600;
        // Tuesday, 31 January 2023 00:00:00
        uint256 JAN_31_2023 = 1675123200;
        // Friday, 30 June 2023 00:00:00
        uint256 JUN_30_2023 = 1688083200;
        // Saturday, 1 July 2023 00:00:00
        uint256 JUL_01_2023 = 1688169600;

        assertEq(vest.ids(), 5);

        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        assertEq(vest.ids(), 8);

        assertEq(vest.cap(), 1 * MILLION * WAD / 30 days);

        assertEq(vest.usr(6), SF_WALLET);
        assertEq(vest.bgn(6), JUL_01_2022);
        assertEq(vest.clf(6), JUL_01_2022);
        assertEq(vest.fin(6), JUL_01_2023);
        assertEq(vest.fin(6), JUL_01_2022 + 365 days);
        assertEq(vest.mgr(6), address(0));
        assertEq(vest.res(6), 1);
        assertEq(vest.tot(6), 989004 * WAD);
        assertEq(vest.rxd(6), 0);

        assertEq(vest.usr(7), GRO_WALLET);
        assertEq(vest.bgn(7), JUL_01_2022);
        assertEq(vest.clf(7), JUL_01_2022);
        assertEq(vest.fin(7), JUN_30_2023);
        assertEq(vest.fin(7), JUL_01_2022 + 364 days);
        assertEq(vest.mgr(7), address(0));
        assertEq(vest.res(7), 1);
        assertEq(vest.tot(7), 2913995 * WAD);
        assertEq(vest.rxd(7), 0);

        assertEq(vest.usr(8), KEEP3R_VEST_STREAMING);
        assertEq(vest.bgn(8), JUL_01_2022);
        assertEq(vest.clf(8), JUL_01_2022);
        assertEq(vest.fin(8), JAN_31_2023);
        assertEq(vest.fin(8), JUL_01_2022 + 214 days);
        assertEq(vest.mgr(8), address(0));
        assertEq(vest.res(8), 1);
        assertEq(vest.tot(8), 215000 * WAD);
        assertEq(vest.rxd(8), 0);

        // Give admin powers to Test contract address and make the vesting unrestricted for testing
        giveAuth(address(vest), address(this));
        vest.unrestrict(6);
        vest.unrestrict(7);
        vest.unrestrict(8);

        uint256 prevBalance;
        hevm.warp(JUL_01_2022 + 365 days);
        prevBalance = dai.balanceOf(SF_WALLET);
        assertTrue(tryVest(address(vest), 6));
        assertEq(dai.balanceOf(SF_WALLET), prevBalance + 989004 * WAD);

        hevm.warp(JUL_01_2022 + 364 days);
        prevBalance = dai.balanceOf(GRO_WALLET);
        assertTrue(tryVest(address(vest), 7));
        assertEq(dai.balanceOf(GRO_WALLET), prevBalance + 2913995 * WAD);

        hevm.warp(JUL_01_2022 + 214 days);
        prevBalance = dai.balanceOf(KEEP3R_VEST_STREAMING);
        assertTrue(tryVest(address(vest), 8));
        assertEq(dai.balanceOf(KEEP3R_VEST_STREAMING), prevBalance + 215000 * WAD);
    }

    function testVestMKR() private {
        VestAbstract vest = VestAbstract(addr.addr("MCD_VEST_MKR_TREASURY"));
        assertEq(vest.ids(), 22);

        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        assertEq(vest.cap(), 1_100 * WAD / 365 days);
        assertEq(vest.ids(), 23);

        // Wed 01 Jun 2022 12:00:00 AM UTC
        uint256 JUN_01_2022 = 1654041600;
        // Thu 23 Nov 2023 12:00:00 AM UTC
        uint256 NOV_23_2023 = 1700697600;
        address SH_WALLET = wallets.addr("SH_WALLET");

        // -----
        assertEq(vest.usr(23), SH_WALLET);
        assertEq(vest.bgn(23), JUN_01_2022);
        assertEq(vest.clf(23), NOV_23_2023);
        assertEq(vest.fin(23), JUN_01_2022 + 4 * 365 days);
        assertEq(vest.mgr(23), wallets.addr("SH_WALLET"));
        assertEq(vest.res(23), 1);
        assertEq(vest.tot(23), 250 * 10**18);
        assertEq(vest.rxd(23), 0);


        uint256 prevBalance = gov.balanceOf(SH_WALLET);
        // 20220608 exec: Warp 2 years since cliff here is 18 months
        hevm.warp(JUN_01_2022 + 2 * 365 days);

        // // Give admin powers to Test contract address and make the vesting unrestricted for testing
        giveAuth(address(vest), address(this));
        vest.unrestrict(23);

        vest.vest(23);
        // 20220608 exec: Ensure 2 years vest accumulated
        assertEq(gov.balanceOf(SH_WALLET), prevBalance + (250 * WAD / 4) * 2);
    }

    function testMKRPayments() private {

        uint256 prevMkrPause = gov.balanceOf(address(pauseProxy));
        uint256 prevMkrRisk = gov.balanceOf(wallets.addr("RISK_WALLET_VEST"));

        uint256 amountRisk  = 175 * WAD;

        uint256 total = amountRisk;

        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        assertEq(gov.balanceOf(address(pauseProxy)), prevMkrPause - total);
        assertEq(gov.balanceOf(wallets.addr("RISK_WALLET_VEST")), prevMkrRisk + amountRisk);
    }
}
