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
    function ilks(bytes32) external returns (string memory, address, uint48 toc, uint48 tau);
    function bump(bytes32 ilk, uint256 val) external;
    function tell(bytes32) external;
    function cure(bytes32) external;
    function cull(bytes32, address) external;
    function good(bytes32) external view returns (bool);
}

interface RwaUrnLike {
    function can(address) external view returns (uint256);
    function lock(uint256) external;
    function draw(uint256) external;
    function wipe(uint256) external;
    function free(uint256) external;
}

interface RwaOutputConduitLike {
    function can(address) external view returns (uint256);
    function may(address) external view returns (uint256);
    function gem() external view returns (GemAbstract);
    function bud(address) external view returns (uint256);
    function pick(address) external;
    function push() external;
    function push(uint256) external;
    function quit() external;
    function kiss(address) external;
    function mate(address) external;
    function hope(address) external;
}

interface RwaInputConduitLike {
    function wards(address) external view returns (uint256);
    function may(address) external view returns (uint256);
    function quitTo() external view returns (address);
    function mate(address) external;
    function push() external;
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

    function testPayments() public {
        uint256 prevSin = vat.sin(address(vow));

        // For each payment, create a Payee object with
        //    the Payee address,
        //    the amount to be paid in whole Dai units
        // Initialize the array with the number of payees
        Payee[1] memory payees = [
            Payee(wallets.addr("AMBASSADOR_WALLET"), 81_000)
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

        // RWA007
        checkChainlogKey("RWA007_A_JAR");
        checkChainlogKey("RWA007");
        checkChainlogKey("MCD_JOIN_RWA007_A");
        checkChainlogKey("RWA007_A_URN");
        checkChainlogKey("RWA007_A_OUTPUT_CONDUIT");
        checkChainlogKey("RWA007_A_INPUT_CONDUIT_URN");
        checkChainlogKey("RWA007_A_INPUT_CONDUIT_JAR");
        checkChainlogKey("PIP_RWA007");

        checkChainlogVersion("1.14.2");
    }

    function testNewIlkRegistryValues() public { // make public to use
        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        // RWA007
        (, address pipRwa007,,) = oracle.ilks("RWA007-A");

        assertEq(reg.pos("RWA007-A"),    53);
        assertEq(reg.join("RWA007-A"),   addr.addr("MCD_JOIN_RWA007_A"));
        assertEq(reg.gem("RWA007-A"),    addr.addr("RWA007"));
        assertEq(reg.dec("RWA007-A"),    GemAbstract(addr.addr("RWA007")).decimals());
        assertEq(reg.class("RWA007-A"),  3);
        assertEq(reg.pip("RWA007-A"),    pipRwa007);
        assertEq(reg.name("RWA007-A"),   "RWA007-A: Monetalis Clydesdale");
        assertEq(reg.symbol("RWA007-A"), GemAbstract(addr.addr("RWA007")).symbol());
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
        uint256 OCT_01_2022 = 1664582400; // Saturday, October   1, 2022 12:00:00 AM
        uint256 OCT_31_2022 = 1667260799; // Monday,   October  31, 2022 11:59:59 PM

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

        // Give admin powers to Test contract address and make the vesting unrestricted for testing
        giveAuth(address(vest), address(this));
        uint256 prevBalance;

        vest.unrestrict(10);
        prevBalance = dai.balanceOf(wallets.addr("DAIF_WALLET"));
        hevm.warp(OCT_01_2022 + 31 days);
        assertTrue(tryVest(address(vest), 10));
        assertEq(dai.balanceOf(wallets.addr("DAIF_WALLET")), prevBalance + 67_863 * WAD);
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

    function testVestMKR() public {
        VestAbstract vest = VestAbstract(addr.addr("MCD_VEST_MKR_TREASURY"));
        assertEq(vest.ids(), 24);

        uint256 prevAllowance = gov.allowance(pauseProxy, addr.addr("MCD_VEST_MKR_TREASURY"));

        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        assertEq(gov.allowance(pauseProxy, addr.addr("MCD_VEST_MKR_TREASURY")), prevAllowance + 787.70 ether);

        assertEq(vest.cap(), 1_100 * WAD / 365 days);
        assertEq(vest.ids(), 28);

        uint256 AUG_01_2022 = 1659326400;
        uint256 AUG_01_2023 = 1690862400;
        uint256 SEP_28_2022 = 1664337600;
        uint256 SEP_28_2024 = 1727496000;

        address GOV_WALLET1 = 0xbfDD0E744723192f7880493b66501253C34e1241;
        address GOV_WALLET2 = 0xbb147E995c9f159b93Da683dCa7893d6157199B9;
        address GOV_WALLET3 = 0x01D26f8c5cC009868A4BF66E268c17B057fF7A73;
        address SNE_WALLET = wallets.addr("SNE_WALLET");

        // -----
        assertEq(vest.usr(25), GOV_WALLET1);
        assertEq(vest.bgn(25), AUG_01_2022);
        assertEq(vest.clf(25), AUG_01_2023);
        assertEq(vest.fin(25), AUG_01_2023);
        assertEq(vest.mgr(25), address(0));
        assertEq(vest.res(25), 1);
        assertEq(vest.tot(25), 62.50 ether);
        assertEq(vest.rxd(25), 0);

        assertEq(vest.usr(26), GOV_WALLET2);
        assertEq(vest.bgn(26), AUG_01_2022);
        assertEq(vest.clf(26), AUG_01_2023);
        assertEq(vest.fin(26), AUG_01_2023);
        assertEq(vest.mgr(26), address(0));
        assertEq(vest.res(26), 1);
        assertEq(vest.tot(26), 32.69 ether);
        assertEq(vest.rxd(26), 0);

        assertEq(vest.usr(27), GOV_WALLET3);
        assertEq(vest.bgn(27), AUG_01_2022);
        assertEq(vest.clf(27), AUG_01_2023);
        assertEq(vest.fin(27), AUG_01_2023);
        assertEq(vest.mgr(27), address(0));
        assertEq(vest.res(27), 1);
        assertEq(vest.tot(27), 152.51 ether);
        assertEq(vest.rxd(27), 0);

        assertEq(vest.usr(28), SNE_WALLET);
        assertEq(vest.bgn(28), SEP_28_2022);
        assertEq(vest.clf(28), SEP_28_2022);
        assertEq(vest.fin(28), SEP_28_2024);
        assertEq(vest.mgr(28), address(0));
        assertEq(vest.res(28), 1);
        assertEq(vest.tot(28), 540.00 ether);
        assertEq(vest.rxd(28), 0);
    }

    function testMKRPayments() public {
        uint256 prevMkrPause = gov.balanceOf(address(pauseProxy));
        uint256 prevMkrSNE   = gov.balanceOf(wallets.addr("SNE_WALLET"));
        uint256 prevMkrSES   = gov.balanceOf(wallets.addr("SES_WALLET"));

        uint256 amountSNE    = 270.00 ether;
        uint256 amountSES    = 227.64 ether;

        uint256 total = amountSNE + amountSES;

        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        assertEq(gov.balanceOf(address(pauseProxy)), prevMkrPause - total);
        assertEq(gov.balanceOf(wallets.addr("SNE_WALLET")), prevMkrSNE + amountSNE);
        assertEq(gov.balanceOf(wallets.addr("SES_WALLET")), prevMkrSES + amountSES);
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
    address RWA007_A_OPERATOR                  = addr.addr("RWA007_A_OPERATOR");
    address RWA007_A_COINBASE_CUSTODY          = addr.addr("RWA007_A_COINBASE_CUSTODY");
    
    RwaLiquidationLike oracle                  = RwaLiquidationLike(addr.addr("MIP21_LIQUIDATION_ORACLE"));

    GemAbstract          rwagem_007            = GemAbstract(addr.addr("RWA007"));
    GemJoinAbstract      rwajoin_007           = GemJoinAbstract(addr.addr("MCD_JOIN_RWA007_A"));
    RwaUrnLike           rwaurn_007            = RwaUrnLike(addr.addr("RWA007_A_URN"));
    RwaOutputConduitLike rwaconduitout_007     = RwaOutputConduitLike(addr.addr("RWA007_A_OUTPUT_CONDUIT"));
    GemAbstract          psmGem                = rwaconduitout_007.gem();
    RwaInputConduitLike  rwaconduitinurn_007   = RwaInputConduitLike(addr.addr("RWA007_A_INPUT_CONDUIT_URN"));
    RwaInputConduitLike  rwaconduitinjar_007   = RwaInputConduitLike(addr.addr("RWA007_A_INPUT_CONDUIT_JAR"));
    uint256 daiPsmGemDiffDecimals              = 10**sub(dai.decimals(), psmGem.decimals());

    string OLDDOC = "";
    string NEWDOC = "";

    function testDocChange() private { // make public to use
        bytes32 ilk = "RWA009-A";
        RwaLiquidationLike oracle = RwaLiquidationLike(
            addr.addr("MIP21_LIQUIDATION_ORACLE")
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

    function testRWA007_INTEGRATION_CONDUITS_SETUP() public {
        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        assertEq(rwaconduitout_007.can(pauseProxy), 1, "OutputConduit/pause-proxy-not-operator");
        assertEq(rwaconduitout_007.can(RWA007_A_OPERATOR), 1, "OutputConduit/monetalis-not-operator");
        assertEq(rwaconduitout_007.may(pauseProxy), 1, "OutputConduit/pause-proxy-not-mate");
        assertEq(rwaconduitout_007.may(RWA007_A_OPERATOR), 1, "OutputConduit/monetalis-not-mate");
        
        assertEq(rwaconduitout_007.bud(RWA007_A_COINBASE_CUSTODY), 1, "OutputConduit/coinbase-custody-not-whitelisted-for-pick");

        assertEq(rwaconduitinurn_007.may(pauseProxy), 1, "InputConduitUrn/pause-proxy-not-mate");
        assertEq(rwaconduitinurn_007.may(RWA007_A_OPERATOR), 1, "InputConduitUrn/monetalis-not-mate");
        assertEq(rwaconduitinurn_007.quitTo(), RWA007_A_COINBASE_CUSTODY, "InputConduitUrn/quit-to-not-set");

        assertEq(rwaconduitinjar_007.may(pauseProxy), 1, "InputConduitJar/pause-proxy-not-mate");
        assertEq(rwaconduitinjar_007.may(RWA007_A_OPERATOR), 1, "InputConduitJar/monetalis-not-mate");
        assertEq(rwaconduitinjar_007.quitTo(), RWA007_A_COINBASE_CUSTODY, "InputConduitJar/quit-to-not-set");
    }

    function testRWA007_INTEGRATION_BUMP() public {
        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        giveAuth(address(oracle), address(this));

        (, address pip, , ) = oracle.ilks("RWA007-A");

        assertEq(DSValueAbstract(pip).read(), bytes32(250 * MILLION * WAD), "RWA007: Bad initial PIP value");

        oracle.bump("RWA007-A", 260 * MILLION * WAD);

        assertEq(DSValueAbstract(pip).read(), bytes32(260 * MILLION * WAD), "RWA007: Bad PIP value after bump()");
    }

    function testRWA007_INTEGRATION_TELL() public {
        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        giveAuth(address(vat), address(this));
        giveAuth(address(oracle), address(this));

        (, , , uint48 tocPre) = oracle.ilks("RWA007-A");
        assertEq(uint256(tocPre), 0, "RWA007: `toc` is not 0 before tell()");
        assertTrue(oracle.good("RWA007-A"), "RWA007: Oracle not good before tell()");

        vat.file("RWA007-A", "line", 0);
        oracle.tell("RWA007-A");

        (, , , uint48 tocPost) = oracle.ilks("RWA007-A");
        assertGt(uint256(tocPost), 0, "RWA007: `toc` is not set after tell()");
        assertTrue(!oracle.good("RWA007-A"), "RWA007: Oracle still good after tell()");
    }

    function testRWA007_INTEGRATION_TELL_CURE_GOOD() public {
        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        giveAuth(address(vat), address(this));
        giveAuth(address(oracle), address(this));

        vat.file("RWA007-A", "line", 0);
        oracle.tell("RWA007-A");

        assertTrue(!oracle.good("RWA007-A"), "RWA007: Oracle still good after tell()");

        oracle.cure("RWA007-A");

        assertTrue(oracle.good("RWA007-A"), "RWA007: Oracle not good after cure()");
        (, , , uint48 toc) = oracle.ilks("RWA007-A");
        assertEq(uint256(toc), 0, "RWA007: `toc` not zero after cure()");
    }

    function testFailRWA007_INTEGRATION_CURE_BEFORE_TELL() public {
        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        giveAuth(address(oracle), address(this));

        oracle.cure("RWA007-A");
    }

    function testRWA007_INTEGRATION_TELL_CULL() public {
        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        giveAuth(address(vat), address(this));
        giveAuth(address(oracle), address(this));

        assertTrue(oracle.good("RWA007-A"));

        vat.file("RWA007-A", "line", 0);
        oracle.tell("RWA007-A");

        assertTrue(!oracle.good("RWA007-A"), "RWA007: Oracle still good after tell()");

        oracle.cull("RWA007-A", addr.addr("RWA007_A_URN"));

        assertTrue(!oracle.good("RWA007-A"), "RWA007: Oracle still good after cull()");
        (, address pip, , ) = oracle.ilks("RWA007-A");
        assertEq(DSValueAbstract(pip).read(), bytes32(0), "RWA007: Oracle PIP value not set to zero after cull()");
    }

    function testRWA007_PAUSE_PROXY_OWNS_RWA007_TOKEN_BEFORE_SPELL() public {
        assertEq(rwagem_007.balanceOf(addr.addr('MCD_PAUSE_PROXY')), 1 * WAD);
    }

    function testRWA007_SPELL_LOCK_OPERATOR_DRAW_WIPE_FREE() public {
        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        uint256 drawAmount = 1_000_000 * WAD;

        // setting address(this) as operator
        hevm.store(address(rwaurn_007), keccak256(abi.encode(address(this), uint256(1))), bytes32(uint256(1)));
        assertEq(rwaurn_007.can(address(this)), 1);

        // Check if spell lock 1 * WAD of RWA009
        assertEq(rwagem_007.balanceOf(addr.addr('MCD_PAUSE_PROXY')), 0, "RWA007: gem not transfered from the pause proxy");
        assertEq(rwagem_007.balanceOf(address(rwajoin_007)), 1 * WAD, "RWA007: gem not locked into the urn");

        // 0 DAI in Output Conduit
        assertEq(dai.balanceOf(address(rwaconduitout_007)), 0, "RWA007: Dangling Dai in input conduit before draw()");

        // Draw 1mm
        rwaurn_007.draw(drawAmount);

        // 1mm DAI in Output Conduit
        assertEq(dai.balanceOf(address(rwaconduitout_007)), drawAmount, "RWA007: Dai drawn was not send to the recipient");

        (uint256 ink, uint256 art) = vat.urns("RWA007-A", address(rwaurn_007));
        assertEq(art, drawAmount, "RWA007: bad `art` after spell"); // DAI drawn == art as rate should always be 1 RAY
        assertEq(ink, 1 * WAD, "RWA007: bad `ink` after spell"); // Whole unit of collateral is locked

        hevm.warp(block.timestamp + 10 days);
        jug.drip("RWA007-A");

        (, uint256 rate,,,) = vat.ilks("RWA007-A");
        assertEq(rate, RAY, 'RWA007: bad `rate`'); // rate keeps being 1 RAY

        // wards
        giveAuth(address(rwaconduitout_007), address(this));
        // may
        rwaconduitout_007.mate(address(this));
        assertEq(rwaconduitout_007.may(address(this)), 1);
        rwaconduitout_007.hope(address(this));
        assertEq(rwaconduitout_007.can(address(this)), 1);

        rwaconduitout_007.kiss(address(this));
        assertEq(rwaconduitout_007.bud(address(this)), 1);
        rwaconduitout_007.pick(address(this));

        uint256 pushAmount = 100 * WAD; // We push only 100 DAI
        rwaconduitout_007.push(pushAmount);
        rwaconduitout_007.quit();

        assertEq(dai.balanceOf(address(rwaconduitout_007)), 0, "RWA007: Output conduit still holds Dai after push()");
        assertEq(psmGem.balanceOf(address(this)), pushAmount / daiPsmGemDiffDecimals, "RWA007: Psm GEM not sent to destination after push()");
        assertEq(dai.balanceOf(address(rwaurn_007)), drawAmount - pushAmount, "RWA007: Dai not sent to destination after push()");

        // as we have SF 0 we need to pay exectly the same amount of DAI we have drawn
        uint256 daiToPay = drawAmount;

        // wards
        giveAuth(address(rwaconduitinurn_007), address(this));
        // may
        rwaconduitinurn_007.mate(address(this));
        assertEq(rwaconduitinurn_007.may(address(this)), 1);

        // transfer PSM GEM to input conduit
        psmGem.transfer(address(rwaconduitinurn_007), pushAmount / daiPsmGemDiffDecimals);
        assertEq(psmGem.balanceOf(address(rwaconduitinurn_007)), pushAmount / daiPsmGemDiffDecimals, "RWA007: Psm GEM not sent to input conduit");
        
        // input conduit 'push()' to the urn
        rwaconduitinurn_007.push();

        assertEq(dai.balanceOf(address(rwaurn_007)), daiToPay, "Balance of the URN doesnt match");

        // repay debt and free our collateral
        rwaurn_007.wipe(daiToPay);
        rwaurn_007.free(1 * WAD);

        // check if we get back RWA009 Tokens
        assertEq(rwagem_007.balanceOf(address(this)), 1 * WAD, "RWA007: gem not sent back to the caller");

        // check if we have 0 collateral and outstanding debt in the VAT
        (ink, art) = vat.urns("RWA007-A", address(rwaurn_007));
        assertEq(ink, 0, "RWA007: bad `ink` after free()");
        assertEq(art, 0, "RWA007: bad `art` after wipe()");
    }

    function testRWA007_OPERATOR_LOCK_DRAW_CAGE() public {
        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        uint256 drawAmount = 1_000_000 * WAD;

        // setting address(this) as operator
        hevm.store(address(rwaurn_007), keccak256(abi.encode(address(this), uint256(1))), bytes32(uint256(1)));
        assertEq(rwaurn_007.can(address(this)), 1);

        // Check if spell lock 1 * WAD of RWA009
        assertEq(rwagem_007.balanceOf(addr.addr('MCD_PAUSE_PROXY')), 0, "RWA007: gem not transfered from the pause proxy");
        assertEq(rwagem_007.balanceOf(address(rwajoin_007)), 1 * WAD, "RWA007: gem not locked into the urn");

        // 0 DAI in Output Conduit
        assertEq(dai.balanceOf(address(rwaconduitout_007)), 0, "RWA007: Dangling Dai in input conduit before draw()");

        // Draw 1mm
        rwaurn_007.draw(drawAmount);

        // 1mm DAI in Output Conduit
        assertEq(dai.balanceOf(address(rwaconduitout_007)), drawAmount, "RWA007: Dai drawn was not send to the recipient");

        (uint256 ink, uint256 art) = vat.urns("RWA007-A", address(rwaurn_007));
        assertEq(art, drawAmount, "RWA007: bad `art` after spell"); // DAI drawn == art as rate should always be 1 RAY
        assertEq(ink, 1 * WAD, "RWA007: bad `ink` after spell"); // Whole unit of collateral is locked

        hevm.warp(block.timestamp + 10 days);
        jug.drip("RWA007-A");

        (, uint256 rate,,,) = vat.ilks("RWA007-A");
        assertEq(rate, RAY, 'RWA007: bad `rate`'); // rate keeps being 1 RAY

        // wards
        giveAuth(address(rwaconduitout_007), address(this));
        // may
        rwaconduitout_007.mate(address(this));
        rwaconduitout_007.hope(address(this));

        rwaconduitout_007.kiss(address(this));
        assertEq(rwaconduitout_007.bud(address(this)), 1);
        rwaconduitout_007.pick(address(this));

        uint256 pushAmount = 100 * WAD; // We push only 100 DAI
        rwaconduitout_007.push(pushAmount);
        rwaconduitout_007.quit();

        assertEq(dai.balanceOf(address(rwaconduitout_007)), 0, "RWA007: Output conduit still holds Dai after push()");
        assertEq(psmGem.balanceOf(address(this)), pushAmount / daiPsmGemDiffDecimals, "RWA007: Psm GEM not sent to destination after push()");
        assertEq(dai.balanceOf(address(rwaurn_007)), drawAmount - pushAmount, "RWA007: Dai not sent to destination after push()");

        // END
        giveAuth(address(end), address(this));
        end.cage();
        end.cage("RWA007-A");

        end.skim("RWA007-A", address(rwaurn_007));

        (ink, art) = vat.urns("RWA007-A", address(rwaurn_007));
        uint256 skimmedInk = drawAmount / 250_000_000;
        assertEq(ink, 1 * WAD - skimmedInk, "RWA007: wrong ink in urn after skim");
        assertEq(art, 0, "RWA007: wrong art in urn after skim");

        hevm.warp(block.timestamp + end.wait());

        vow.heal(min(vat.dai(address(vow)), sub(sub(vat.sin(address(vow)), vow.Sin()), vow.Ash())));

        // Removing the surplus to allow continuing the execution.
        hevm.store(
            address(vat),
            keccak256(abi.encode(address(vow), uint256(5))),
            bytes32(uint256(0))
        );

        end.thaw();

        end.flow("RWA007-A");

        giveTokens(address(dai), 1_000_000 * WAD);
        dai.approve(address(daiJoin), 1_000_000 * WAD);
        daiJoin.join(address(this), 1_000_000 * WAD);

        vat.hope(address(end));
        end.pack(1_000_000 * WAD);

        // Check DAI redemption after "cage()"
        assertEq(vat.gem("RWA007-A", address(this)), 0, "RWA007: wrong vat gem");
        assertEq(rwagem_007.balanceOf(address(this)), 0, "RWA007: wrong gem balance");
        end.cash("RWA007-A", 1_000_000 * WAD);
        assertGt(vat.gem("RWA007-A", address(this)), 0, "RWA007: wrong vat gem after cash");
        assertEq(rwagem_007.balanceOf(address(this)), 0, "RWA007: wrong gem balance after cash");
        rwajoin_007.exit(address(this), vat.gem("RWA007-A", address(this)));
        assertEq(vat.gem("RWA007-A", address(this)), 0, "RWA007: wrong vat gem after exit");
        assertGt(rwagem_007.balanceOf(address(this)), 0, "RWA007: wrong gem balance after exit");
    }
}
