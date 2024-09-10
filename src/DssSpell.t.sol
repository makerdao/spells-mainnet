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

import "forge-std/console2.sol";

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

interface UsdsPsmWrapperLike {
    function buyGem(address usr, uint256 gemAmt) external returns (uint256 usdsInWad);
    function dai() external view returns (address);
    function gem() external view returns (address);
    function ilk() external view returns (bytes32);
    function psm() external view returns (address);
    function sellGem(address usr, uint256 gemAmt) external returns (uint256 usdsOutWad);
    function usds() external view returns (address);
    function usdsJoin() external view returns (address);
}

interface PairLike {
    function balanceOf(address usr) external view returns (uint256);
    function totalSupply() external view returns (uint256);
}

interface VestedRewardsDistributionLike {
    function distribute() external returns (uint256 amount);
    function dssVest() external view returns (address);
    function lastDistributedAt() external view returns (uint256);
    function stakingRewards() external view returns (address);
    function vestId() external view returns (uint256);
}

interface StakingRewardsLike {
    function balanceOf(address account) external view returns (uint256);
    function getReward() external;
    function rewardsDistribution() external view returns (address);
    function rewardsToken() external view returns (address);
    function stake(uint256 amount) external;
    function stakingToken() external view returns (address);
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

    function testNextCastTime() public skipped {
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

    function testRemoveChainlogValues() public { // add the `skipped` modifier to skip
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

    function testVestSKY() public { // add the `skipped` modifier to skip
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
        address addr;
        uint256 amount;
    }

    function testDAIPayments() public skipped { // add the `skipped` modifier to skip
        // For each payment, create a Payee object with
        //    the Payee address,
        //    the amount to be paid in whole Dai units
        // Initialize the array with the number of payees
        Payee[1] memory payees = [
            Payee(wallets.addr("LAUNCH_PROJECT_FUNDING"), 9_535_993)
        ];

        uint256 expectedSumPayments = 9_535_993; // Fill the number with the value from exec doc.

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

    function testMKRPayments() public skipped { // add the `skipped` modifier to skip
        // For each payment, create a Payee object with
        //    the Payee address,
        //    the amount to be paid
        // Initialize the array with the number of payees
        Payee[1] memory payees = [
            Payee(wallets.addr("LAUNCH_PROJECT_FUNDING"), 2630.00 ether) // Note: ether is a keyword helper, only MKR is transferred here
        ];
        // Fill the value below with the value from exec doc
        uint256 expectedSumPayments = 2630.00 ether; // Note: ether is a keyword helper, only MKR is transferred here

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
        address SPARK_SPELL = 0x668C84584Ef8EeEd6BFb4FFB2a4Fa03231F8b241;

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

    uint256 constant MIN_ETA = 1726574400; // 2024-09-17T12:00:00Z

    function testNextCastTimeMinEta() public {
        {
            uint256 before = vm.snapshot();

            vm.warp(1606161600); // Nov 23, 20 UTC - could be any date far enough in the past
            _vote(address(spell));
            spell.schedule();

            assertEq(spell.nextCastTime(), MIN_ETA, "testNextCastTimeMinEta/min-eta-not-enforced");

            vm.revertTo(before);
        }

        {
            uint256 before = vm.snapshot();

            vm.warp(MIN_ETA); // As we move closer to MIN_ETA, GSM delay is still applicable
            _vote(address(spell));
            spell.schedule();

            assertEq(spell.nextCastTime(), MIN_ETA + pause.delay(), "testNextCastTimeMinEta/gsm-delay-not-enforced");

            vm.revertTo(before);
        }
    }

    function testUniV2PoolMigration() public {
        PairLike daiMkr  = PairLike(addr.addr("UNIV2DAIMKR"));
        PairLike usdsSky = PairLike(addr.addr("UNIV2USDSSKY"));

        uint256 pbalanceDaiMkr  = daiMkr.balanceOf(address(pauseProxy));
        uint256 pbalanceUsdsSky = usdsSky.balanceOf(address(pauseProxy));

        assertGt(pbalanceDaiMkr,  0, "before: testPoolMigration/invalid-dai-mkr-balance");
        assertEq(pbalanceUsdsSky, 0, "before: testPoolMigration/invalid-usds-sky-balance");

        uint256 pbalanceDai = dai.balanceOf(address(daiMkr)) * pbalanceDaiMkr / daiMkr.totalSupply();
        uint256 pbalanceMkr = gov.balanceOf(address(daiMkr)) * pbalanceDaiMkr / daiMkr.totalSupply();

        _vote(address(spell));
        _scheduleWaitAndCast(address(spell));
        assertTrue(spell.done(), "TestError/spell-not-done");

        uint256 balanceDaiMkr  = daiMkr.balanceOf(address(pauseProxy));
        uint256 balanceUsdsSky = usdsSky.balanceOf(address(pauseProxy));

        assertEq(balanceDaiMkr,  0,                             "after: testPoolMigration/invalid-dai-mkr-balance");
        // 10**3 == UniswapV2Pair MINIMUM_LIQUIDITY => https://github.com/Uniswap/v2-core/blob/ee547b17853e71ed4e0101ccfd52e70d5acded58/contracts/UniswapV2Pair.sol#L121
        assertEq(balanceUsdsSky, usdsSky.totalSupply() - 10**3, "after: testPoolMigration/invalid-usds-sky-balance");

        assertEq(usds.balanceOf(address(usdsSky)), pbalanceDai,          "after: testPoolMigration/invalid-usds-balance");
        assertEq(sky.balanceOf(address(usdsSky)),  pbalanceMkr * 24_000, "after: testPoolMigration/invalid-usds-balance");
    }

    function testUsdsSkyRewards() public {
        _vote(address(spell));
        _scheduleWaitAndCast(address(spell));
        assertTrue(spell.done(), "TestError/spell-not-done");

        StakingRewardsLike rewards = StakingRewardsLike(addr.addr("REWARDS_USDS_SKY"));
        VestedRewardsDistributionLike dist = VestedRewardsDistributionLike(addr.addr("REWARDS_DIST_USDS_SKY"));

        // Sanity checks
        assertEq(rewards.rewardsDistribution(), address(dist), "testUsdsSkyRewards/rewards-rewards-dist-mismatch");
        assertEq(rewards.stakingToken(),        address(usds), "testUsdsSkyRewards/rewards-staking-token-mismatch");
        assertEq(rewards.rewardsToken(),        address(sky),  "testUsdsSkyRewards/rewards-rewards-token-mismatch");

        assertTrue(vestSky.valid(dist.vestId()),               "testUsdsSkyRewards/invalid-dist-vest-id");

        assertEq(dist.dssVest(),           address(vestSky),   "testUsdsSkyRewards/dist-vest-mismatch");
        assertEq(dist.stakingRewards(),    address(rewards),   "testUsdsSkyRewards/dist-rewards-mismatch");
        assertEq(dist.lastDistributedAt(), block.timestamp,    "testUsdsSkyRewards/dist-distribute-not-called-in-spell");

        // Check if users can stake and get rewards
        {
            uint256 before = vm.snapshot();

            uint256 stakingWad = 100_000 * WAD;
            _giveTokens(address(usds), stakingWad);
            usds.approve(address(rewards), stakingWad);
            rewards.stake(stakingWad);
            assertEq(rewards.balanceOf(address(this)), stakingWad, "testUsdsSkyRewards/rewards-invalid-staked-balance");

            uint256 pbalance = sky.balanceOf(address(this));
            skip(7 days);
            rewards.getReward();
            assertGt(sky.balanceOf(address(this)), pbalance);

            vm.revertTo(before);
        }

        // Check if distribute can be called again in the future
        {
            uint256 before = vm.snapshot();

            uint256 pbalance = sky.balanceOf(address(rewards));
            skip(7 days);
            dist.distribute();
            assertGt(sky.balanceOf(address(rewards)), pbalance, "testUsdsSkyRewards/distribute-no-increase-balance");

            vm.revertTo(before);
        }
    }

    function testUsds01Rewards() public {
        _vote(address(spell));
        _scheduleWaitAndCast(address(spell));
        assertTrue(spell.done(), "TestError/spell-not-done");

        StakingRewardsLike rewards = StakingRewardsLike(addr.addr("REWARDS_USDS_01"));

        // Sanity checks
        assertEq(rewards.rewardsDistribution(), address(0),    "testUsds01Rewards/rewards-invalid-rewards-dist");
        assertEq(rewards.stakingToken(),        address(usds), "testUsds01Rewards/rewards-staking-token-mismatch");
        assertEq(rewards.rewardsToken(),        address(0),    "testUsds01Rewards/rewards-invalid-rewards-token");


        // Check if users can stake
        {
            uint256 before = vm.snapshot();

            uint256 stakingWad = 100_000 * WAD;
            _giveTokens(address(usds), stakingWad);
            usds.approve(address(rewards), stakingWad);
            rewards.stake(stakingWad);
            assertEq(rewards.balanceOf(address(this)), stakingWad, "testUsds01Rewards/rewards-invalid-staked-balance");

            vm.revertTo(before);
        }
    }

    function testUsdsPsmWrapper() public {
        _vote(address(spell));
        _scheduleWaitAndCast(address(spell));
        assertTrue(spell.done(), "TestError/spell-not-done");

        UsdsPsmWrapperLike wrapper = UsdsPsmWrapperLike(addr.addr("WRAPPER_USDS_LITE_PSM_USDC_A"));
        LitePsmLike litePsm = LitePsmLike(wrapper.psm());

        assertEq(address(litePsm),   addr.addr("MCD_LITE_PSM_USDC_A"), "testUsdsPsmWrapper/psm-mismatch");
        assertEq(wrapper.gem(),      litePsm.gem(),                    "testUsdsPsmWrapper/gem-mismatch");
        assertEq(wrapper.ilk(),      litePsm.ilk(),                    "testUsdsPsmWrapper/ilk-mismatch");
        assertEq(wrapper.dai(),      addr.addr("USDS"),                "testUsdsPsmWrapper/invalid-dai-alias-usds");
        assertEq(wrapper.usds(),     addr.addr("USDS"),                "testUsdsPsmWrapper/invalid-usds");
        assertEq(wrapper.usdsJoin(), addr.addr("USDS_JOIN"),           "testUsdsPsmWrapper/invalid-usds");

        // Arbitrary amount of TOKEN to test PSM sellGem and buyGem with (in whole units)
        // `amount` is the amount of _TOKEN_ we are selling/buying (NOT measured in USDS)
        uint256 amount = 100_000;
        // Amount should be more than 10,000 as `tin` and `tout` are basis point measurements
        require(amount >= 10_000, "checkLitePsmIlkIntegration/amount-too-low-for-precision-checks");

        GemAbstract token = GemAbstract(wrapper.gem());
        // Approvals
        token.approve(address(wrapper), type(uint256).max);
        usds.approve(address(wrapper), type(uint256).max);

        uint256 snapshot = vm.snapshot();

        // Sell TOKEN _to_ the PSM for USDS
        {
            uint256 sellWadOut  = amount * WAD;                     // Scale to USDS decimals (18) for USDS balance check
            sellWadOut         -= sellWadOut * litePsm.tin() / WAD; // Subtract `tin` fee (was deducted by PSM)

            uint256 sellAmt = amount * WAD / _to18ConversionFactor(litePsm);
            _giveTokens(address(token), sellAmt);
            wrapper.sellGem(address(this), sellAmt);

            assertEq(token.balanceOf(address(this)), 0,          "testUsdsPsmWrapper/invalid-sellGem-gem-balance");
            assertEq(usds.balanceOf(address(this)),  sellWadOut, "testUsdsPsmWrapper/sellGem-usds-balance");

            vm.revertTo(snapshot);
        }

        // Buy TOKEN _from_ the PSM for USDS
        {
            uint256 buyWadIn  = amount * WAD;                    // Scale to USDS decimals (18) for USDS balance check
            buyWadIn         += buyWadIn * litePsm.tout() / WAD; // Add `tout` fee (was included by PSM)

            uint256 buyAmt = amount * WAD / _to18ConversionFactor(litePsm);
            _giveTokens(address(usds), buyWadIn);
            wrapper.buyGem(address(this), buyAmt);

            assertEq(token.balanceOf(address(this)), buyAmt, "testUsdsPsmWrapper/invalid-buyGem-gem-balance");
            assertEq(usds.balanceOf(address(this)),  0,      "testUsdsPsmWrapper/buyGem-usds-balance");

            vm.revertTo(snapshot);
        }
    }
}
