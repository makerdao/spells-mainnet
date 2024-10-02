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

interface SequencerLike {
    function getMaster() external view returns (bytes32);
    function hasJob(address job) external view returns (bool);
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

    function testSplitter() public {
        _testSplitter();
    }

    function testSystemTokens() public {
        _testSystemTokens();
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
            0,   // tin
            0    // tout
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
                bufUnits: 400_000_000,
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
            "FLAPPER_MOM"
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

    function testVestDAI() public skipped { // add the `skipped` modifier to skip
        // Provide human-readable names for timestamps
        uint256 DEC_01_2023 = 1701385200;
        uint256 NOV_30_2024 = 1733007599;

        // For each new stream, provide Stream object
        // and initialize the array with the corrent number of new streams
        VestStream[] memory streams = new VestStream[](1);
        streams[0] = VestStream({
            id:  38,
            usr: wallets.addr("ECOSYSTEM_FACILITATOR"),
            bgn: DEC_01_2023,
            clf: DEC_01_2023,
            fin: NOV_30_2024,
            tau: 366 days,
            mgr: address(0),
            res: 1,
            tot: 504_000 * WAD,
            rxd: 0
        });

        _checkVestDai(streams);
    }

    function testVestMKR() public skipped { // add the `skipped` modifier to skip
        // Provide human-readable names for timestamps
        uint256 DEC_01_2023 = 1701385200;
        uint256 NOV_30_2024 = 1733007599;

        // For each new stream, provide Stream object
        // and initialize the array with the corrent number of new streams
        VestStream[] memory streams = new VestStream[](1);
        streams[0] = VestStream({
            id:  44,
            usr: wallets.addr("ECOSYSTEM_FACILITATOR"),
            bgn: DEC_01_2023,
            clf: DEC_01_2023,
            fin: NOV_30_2024,
            tau: 366 days,
            mgr: address(0),
            res: 1,
            tot: 216 * WAD,
            rxd: 0
        });

        _checkVestMkr(streams);
    }

    function testVestSKY() public skipped { // add the `skipped` modifier to skip
        // Provide human-readable names for timestamps
        // uint256 DEC_01_2023 = 1701385200;

        // For each new stream, provide Stream object
        // and initialize the array with the corrent number of new streams
        VestStream[] memory streams = new VestStream[](1);

        // This stream is configured in relative to the spell casting time.
        {
            uint256 before = vm.snapshot();
            _vote(address(spell));
            spell.schedule();
            vm.warp(spell.nextCastTime());

            streams[0] = VestStream({
                id:  1,
                usr: addr.addr("REWARDS_DIST_USDS_SKY"),
                bgn: block.timestamp - 7 days,
                clf: block.timestamp - 7 days,
                fin: block.timestamp - 7 days + 365 days - 1,
                tau: 365 days - 1,
                mgr: address(0),
                res: 1,
                tot: 600_000_000 * WAD,
                // Note: the accumulated vested amount is claimed during the spell (`REWARDS_DIST_USDS_SKY.distribute()`)
                rxd: 600_000_000 * WAD * 7 days / (365 days - 1)
            });

            vm.revertTo(before);
        }

        _checkVestSky(streams);
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

    struct Payee {
        address token;
        address addr;
        uint256 amount;
    }

    struct PaymentAmounts {
        uint256 dai;
        uint256 mkr;
        uint256 usds;
        uint256 sky;
    }

    function testPayments() public skipped { // add the `skipped` modifier to skip
        // For each payment, create a Payee object with:
        //    the address of the transferred token,
        //    the destination address,
        //    the amount to be paid
        // Initialize the array with the number of payees
        Payee[15] memory payees = [
            Payee(address(dai), wallets.addr("BLUE"), 54_167 * WAD),
            Payee(address(dai), wallets.addr("CLOAKY"), 20_417 * WAD),
            Payee(address(dai), wallets.addr("CLOAKY_KOHLA_2"), 10_000 * WAD),
            Payee(address(dai), wallets.addr("CLOAKY_ENNOIA"), 10_000 * WAD),
            Payee(address(dai), wallets.addr("JULIACHANG"), 8_333 * WAD),
            Payee(address(dai), wallets.addr("BYTERON"), 8_333 * WAD),
            Payee(address(dai), wallets.addr("ROCKY"), 8_065 * WAD),
            Payee(address(dai), wallets.addr("BONAPUBLICA"), 5_430 * WAD),
            Payee(address(mkr), wallets.addr("BLUE"), 13.75 ether), // Note: ether is only a keyword helper
            Payee(address(mkr), wallets.addr("CLOAKY"), 12.00 ether), // Note: ether is only a keyword helper
            Payee(address(mkr), wallets.addr("JULIACHANG"), 1.25 ether), // Note: ether is only a keyword helper
            Payee(address(mkr), wallets.addr("BYTERON"), 1.25 ether), // Note: ether is only a keyword helper
            Payee(address(mkr), wallets.addr("ROCKY"), 1.21 ether), // Note: ether is only a keyword helper
            Payee(address(usds), wallets.addr("LIQUIDITY_BOOTSTRAPPING"), 10_000_000 * WAD),
            Payee(address(sky), wallets.addr("LIQUIDITY_BOOTSTRAPPING"), 320_000_000 * WAD)
        ];
        // Fill the total values from exec sheet
        PaymentAmounts memory expectedTotalDiff = PaymentAmounts({
            dai: 124_745 * WAD,
            mkr: 29.46 ether, // Note: ether is only a keyword helper
            usds: 10_000_000 * WAD,
            sky: 320_000_000 * WAD
        });

        // Vote, schedule and warp, but not yet cast (to get correct surplus balance)
        _vote(address(spell));
        spell.schedule();
        vm.warp(spell.nextCastTime());
        pot.drip();

        // Calculate and save previous balances
        PaymentAmounts memory previousTotalBalance = PaymentAmounts({
            dai: vat.sin(address(vow)),
            mkr: mkr.balanceOf(address(pauseProxy)),
            usds: usds.balanceOf(address(pauseProxy)),
            sky: sky.balanceOf(address(pauseProxy))
        });
        PaymentAmounts memory calculatedTotalDiff;
        PaymentAmounts[] memory previousPayeeBalances = new PaymentAmounts[](payees.length);
        for (uint256 i = 0; i < payees.length; i++) {
            if (payees[i].token == address(dai)) {
                calculatedTotalDiff.dai += payees[i].amount;
            } else if (payees[i].token == address(mkr)) {
                calculatedTotalDiff.mkr += payees[i].amount;
            } else if (payees[i].token == address(usds)) {
                calculatedTotalDiff.usds += payees[i].amount;
            } else if (payees[i].token == address(sky)) {
                calculatedTotalDiff.sky += payees[i].amount;
            } else {
                revert('TestPayments/unexpected-payee-token');
            }
            previousPayeeBalances[i] = PaymentAmounts({
                dai: dai.balanceOf(payees[i].addr),
                mkr: mkr.balanceOf(payees[i].addr),
                usds: usds.balanceOf(payees[i].addr),
                sky: sky.balanceOf(payees[i].addr)
            });
        }

        // Cast spell
        spell.cast();
        assertTrue(spell.done(), "TestPayments/spell-not-done");

        // Check no other transfers were made
        PaymentAmounts memory actualBalanceDiff = PaymentAmounts({
            dai: vat.sin(address(vow)) - previousTotalBalance.dai, // We expect debt to increase
            mkr: previousTotalBalance.mkr - mkr.balanceOf(address(pauseProxy)),
            usds: previousTotalBalance.usds - usds.balanceOf(address(pauseProxy)),
            sky: sky.balanceOf(address(pauseProxy)) - previousTotalBalance.sky // We expect Sky balance to increase
        });
        assertEq(
            actualBalanceDiff.dai,
            (calculatedTotalDiff.dai + calculatedTotalDiff.usds) * RAY,
            "TestPayments/vat-sin-mismatch-calculated"
        );
        assertEq(
            actualBalanceDiff.dai,
            (expectedTotalDiff.dai + expectedTotalDiff.usds) * RAY,
            "TestPayments/vat-sin-mismatch-expected"
        );
        assertLe(
            actualBalanceDiff.mkr - (calculatedTotalDiff.mkr + calculatedTotalDiff.sky / afterSpell.sky_mkr_rate) - actualBalanceDiff.sky / afterSpell.sky_mkr_rate,
            1, // To account for rounding errors when converting Sky back to Mkr
            "TestPayments/invalid-total"
        );
        assertLe(
            actualBalanceDiff.mkr - (expectedTotalDiff.mkr + expectedTotalDiff.sky / afterSpell.sky_mkr_rate) - actualBalanceDiff.sky / afterSpell.sky_mkr_rate,
            1, // To account for rounding errors when converting Sky back to Mkr
            "TestPayments/invalid-total"
        );
        assertEq(actualBalanceDiff.usds, 0, "TestPayments/unexpected-usds-balance-change");

        // Check that payees received their payments
        for (uint256 i = 0; i < payees.length; i++) {
            if (payees[i].token == address(dai)) {
                assertEq(
                    dai.balanceOf(payees[i].addr),
                    previousPayeeBalances[i].dai + payees[i].amount,
                    "TestPayments/invalid-payee-dai-balance"
                );
            } else if (payees[i].token == address(mkr)) {
                assertEq(
                    mkr.balanceOf(payees[i].addr),
                    previousPayeeBalances[i].mkr + payees[i].amount,
                    "TestPayments/invalid-payee-mkr-balance"
                );
            } else if (payees[i].token == address(usds)) {
                assertEq(
                    usds.balanceOf(payees[i].addr),
                    previousPayeeBalances[i].usds + payees[i].amount,
                    "TestPayments/invalid-payee-usds-balance"
                );
            } else if (payees[i].token == address(sky)) {
                assertEq(
                    sky.balanceOf(payees[i].addr),
                    previousPayeeBalances[i].sky + payees[i].amount,
                    "TestPayments/invalid-payee-sky-balance"
                );
            } else {
                revert('TestPayments/unexpected-payee-token');
            }
        }
    }

    function testNewCronJobs() public skipped { // add the `skipped` modifier to skip
        SequencerLike seq = SequencerLike(addr.addr("CRON_SEQUENCER"));
        address[1] memory newJobs = [
            addr.addr("CRON_REWARDS_DIST_JOB")
        ];

        for (uint256 i = 0; i < newJobs.length; i++) {
            assertFalse(seq.hasJob(newJobs[i]), "TestError/cron-job-already-in-sequencer");
        }

        _vote(address(spell));
        _scheduleWaitAndCast(address(spell));
        assertTrue(spell.done(), "TestError/spell-not-done");

        for (uint256 i = 0; i < newJobs.length; i++) {
            assertTrue(seq.hasJob(newJobs[i]), "TestError/cron-job-not-added-to-sequencer");
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
        address SPARK_SPELL = 0xc80621140bEe6A105C180Ae7cb0a084c2409C738;

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
    uint256           constant  srcKeep       = 0;
    uint256           constant  dstWant       = type(uint256).max;
    uint256           constant  dstBuf        = 400 * MILLION * WAD;
    uint256           constant  dstMaxLine    = 10 * BILLION * RAD;
    uint256           constant  dstGap        = 400 * MILLION * RAD;
    uint256           constant  dstTtl        = 12 hours;

    uint256           constant  srcTin        = 0;
    uint256           constant  srcTout       = 0;

    function test_LITE_PSM_USDC_A_MigrationPhase3() public skipped {
        (uint256 psrcInk, uint256 psrcArt) = vat.urns(SRC_ILK, address(srcPsm));
        uint256 psrcVatGem = vat.gem(SRC_ILK, address(srcPsm));
        uint256 psrcGemBalance = gem.balanceOf(address(srcPsm.gemJoin()));
        (uint256 pdstInk, uint256 pdstArt) = vat.urns(DST_ILK, address(dstPsm));
        uint256 pdstVatGem = vat.gem(DST_ILK, address(dstPsm));
        uint256 pdstGemBalance = gem.balanceOf(address(pocket));
        uint256 pvice = vat.vice();
        uint256 ppauseSin = vat.sin(pauseProxy);

        uint256 expectedMoveWad = _min(dstWant, _subcap(psrcInk, srcKeep));

        // ----- Pre-spell sanity checks -----
        {
            (uint256 psrcIlkArt,,, uint256 psrcLine,) = vat.ilks(SRC_ILK);

            assertGt(psrcIlkArt,       0,                   "before: src ilk Art is zero");
            assertGt(psrcLine,         0,                   "before: src line is zero");
            assertGt(psrcArt,          0,                   "before: src art is zero");
            assertGt(psrcInk,          0,                   "before: src ink is zero");
            assertGt(srcPsm.tin(),     0,                   "before: src tin is zero");
            assertGt(srcPsm.tout(),    0,                   "before: src tout is zero");
            assertEq(dstPsm.buf(),     200 * MILLION * WAD, "before: dst buf does not match");
        }

        {
            (uint256 maxLine, uint256 gap, uint48 ttl,,) = autoLine.ilks(DST_ILK);
            assertEq(maxLine, 7_500 * MILLION * RAD, "before: dst maxLine does not match");
            assertEq(gap,     200 * MILLION * RAD,   "before: dst gap does not match");
            assertEq(ttl,     12 hours,              "before: dst ttl does not match");
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

        // No bad debt is left behind
        assertEq(vat.vice(), pvice, "vice mismatch");
        assertEq(vat.sin(pauseProxy), ppauseSin, "sin mismatch");

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
                "after: invalid gem balance for src gemJoin"
            );
        }
        // Old PSM line is set to 0
        {
            (,,, uint256 psrcLine,) = vat.ilks(SRC_ILK);
            assertEq(psrcLine, 0, "after: AutoLine invalid maxLine");
        }
        // Old PSM is removed from the AutoLine
        {
            (uint256 maxLine, uint256 gap, uint48 ttl, uint256 last,) = autoLine.ilks(SRC_ILK);
            assertEq(maxLine, 0, "after: AutoLine invalid maxLine");
            assertEq(gap,     0, "after: AutoLine invalid gap");
            assertEq(ttl,     0, "after: AutoLine invalid ttl");
            assertEq(last,    0, "after: AutoLine invalid last");
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

    function test_WBTC_A_LerpOffboarding() public {
        _checkIlkLerpOffboarding("WBTC-A", "WBTC-A Offboarding", 145, 150);
    }

    function test_WBTC_B_LerpOffboarding() public {
        _checkIlkLerpOffboarding("WBTC-B", "WBTC-B Offboarding", 130, 150);
    }
}
