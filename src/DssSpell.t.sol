// SPDX-FileCopyrightText: © 2020 Dai Foundation <www.daifoundation.org>
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
pragma experimental ABIEncoderV2;

import "./DssSpell.t.base.sol";

interface RwaLiquidationLike {
    function ilks(bytes32) external returns (string memory, address, uint48, uint48);
}

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
        Payee[2] memory payees = [
            Payee(wallets.addr("BIBTA_WALLET"),      50_000),
            Payee(wallets.addr("MIP65_WALLET"),      30_000)
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

        // // Insert new collateral tests here
        // checkIlkIntegration(
        //      "TOKEN-X",
        //      GemJoinAbstract(addr.addr("MCD_JOIN_TOKEN_X")),
        //      ClipAbstract(addr.addr("MCD_CLIP_TOKEN_X")),
        //      addr.addr("PIP_TOKEN"),
        //      true,
        //      true,
        //      false
        // );
    }

    function testIlkClipper() private { // make public to use
        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        // // Insert new ilk clipper tests here
        // checkIlkClipper(
        //     "TOKEN-X",
        //     GemJoinAbstract(addr.addr("MCD_JOIN_TOKEN_X")),
        //     ClipAbstract(addr.addr("MCD_CLIP_TOKEN_X")),
        //     addr.addr("MCD_CLIP_CALC_TOKEN_X"),
        //     OsmAbstract(addr.addr("PIP_TOKEN")),
        //     20_000 * WAD
        // );
    }

    function testNewChainlogValues() public { // make private to disable
        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        checkChainlogKey("PROXY_ACTIONS_END_CROPPER");
        checkChainlogVersion("1.14.1");
    }

    function testNewIlkRegistryValues() private { // make public to use
        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        // Insert new ilk registry values tests here
        // assertEq(reg.pos("TELEPORT-FW-A"), 52);
        // assertEq(reg.join("TELEPORT-FW-A"), addr.addr("MCD_JOIN_TELEPORT_FW_A"));
        // assertEq(reg.gem("TELEPORT-FW-A"), address(0));
        // assertEq(reg.dec("TELEPORT-FW-A"), 0);
        // assertEq(reg.class("TELEPORT-FW-A"), 4);
        // assertEq(reg.pip("TELEPORT-FW-A"), address(0));
        // assertEq(reg.xlip("TELEPORT-FW-A"), address(0));
        // assertEq(reg.name("TELEPORT-FW-A"), "");
        // assertEq(reg.symbol("TELEPORT-FW-A"), "");
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

        // // Track Median authorizations here
        // address PIP     = addr.addr("PIP_XXX");
        // address MEDIAN  = OsmAbstract(PIP).src();
        // assertEq(MedianAbstract(MEDIAN).bud(PIP), 1);
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

    function testVestDAI() private { // make public to use
        VestAbstract vest = VestAbstract(addr.addr("MCD_VEST_DAI"));

        // All times in GMT
        uint256 JUL_01_2022 = 1656633600; // Friday,   July      1, 2022 12:00:00 AM
        uint256 OCT_01_2022 = 1664582400; // Saturday, October   1, 2022 12:00:00 AM
        uint256 OCT_31_2022 = 1667260799; // Monday,   October  31, 2022 11:59:59 PM
        uint256 NOV_01_2022 = 1667260800; // Tuesday,  November  1, 2022 12:00:00 AM
        uint256 JUN_30_2023 = 1688169599; // Friday,   June     30, 2023 11:59:59 PM
        uint256 AUG_31_2023 = 1693526399; // Thursday, August   31, 2023 11:59:59 PM
        uint256 DEC_31_2022 = 1672531199; // Saturday, December 31, 2022 11:59:59 PM

        assertEq(vest.ids(), 9);

        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        assertEq(vest.ids(), 9 + 4);

        assertEq(vest.cap(), 1 * MILLION * WAD / 30 days);

        assertTrue(vest.valid(10)); // check for valid contract
        checkDaiVest({
            _index:      10,                                             // id
            _wallet:     wallets.addr("DAIF_WALLET"),                    // usr
            _start:      OCT_01_2022,                                    // bgn
            _cliff:      OCT_01_2022,                                    // clf
            _end:        OCT_31_2022,                                    // fin
            _days:       31 days,                                        // fin
            _manager:    address(0),                                     // mgr
            _restricted: 1,                                              // res
            _reward:     67_863 * WAD,                                   // tot
            _claimed:    0                                               // rxd
        });

        assertTrue(vest.valid(11)); // check for valid contract
        checkDaiVest({
            _index:      11,                                             // id
            _wallet:     wallets.addr("DAIF_WALLET"),                    // usr
            _start:      NOV_01_2022,                                    // bgn
            _cliff:      NOV_01_2022,                                    // clf
            _end:        AUG_31_2023,                                    // fin
            _days:       304 days,                                       // fin
            _manager:    address(0),                                     // mgr
            _restricted: 1,                                              // res
            _reward:     329_192 * WAD,                                  // tot
            _claimed:    0                                               // rxd
        });

        assertTrue(vest.valid(12)); // check for valid contract
        checkDaiVest({
            _index:      12,                                             // id
            _wallet:     wallets.addr("DAIF_RESERVE_WALLET"),            // usr
            _start:      OCT_01_2022,                                    // bgn
            _cliff:      OCT_01_2022,                                    // clf
            _end:        DEC_31_2022,                                    // fin
            _days:       92 days,                                        // fin
            _manager:    address(0),                                     // mgr
            _restricted: 1,                                              // res
            _reward:     270_000 * WAD,                                  // tot
            _claimed:    0                                               // rxd
        });

        assertTrue(vest.valid(13)); // check for valid contract
        checkDaiVest({
            _index:      13,                                             // id
            _wallet:     wallets.addr("ORA_WALLET"),                     // usr
            _start:      JUL_01_2022,                                    // bgn
            _cliff:      JUL_01_2022,                                    // clf
            _end:        JUN_30_2023,                                    // fin
            _days:       365 days,                                       // fin
            _manager:    address(0),                                     // mgr
            _restricted: 1,                                              // res
            _reward:     2_337_804 * WAD,                                // tot
            _claimed:    0                                               // rxd
        });

        // Give admin powers to Test contract address and make the vesting unrestricted for testing
        giveAuth(address(vest), address(this));
        uint256 prevBalance;

        vest.unrestrict(10);
        prevBalance = dai.balanceOf(wallets.addr("DAIF_WALLET"));
        hevm.warp(OCT_01_2022 + 31 days);
        assertTrue(tryVest(address(vest), 10));
        assertEq(dai.balanceOf(wallets.addr("DAIF_WALLET")), prevBalance + 67_863 * WAD);

        vest.unrestrict(11);
        prevBalance = dai.balanceOf(wallets.addr("DAIF_WALLET"));
        hevm.warp(NOV_01_2022 + 304 days);
        assertTrue(tryVest(address(vest), 11));
        assertEq(dai.balanceOf(wallets.addr("DAIF_WALLET")), prevBalance + 329_192 * WAD);

        vest.unrestrict(12);
        prevBalance = dai.balanceOf(wallets.addr("DAIF_RESERVE_WALLET"));
        hevm.warp(OCT_01_2022 + 92 days);
        assertTrue(tryVest(address(vest), 12));
        assertEq(dai.balanceOf(wallets.addr("DAIF_RESERVE_WALLET")), prevBalance + 270_000 * WAD);

        vest.unrestrict(13);
        prevBalance = dai.balanceOf(wallets.addr("ORA_WALLET"));
        hevm.warp(JUL_01_2022 + 365 days);
        assertTrue(tryVest(address(vest), 13));
        assertEq(dai.balanceOf(wallets.addr("ORA_WALLET")), prevBalance + 2_337_804 * WAD);
    }

    function testYankDAI() private { // make public to use

        VestAbstract vest = VestAbstract(addr.addr("MCD_VEST_DAI"));
        address KEEP3R_VEST_STREAMING_LEGACY = wallets.addr("KEEP3R_VEST_STREAMING_LEGACY");
        // Tuesday, 31 January 2023 00:00:00
        uint256 JAN_31_2023 = 1675123200;

        assertEq(vest.usr(8), KEEP3R_VEST_STREAMING_LEGACY);
        assertEq(vest.fin(8), JAN_31_2023);

        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        assertEq(vest.fin(8), block.timestamp);
    }

    function testVestMKR() private { // make public to use
        VestAbstract vest = VestAbstract(addr.addr("MCD_VEST_MKR_TREASURY"));
        assertEq(vest.ids(), 23);

        uint256 prevAllowance = gov.allowance(pauseProxy, addr.addr("MCD_VEST_MKR_TREASURY"));

        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        assertEq(gov.allowance(pauseProxy, addr.addr("MCD_VEST_MKR_TREASURY")), prevAllowance + 803 * WAD);

        assertEq(vest.cap(), 1_100 * WAD / 365 days);
        assertEq(vest.ids(), 24);

        // Friday,   1 July 2022 00:00:00 UTC
        uint256 JUL_01_2022 = 1656633600;
        // Saturday, 1 July 2023 00:00:00 UTC
        uint256 JUL_01_2023 = 1688169600;

        address GRO_WALLET = wallets.addr("GRO_WALLET");

        // -----
        assertEq(vest.usr(24), GRO_WALLET);
        assertEq(vest.bgn(24), JUL_01_2022);
        assertEq(vest.clf(24), JUL_01_2022);
        assertEq(vest.fin(24), JUL_01_2022 + 365 days);
        assertEq(vest.fin(24), JUL_01_2023);
        assertEq(vest.mgr(24), address(0));
        assertEq(vest.res(24), 1);
        assertEq(vest.tot(24), 803 * WAD);
        assertEq(vest.rxd(24), 0);

        uint256 prevBalance = gov.balanceOf(GRO_WALLET);

        // Give admin powers to test contract address and make the vesting unrestricted for testing
        giveAuth(address(vest), address(this));
        vest.unrestrict(24);

        // 20220907 exec: Warp 1/2 year since cliff, ensure vest was accumulated
        hevm.warp(JUL_01_2022 + 365 days / 2);
        vest.vest(24);
        assertEq(gov.balanceOf(GRO_WALLET), prevBalance + (803 * WAD / 2));

        // 20220907 exec: Warp to end and vest remaining
        hevm.warp(JUL_01_2022 + 365 days);
        vest.vest(24);
        assertEq(gov.balanceOf(GRO_WALLET), prevBalance + 803 * WAD);

        // 20220907 exec: Warp even further and make sure nothing else was accumulated
        hevm.warp(JUL_01_2022 + 365 days + 10 days);
        vest.vest(24);
        assertEq(gov.balanceOf(GRO_WALLET), prevBalance + 803 * WAD);
    }

    function testMKRPayments() private { // make public to use
        uint256 prevMkrPause = gov.balanceOf(address(pauseProxy));
        uint256 prevMkrRWF   = gov.balanceOf(wallets.addr("RWF_WALLET"));
        uint256 prevMkrCES   = gov.balanceOf(wallets.addr("CES_OP_WALLET"));
        uint256 prevMkrRisk  = gov.balanceOf(wallets.addr("RISK_WALLET_VEST"));

        uint256 amountRWF    =  20.00 ether;
        uint256 amountCES    = 966.49 ether;
        uint256 amountRisk   = 175.00 ether;

        uint256 total = amountRWF + amountCES + amountRisk;

        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        assertEq(gov.balanceOf(address(pauseProxy)), prevMkrPause - total);
        assertEq(gov.balanceOf(wallets.addr("RWF_WALLET")), prevMkrRWF + amountRWF);
        assertEq(gov.balanceOf(wallets.addr("CES_OP_WALLET")), prevMkrCES + amountCES);
        assertEq(gov.balanceOf(wallets.addr("RISK_WALLET_VEST")), prevMkrRisk + amountRisk);
    }

    function testMKRVestFix() private { // make public to use
        uint256 prevMkrPause  = gov.balanceOf(address(pauseProxy));
        VestAbstract vest = VestAbstract(addr.addr("MCD_VEST_MKR_TREASURY"));

        address usr = vest.usr(2);
        assertEq(usr, pauseProxy, "usr of id 2 is pause proxy");

        uint256 unpaid = vest.unpaid(2);
        assertEq(unpaid, 63180000000000000000, "amount doesn't match expectation");

        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        unpaid = vest.unpaid(2);
        assertEq(unpaid, 0, "vest still has a balance");
        assertEq(gov.balanceOf(address(pauseProxy)), prevMkrPause);
    }

    // RWA tests
    string OLDDOC = "";
    string NEWDOC = "";

    function testDocChange() private { // make public to use
        bytes32 ilk = "RWA009-A";
        RwaLiquidationLike oracle = RwaLiquidationLike(
            chainLog.getAddress("MIP21_LIQUIDATION_ORACLE")
        );

        (string memory docOld, address pipOld, uint48 tauOld, uint48 tocOld) =
            oracle.ilks(ilk);

        assertEq(docOld, OLDDOC, "bad old document");

        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        (string memory docNew, address pipNew, uint48 tauNew, uint48 tocNew) =
            oracle.ilks(ilk);

        assertEq(docNew, NEWDOC,     "bad new document");
        assertEq(pipOld, pipNew,     "pip is the same");
        assertTrue(tauOld == tauNew, "tau is the same");
        assertTrue(tocOld == tocNew, "toc is the same");
    }
}
