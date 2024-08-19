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

pragma solidity 0.8.16;

import "./DssSpell.t.base.sol";
import {ScriptTools} from "dss-test/DssTest.sol";

import {RootDomain} from "dss-test/domains/RootDomain.sol";
import {OptimismDomain} from "dss-test/domains/OptimismDomain.sol";
import {ArbitrumDomain} from "dss-test/domains/ArbitrumDomain.sol";

interface L2Spell {
    function dstDomain() external returns (bytes32);
    function gateway() external returns (address);
}

interface L2Gateway {
    function validDomains(bytes32) external returns (uint256);
}

interface BridgeLike {
    function l2TeleportGateway() external view returns (address);
}

interface ProxyLike {
    function exec(address target, bytes calldata args) external payable returns (bytes memory out);
}

interface SpellActionLike {
    function dao_resolutions() external view returns (string memory);
}

interface RwaConduitLike {
    function psm() external view returns (address);
    function pal(address) external view returns (uint256);
}

interface CronSequencerLike {
    function getMaster() external view returns (bytes32);
    function hasJob(address) external view returns (bool);
}

interface LitePsmJobLike {
    function cutThreshold() external view returns (uint256);
    function gushThreshold() external view returns (uint256);
    function litePsm() external view returns (address);
    function rushThreshold() external view returns (uint256);
    function sequencer() external view returns (address);
    function work(bytes32, bytes calldata) external;
    function workable(bytes32) external view returns (bool, bytes memory);
}

contract DssSpellTest is DssSpellTestBase {
    string         config;
    RootDomain     rootDomain;
    OptimismDomain optimismDomain;
    ArbitrumDomain arbitrumDomain;

    // DO NOT TOUCH THE FOLLOWING TESTS, THEY SHOULD BE RUN ON EVERY SPELL
    function testGeneral() public {
        _testGeneral();
    }

    function testOfficeHours() public {
        _testOfficeHours();
    }

    function testCastOnTime() public {
        _testCastOnTime();
    }

    function testNextCastTime() public {
        _testNextCastTime();
    }

    function testRevertIfNotScheduled() public {
        _testRevertIfNotScheduled();
    }

    function testUseEta() public {
        _testUseEta();
    }

    function testContractSize() public skippedWhenDeployed {
        _testContractSize();
    }

    function testDeployCost() public skippedWhenDeployed {
        _testDeployCost();
    }

    function testBytecodeMatches() public skippedWhenNotDeployed {
        _testBytecodeMatches();
    }

    function testCastCost() public {
        _testCastCost();
    }

    function testChainlogIntegrity() public {
        _testChainlogIntegrity();
    }

    function testChainlogValues() public {
        _testChainlogValues();
    }

    // Leave this test public (for now) as this is acting like a config test
    function testPSMs() public {
        _vote(address(spell));
        _scheduleWaitAndCast(address(spell));
        assertTrue(spell.done(), "TestError/spell-not-done");

        bytes32 _ilk;

        // USDC
        _ilk = "PSM-USDC-A";
        assertEq(addr.addr("MCD_JOIN_PSM_USDC_A"), reg.join(_ilk));
        assertEq(addr.addr("MCD_CLIP_PSM_USDC_A"), reg.xlip(_ilk));
        assertEq(addr.addr("PIP_USDC"), reg.pip(_ilk));
        assertEq(addr.addr("MCD_PSM_USDC_A"), chainLog.getAddress("MCD_PSM_USDC_A"));
        _checkPsmIlkIntegration(
            _ilk,
            GemJoinAbstract(addr.addr("MCD_JOIN_PSM_USDC_A")),
            ClipAbstract(addr.addr("MCD_CLIP_PSM_USDC_A")),
            addr.addr("PIP_USDC"),
            PsmAbstract(addr.addr("MCD_PSM_USDC_A")),
            1,   // tin
            1    // tout
        );

        // GUSD
        _ilk = "PSM-GUSD-A";
        assertEq(addr.addr("MCD_JOIN_PSM_GUSD_A"), reg.join(_ilk));
        assertEq(addr.addr("MCD_CLIP_PSM_GUSD_A"), reg.xlip(_ilk));
        assertEq(addr.addr("PIP_GUSD"), reg.pip(_ilk));
        assertEq(addr.addr("MCD_PSM_GUSD_A"), chainLog.getAddress("MCD_PSM_GUSD_A"));
        _checkPsmIlkIntegration(
            _ilk,
            GemJoinAbstract(addr.addr("MCD_JOIN_PSM_GUSD_A")),
            ClipAbstract(addr.addr("MCD_CLIP_PSM_GUSD_A")),
            addr.addr("PIP_GUSD"),
            PsmAbstract(addr.addr("MCD_PSM_GUSD_A")),
            0,  // tin
            0    // tout
        );

        // USDP
        _ilk = "PSM-PAX-A";
        assertEq(addr.addr("MCD_JOIN_PSM_PAX_A"), reg.join(_ilk));
        assertEq(addr.addr("MCD_CLIP_PSM_PAX_A"), reg.xlip(_ilk));
        assertEq(addr.addr("PIP_PAX"), reg.pip(_ilk));
        assertEq(addr.addr("MCD_PSM_PAX_A"), chainLog.getAddress("MCD_PSM_PAX_A"));
        _checkPsmIlkIntegration(
            _ilk,
            GemJoinAbstract(addr.addr("MCD_JOIN_PSM_PAX_A")),
            ClipAbstract(addr.addr("MCD_CLIP_PSM_PAX_A")),
            addr.addr("PIP_PAX"),
            PsmAbstract(addr.addr("MCD_PSM_PAX_A")),
            0,   // tin
            0    // tout
        );
    }

    function testLitePSMs() public {
        _vote(address(spell));
        _scheduleWaitAndCast(address(spell));
        assertTrue(spell.done(), "TestError/spell-not-done");

        bytes32 _ilk;

        // USDC
        _ilk = "LITE-PSM-USDC-A";
        assertEq(addr.addr("PIP_USDC"),            reg.pip(_ilk));
        assertEq(addr.addr("MCD_LITE_PSM_USDC_A"), chainLog.getAddress("MCD_LITE_PSM_USDC_A"));
        _checkLitePsmIlkIntegration(
            LitePsmIlkIntegrationParams({
                ilk:      _ilk,
                pip:      addr.addr("PIP_USDC"),
                litePsm:  addr.addr("MCD_LITE_PSM_USDC_A"),
                pocket:   addr.addr("MCD_LITE_PSM_USDC_A_POCKET"),
                bufUnits: 200_000_000,
                tinBps:             0,
                toutBps:            0
            })
        );
    }

    // END OF TESTS THAT SHOULD BE RUN ON EVERY SPELL

    // TESTS BELOW CAN BE ENABLED/DISABLED ON DEMAND

    function testOracleList() public skipped { // TODO: check if this test can be removed for good.
        // address ORACLE_WALLET01 = 0x4D6fbF888c374D7964D56144dE0C0cFBd49750D3;

        //assertEq(OsmAbstract(0xF15993A5C5BE496b8e1c9657Fd2233b579Cd3Bc6).wards(ORACLE_WALLET01), 0);

        //_vote(address(spell));
        //_scheduleWaitAndCast(address(spell));
        //assertTrue(spell.done());

        //assertEq(OsmAbstract(0xF15993A5C5BE496b8e1c9657Fd2233b579Cd3Bc6).wards(ORACLE_WALLET01), 1);
    }

    function testRemoveChainlogValues() public skipped { // add the `skipped` modifier to skip
        string[1] memory removedKeys = [
            "MCD_CAT"
        ];

        for (uint256 i = 0; i < removedKeys.length; i++) {
            try chainLog.getAddress(_stringToBytes32(removedKeys[i])) {
            } catch Error(string memory errmsg) {
                if (_cmpStr(errmsg, "dss-chain-log/invalid-key")) {
                    fail(_concat("TestError/key-to-remove-does-not-exist: ", removedKeys[i]));
                } else {
                    fail(errmsg);
                }
            }
        }

        _vote(address(spell));
        _scheduleWaitAndCast(address(spell));
        assertTrue(spell.done(), "TestError/spell-not-done");

        for (uint256 i = 0; i < removedKeys.length; i++) {
            try chainLog.getAddress(_stringToBytes32(removedKeys[i])) {
                fail(_concat("TestError/key-not-removed: ", removedKeys[i]));
            } catch Error(string memory errmsg) {
                assertTrue(
                    _cmpStr(errmsg, "dss-chain-log/invalid-key"),
                    _concat("TestError/key-not-removed: ", removedKeys[i])
                );
            } catch {
                fail(_concat("TestError/unknown-reason: ", removedKeys[i]));
            }
        }
    }

    function testCollateralIntegrations() public skipped { // add the `skipped` modifier to skip
        _vote(address(spell));
        _scheduleWaitAndCast(address(spell));
        assertTrue(spell.done(), "TestError/spell-not-done");

        // Insert new collateral tests here
        _checkIlkIntegration(
            "GNO-A",
            GemJoinAbstract(addr.addr("MCD_JOIN_GNO_A")),
            ClipAbstract(addr.addr("MCD_CLIP_GNO_A")),
            addr.addr("PIP_GNO"),
            true, /* _isOSM */
            true, /* _checkLiquidations */
            false /* _transferFee */
        );
    }

    function testIlkClipper() public skipped { // add the `skipped` modifier to skip
        _vote(address(spell));
        _scheduleWaitAndCast(address(spell));
        assertTrue(spell.done(), "TestError/spell-not-done");

        _checkIlkClipper(
            "RETH-A",
            GemJoinAbstract(addr.addr("MCD_JOIN_RETH_A")),
            ClipAbstract(addr.addr("MCD_CLIP_RETH_A")),
            addr.addr("MCD_CLIP_CALC_RETH_A"),
            OsmAbstract(addr.addr("PIP_RETH")),
            1_000 * WAD
        );
    }

    function testLerpSurplusBuffer() public skipped { // add the `skipped` modifier to skip
        _vote(address(spell));
        _scheduleWaitAndCast(address(spell));
        assertTrue(spell.done(), "TestError/spell-not-done");

        // Insert new SB lerp tests here

        LerpAbstract lerp = LerpAbstract(lerpFactory.lerps("NAME"));

        uint256 duration = 210 days;
        vm.warp(block.timestamp + duration / 2);
        assertEq(vow.hump(), 60 * MILLION * RAD);
        lerp.tick();
        assertEq(vow.hump(), 75 * MILLION * RAD);
        vm.warp(block.timestamp + duration / 2);
        lerp.tick();
        assertEq(vow.hump(), 90 * MILLION * RAD);
        assertTrue(lerp.done());
    }

    function testNewIlkRegistryValues() public skipped { // add the `skipped` modifier to skip
        _vote(address(spell));
        _scheduleWaitAndCast(address(spell));
        assertTrue(spell.done(), "TestError/spell-not-done");

        // Insert new ilk registry values tests here
        _checkIlkIntegration(
             "TOKEN-X",
             GemJoinAbstract(addr.addr("MCD_JOIN_TOKEN_X")),
             ClipAbstract(addr.addr("MCD_CLIP_TOKEN_X")),
             addr.addr("PIP_TOKEN"),
             true,
             true,
             false
        );
    }

    function testEsmAuth() public skipped { // add the `skipped` modifier to skip
        string[1] memory esmAuthorisedContractKeys = [
            "MCD_LITE_PSM_USDC_A_IN_CDT_JAR"
        ];

        for (uint256 i = 0; i < esmAuthorisedContractKeys.length; i++) {
            assertEq(
                WardsAbstract(addr.addr(_stringToBytes32(esmAuthorisedContractKeys[i]))).wards(address(esm)),
                0,
                _concat("TestError/esm-is-ward-before-spell: ", esmAuthorisedContractKeys[i])
            );
        }

        _vote(address(spell));
        _scheduleWaitAndCast(address(spell));
        assertTrue(spell.done(), "TestError/spell-not-done");

        for (uint256 i = 0; i < esmAuthorisedContractKeys.length; i++) {
            assertEq(
                WardsAbstract(addr.addr(_stringToBytes32(esmAuthorisedContractKeys[i]))).wards(address(esm)),
                1,
                _concat("TestError/esm-is-not-ward-after-spell: ", esmAuthorisedContractKeys[i])
            );
        }
    }

    function testOSMs() public skipped { // add the `skipped` modifier to skip
        address READER = address(0);

        // Track OSM authorizations here
        assertEq(OsmAbstract(addr.addr("PIP_TOKEN")).bud(READER), 0);

        _vote(address(spell));
        _scheduleWaitAndCast(address(spell));
        assertTrue(spell.done(), "TestError/spell-not-done");

        assertEq(OsmAbstract(addr.addr("PIP_TOKEN")).bud(READER), 1);
    }

    function testMedianizers() public skipped { // add the `skipped` modifier to skip
        _vote(address(spell));
        _scheduleWaitAndCast(address(spell));
        assertTrue(spell.done(), "TestError/spell-not-done");

        // Track Median authorizations here
        address SET_TOKEN    = address(0);
        address TOKENUSD_MED = OsmAbstract(addr.addr("PIP_TOKEN")).src();
        assertEq(MedianAbstract(TOKENUSD_MED).bud(SET_TOKEN), 1);
    }

    struct Stream {
        uint256 streamId;
        address wallet;
        uint256 rewardAmount;
        uint256 start;
        uint256 cliff;
        uint256 end;
        uint256 durationDays;
        address manager;
        uint256 isRestricted;
        uint256 claimedAmount;
    }

    function testVestDAI() public skipped { // add the `skipped` modifier to skip
        // Provide human-readable names for timestamps
        uint256 DEC_01_2023 = 1701385200;
        uint256 NOV_30_2024 = 1733007599;

        // For each new stream, provide Stream object
        // and initialize the array with the corrent number of new streams
        Stream[1] memory streams = [
            Stream({
                streamId:      38,
                wallet:        wallets.addr("ECOSYSTEM_FACILITATOR"),
                rewardAmount:  504_000 * WAD,
                start:         DEC_01_2023,
                cliff:         DEC_01_2023,
                end:           NOV_30_2024,
                durationDays:  366 days,
                manager:       address(0),
                isRestricted:  1,
                claimedAmount: 0
            })
        ];

        // Record previous values for the reference
        VestAbstract vest = VestAbstract(addr.addr("MCD_VEST_DAI"));
        uint256 prevStreamCount = vest.ids();

        _vote(address(spell));
        _scheduleWaitAndCast(address(spell));
        assertTrue(spell.done(), "TestError/spell-not-done");

        // Check maximum vesting rate (Note: this should eventually be moved to _testGeneral)
        assertEq(vest.cap(), 1 * MILLION * WAD / 30 days, "testVestDAI/invalid-cap");

        // Check that all streams added in this spell are tested
        assertEq(vest.ids(), prevStreamCount + streams.length, "testVestDAI/not-all-streams-tested");

        for (uint256 i = 0; i < streams.length; i++) {
            uint256 streamId = prevStreamCount + i + 1;

            // Check values of the each stream
            assertEq(streamId, streams[i].streamId, "testVestDAI/invalid-id");
            assertEq(vest.usr(streamId), streams[i].wallet, "testVestDAI/invalid-address");
            assertEq(vest.tot(streamId), streams[i].rewardAmount, "testVestDAI/invalid-total");
            assertEq(vest.bgn(streamId), streams[i].start, "testVestDAI/invalid-bgn");
            assertEq(vest.clf(streamId), streams[i].cliff, "testVestDAI/invalid-clif");
            assertEq(vest.fin(streamId), streams[i].start + streams[i].durationDays - 1, "testVestDAI/invalid-calculated-fin");
            assertEq(vest.fin(streamId), streams[i].end, "testVestDAI/invalid-fin-variable");
            assertEq(vest.mgr(streamId), streams[i].manager, "testVestDAI/invalid-manager");
            assertEq(vest.res(streamId), streams[i].isRestricted, "testVestDAI/invalid-res");
            assertEq(vest.rxd(streamId), streams[i].claimedAmount, "testVestDAI/invalid-rxd");

            // Check each new stream is payable in the future
            uint256 prevWalletBalance = dai.balanceOf(streams[i].wallet);
            GodMode.setWard(address(vest), address(this), 1);
            vest.unrestrict(streamId);
            vm.warp(streams[i].end);
            vest.vest(streamId);
            assertEq(dai.balanceOf(streams[i].wallet), prevWalletBalance + streams[i].rewardAmount, "testVestDAI/invalid-received-amount");
        }
    }

    struct Payee {
        address addr;
        uint256 amount;
    }

    function testDAIPayments() public skipped { // add the `skipped` modifier to skip
        // For each payment, create a Payee object with
        //    the Payee address,
        //    the amount to be paid in whole Dai units
        // Initialize the array with the number of payees
        Payee[10] memory payees = [
            Payee(wallets.addr("IMMUNEFI_USER_PAYOUT_2024_08_08"), 100_000),
            Payee(wallets.addr("IMMUNEFI_COMISSION"), 10_000),
            Payee(wallets.addr("BLUE"), 54_167),
            Payee(wallets.addr("CLOAKY"), 20_417),
            Payee(wallets.addr("CLOAKY_KOHLA_2"), 14_172),
            Payee(wallets.addr("CLOAKY_ENNOIA"), 9_083),
            Payee(wallets.addr("BYTERON"), 8_333),
            Payee(wallets.addr("JULIACHANG"), 8_333),
            Payee(wallets.addr("ROCKY"), 7_500),
            Payee(wallets.addr("PBG"), 6_667)
        ];

        uint256 expectedSumPayments = 238_672; // Fill the number with the value from exec doc.

        uint256 prevBalance;
        uint256 totAmount;
        uint256[] memory prevAmounts = new uint256[](payees.length);

        for (uint256 i = 0; i < payees.length; i++) {
            totAmount += payees[i].amount;
            prevAmounts[i] = dai.balanceOf(payees[i].addr);
            prevBalance += prevAmounts[i];
        }

        _vote(address(spell));
        spell.schedule();
        vm.warp(spell.nextCastTime());
        pot.drip();
        uint256 prevSin = vat.sin(address(vow));
        spell.cast();
        assertTrue(spell.done(), "TestError/spell-not-done");

        assertEq(vat.sin(address(vow)) - prevSin, totAmount * RAD, "testPayments/vat-sin-mismatch");
        assertEq(vat.sin(address(vow)) - prevSin, expectedSumPayments * RAD, "testPaymentsSum/vat-sin-mismatch");

        for (uint256 i = 0; i < payees.length; i++) {
            assertEq(
                dai.balanceOf(payees[i].addr) - prevAmounts[i],
                payees[i].amount * WAD
            );
        }
    }

    struct Yank {
        uint256 streamId;
        address addr;
        uint256 finPlanned;
    }

    function testYankDAI() public skipped { // add the `skipped` modifier to skip
        // Provide human-readable names for timestamps
        uint256 FEB_29_2024 = 1709251199;
        uint256 MAR_31_2024 = 1711929599;

        // For each yanked stream, provide Yank object with:
        //   the stream id
        //   the address of the stream
        //   the planned fin of the stream (via variable defined above)
        // Initialize the array with the corrent number of yanks
        Yank[2] memory yanks = [
            Yank(20, wallets.addr("BA_LABS"), FEB_29_2024),
            Yank(21, wallets.addr("BA_LABS"), MAR_31_2024)
        ];

        // Test stream id matches `addr` and `fin`
        VestAbstract vest = VestAbstract(addr.addr("MCD_VEST_DAI")); // or "MCD_VEST_DAI_LEGACY"
        for (uint256 i = 0; i < yanks.length; i++) {
            assertEq(vest.usr(yanks[i].streamId), yanks[i].addr, "testYankDAI/unexpected-address");
            assertEq(vest.fin(yanks[i].streamId), yanks[i].finPlanned, "testYankDAI/unexpected-fin-date");
        }

        _vote(address(spell));
        _scheduleWaitAndCast(address(spell));
        assertTrue(spell.done(), "TestError/spell-not-done");
        for (uint256 i = 0; i < yanks.length; i++) {
            // Test stream.fin is set to the current block after the spell
            assertEq(vest.fin(yanks[i].streamId), block.timestamp, "testYankDAI/steam-not-yanked");
        }
    }

    function testYankMKR() public skipped { // add the `skipped` modifier to skip
        // Provide human-readable names for timestamps
        uint256 MAR_31_2024 = 1711929599;

        // For each yanked stream, provide Yank object with:
        //   the stream id
        //   the address of the stream
        //   the planned fin of the stream (via variable defined above)
        // Initialize the array with the corrent number of yanks
        Yank[1] memory yanks = [
            Yank(35, wallets.addr("BA_LABS"), MAR_31_2024)
        ];

        // Test stream id matches `addr` and `fin`
        VestAbstract vestTreasury = VestAbstract(addr.addr("MCD_VEST_MKR_TREASURY"));
        for (uint256 i = 0; i < yanks.length; i++) {
            assertEq(vestTreasury.usr(yanks[i].streamId), yanks[i].addr, "testYankMKR/unexpected-address");
            assertEq(vestTreasury.fin(yanks[i].streamId), yanks[i].finPlanned, "testYankMKR/unexpected-fin-date");
        }

        _vote(address(spell));
        _scheduleWaitAndCast(address(spell));
        assertTrue(spell.done(), "TestError/spell-not-done");
        for (uint256 i = 0; i < yanks.length; i++) {
            // Test stream.fin is set to the current block after the spell
            assertEq(vestTreasury.fin(yanks[i].streamId), block.timestamp, "testYankMKR/steam-not-yanked");

            // Give admin powers to test contract address and make the vesting unrestricted for testing
            GodMode.setWard(address(vestTreasury), address(this), 1);

            // Test vest can still be called, making stream "invalid" and not changing `fin` timestamp
            vestTreasury.unrestrict(yanks[i].streamId);
            vestTreasury.vest(yanks[i].streamId);
            assertTrue(!vestTreasury.valid(yanks[i].streamId));
            assertEq(vestTreasury.fin(yanks[i].streamId), block.timestamp, "testYankMKR/steam-fin-changed");
        }
    }

    function testVestMKR() public skipped { // add the `skipped` modifier to skip
        // Provide human-readable names for timestamps
        uint256 DEC_01_2023 = 1701385200;
        uint256 NOV_30_2024 = 1733007599;

        // For each new stream, provide Stream object
        // and initialize the array with the corrent number of new streams
        Stream[1] memory streams = [
            Stream({
                streamId:      44,
                wallet:        wallets.addr("ECOSYSTEM_FACILITATOR"),
                rewardAmount:  216 * WAD,
                start:         DEC_01_2023,
                cliff:         DEC_01_2023,
                end:           NOV_30_2024,
                durationDays:  366 days,
                manager:       address(0),
                isRestricted:  1,
                claimedAmount: 0
            })
        ];

        // Record previous values for the reference
        VestAbstract vest = VestAbstract(addr.addr("MCD_VEST_MKR_TREASURY"));
        uint256 prevStreamCount = vest.ids();
        uint256 prevAllowance = gov.allowance(pauseProxy, addr.addr("MCD_VEST_MKR_TREASURY"));

        _vote(address(spell));
        _scheduleWaitAndCast(address(spell));
        assertTrue(spell.done(), "TestError/spell-not-done");

        // Check allowance was increased according to the streams
        uint256 totalRewardAmount = 0;
        for (uint256 i = 0; i < streams.length; i++) {
            totalRewardAmount = totalRewardAmount + streams[i].rewardAmount;
        }
        assertEq(gov.allowance(pauseProxy, addr.addr("MCD_VEST_MKR_TREASURY")), prevAllowance + totalRewardAmount, "testVestMKR/invalid-allowance");

        // Check maximum vesting rate (Note: this should eventually be moved to _testGeneral)
        assertEq(vest.cap(), 2_220 * WAD / 365 days, "testVestMKR/invalid-cap");

        // Check that all streams added in this spell are tested
        assertEq(vest.ids(), prevStreamCount + streams.length, "testVestMKR/not-all-streams-tested");

        for (uint256 i = 0; i < streams.length; i++) {
            uint256 streamId = prevStreamCount + i + 1;

            // Check values of the each stream
            assertEq(streamId, streams[i].streamId, "testVestMKR/invalid-id");
            assertEq(vest.usr(streamId), streams[i].wallet, "testVestMKR/invalid-address");
            assertEq(vest.tot(streamId), streams[i].rewardAmount, "testVestMKR/invalid-total");
            assertEq(vest.bgn(streamId), streams[i].start, "testVestMKR/invalid-bgn");
            assertEq(vest.clf(streamId), streams[i].cliff, "testVestMKR/invalid-clif");
            assertEq(vest.fin(streamId), streams[i].start + streams[i].durationDays - 1, "testVestMKR/invalid-calculated-fin");
            assertEq(vest.fin(streamId), streams[i].end, "testVestMKR/invalid-fin-variable");
            assertEq(vest.mgr(streamId), streams[i].manager, "testVestMKR/invalid-manager");
            assertEq(vest.res(streamId), streams[i].isRestricted, "testVestMKR/invalid-res");
            assertEq(vest.rxd(streamId), streams[i].claimedAmount, "testVestMKR/invalid-rxd");

            // Check each new stream is payable in the future
            uint256 prevWalletBalance = gov.balanceOf(streams[i].wallet);
            GodMode.setWard(address(vest), address(this), 1);
            vest.unrestrict(streamId);
            vm.warp(streams[i].end);
            vest.vest(streamId);
            assertEq(gov.balanceOf(streams[i].wallet), prevWalletBalance + streams[i].rewardAmount, "testVestMKR/invalid-received-amount");
        }
    }

    function testMKRPayments() public skipped { // add the `skipped` modifier to skip
        // For each payment, create a Payee object with
        //    the Payee address,
        //    the amount to be paid
        // Initialize the array with the number of payees
        Payee[6] memory payees = [
            Payee(wallets.addr("BLUE"), 13.75 ether), // Note: ether is a keyword helper, only MKR is transferred here
            Payee(wallets.addr("CLOAKY"), 12.00 ether), // Note: ether is a keyword helper, only MKR is transferred here
            Payee(wallets.addr("BYTERON"), 1.25 ether), // Note: ether is a keyword helper, only MKR is transferred here
            Payee(wallets.addr("JULIACHANG"), 1.25 ether), // Note: ether is a keyword helper, only MKR is transferred here
            Payee(wallets.addr("ROCKY"), 1.13 ether), // Note: ether is a keyword helper, only MKR is transferred here
            Payee(wallets.addr("PBG"), 1.00 ether) // Note: ether is a keyword helper, only MKR is transferred here
        ];
        // Fill the value below with the value from exec doc
        uint256 expectedSumPayments = 30.38 ether; // Note: ether is a keyword helper, only MKR is transferred here

        // Calculate and save previous balances
        uint256 totalAmountToTransfer = 0; // Increment in the loop below
        uint256[] memory prevBalances = new uint256[](payees.length);
        uint256 prevMkrBalance       = gov.balanceOf(address(pauseProxy));
        for (uint256 i = 0; i < payees.length; i++) {
            totalAmountToTransfer += payees[i].amount;
            prevBalances[i] = gov.balanceOf(payees[i].addr);
        }

        // Cast the spell
        _vote(address(spell));
        _scheduleWaitAndCast(address(spell));
        assertTrue(spell.done(), "TestError/spell-not-done");

        // Check that pause proxy balance has decreased
        assertEq(gov.balanceOf(address(pauseProxy)), prevMkrBalance - totalAmountToTransfer, "testMKRPayments/invalid-total");
        assertEq(gov.balanceOf(address(pauseProxy)), prevMkrBalance - expectedSumPayments, "testMKRPayments/invalid-sum");

        // Check that payees received their payments
        for (uint256 i = 0; i < payees.length; i++) {
            assertEq(gov.balanceOf(payees[i].addr) - prevBalances[i], payees[i].amount, "testMKRPayments/invalid-balance");
        }
    }

    function _setupRootDomain() internal {
        vm.makePersistent(address(spell), address(spell.action()), address(addr));

        string memory root = string.concat(vm.projectRoot(), "/lib/dss-test");
        config = ScriptTools.readInput(root, "integration");

        rootDomain = new RootDomain(config, getRelativeChain("mainnet"));
    }

    function testL2OptimismSpell() public skipped { // TODO: check if this test can be removed for good.
        address l2TeleportGateway = BridgeLike(
            chainLog.getAddress("OPTIMISM_TELEPORT_BRIDGE")
        ).l2TeleportGateway();

        _setupRootDomain();

        optimismDomain = new OptimismDomain(config, getRelativeChain("optimism"), rootDomain);
        optimismDomain.selectFork();

        // Check that the L2 Optimism Spell is there and configured
        L2Spell optimismSpell = L2Spell(0x9495632F53Cc16324d2FcFCdD4EB59fb88dDab12);

        L2Gateway optimismGateway = L2Gateway(optimismSpell.gateway());
        assertEq(address(optimismGateway), l2TeleportGateway, "l2-optimism-wrong-gateway");

        bytes32 optDstDomain = optimismSpell.dstDomain();
        assertEq(optDstDomain, bytes32("ETH-MAIN-A"), "l2-optimism-wrong-dst-domain");

        // Validate pre-spell optimism state
        assertEq(optimismGateway.validDomains(optDstDomain), 1, "l2-optimism-invalid-dst-domain");
        // Cast the L1 Spell
        rootDomain.selectFork();

        _vote(address(spell));
        _scheduleWaitAndCast(address(spell));
        assertTrue(spell.done(), "TestError/spell-not-done");

        // switch to Optimism domain and relay the spell from L1
        // the `true` keeps us on Optimism rather than `rootDomain.selectFork()
        optimismDomain.relayFromHost(true);

        // Validate post-spell state
        assertEq(optimismGateway.validDomains(optDstDomain), 0, "l2-optimism-invalid-dst-domain");
    }

    function testL2ArbitrumSpell() public skipped { // TODO: check if this test can be removed for good.
        // Ensure the Arbitrum Gov Relay has some ETH to pay for the Arbitrum spell
        assertGt(chainLog.getAddress("ARBITRUM_GOV_RELAY").balance, 0);

        address l2TeleportGateway = BridgeLike(
            chainLog.getAddress("ARBITRUM_TELEPORT_BRIDGE")
        ).l2TeleportGateway();

        _setupRootDomain();

        arbitrumDomain = new ArbitrumDomain(config, getRelativeChain("arbitrum_one"), rootDomain);
        arbitrumDomain.selectFork();

        // Check that the L2 Arbitrum Spell is there and configured
        L2Spell arbitrumSpell = L2Spell(0x852CCBB823D73b3e35f68AD6b14e29B02360FD3d);

        L2Gateway arbitrumGateway = L2Gateway(arbitrumSpell.gateway());
        assertEq(address(arbitrumGateway), l2TeleportGateway, "l2-arbitrum-wrong-gateway");

        bytes32 arbDstDomain = arbitrumSpell.dstDomain();
        assertEq(arbDstDomain, bytes32("ETH-MAIN-A"), "l2-arbitrum-wrong-dst-domain");

        // Validate pre-spell arbitrum state
        assertEq(arbitrumGateway.validDomains(arbDstDomain), 1, "l2-arbitrum-invalid-dst-domain");

        // Cast the L1 Spell
        rootDomain.selectFork();

        _vote(address(spell));
        _scheduleWaitAndCast(address(spell));
        assertTrue(spell.done(), "TestError/spell-not-done");

        // switch to Arbitrum domain and relay the spell from L1
        // the `true` keeps us on Arbitrum rather than `rootDomain.selectFork()
        arbitrumDomain.relayFromHost(true);

        // Validate post-spell state
        assertEq(arbitrumGateway.validDomains(arbDstDomain), 0, "l2-arbitrum-invalid-dst-domain");
    }

    function testOffboardings() public skipped { // add the `skipped` modifier to skip
        uint256 Art;
        (Art,,,,) = vat.ilks("USDC-A");
        assertGt(Art, 0);
        (Art,,,,) = vat.ilks("PAXUSD-A");
        assertGt(Art, 0);
        (Art,,,,) = vat.ilks("GUSD-A");
        assertGt(Art, 0);

        _vote(address(spell));
        _scheduleWaitAndCast(address(spell));
        assertTrue(spell.done(), "TestError/spell-not-done");

        DssCdpManagerAbstract cdpManager = DssCdpManagerAbstract(addr.addr("CDP_MANAGER"));

        dog.bark("USDC-A", cdpManager.urns(14981), address(0));
        dog.bark("USDC-A", 0x936d9045E7407aBE8acdBaF34EAe4023B44cEfE2, address(0));
        dog.bark("USDC-A", cdpManager.urns(10791), address(0));
        dog.bark("USDC-A", cdpManager.urns(9529), address(0));
        dog.bark("USDC-A", cdpManager.urns(7062), address(0));
        dog.bark("USDC-A", cdpManager.urns(13008), address(0));
        dog.bark("USDC-A", cdpManager.urns(18152), address(0));
        dog.bark("USDC-A", cdpManager.urns(15504), address(0));
        dog.bark("USDC-A", cdpManager.urns(17116), address(0));
        dog.bark("USDC-A", cdpManager.urns(20087), address(0));
        dog.bark("USDC-A", cdpManager.urns(21551), address(0));
        dog.bark("USDC-A", cdpManager.urns(12964), address(0));
        dog.bark("USDC-A", cdpManager.urns(7361), address(0));
        dog.bark("USDC-A", cdpManager.urns(12588), address(0));
        dog.bark("USDC-A", cdpManager.urns(13641), address(0));
        dog.bark("USDC-A", cdpManager.urns(18786), address(0));
        dog.bark("USDC-A", cdpManager.urns(14676), address(0));
        dog.bark("USDC-A", cdpManager.urns(20189), address(0));
        dog.bark("USDC-A", cdpManager.urns(15149), address(0));
        dog.bark("USDC-A", cdpManager.urns(7976), address(0));
        dog.bark("USDC-A", cdpManager.urns(16639), address(0));
        dog.bark("USDC-A", cdpManager.urns(8724), address(0));
        dog.bark("USDC-A", cdpManager.urns(7170), address(0));
        dog.bark("USDC-A", cdpManager.urns(7337), address(0));
        dog.bark("USDC-A", cdpManager.urns(14142), address(0));
        dog.bark("USDC-A", cdpManager.urns(12753), address(0));
        dog.bark("USDC-A", cdpManager.urns(9579), address(0));
        dog.bark("USDC-A", cdpManager.urns(14628), address(0));
        dog.bark("USDC-A", cdpManager.urns(15288), address(0));
        dog.bark("USDC-A", cdpManager.urns(16139), address(0));
        dog.bark("USDC-A", cdpManager.urns(12287), address(0));
        dog.bark("USDC-A", cdpManager.urns(11908), address(0));
        dog.bark("USDC-A", cdpManager.urns(8829), address(0));
        dog.bark("USDC-A", cdpManager.urns(7925), address(0));
        dog.bark("USDC-A", cdpManager.urns(10430), address(0));
        dog.bark("USDC-A", cdpManager.urns(11122), address(0));
        dog.bark("USDC-A", cdpManager.urns(12663), address(0));
        dog.bark("USDC-A", cdpManager.urns(9027), address(0));
        dog.bark("USDC-A", cdpManager.urns(8006), address(0));
        dog.bark("USDC-A", cdpManager.urns(12693), address(0));
        dog.bark("USDC-A", cdpManager.urns(7079), address(0));
        dog.bark("USDC-A", cdpManager.urns(12220), address(0));
        dog.bark("USDC-A", cdpManager.urns(8636), address(0));
        dog.bark("USDC-A", cdpManager.urns(8643), address(0));
        dog.bark("USDC-A", cdpManager.urns(6992), address(0));
        dog.bark("USDC-A", cdpManager.urns(7083), address(0));
        dog.bark("USDC-A", cdpManager.urns(7102), address(0));
        dog.bark("USDC-A", cdpManager.urns(7124), address(0));
        dog.bark("USDC-A", cdpManager.urns(7328), address(0));
        dog.bark("USDC-A", cdpManager.urns(8053), address(0));
        dog.bark("USDC-A", cdpManager.urns(12246), address(0));
        dog.bark("USDC-A", cdpManager.urns(7829), address(0));
        dog.bark("USDC-A", cdpManager.urns(8486), address(0));
        dog.bark("USDC-A", cdpManager.urns(8677), address(0));
        dog.bark("USDC-A", cdpManager.urns(8700), address(0));
        dog.bark("USDC-A", cdpManager.urns(9139), address(0));
        dog.bark("USDC-A", cdpManager.urns(9240), address(0));
        dog.bark("USDC-A", cdpManager.urns(9250), address(0));
        dog.bark("USDC-A", cdpManager.urns(9144), address(0));
        dog.bark("USDC-A", cdpManager.urns(9568), address(0));
        dog.bark("USDC-A", cdpManager.urns(10773), address(0));
        dog.bark("USDC-A", cdpManager.urns(11404), address(0));
        dog.bark("USDC-A", cdpManager.urns(11609), address(0));
        dog.bark("USDC-A", cdpManager.urns(11856), address(0));
        dog.bark("USDC-A", cdpManager.urns(12355), address(0));
        dog.bark("USDC-A", cdpManager.urns(12778), address(0));
        dog.bark("USDC-A", cdpManager.urns(12632), address(0));
        dog.bark("USDC-A", cdpManager.urns(12747), address(0));
        dog.bark("USDC-A", cdpManager.urns(12679), address(0));

        dog.bark("PAXUSD-A", cdpManager.urns(14896), address(0));

        vm.store(
            address(dog),
            bytes32(uint256(keccak256(abi.encode(bytes32("GUSD-A"), uint256(1)))) + 2),
            bytes32(type(uint256).max)
        ); // Remove GUSD-A hole limit to reach the objective of the testing 0 debt after all barks
        dog.bark("GUSD-A", cdpManager.urns(24382), address(0));
        dog.bark("GUSD-A", cdpManager.urns(23939), address(0));
        dog.bark("GUSD-A", cdpManager.urns(25398), address(0));

        (Art,,,,) = vat.ilks("USDC-A");
        assertEq(Art, 0, "USDC-A Art is not 0");
        (Art,,,,) = vat.ilks("PAXUSD-A");
        assertEq(Art, 0, "PAXUSD-A Art is not 0");
        (Art,,,,) = vat.ilks("GUSD-A");
        assertEq(Art, 0, "GUSD-A Art is not 0");
    }

    function testDaoResolutions() public skipped { // add the `skipped` modifier to skip
        // For each resolution, add IPFS hash as item to the resolutions array
        // Initialize the array with the number of resolutions
        string[1] memory resolutions = [
            "QmaYKt61v6aCTNTYjuHm1Wjpe6JWBzCW2ZHR4XDEJhjm1R"
        ];

        string memory comma_separated_resolutions = "";
        for (uint256 i = 0; i < resolutions.length; i++) {
            comma_separated_resolutions = string.concat(comma_separated_resolutions, resolutions[i]);
            if (i + 1 < resolutions.length) {
                comma_separated_resolutions = string.concat(comma_separated_resolutions, ",");
            }
        }

        assertEq(SpellActionLike(spell.action()).dao_resolutions(), comma_separated_resolutions, "dao_resolutions/invalid-format");
    }

    // SPARK TESTS
    function testSparkSpellIsExecuted() public skipped { // add the `skipped` modifier to skip
        address SPARK_PROXY = addr.addr('SPARK_PROXY');
        address SPARK_SPELL = 0x85042d44894E08f81D70A2Ae568C09f907297dcb;

        vm.expectCall(
            SPARK_PROXY,
            /* value = */ 0,
            abi.encodeCall(
                ProxyLike(SPARK_PROXY).exec,
                (SPARK_SPELL, abi.encodeWithSignature("execute()"))
            )
        );

        _vote(address(spell));
        _scheduleWaitAndCast(address(spell));
        assertTrue(spell.done(), "TestError/spell-not-done");
    }

    // SPELL-SPECIFIC TESTS GO BELOW
    bytes32           constant  SRC_ILK       = "PSM-USDC-A";
    bytes32           constant  DST_ILK       = "LITE-PSM-USDC-A";
    PsmAbstract       immutable srcPsm        = PsmAbstract(      addr.addr("MCD_PSM_USDC_A"));
    LitePsmLike       immutable dstPsm        = LitePsmLike(      addr.addr("MCD_LITE_PSM_USDC_A"));
    address           immutable pocket        =                   addr.addr("MCD_LITE_PSM_USDC_A_POCKET");
    GemAbstract       immutable gem           = GemAbstract(      addr.addr("USDC"));
    CronSequencerLike immutable sequencer     = CronSequencerLike(addr.addr("CRON_SEQUENCER"));
    LitePsmJobLike    immutable litePsmJob    = LitePsmJobLike(  0x0C86162ba3E507592fC8282b07cF18c7F902C401);
    uint256           constant  srcKeep       = 200_000_000 * WAD;
    uint256           constant  srcTin        = 0.0001 ether;
    uint256           constant  srcTout       = 0.0001 ether;
    uint256           constant  srcMaxLine    = 2_500 * MILLION * RAD;
    uint256           constant  srcGap        = 200 * MILLION * RAD;
    uint256           constant  srcTtl        = 12 hours;
    uint256           constant  dstBuf        = 200 * MILLION * WAD;
    uint256           constant  dstMaxLine    = 7_500 * MILLION * RAD;
    uint256           constant  dstGap        = 200 * MILLION * RAD;
    uint256           constant  dstTtl        = 12 hours;
    uint256           constant  rushThreshold = 20_000_000 * WAD;
    uint256           constant  gushThreshold = 20_000_000 * WAD;
    uint256           constant  cutThreshold  = 300_000 * WAD;

    function testRwaConduitsPsmUpdate() public {
        address MCD_PSM_USDC_A                  = addr.addr("MCD_PSM_USDC_A");
        address MCD_LITE_PSM_USDC_A             = addr.addr("MCD_LITE_PSM_USDC_A");
        address RWA015_A_OUTPUT_CONDUIT         = addr.addr("RWA015_A_OUTPUT_CONDUIT");

        address[9] memory singleSwapConduits = [
            addr.addr("RWA014_A_INPUT_CONDUIT_URN"),
            addr.addr("RWA014_A_INPUT_CONDUIT_JAR"),
            addr.addr("RWA014_A_OUTPUT_CONDUIT"),
            addr.addr("RWA007_A_JAR_INPUT_CONDUIT"),
            addr.addr("RWA007_A_INPUT_CONDUIT"),
            addr.addr("RWA007_A_OUTPUT_CONDUIT"),
            addr.addr("RWA015_A_INPUT_CONDUIT_JAR_USDC"),
            addr.addr("RWA015_A_INPUT_CONDUIT_URN_USDC"),
            addr.addr("RWA009_A_INPUT_CONDUIT_URN_USDC")
        ];

        // ----- Pre-spell sanity checks -----
        // single swap conduits
        _testSingleSwapRwaConduits(singleSwapConduits, MCD_PSM_USDC_A);

        // multi swap conduit
        assertEq (RwaConduitLike(RWA015_A_OUTPUT_CONDUIT).pal(MCD_PSM_USDC_A), 1);
        assertEq (RwaConduitLike(RWA015_A_OUTPUT_CONDUIT).pal(MCD_LITE_PSM_USDC_A), 0);

        // ----- Execute spell -----
        _vote(address(spell));
        _scheduleWaitAndCast(address(spell));
        assertTrue(spell.done(), "TestError/spell-not-done");

        // ----- Post-spell state checks -----
        // single swap conduits
        _testSingleSwapRwaConduits(singleSwapConduits, MCD_LITE_PSM_USDC_A);

        // multi swap conduit
        assertEq (RwaConduitLike(RWA015_A_OUTPUT_CONDUIT).pal(MCD_PSM_USDC_A), 0);
        assertEq (RwaConduitLike(RWA015_A_OUTPUT_CONDUIT).pal(MCD_LITE_PSM_USDC_A), 1);
    }

    function _testSingleSwapRwaConduits(address[9] memory conduits, address psm) internal {
        for (uint256 i; i < conduits.length - 1; i++) {
            assertEq(
                RwaConduitLike(conduits[i]).psm(),
                psm
            );
        }
    }

    function test_LITE_PSM_USDC_A_MigrationPhase2() public {
        (uint256 psrcInk, uint256 psrcArt) = vat.urns(SRC_ILK, address(srcPsm));
        uint256 psrcVatGem = vat.gem(SRC_ILK, address(srcPsm));
        uint256 psrcGemBalance = gem.balanceOf(address(srcPsm.gemJoin()));
        (uint256 pdstInk, uint256 pdstArt) = vat.urns(DST_ILK, address(dstPsm));
        uint256 pdstVatGem = vat.gem(DST_ILK, address(dstPsm));
        uint256 pdstGemBalance = gem.balanceOf(address(pocket));

        uint256 expectedMoveWad = _min(psrcInk, _subcap(psrcInk, srcKeep));

        // ----- Pre-spell sanity checks -----
        {
            (uint256 psrcIlkArt,,, uint256 psrcLine,) = vat.ilks(SRC_ILK);
            assertGt(psrcIlkArt, 0, "before: src ilk Art is zero");
            assertGt(psrcLine,   0, "before: src line is zero");
            assertGt(psrcArt,    0, "before: src art is zero");
            assertGt(psrcInk,    0, "before: src ink is zero");
        }

        // ----- Execute spell -----
        _vote(address(spell));
        _scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        // ----- Post-spell state checks -----

        // Sanity checks
        assertEq(srcPsm.tin(), srcTin, "after: invalid src tin");
        assertEq(srcPsm.tout(), srcTout, "after: invalid src tout");
        assertEq(srcPsm.vow(), address(vow), "after: unexpected src vow update");

        assertEq(dstPsm.buf(),  dstBuf, "after: invalid dst buf");
        assertEq(dstPsm.vow(), address(vow), "after: unexpected dst vow update");

        // Old PSM state is set correctly
        {
            (uint256 srcInk, uint256 srcArt) = vat.urns(SRC_ILK, address(srcPsm));
            assertEq(srcInk, psrcInk - expectedMoveWad, "after: src ink is not decreased by the moved amount");
            assertEq(srcInk, srcKeep, "after: src ink is different from src keep");
            assertEq(srcArt, psrcArt - expectedMoveWad, "after: src art is not decreased by the moved amount");
            assertEq(vat.gem(SRC_ILK, address(srcPsm)), psrcVatGem, "after: unexpected src vat gem change");
            assertEq(
                _amtToWad(gem.balanceOf(address(srcPsm.gemJoin()))),
                _amtToWad(psrcGemBalance) - expectedMoveWad,
                "after: invalid gem balance for src pocket"
            );
        }

        // Old PSM is properly configured on AutoLine
        {
            (uint256 maxLine, uint256 gap, uint48 ttl, uint256 last,) = autoLine.ilks(SRC_ILK);
            assertEq(maxLine, srcMaxLine, "after: AutoLine invalid maxLine");
            assertEq(gap, srcGap, "after: AutoLine invalid gap");
            assertEq(ttl, srcTtl, "after: AutoLine invalid ttl");
            assertEq(last, block.number, "after: AutoLine invalid last");
        }

        // New PSM state is set correctly
        {
            // LitePSM ink is never modified
            (uint256 dstInk, uint256 dstArt) = vat.urns(DST_ILK, address(dstPsm));
            assertEq(dstInk, pdstInk, "after: unexpected dst ink chagne");
            // There might be extra `art` because of the calls to `fill`.
            assertGe(dstArt, pdstArt + expectedMoveWad, "after: dst art is not increased at least by the moved amount");
            assertEq(dai.balanceOf(address(dstPsm)), dstBuf, "after: invalid dst psm dai balance");
            assertEq(vat.gem(DST_ILK, address(dstPsm)), pdstVatGem, "after: unexpected dst vat gem change");
            assertEq(
                _amtToWad(gem.balanceOf(address(pocket))),
                _amtToWad(pdstGemBalance) + expectedMoveWad,
                "after: invalid gem balance for dst pocket"
            );
        }

        // New PSM is properly configured on AutoLine
        {
            (uint256 maxLine, uint256 gap, uint48 ttl, uint256 last, uint256 lastInc) = autoLine.ilks(DST_ILK);
            assertEq(maxLine, dstMaxLine, "after: AutoLine invalid maxLine");
            assertEq(gap, dstGap, "after: AutoLine invalid gap");
            assertEq(ttl, uint48(dstTtl), "after: AutoLine invalid ttl");
            assertEq(last, block.number, "after: AutoLine invalid last");
            assertEq(lastInc, block.timestamp, "after: AutoLine invalid lastInc");
        }
    }

    function test_CRON_LITE_PSM_JOB() public {
        // ----- Pre-spell sanity checks -----

        // Sequencer matches
        assertEq(litePsmJob.sequencer(),     address(sequencer), "invalid sequencer");
        // LitePsm matches
        assertEq(litePsmJob.litePsm(),       address(dstPsm),    "invalid litePsm");
        // fill: Set threshold at 15M DAI
        assertEq(litePsmJob.rushThreshold(), rushThreshold,      "invalid rush threshold");
        // trim: Set threshold at 30M DAI
        assertEq(litePsmJob.gushThreshold(), gushThreshold,      "invalid rush threshold");
        // chug: Set threshold at 300k DAI
        assertEq(litePsmJob.cutThreshold(),  cutThreshold,       "invalid rush threshold");

        // ----- Execute spell -----

        _vote(address(spell));
        _scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        // ----- Post-spell sanity checks -----

        assertTrue(sequencer.hasJob(address(litePsmJob)));

        // ----- E2E tests -----

        bytes32 master = sequencer.getMaster();

        // Base state
        {
            (bool ok, ) = litePsmJob.workable(master);
            assertFalse(ok, "invalid workable ok - no changes");

            vm.expectRevert();
            litePsmJob.work(master, abi.encodeWithSelector(dstPsm.fill.selector));

            vm.expectRevert();
            litePsmJob.work(master, abi.encodeWithSelector(dstPsm.trim.selector));

            vm.expectRevert();
            litePsmJob.work(master, abi.encodeWithSelector(dstPsm.chug.selector));
        }

        // Modify local `line` so it is not a limiting factor
        GodMode.setWard(address(vat), address(this), 1);
        vat.file(DST_ILK, "line", type(uint256).max);

        // Allow the test contract to swap with no fees
        GodMode.setWard(address(dstPsm), address(this), 1);
        dstPsm.kiss(address(this));

        // Approvals
        gem.approve(address(dstPsm), type(uint256).max);
        dai.approve(address(dstPsm), type(uint256).max);

        uint256 snapshot = vm.snapshot();

        // --- rushThreshold is breached ---
        {
            uint256 wadOut = rushThreshold; // Must be >= rushThreshold
            uint256 amtIn = _wadToAmt(wadOut);
            _giveTokens(address(gem), amtIn);
            dstPsm.sellGemNoFee(address(this), amtIn);

            assertGe(dstPsm.rush(), rushThreshold, "fill: invalid rush");

            (bool ok, bytes memory args) = litePsmJob.workable(master);
            assertTrue(ok, "fill: invalid workable ok");
            (bytes4 fn) = abi.decode(args, (bytes4));
            assertEq(fn, dstPsm.fill.selector, "fill: invalid data - expected fill.selector");

            litePsmJob.work(master, args);

            vm.revertTo(snapshot);
        }

        // --- rushThreshold is not breached ---
        {
            uint256 wadOut = rushThreshold / 2; // Must be < rushThreshold
            uint256 amtIn = _wadToAmt(wadOut);
            _giveTokens(address(gem), amtIn);
            dstPsm.sellGemNoFee(address(this), amtIn);

            assertGt(dstPsm.rush(), 0, "no fill: invalid rush");
            assertLt(dstPsm.rush(), rushThreshold, "no fill: invalid rush");

            (bool ok, bytes memory args) = litePsmJob.workable(master);
            assertFalse(ok, "no fill: invalid workable ok");
            assertEq(args, bytes("No work to do"), "no fill: invalid data");

            vm.expectRevert();
            litePsmJob.work(master, args);

            vm.revertTo(snapshot);
        }

        // --- gushThreshold is breached ---
        {
            // Before buying gems, we need to sell more gems into it to ensure the threshold will be met
            uint256 wadOut = gushThreshold; // Must be >= gushThreshold
            uint256 amtIn = _wadToAmt(wadOut);
            _giveTokens(address(gem), amtIn);
            // Selling gem is limited by `buf`, so we might need to split it into several parts
            uint256 wadAcc = 0;
            do {
                if (dstPsm.rush() > 0) dstPsm.fill();
                uint256 wadDelta = _min(dai.balanceOf(address(dstPsm)), wadOut - wadAcc);
                dstPsm.sellGemNoFee(address(this), _wadToAmt(wadDelta));
                wadAcc += wadDelta;
            } while (wadAcc < wadOut);

            // Buy the max amount of gems
            uint256 wadIn = _amtToWad(gem.balanceOf(pocket));
            _giveTokens(address(dai), wadIn);
            uint256 amtOut = _wadToAmt(wadIn);
            dstPsm.buyGemNoFee(address(this), amtOut);

            assertGe(dstPsm.gush(), gushThreshold, "trim: nvalid gush");

            (bool ok, bytes memory args) = litePsmJob.workable(master);
            assertTrue(ok, "trim: invalid workable ok");
            (bytes4 fn) = abi.decode(args, (bytes4));
            assertEq(fn, dstPsm.trim.selector, "trim: invalid data - expected trim.selector");

            litePsmJob.work(master, args);

            vm.revertTo(snapshot);
        }

        // --- gushThreshold is not breached ---
        {
            // Before buying gems, we need to sell more gems into it
            uint256 wadOut = _min(dai.balanceOf(address(dstPsm)), gushThreshold / 10); // Must be < gushThreshold
            uint256 amtIn = _wadToAmt(wadOut);
            _giveTokens(address(gem), amtIn);
            dstPsm.sellGemNoFee(address(this), amtIn);

            // Buy the max amount of gems within threshold
            uint256 wadIn = gushThreshold;
            _giveTokens(address(dai), wadIn);
            uint256 amtOut = _wadToAmt(wadIn);
            dstPsm.buyGemNoFee(address(this), amtOut);

            assertGt(dstPsm.gush(), 0, "no trim: invalid gush");
            assertLt(dstPsm.gush(), gushThreshold, "no trim: invalid gush");

            (bool ok, bytes memory args) = litePsmJob.workable(master);
            assertFalse(ok, "no trim: invalid workable ok - expected false");
            assertEq(args, bytes("No work to do"), "no trim: invalid data");

            vm.expectRevert();
            litePsmJob.work(master, args);

            vm.revertTo(snapshot);
        }

        // --- chugThreshold is breached ---
        {
            // Donating Dai has the same effect as accumulating swap fees
            uint256 wadDonation = cutThreshold; // Must be >= cutThreshold
            _giveTokens(address(dai), wadDonation);
            dai.transfer(address(dstPsm), wadDonation);

            assertGe(dstPsm.cut(), cutThreshold, "chug: invalid cut");

            (bool ok, bytes memory args) = litePsmJob.workable(master);
            assertTrue(ok, "chug: invalid workable ok");
            (bytes4 fn) = abi.decode(args, (bytes4));
            assertEq(fn, dstPsm.chug.selector, "chug: invalid data - expected chug.selector");

            litePsmJob.work(master, args);

            vm.revertTo(snapshot);
        }

        // --- chugThreshold is not breached ---
        {
            uint256 wadDonation = cutThreshold / 5; // Must be < cutThreshold
            _giveTokens(address(dai), wadDonation);
            dai.transfer(address(dstPsm), wadDonation);

            assertGt(dstPsm.cut(), 0, "no chug: invalid cut");
            assertLt(dstPsm.cut(), cutThreshold, "no chug: invalid cut");

            (bool ok, bytes memory args) = litePsmJob.workable(master);
            assertFalse(ok, "no chug: invalid workable ok");
            assertEq(args, bytes("No work to do"), "no chug: invalid data");

            vm.expectRevert();
            litePsmJob.work(master, args);

            vm.revertTo(snapshot);
        }
    }

    function _amtToWad(uint256 amt) internal view returns (uint256) {
        return amt * dstPsm.to18ConversionFactor();
    }

    function _wadToAmt(uint256 wad) internal view returns (uint256) {
        return wad / dstPsm.to18ConversionFactor();
    }

    function _min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    function _subcap(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? 0 : x - y;
    }
}
