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

import "./DssSpell.t.base.sol";

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

    function testPayments() private { // make public to enable
        uint256 prevSin = vat.sin(address(vow));

        // For each payment, create a Payee object with
        //    the Payee address,
        //    the amount to be paid in whole Dai units
        // Initialize the array with the number of payees
        Payee[18] memory payees = [
            Payee(wallets.addr("STABLENODE"),           12_000),
            Payee(wallets.addr("ULTRASCHUPPI"),         12_000),
            Payee(wallets.addr("FLIPFLOPFLAP"),         11_615),
            Payee(wallets.addr("FLIPSIDE"),             11_395),
            Payee(wallets.addr("FEEDBLACKLOOPS"),       10_671),
            Payee(wallets.addr("PENNBLOCKCHAIN"),       10_390),
            Payee(wallets.addr("JUSTINCASE"),            8_056),
            Payee(wallets.addr("MHONKASALOTEEMULAU"),    7_545),
            Payee(wallets.addr("ACREINVEST"),            6_682),
            Payee(wallets.addr("GFXLABS"),               5_306),
            Payee(wallets.addr("BLOCKCHAINCOLUMBIA"),    5_109),
            Payee(wallets.addr("CHRISBLEC"),             5_057),
            Payee(wallets.addr("LBSBLOCKCHAIN"),         2_995),
            Payee(wallets.addr("FRONTIERRESEARCH"),      2_136),
            Payee(wallets.addr("ONESTONE"),                271),
            Payee(wallets.addr("CODEKNIGHT"),              270),
            Payee(wallets.addr("LLAMA"),                   149),
            Payee(wallets.addr("PVL"),                      65)
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

        // checkIlkIntegration(
        //     "RETH-A",
        //     GemJoinAbstract(addr.addr("MCD_JOIN_RETH_A")),
        //     ClipAbstract(addr.addr("MCD_CLIP_RETH_A")),
        //     addr.addr("PIP_RETH"),
        //     true, /* _isOSM */
        //     true, /* _checkLiquidations */
        //     false /* _transferFee */
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

    function testNewChainlogValues() private { // make private to disable
        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        // Insert new chainlog values tests here
        // checkChainlogKey("STARKNET_TELEPORT_BRIDGE");
        // checkChainlogKey("STARKNET_TELEPORT_FEE");

        // checkChainlogVersion("1.14.4");
    }

    function testNewIlkRegistryValues() private { // make private to disable
        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        // Insert new ilk registry values tests here
        // RETH-A
        //assertEq(reg.pos("RETH-A"),    54);
        //assertEq(reg.join("RETH-A"),   addr.addr("MCD_JOIN_RETH_A"));
        // assertEq(reg.gem("RETH-A"),    addr.addr("RETH"));
        // assertEq(reg.dec("RETH-A"),    GemAbstract(addr.addr("RETH")).decimals());
        // assertEq(reg.class("RETH-A"),  1);
        // assertEq(reg.pip("RETH-A"),    addr.addr("PIP_RETH"));
        // assertEq(reg.name("RETH-A"),   "Rocket Pool ETH");
        // assertEq(reg.symbol("RETH-A"), GemAbstract(addr.addr("RETH")).symbol());
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
        // assertEq(OsmAbstract(addr.addr("PIP_TOKEN")).bud(READER), 0);

        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        // assertEq(OsmAbstract(addr.addr("PIP_TOKEN")).bud(READER), 1);
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
        // The DssSpell bytecode is non-deterministic, compare only code size
        DssSpell expectedSpell = new DssSpell();
        assertEq(getExtcodesize(address(spell)), getExtcodesize(address(expectedSpell)), "TestError/spell-codesize");

        // The SpellAction bytecode can be compared after chopping off the metada
        address expectedAction = expectedSpell.action();
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
        assertEq(actualHash, expectedHash);
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

    // @dev when testing new vest contracts, use the explicit id when testing to assist in
    //      identifying streams later for modification or removal
    function testVestDAI() private { // make public to use
        // VestAbstract vest = VestAbstract(addr.addr("MCD_VEST_DAI"));

        // All times in GMT
        // uint256 OCT_01_2022 = 1664582400; // Saturday, October   1, 2022 12:00:00 AM
        // uint256 OCT_31_2022 = 1667260799; // Monday,   October  31, 2022 11:59:59 PM

        // assertEq(vest.ids(), 9);

        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        // assertEq(vest.ids(), 9 + 1);

        // assertEq(vest.cap(), 1 * MILLION * WAD / 30 days);

        // assertTrue(vest.valid(10)); // check for valid contract
        // checkDaiVest({
        //     _index:      10,                                             // id
        //     _wallet:     wallets.addr("DAIF_WALLET"),                    // usr
        //     _start:      OCT_01_2022,                                    // bgn
        //     _cliff:      OCT_01_2022,                                    // clf
        //     _end:        OCT_31_2022,                                    // fin
        //     _days:       31 days,                                        // fin
        //     _manager:    address(0),                                     // mgr
        //     _restricted: 1,                                              // res
        //     _reward:     67_863 * WAD,                                   // tot
        //     _claimed:    0                                               // rxd
        // });

        // // Give admin powers to Test contract address and make the vesting unrestricted for testing
        // giveAuth(address(vest), address(this));
        // uint256 prevBalance;

        // vest.unrestrict(10);
        // prevBalance = dai.balanceOf(wallets.addr("DAIF_WALLET"));
        // hevm.warp(OCT_01_2022 + 31 days);
        // assertTrue(tryVest(address(vest), 10));
        // assertEq(dai.balanceOf(wallets.addr("DAIF_WALLET")), prevBalance + 67_863 * WAD);

    }

    function testYankDAI() private { // make public to use

        // VestAbstract vest = VestAbstract(addr.addr("MCD_VEST_DAI"));
        // VestAbstract vestLegacy = VestAbstract(addr.addr("MCD_VEST_DAI_LEGACY"));

        // // Saturday, December 31, 2022 12:00:00 AM
        // uint256 DEC_31_2022 = 1672444800;
        // // Wednesday, March 15, 2023 12:00:00 AM
        // uint256 MAR_15_2023 = 1678838400;
        // // Monday, May 1, 2023 12:00:00 AM
        // uint256 MAY_1_2023 = 1682899200;

        // assertEq(vest.usr(4), wallets.addr("EVENTS_WALLET"));
        // assertEq(vest.fin(4), MAY_1_2023);
        // assertEq(vest.usr(5), wallets.addr("SH_MULTISIG"));
        // assertEq(vest.fin(5), MAR_15_2023);
        // assertEq(vestLegacy.usr(35), wallets.addr("RWF_WALLET"));
        // assertEq(vestLegacy.fin(35), DEC_31_2022);

        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        // assertEq(vest.fin(4), block.timestamp);
        // assertEq(vest.fin(5), block.timestamp);
        // assertEq(vestLegacy.fin(35), block.timestamp);
    }

    function testYankMKR() private { // make public to use

        // VestAbstract vestTreas = VestAbstract(addr.addr("MCD_VEST_MKR_TREASURY"));
        // //VestAbstract vestMint  = VestAbstract(addr.addr("MCD_VEST_MKR"));

        // // Sunday, May 31, 2026 12:00:00 AM
        // uint256 MAY_31_2026 = 1780185600;

        // assertEq(vestTreas.usr(23), wallets.addr("SH_WALLET"));
        // assertEq(vestTreas.fin(23), MAY_31_2026);

        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        // assertEq(vestTreas.fin(23), block.timestamp);
    }

    function testVestMKR() private { // make public to use
        // VestAbstract vest = VestAbstract(addr.addr("MCD_VEST_MKR_TREASURY"));
        // assertEq(vest.ids(), 24);

        // uint256 prevAllowance = gov.allowance(pauseProxy, addr.addr("MCD_VEST_MKR_TREASURY"));

        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        // assertEq(gov.allowance(pauseProxy, addr.addr("MCD_VEST_MKR_TREASURY")), prevAllowance + 787.70 ether);

        // assertEq(vest.cap(), 1_100 * WAD / 365 days);
        // assertEq(vest.ids(), 28);

        // uint256 AUG_01_2022 = 1659312000;
        // uint256 AUG_01_2023 = 1690848000;
        // uint256 SEP_28_2022 = 1664323200;
        // uint256 SEP_28_2024 = 1727481600;

        // address GOV_WALLET1 = 0xbfDD0E744723192f7880493b66501253C34e1241;
        // address GOV_WALLET2 = 0xbb147E995c9f159b93Da683dCa7893d6157199B9;
        // address GOV_WALLET3 = 0x01D26f8c5cC009868A4BF66E268c17B057fF7A73;
        // address SNE_WALLET = wallets.addr("SNE_WALLET");

        // // -----
        // assertEq(vest.usr(25), GOV_WALLET1);
        // assertEq(vest.bgn(25), AUG_01_2022);
        // assertEq(vest.clf(25), AUG_01_2023);
        // assertEq(vest.fin(25), AUG_01_2022 + 365 days);
        // assertEq(vest.fin(25), AUG_01_2023);
        // assertEq(vest.mgr(25), address(0));
        // assertEq(vest.res(25), 1);
        // assertEq(vest.tot(25), 62.50 ether);
        // assertEq(vest.rxd(25), 0);

        // assertEq(vest.usr(26), GOV_WALLET2);
        // assertEq(vest.bgn(26), AUG_01_2022);
        // assertEq(vest.clf(26), AUG_01_2023);
        // assertEq(vest.fin(26), AUG_01_2022 + 365 days);
        // assertEq(vest.fin(26), AUG_01_2023);
        // assertEq(vest.mgr(26), address(0));
        // assertEq(vest.res(26), 1);
        // assertEq(vest.tot(26), 32.69 ether);
        // assertEq(vest.rxd(26), 0);

        // assertEq(vest.usr(27), GOV_WALLET3);
        // assertEq(vest.bgn(27), AUG_01_2022);
        // assertEq(vest.clf(27), AUG_01_2023);
        // assertEq(vest.fin(27), AUG_01_2022 + 365 days);
        // assertEq(vest.fin(27), AUG_01_2023);
        // assertEq(vest.mgr(27), address(0));
        // assertEq(vest.res(27), 1);
        // assertEq(vest.tot(27), 152.51 ether);
        // assertEq(vest.rxd(27), 0);

        // assertEq(vest.usr(28), SNE_WALLET);
        // assertEq(vest.bgn(28), SEP_28_2022);
        // assertEq(vest.clf(28), SEP_28_2022);
        // assertEq(vest.fin(28), SEP_28_2022 + 731 days);
        // assertEq(vest.fin(28), SEP_28_2024);
        // assertEq(vest.mgr(28), address(0));
        // assertEq(vest.res(28), 1);
        // assertEq(vest.tot(28), 540.00 ether);
        // assertEq(vest.rxd(28), 0);

        // uint256 prevBalance = gov.balanceOf(GOV_WALLET1);

        // // Give admin powers to test contract address and make the vesting unrestricted for testing
        // giveAuth(address(vest), address(this));
        // vest.unrestrict(25);

        // hevm.warp(AUG_01_2022 + 365 days);
        // vest.vest(25);
        // assertEq(gov.balanceOf(GOV_WALLET1), prevBalance + 62.50 ether);

        // hevm.warp(AUG_01_2022 + 365 days + 10 days);
        // vest.vest(25);
        // assertEq(gov.balanceOf(GOV_WALLET1), prevBalance + 62.50 ether);

        // prevBalance = gov.balanceOf(GOV_WALLET2);
        // vest.unrestrict(26);

        // hevm.warp(AUG_01_2022 + 365 days);
        // vest.vest(26);
        // assertEq(gov.balanceOf(GOV_WALLET2), prevBalance + 32.69 ether);

        // hevm.warp(AUG_01_2022 + 365 days + 10 days);
        // vest.vest(26);
        // assertEq(gov.balanceOf(GOV_WALLET2), prevBalance + 32.69 ether);

        // prevBalance = gov.balanceOf(GOV_WALLET3);
        // vest.unrestrict(27);

        // hevm.warp(AUG_01_2022 + 365 days);
        // vest.vest(27);
        // assertEq(gov.balanceOf(GOV_WALLET3), prevBalance + 152.51 ether);

        // hevm.warp(AUG_01_2022 + 365 days + 10 days);
        // vest.vest(27);
        // assertEq(gov.balanceOf(GOV_WALLET3), prevBalance + 152.51 ether);

        // prevBalance = gov.balanceOf(SNE_WALLET);
        // vest.unrestrict(28);

        // hevm.warp(SEP_28_2022 + 731 days);
        // vest.vest(28);
        // assertEq(gov.balanceOf(SNE_WALLET), prevBalance + 540.00 ether);

        // hevm.warp(SEP_28_2022 + 731 days + 10 days);
        // vest.vest(28);
        // assertEq(gov.balanceOf(SNE_WALLET), prevBalance + 540.00 ether);
    }

    function testMKRPayments() private { // make public to use
        // uint256 prevMkrPause = gov.balanceOf(address(pauseProxy));
        // uint256 prevMkrSH    = gov.balanceOf(wallets.addr("SH_MULTISIG"));
        // uint256 prevMkrRWF   = gov.balanceOf(wallets.addr("RWF_WALLET"));

        // uint256 amountSH     =  26.04 ether;
        // uint256 amountRWF    = 143.46 ether;

        // uint256 total        = 169.50 ether;

        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        // assertEq(gov.balanceOf(address(pauseProxy)), prevMkrPause - total);
        // assertEq(gov.balanceOf(wallets.addr("SH_MULTISIG")), prevMkrSH + amountSH);
        // assertEq(gov.balanceOf(wallets.addr("RWF_WALLET")), prevMkrRWF + amountRWF);
    }

    function testMKRVestFix() private { // make public to use
        // uint256 prevMkrPause  = gov.balanceOf(address(pauseProxy));
        // VestAbstract vest = VestAbstract(addr.addr("MCD_VEST_MKR_TREASURY"));

        // address usr = vest.usr(2);
        // assertEq(usr, pauseProxy, "usr of id 2 is pause proxy");

        // uint256 unpaid = vest.unpaid(2);
        // assertEq(unpaid, 63180000000000000000, "amount doesn't match expectation");

        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        // unpaid = vest.unpaid(2);
        // assertEq(unpaid, 0, "vest still has a balance");
        // assertEq(gov.balanceOf(address(pauseProxy)), prevMkrPause);
    }

        function testAutoLineGap() public {
        bytes32 ilk;
        uint256 line;

        giveAuth(address(autoLine), address(this));

        // Inflate Gap and Line - MATIC-A
        ilk = "MATIC-A";
        (uint256 alLine, uint256 gap, uint48 ttl,,) = autoLine.ilks(ilk);
        uint256 highGap = gap * 5;
        autoLine.setIlk(ilk, highGap * 5, highGap, ttl);
        hevm.warp(block.timestamp + ttl);
        uint256 newLine = autoLine.exec(ilk);
         (uint256 Art, uint256 rate,,,) = vat.ilks(ilk);
        assertEq(newLine, add(highGap, mul(Art, rate)), "MATIC-gap-boost-failed");

        // Inflate Gap and Line - LINK-A
        ilk = "LINK-A";
        (alLine, gap, ttl,,) = autoLine.ilks(ilk);
        highGap = gap * 5;
        autoLine.setIlk(ilk, highGap * 5, highGap, ttl);
        hevm.warp(block.timestamp + ttl);
        newLine = autoLine.exec(ilk);
        (Art, rate,,,) = vat.ilks(ilk);
        assertEq(newLine, add(highGap, mul(Art, rate)), "LINK-gap-boost-failed");

        // Inflate Gap and Line - YFI-A
        ilk = "YFI-A";
        (alLine, gap, ttl,,) = autoLine.ilks(ilk);
        highGap = gap * 5;
        // YFI had a lower line, need to inflate that too
        autoLine.setIlk(ilk, highGap * 5, highGap, ttl);
        hevm.warp(block.timestamp + ttl);
        newLine = autoLine.exec(ilk);
        (Art, rate,,,) = vat.ilks(ilk);
        assertEq(newLine, add(highGap, mul(Art, rate)), "YFI-gap-boost-failed");

        // Inflate Gap and Line - MANA-A
        ilk = "MANA-A";
        (alLine, gap, ttl,,) = autoLine.ilks(ilk);
        highGap = gap * 5;
        autoLine.setIlk(ilk, highGap * 5, highGap, ttl);
        hevm.warp(block.timestamp + ttl);
        newLine = autoLine.exec(ilk);
        (Art, rate,,,) = vat.ilks(ilk);
        assertEq(newLine, add(highGap, mul(Art, rate)), "MANA-gap-boost-failed");

        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        ilk = "MATIC-A";
        hevm.warp(block.timestamp + afterSpell.collaterals[ilk].aL_ttl);
        newLine = autoLine.exec(ilk);
        (,,,line,) = vat.ilks(ilk);
        assertEq(newLine, line);
        assertEq(line, afterSpell.collaterals[ilk].aL_line * RAD, "MATIC-line-limit-failed");

        ilk = "LINK-A";
        hevm.warp(block.timestamp + afterSpell.collaterals[ilk].aL_ttl);
        newLine = autoLine.exec(ilk);
        (,,,line,) = vat.ilks(ilk);
        assertEq(newLine, line);
        assertEq(line, afterSpell.collaterals[ilk].aL_line * RAD, "LINK-line-limit-failed");

        ilk = "YFI-A";
        hevm.warp(block.timestamp + afterSpell.collaterals[ilk].aL_ttl);
        newLine = autoLine.exec(ilk);
        (,,,line,) = vat.ilks(ilk);
        assertEq(newLine, line);
        assertEq(line, afterSpell.collaterals[ilk].aL_line * RAD, "YFI-line-limit-failed");

        ilk = "MANA-A";
        hevm.warp(block.timestamp + afterSpell.collaterals[ilk].aL_ttl);
        newLine = autoLine.exec(ilk);
        (,,,line,) = vat.ilks(ilk);
        assertEq(newLine, line);
        assertEq(line, afterSpell.collaterals[ilk].aL_line * RAD, "MANA-line-limit-failed");
    }
}
