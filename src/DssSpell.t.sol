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

interface WardsLike {
    function wards(address) external view returns (uint256);
}

interface SpellActionLike {
    function dao_resolutions() external view returns (string memory);
}

interface RwaLiquidationOracleLike {
    function ilks(bytes32) external view returns (string memory, address, uint48 toc, uint48 tau);
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

    function testFailWrongDay() public {
        _testFailWrongDay();
    }

    function testFailTooEarly() public {
        _testFailTooEarly();
    }

    function testFailTooLate() public {
        _testFailTooLate();
    }

    function testOnTime() public {
        _testOnTime();
    }

    function testCastCost() public {
        _testCastCost();
    }

    function testDeployCost() public {
        _testDeployCost();
    }

    function testContractSize() public {
        _testContractSize();
    }

    function testNextCastTime() public {
        _testNextCastTime();
    }

    function testFailNotScheduled() public view {
        _testFailNotScheduled();
    }

    function testUseEta() public {
        _testUseEta();
    }

    function testAuth() public {
        _checkAuth(false);
    }

    function testAuthInSources() public {
        _checkAuth(true);
    }

    function testBytecodeMatches() public {
        _testBytecodeMatches();
    }

    function testChainlogValues() public {
        _testChainlogValues();
    }

    function testChainlogVersionBump() public {
        _testChainlogVersionBump();
    }

    // Leave this test public (for now) as this is acting like a config test
    function testPSMs() public {
        _vote(address(spell));
        _scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

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

    // END OF TESTS THAT SHOULD BE RUN ON EVERY SPELL

    // TESTS BELOW CAN BE ENABLED/DISABLED ON DEMAND

    function testOsmAuth() private {  // make private to disable
        // address ORACLE_WALLET01 = 0x4D6fbF888c374D7964D56144dE0C0cFBd49750D3;

        // validate the spell does what we told it to
        //bytes32[] memory ilks = reg.list();

        //for(uint256 i = 0; i < ilks.length; i++) {
        //    uint256 class = reg.class(ilks[i]);
        //    if (class != 1) { continue; }

        //    address pip = reg.pip(ilks[i]);
        //    // skip USDC, TUSD, PAXUSD, GUSD
        //    if (pip == 0x838212865E2c2f4F7226fCc0A3EFc3EB139eC661 ||
        //        pip == 0x0ce19eA2C568890e63083652f205554C927a0caa ||
        //        pip == 0xdF8474337c9D3f66C0b71d31C7D3596E4F517457 ||
        //        pip == 0x57A00620Ba1f5f81F20565ce72df4Ad695B389d7) {
        //        continue;
        //    }

        //    assertEq(OsmAbstract(pip).wards(ORACLE_WALLET01), 0);
        //}

        //_vote(address(spell));
        //_scheduleWaitAndCast(address(spell));
        //assertTrue(spell.done());

        //for(uint256 i = 0; i < ilks.length; i++) {
        //    uint256 class = reg.class(ilks[i]);
        //    if (class != 1) { continue; }

        //    address pip = reg.pip(ilks[i]);
        //    // skip USDC, TUSD, PAXUSD, GUSD
        //    if (pip == 0x838212865E2c2f4F7226fCc0A3EFc3EB139eC661 ||
        //        pip == 0x0ce19eA2C568890e63083652f205554C927a0caa ||
        //        pip == 0xdF8474337c9D3f66C0b71d31C7D3596E4F517457 ||
        //        pip == 0x57A00620Ba1f5f81F20565ce72df4Ad695B389d7) {
        //        continue;
        //    }

        //    assertEq(OsmAbstract(pip).wards(ORACLE_WALLET01), 1);
        //}
    }

    function testOracleList() private {  // make private to disable
        // address ORACLE_WALLET01 = 0x4D6fbF888c374D7964D56144dE0C0cFBd49750D3;

        //assertEq(OsmAbstract(0xF15993A5C5BE496b8e1c9657Fd2233b579Cd3Bc6).wards(ORACLE_WALLET01), 0);

        //_vote(address(spell));
        //_scheduleWaitAndCast(address(spell));
        //assertTrue(spell.done());

        //assertEq(OsmAbstract(0xF15993A5C5BE496b8e1c9657Fd2233b579Cd3Bc6).wards(ORACLE_WALLET01), 1);
    }

    function testRemoveChainlogValues() private { // make private to disable
        _vote(address(spell));
        _scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        try chainLog.getAddress("MCD_CAT") {
            assertTrue(false);
        } catch Error(string memory errmsg) {
            assertTrue(_cmpStr(errmsg, "dss-chain-log/invalid-key"));
        } catch {
            assertTrue(false);
        }
    }

    function testCollateralIntegrations() private { // make private to disable
        _vote(address(spell));
        _scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

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

    function testIlkClipper() private { // make public to enable
        _castPreviousSpell();
        _vote(address(spell));
        _scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        // _checkIlkClipper(
        //     "LINK-A",
        //     GemJoinAbstract(addr.addr("MCD_JOIN_LINK_A")),
        //     ClipAbstract(addr.addr("MCD_CLIP_LINK_A")),
        //     addr.addr("MCD_CLIP_CALC_LINK_A"),
        //     OsmAbstract(addr.addr("PIP_LINK")),
        //     1_000_000 * WAD
        // );

        // _checkIlkClipper(
        //     "MATIC-A",
        //     GemJoinAbstract(addr.addr("MCD_JOIN_MATIC_A")),
        //     ClipAbstract(addr.addr("MCD_CLIP_MATIC_A")),
        //     addr.addr("MCD_CLIP_CALC_MATIC_A"),
        //     OsmAbstract(addr.addr("PIP_MATIC")),
        //     10_000_000 * WAD
        // );

        // _checkIlkClipper(
        //     "YFI-A",
        //     GemJoinAbstract(addr.addr("MCD_JOIN_YFI_A")),
        //     ClipAbstract(addr.addr("MCD_CLIP_YFI_A")),
        //     addr.addr("MCD_CLIP_CALC_YFI_A"),
        //     OsmAbstract(addr.addr("PIP_YFI")),
        //     1_000 * WAD
        // );

        // _checkIlkClipper(
        //     "UNIV2USDCETH-A",
        //     GemJoinAbstract(addr.addr("MCD_JOIN_UNIV2USDCETH_A")),
        //     ClipAbstract(addr.addr("MCD_CLIP_UNIV2USDCETH_A")),
        //     addr.addr("MCD_CLIP_CALC_UNIV2USDCETH_A"),
        //     OsmAbstract(addr.addr("PIP_UNIV2USDCETH")),
        //     1 * WAD
        // );
    }

    function testLerpSurplusBuffer() private { // make private to disable
        _vote(address(spell));
        _scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

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

    function testNewChainlogValues() private { // make private to disable

        _vote(address(spell));
        _scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        // _checkChainlogKey("MCD_PSM_GUSD_A_JAR");
        // _checkChainlogKey("MCD_PSM_GUSD_A_INPUT_CONDUIT_JAR");
        // _checkChainlogKey("MCD_PSM_PAX_A_JAR");
        // _checkChainlogKey("MCD_PSM_PAX_A_INPUT_CONDUIT_JAR");
        // _checkChainlogVersion("1.17.1");
    }

    function testNewIlkRegistryValues() private { // make private to disable
        _vote(address(spell));
        _scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

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

    function testOSMs() private { // make private to disable
        address READER = address(0);

        // Track OSM authorizations here
        assertEq(OsmAbstract(addr.addr("PIP_TOKEN")).bud(READER), 0);

        _vote(address(spell));
        _scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        assertEq(OsmAbstract(addr.addr("PIP_TOKEN")).bud(READER), 1);
    }

    function testMedianizers() private { // make private to disable
        _vote(address(spell));
        _scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        // Track Median authorizations here
        address SET_TOKEN    = address(0);
        address TOKENUSD_MED = OsmAbstract(addr.addr("PIP_TOKEN")).src();
        assertEq(MedianAbstract(TOKENUSD_MED).bud(SET_TOKEN), 1);
    }

    function testVestDAI() public {
        assertEq(DAI_STREAMS_COUNT, daiStreams.length, "testVestDAI/invalid-streams-count");
        _skipTest(DAI_STREAMS_COUNT == 0); // skip if there are no streams

        // Record previous values for the reference
        VestAbstract vest = VestAbstract(addr.addr("MCD_VEST_DAI"));
        uint256 prevStreamCount = vest.ids();

        _vote(address(spell));
        _scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        // Check maximum vesting rate (Note: this should eventually be moved to _testGeneral)
        assertEq(vest.cap(), 1 * MILLION * WAD / 30 days, "testVestDAI/invalid-cap");

        // Check that all streams added in this spell are tested
        assertEq(vest.ids(), prevStreamCount + DAI_STREAMS_COUNT, "testVestDAI/not-all-streams-tested");

        for (uint256 i = 0; i < DAI_STREAMS_COUNT; i++) {
            uint256 streamId = prevStreamCount + i + 1;
            address wallet = wallets.addr(daiStreams[i].wallet);

            // Check values of the each stream
            assertEq(streamId, daiStreams[i].streamId, "testVestDAI/invalid-id");
            assertEq(vest.usr(streamId), wallet, "testVestDAI/invalid-address");
            assertEq(vest.tot(streamId), daiStreams[i].rewardAmount * WAD, "testVestDAI/invalid-total");
            assertEq(vest.bgn(streamId), daiStreams[i].start, "testVestDAI/invalid-bgn");
            assertEq(vest.clf(streamId), daiStreams[i].cliff, "testVestDAI/invalid-clif");
            assertEq(vest.fin(streamId), daiStreams[i].start + daiStreams[i].durationDays - 1, "testVestDAI/invalid-calculated-fin");
            assertEq(vest.fin(streamId), daiStreams[i].end, "testVestDAI/invalid-fin-variable");
            assertEq(vest.mgr(streamId), daiStreams[i].manager, "testVestDAI/invalid-manager");
            assertEq(vest.res(streamId), daiStreams[i].isRestricted, "testVestDAI/invalid-res");
            assertEq(vest.rxd(streamId), daiStreams[i].claimedAmount, "testVestDAI/invalid-rxd");

            // Check each new stream is payable in the future
            uint256 prevWalletBalance = dai.balanceOf(wallet);
            GodMode.setWard(address(vest), address(this), 1);
            vest.unrestrict(streamId);
            vm.warp(daiStreams[i].end);
            vest.vest(streamId);
            assertEq(dai.balanceOf(wallet), prevWalletBalance + daiStreams[i].rewardAmount * WAD, "testVestDAI/invalid-received-amount");
        }
    }

    function testDAIPayments() public {
        assertEq(DAI_PAYEES_COUNT, daiPayees.length, "testDAIPayments/invalid-payees-count");
        _skipTest(DAI_PAYEES_COUNT == 0); // skip if there are no payments

        uint256 prevBalance;
        uint256 totAmount;
        uint256[] memory prevAmounts = new uint256[](DAI_PAYEES_COUNT);

        for (uint256 i = 0; i < DAI_PAYEES_COUNT; i++) {
            totAmount += daiPayees[i].amount;
            prevAmounts[i] = dai.balanceOf(wallets.addr(daiPayees[i].wallet));
            prevBalance += prevAmounts[i];
        }

        _vote(address(spell));
        spell.schedule();
        vm.warp(spell.nextCastTime());
        pot.drip();
        uint256 prevSin = vat.sin(address(vow));
        spell.cast();
        assertTrue(spell.done());

        assertEq(vat.sin(address(vow)) - prevSin, totAmount * RAD, "testPayments/vat-sin-mismatch");
        assertEq(vat.sin(address(vow)) - prevSin, DAI_SUM_PAYMENTS * RAD, "testPaymentsSum/vat-sin-mismatch");

        for (uint256 i = 0; i < DAI_PAYEES_COUNT; i++) {
            assertEq(
                dai.balanceOf(wallets.addr(daiPayees[i].wallet)) - prevAmounts[i],
                daiPayees[i].amount * WAD
            );
        }
    }

    function testYankDAI() public {
        assertEq(DAI_YANKS_COUNT, daiYanks.length, "testYankDAI/invalid-yanks-count");
        _skipTest(DAI_YANKS_COUNT == 0); // skip if there are no yanks

        // Test stream id matches `addr` and `fin`
        VestAbstract vest = VestAbstract(addr.addr("MCD_VEST_DAI")); // or "MCD_VEST_DAI_LEGACY"
        for (uint256 i = 0; i < DAI_YANKS_COUNT; i++) {
            assertEq(vest.usr(daiYanks[i].streamId), wallets.addr(daiYanks[i].wallet), "testYankDAI/unexpected-address");
            assertEq(vest.fin(daiYanks[i].streamId), daiYanks[i].finPlanned, "testYankDAI/unexpected-fin-date");
        }

        _vote(address(spell));
        _scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());
        for (uint256 i = 0; i < DAI_YANKS_COUNT; i++) {
            // Test stream.fin is set to the current block after the spell
            assertEq(vest.fin(daiYanks[i].streamId), block.timestamp, "testYankDAI/steam-not-yanked");
        }
    }

    function testYankMKR() public {
        assertEq(MKR_YANKS_COUNT, mkrYanks.length, "testYankMKR/invalid-yanks-count");
        _skipTest(MKR_YANKS_COUNT == 0); // skip if there are no yanks

        // Test stream id matches `addr` and `fin`
        VestAbstract vestTreasury = VestAbstract(addr.addr("MCD_VEST_MKR_TREASURY"));
        for (uint256 i = 0; i < MKR_YANKS_COUNT; i++) {
            assertEq(vestTreasury.usr(mkrYanks[i].streamId), wallets.addr(mkrYanks[i].wallet), "testYankDAI/unexpected-address");
            assertEq(vestTreasury.fin(mkrYanks[i].streamId), mkrYanks[i].finPlanned, "testYankDAI/unexpected-fin-date");
        }

        _vote(address(spell));
        _scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());
        for (uint256 i = 0; i < MKR_YANKS_COUNT; i++) {
            // Test stream.fin is set to the current block after the spell
            assertEq(vestTreasury.fin(mkrYanks[i].streamId), block.timestamp, "testYankDAI/steam-not-yanked");

            // Give admin powers to test contract address and make the vesting unrestricted for testing
            GodMode.setWard(address(vestTreasury), address(this), 1);

            // Test vest can still be called, making stream "invalid" and not changing `fin` timestamp
            vestTreasury.unrestrict(mkrYanks[i].streamId);
            vestTreasury.vest(mkrYanks[i].streamId);
            assertTrue(!vestTreasury.valid(mkrYanks[i].streamId));
            assertEq(vestTreasury.fin(mkrYanks[i].streamId), block.timestamp, "testYankDAI/steam-fin-changed");
        }
    }

    function testVestMKR() public {
        assertEq(MKR_STREAMS_COUNT, mkrStreams.length, "testVestMKR/invalid-streams-count");
        _skipTest(MKR_STREAMS_COUNT == 0); // skip if there are no streams

        // Record previous values for the reference
        VestAbstract vest = VestAbstract(addr.addr("MCD_VEST_MKR_TREASURY"));
        uint256 prevStreamCount = vest.ids();
        uint256 prevAllowance = gov.allowance(pauseProxy, addr.addr("MCD_VEST_MKR_TREASURY"));

        _vote(address(spell));
        _scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        // Check allowance was increased according to the streams
        uint256 totalRewardAmount = 0;
        for (uint256 i = 0; i < MKR_STREAMS_COUNT; i++) {
            totalRewardAmount = totalRewardAmount + mkrStreams[i].rewardAmount * WAD;
        }
        assertEq(gov.allowance(pauseProxy, addr.addr("MCD_VEST_MKR_TREASURY")), prevAllowance + totalRewardAmount, "testVestMKR/invalid-allowance");

        // Check maximum vesting rate (Note: this should eventually be moved to _testGeneral)
        assertEq(vest.cap(), 2_220 * WAD / 365 days, "testVestMKR/invalid-cap");

        // Check that all streams added in this spell are tested
        assertEq(vest.ids(), prevStreamCount + MKR_STREAMS_COUNT, "testVestMKR/not-all-streams-tested");

        for (uint256 i = 0; i < MKR_STREAMS_COUNT; i++) {
            uint256 streamId = prevStreamCount + i + 1;
            address wallet = wallets.addr(mkrStreams[i].wallet);

            // Check values of the each stream
            assertEq(streamId, mkrStreams[i].streamId, "testVestMKR/invalid-id");
            assertEq(vest.usr(streamId), wallet, "testVestMKR/invalid-address");
            assertEq(vest.tot(streamId), mkrStreams[i].rewardAmount * WAD, "testVestMKR/invalid-total");
            assertEq(vest.bgn(streamId), mkrStreams[i].start, "testVestMKR/invalid-bgn");
            assertEq(vest.clf(streamId), mkrStreams[i].cliff, "testVestMKR/invalid-clif");
            assertEq(vest.fin(streamId), mkrStreams[i].start + mkrStreams[i].durationDays - 1, "testVestMKR/invalid-calculated-fin");
            assertEq(vest.fin(streamId), mkrStreams[i].end, "testVestMKR/invalid-fin-variable");
            assertEq(vest.mgr(streamId), mkrStreams[i].manager, "testVestMKR/invalid-manager");
            assertEq(vest.res(streamId), mkrStreams[i].isRestricted, "testVestMKR/invalid-res");
            assertEq(vest.rxd(streamId), mkrStreams[i].claimedAmount, "testVestMKR/invalid-rxd");

            // Check each new stream is payable in the future
            uint256 prevWalletBalance = gov.balanceOf(wallet);
            GodMode.setWard(address(vest), address(this), 1);
            vest.unrestrict(streamId);
            vm.warp(mkrStreams[i].end);
            vest.vest(streamId);
            assertEq(gov.balanceOf(wallet), prevWalletBalance + mkrStreams[i].rewardAmount * WAD, "testVestMKR/invalid-received-amount");
        }
    }

    function testMKRPayments() public {
        assertEq(MKR_PAYEES_COUNT, mkrPayees.length, "testMKRPayments/invalid-payees-count");
        _skipTest(MKR_PAYEES_COUNT == 0); // skip if there are no payments

        // Calculate and save previous balances
        uint256 totalAmountToTransfer = 0; // Increment in the loop below
        uint256[] memory prevBalances = new uint256[](MKR_PAYEES_COUNT);
        uint256 prevMkrBalance       = gov.balanceOf(address(pauseProxy));
        for (uint256 i = 0; i < MKR_PAYEES_COUNT; i++) {
            totalAmountToTransfer += mkrPayees[i].amount;
            prevBalances[i] = gov.balanceOf(wallets.addr(mkrPayees[i].wallet));
        }

        // Cast the spell
        _vote(address(spell));
        _scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        // Check that pause proxy balance has decreased
        assertEq(gov.balanceOf(address(pauseProxy)), prevMkrBalance - totalAmountToTransfer);
        assertEq(gov.balanceOf(address(pauseProxy)), prevMkrBalance - MKR_SUM_PAYMENTS * WAD);

        // Check that payees received their payments
        for (uint256 i = 0; i < MKR_PAYEES_COUNT; i++) {
            assertEq(gov.balanceOf(wallets.addr(mkrPayees[i].wallet)) - prevBalances[i], mkrPayees[i].amount * WAD);
        }
    }

    function _setupRootDomain() internal {
        vm.makePersistent(address(spell), address(spell.action()), address(addr));

        string memory root = string.concat(vm.projectRoot(), "/lib/dss-test");
        config = ScriptTools.readInput(root, "integration");

        rootDomain = new RootDomain(config, getRelativeChain("mainnet"));
    }

    function testL2OptimismSpell() private {
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
        assertTrue(spell.done());

        // switch to Optimism domain and relay the spell from L1
        // the `true` keeps us on Optimism rather than `rootDomain.selectFork()
        optimismDomain.relayFromHost(true);

        // Validate post-spell state
        assertEq(optimismGateway.validDomains(optDstDomain), 0, "l2-optimism-invalid-dst-domain");
    }

    function testL2ArbitrumSpell() private {
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
        assertTrue(spell.done());

        // switch to Arbitrum domain and relay the spell from L1
        // the `true` keeps us on Arbitrum rather than `rootDomain.selectFork()
        arbitrumDomain.relayFromHost(true);

        // Validate post-spell state
        assertEq(arbitrumGateway.validDomains(arbDstDomain), 0, "l2-arbitrum-invalid-dst-domain");
    }

    function testOffboardings() private {
        uint256 Art;
        (Art,,,,) = vat.ilks("USDC-A");
        assertGt(Art, 0);
        (Art,,,,) = vat.ilks("PAXUSD-A");
        assertGt(Art, 0);
        (Art,,,,) = vat.ilks("GUSD-A");
        assertGt(Art, 0);

        _vote(address(spell));
        _scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

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

    function testDaoResolutions() public { // make private to disable
        // For each resolution, add IPFS hash as item to the resolutions array
        // Initialize the array with the number of resolutions
        string[1] memory resolutions = [
            "QmPiEHtt8rkVtSibBXMrhEzHUmSriXWz4AL2bjscq8dUvU"
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

    function testSparkSpellIsExecuted() public { // make private to disable
        address SUBPROXY_SPARK = 0x3300f198988e4C9C63F75dF86De36421f06af8c4;
        address SPARK_SPELL    = address(0x68a075249fA77173b8d1B92750c9920423997e2B);

        vm.expectCall(
            SUBPROXY_SPARK,
            /* value = */ 0,
            abi.encodeCall(
                ProxyLike(SUBPROXY_SPARK).exec,
                (SPARK_SPELL, abi.encodeWithSignature("execute()"))
            )
        );

        _vote(address(spell));
        _scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());
    }

    // SPELL-SPECIFIC TESTS GO BELOW

    // RWA tests
    RwaLiquidationOracleLike oracle = RwaLiquidationOracleLike(addr.addr("MIP21_LIQUIDATION_ORACLE"));
    function testRWApriceBump() public {
        _vote(address(spell));
        _scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        // Get the oracle address
        (,address pip,,  ) = oracle.ilks("RWA014-A");
        assertEq(uint256(DSValueAbstract(pip).read()), 1_500_000_000 * WAD, "RWA014: Bad pip value after bump()");

        // Get collateral's parameters
        (,, uint256 spot,,) = vat.ilks("RWA014-A");
        assertEq(spot, 1_500_000_000 * RAY, "RWA014: Bad spot value after bump()");
    }
}
