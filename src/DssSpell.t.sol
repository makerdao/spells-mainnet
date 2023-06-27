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

interface RwaLiquidationOracleLike {
    function ilks(bytes32) external view returns (string memory, address, uint48 toc, uint48 tau);
}

interface RwaUrnLike {
    function can(address) external view returns (uint256);
    function outputConduit() external view returns (address);
    function draw(uint256) external;
    function wipe(uint256) external;
    function free(uint256) external;
}

interface RwaOutputConduitLike {
    function wards(address) external view returns (uint256);
    function can(address) external view returns (uint256);
    function may(address) external view returns (uint256);
    function dai() external view returns (address);
    function psm() external view returns (address);
    function gem() external view returns (address);
    function bud(address) external view returns (uint256);
    function quitTo() external view returns (address);
    function pick(address) external;
    function kiss(address) external;
    function mate(address) external;
    function hope(address) external;
    function push() external;
    function push(uint256) external;
    function quit() external;
}

interface NetworkPaymentAdapterLike {
    function treasury() external view returns (address);
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
    // END OF TESTS THAT SHOULD BE RUN ON EVERY SPELL

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

        // try chainLog.getAddress("RWA007_A_INPUT_CONDUIT_URN") {
        //     assertTrue(false);
        // } catch Error(string memory errmsg) {
        //     assertTrue(cmpStr(errmsg, "dss-chain-log/invalid-key"));
        // } catch {
        //     assertTrue(false);
        // }
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

    function testNewChainlogValues() public { // don't disable
        _vote(address(spell));
        _scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        _checkChainlogKey("RWA015_A_OUTPUT_CONDUIT");
        _checkChainlogKey("RWA015_A_OUTPUT_CONDUIT_LEGACY");

        _checkChainlogVersion("1.14.14");
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

    // @dev when testing new vest contracts, use the explicit id when testing to assist in
    //      identifying streams later for modification or removal
    function testVestDAI() private { // make private to disable
        VestAbstract vest = VestAbstract(addr.addr("MCD_VEST_DAI"));

        // All times in GMT
        // $ make time stamp=<STAMP>
        // 24 May 2023 12:00:00 AM UTC
        uint256 MAY_24_2023  = 1684886400;
        // 23 May 2023 11:59:59 PM UTC
        uint256 MAY_23_2024  = 1716508799;
        // 23 May 2026 11:59:59 PM UTC
        uint256 MAY_23_2026  = 1779580799;

        uint256 prevBalance;

        // Store previous amount of streams
        uint256 prevStreamCount = vest.ids();

        // Cast the spell
        _vote(address(spell));
        _scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        // Check that 4 new streams are added
        assertEq(vest.ids(), prevStreamCount + 4);

        // Check the first stream
        uint256 gelatoStreamId = prevStreamCount + 1;
        assertTrue(vest.valid(gelatoStreamId)); // check for valid contract
        _checkDaiVest({
            _index:      gelatoStreamId,                                 // id
            _wallet:     wallets.addr("GELATO_PAYMENT_ADAPTER"),         // usr
            _start:      MAY_24_2023,                                    // bgn
            _cliff:      MAY_24_2023,                                    // clf
            _end:        MAY_23_2026,                                    // fin
            _days:       1096 days,                                      // fin
            _manager:    address(0),                                     // mgr
            _restricted: 1,                                              // res
            _reward:     1_644_000 * WAD,                                // tot
            _claimed:    0                                               // rxd
        });
        // Give admin powers to Test contract address and make the vesting unrestricted for testing
        GodMode.setWard(address(vest), address(this), 1);
        prevBalance = dai.balanceOf(wallets.addr("GELATO_PAYMENT_ADAPTER"));
        vest.unrestrict(gelatoStreamId);
        vm.warp(MAY_24_2023 + 1096 days);
        vest.vest(gelatoStreamId);
        assertEq(dai.balanceOf(wallets.addr("GELATO_PAYMENT_ADAPTER")), prevBalance + 1_644_000 * WAD);

        // Check the second stream
        uint256 keeperStreamId = prevStreamCount + 2;
        assertTrue(vest.valid(keeperStreamId)); // check for valid contract
        _checkDaiVest({
            _index:      keeperStreamId,                                 // id
            _wallet:     wallets.addr("KEEP3R_PAYMENT_ADAPTER"),         // usr
            _start:      MAY_24_2023,                                    // bgn
            _cliff:      MAY_24_2023,                                    // clf
            _end:        MAY_23_2026,                                    // fin
            _days:       1096 days,                                      // fin
            _manager:    address(0),                                     // mgr
            _restricted: 1,                                              // res
            _reward:     1_644_000 * WAD,                                // tot
            _claimed:    0                                               // rxd
        });
        // Give admin powers to Test contract address and make the vesting unrestricted for testing
        GodMode.setWard(address(vest), address(this), 1);
        prevBalance = dai.balanceOf(wallets.addr("KEEP3R_PAYMENT_ADAPTER"));
        vest.unrestrict(keeperStreamId);
        vm.warp(MAY_24_2023 + 1096 days);
        vest.vest(keeperStreamId);
        assertEq(dai.balanceOf(wallets.addr("KEEP3R_PAYMENT_ADAPTER")), prevBalance + 1_644_000 * WAD);

        // Check the third stream
        uint256 chainlinkStreamId = prevStreamCount + 3;
        assertTrue(vest.valid(chainlinkStreamId)); // check for valid contract
        _checkDaiVest({
            _index:      chainlinkStreamId,                                 // id
            _wallet:     wallets.addr("CHAINLINK_PAYMENT_ADAPTER"),         // usr
            _start:      MAY_24_2023,                                    // bgn
            _cliff:      MAY_24_2023,                                    // clf
            _end:        MAY_23_2026,                                    // fin
            _days:       1096 days,                                      // fin
            _manager:    address(0),                                     // mgr
            _restricted: 1,                                              // res
            _reward:     1_644_000 * WAD,                                // tot
            _claimed:    0                                               // rxd
        });
        // Give admin powers to Test contract address and make the vesting unrestricted for testing
        GodMode.setWard(address(vest), address(this), 1);
        prevBalance = dai.balanceOf(wallets.addr("CHAINLINK_PAYMENT_ADAPTER"));
        vest.unrestrict(chainlinkStreamId);
        vm.warp(MAY_24_2023 + 1096 days);
        vest.vest(chainlinkStreamId);
        assertEq(dai.balanceOf(wallets.addr("CHAINLINK_PAYMENT_ADAPTER")), prevBalance + 1_644_000 * WAD);

        // Check the fourth stream
        uint256 techopsStreamId = prevStreamCount + 4;
        assertTrue(vest.valid(techopsStreamId)); // check for valid contract
        _checkDaiVest({
            _index:      techopsStreamId,                                 // id
            _wallet:     wallets.addr("TECHOPS_VEST_STREAMING"),         // usr
            _start:      MAY_24_2023,                                    // bgn
            _cliff:      MAY_24_2023,                                    // clf
            _end:        MAY_23_2024,                                    // fin
            _days:       366 days,                                      // fin
            _manager:    address(0),                                     // mgr
            _restricted: 1,                                              // res
            _reward:     366_000 * WAD,                                // tot
            _claimed:    0                                               // rxd
        });
        // Give admin powers to Test contract address and make the vesting unrestricted for testing
        GodMode.setWard(address(vest), address(this), 1);
        prevBalance = dai.balanceOf(wallets.addr("TECHOPS_VEST_STREAMING"));
        vest.unrestrict(techopsStreamId);
        vm.warp(MAY_24_2023 + 1096 days);
        vest.vest(techopsStreamId);
        assertEq(dai.balanceOf(wallets.addr("TECHOPS_VEST_STREAMING")), prevBalance + 366_000 * WAD);
    }

    struct Payee {
        address addr;
        uint256 amount;
    }

    function testPayments() public { // make private to disable

        // For each payment, create a Payee object with
        //    the Payee address,
        //    the amount to be paid in whole Dai units
        // Initialize the array with the number of payees
        Payee[1] memory payees = [
            // ECOSYSTEM ACTOR DAI TRANSFERS
            Payee(wallets.addr("BLOCKTOWER_WALLET_2"), 133_466)
        ];

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
        assertTrue(spell.done());

        assertEq(vat.sin(address(vow)) - prevSin, totAmount * RAD, "testPayments/vat-sin-mismatch");

        for (uint256 i = 0; i < payees.length; i++) {
            assertEq(
                dai.balanceOf(payees[i].addr) - prevAmounts[i],
                payees[i].amount * WAD
            );
        }
    }

    function testYankDAI() private { // make private to disable
        VestAbstract vest = VestAbstract(addr.addr("MCD_VEST_DAI"));
        // VestAbstract vestLegacy = VestAbstract(addr.addr("MCD_VEST_DAI_LEGACY"));

        // 31 Jul 2023 11:59:59 PM UTC
        uint256 JUL_31_2023 = 1690847999;

        assertEq(vest.usr(16), wallets.addr("CHAINLINK_AUTOMATION"));
        assertEq(vest.fin(16), JUL_31_2023);

        _vote(address(spell));
        _scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        assertEq(vest.fin(16), block.timestamp);
    }

    function testYankMKR() private { // make private to disable
        VestAbstract vestTreasury = VestAbstract(addr.addr("MCD_VEST_MKR_TREASURY"));

        // 01 Apr 2024 11:59:59 PM UTC
        uint256 APR_1_2024 = 1712015999;

        assertEq(vestTreasury.usr(37), wallets.addr("PHOENIX_LABS_2"));
        assertEq(vestTreasury.fin(37),  APR_1_2024);

        _vote(address(spell));
        _scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        assertEq(vestTreasury.fin(37),  block.timestamp);

        // Give admin powers to test contract address and make the vesting unrestricted for testing
        GodMode.setWard(address(vestTreasury), address(this), 1);

        vestTreasury.unrestrict(37);

        vestTreasury.vest(37);

        assertTrue(!vestTreasury.valid(37));
        assertEq(vestTreasury.fin(37), block.timestamp);
    }

    function testVestMKR() private { // make private to disable
        VestAbstract vest = VestAbstract(addr.addr("MCD_VEST_MKR_TREASURY"));
        assertEq(vest.ids(), 37);

        uint256 prevAllowance = gov.allowance(pauseProxy, addr.addr("MCD_VEST_MKR_TREASURY"));

        _vote(address(spell));
        _scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        uint256 newAllowance = 986.25 ether; // Phoenix Lab
               newAllowance += 4_000 ether; // PullUp Labs

        assertEq(gov.allowance(pauseProxy, addr.addr("MCD_VEST_MKR_TREASURY")), prevAllowance + newAllowance);

        assertEq(vest.cap(), 2_200 * WAD / 365 days);
        assertEq(vest.ids(), 37 + 2);

        // 01 May 2023 12:00:00 AM UTC
        uint256 MAY_01_2023 = 1682899200;
        // 30 Apr 2024 11:59:59 PM UTC
        uint256 APR_30_2024 = 1714521599;
        // 30 Apr 2025 11:59:59 PM UTC
        uint256 APR_30_2025 = 1746057599;


        uint256 PHOENIX_LABS_FIN  = MAY_01_2023 + (366 days) - 1; // -1 because we are going to 11:59:59 on Apr 30 24
        uint256 PULLUP_LABS_FIN   = MAY_01_2023 + (366 days + 365 days) - 1; // -1 because we are going to 11:59:59 on Apr 30 25

        assertEq(vest.usr(38), wallets.addr("PHOENIX_LABS_2"));
        assertEq(vest.bgn(38), MAY_01_2023);
        assertEq(vest.clf(38), MAY_01_2023);
        assertEq(vest.fin(38), PHOENIX_LABS_FIN);
        assertEq(vest.fin(38), APR_30_2024);
        assertEq(vest.mgr(38), address(0));
        assertEq(vest.res(38), 1);
        assertEq(vest.tot(38), 986.25 ether);
        assertEq(vest.rxd(38), 0);

        assertEq(vest.usr(39), wallets.addr("PULLUP_LABS"));
        assertEq(vest.bgn(39), MAY_01_2023);
        assertEq(vest.clf(39), MAY_01_2023);
        assertEq(vest.fin(39), PULLUP_LABS_FIN);
        assertEq(vest.fin(39), APR_30_2025);
        assertEq(vest.mgr(39), wallets.addr("PULLUP_LABS_VEST_MGR"));
        assertEq(vest.res(39), 1);
        assertEq(vest.tot(39), 4_000 ether);
        assertEq(vest.rxd(39), 0);

        uint256 prevBalance0 = gov.balanceOf(wallets.addr("PHOENIX_LABS_2"));
        uint256 prevBalance1 = gov.balanceOf(wallets.addr("PULLUP_LABS"));

        // Give admin powers to test contract address and make the vesting unrestricted for testing
        GodMode.setWard(address(vest), address(this), 1);
        vest.unrestrict(38);
        vest.unrestrict(39);

        vm.warp(PHOENIX_LABS_FIN);

        vest.vest(38);
        assertEq(gov.balanceOf(wallets.addr("PHOENIX_LABS_2")), prevBalance0 + 986.25 ether);

        vm.warp(PULLUP_LABS_FIN);

        vest.vest(39);
        assertEq(gov.balanceOf(wallets.addr("PULLUP_LABS")), prevBalance1 + 4_000 ether);
    }

    function testMKRPayments() public { // make public to enable
        // For each payment, create a Payee object with
        //    the Payee address,
        //    the amount to be paid
        // Initialize the array with the number of payees
        Payee[17] memory payees = [
            Payee(wallets.addr("ORA_WALLET"),       297.3 ether),  // note: ether is a keyword helper, only MKR is transferred here
            Payee(wallets.addr("RISK_WALLET_VEST"), 175 ether),    // note: ether is a keyword helper, only MKR is transferred here
            Payee(wallets.addr("SES_WALLET"),       10.3 ether),   // note: ether is a keyword helper, only MKR is transferred here
            Payee(wallets.addr("VIGILANT"),         29.76 ether),  // note: ether is a keyword helper, only MKR is transferred here
            Payee(wallets.addr("DEFENSOR"),         29.76 ether),  // note: ether is a keyword helper, only MKR is transferred here
            Payee(wallets.addr("BONAPUBLICA"),      29.76 ether),  // note: ether is a keyword helper, only MKR is transferred here
            Payee(wallets.addr("FRONTIERRESEARCH"), 29.76 ether),  // note: ether is a keyword helper, only MKR is transferred here
            Payee(wallets.addr("GFXLABS_2"),        29.76 ether),  // note: ether is a keyword helper, only MKR is transferred here
            Payee(wallets.addr("QGOV"),             29.76 ether),  // note: ether is a keyword helper, only MKR is transferred here
            Payee(wallets.addr("TRUENAME"),         29.76 ether),  // note: ether is a keyword helper, only MKR is transferred here
            Payee(wallets.addr("UPMAKER"),          9.92 ether),   // note: ether is a keyword helper, only MKR is transferred here
            Payee(wallets.addr("WBC"),              9.92 ether),   // note: ether is a keyword helper, only MKR is transferred here
            Payee(wallets.addr("LIBERTAS"),         9.92 ether),   // note: ether is a keyword helper, only MKR is transferred here
            Payee(wallets.addr("CODEKNIGHT"),       9.92 ether),   // note: ether is a keyword helper, only MKR is transferred here
            Payee(wallets.addr("PBG"),              9.92 ether),   // note: ether is a keyword helper, only MKR is transferred here
            Payee(wallets.addr("FLIPFLOPFLAP_2"),   9.92 ether),   // note: ether is a keyword helper, only MKR is transferred here
            Payee(wallets.addr("BANDHAR"),          9.92 ether)    // note: ether is a keyword helper, only MKR is transferred here
        ];

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
        assertTrue(spell.done());

        // Check that pause proxy balance has decreased
        assertEq(gov.balanceOf(address(pauseProxy)), prevMkrBalance - totalAmountToTransfer);

        // Check that payees received their payments
        for (uint256 i = 0; i < payees.length; i++) {
            assertEq(gov.balanceOf(payees[i].addr) - prevBalances[i], payees[i].amount);
        }
    }

    function testMKRVestFix() private { // make private to disable
        // uint256 prevMkrPause  = gov.balanceOf(address(pauseProxy));
        // VestAbstract vest = VestAbstract(addr.addr("MCD_VEST_MKR_TREASURY"));

        // address usr = vest.usr(2);
        // assertEq(usr, pauseProxy, "usr of id 2 is pause proxy");

        // uint256 unpaid = vest.unpaid(2);
        // assertEq(unpaid, 63180000000000000000, "amount doesn't match expectation");

        _vote(address(spell));
        _scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        // unpaid = vest.unpaid(2);
        // assertEq(unpaid, 0, "vest still has a balance");
        // assertEq(gov.balanceOf(address(pauseProxy)), prevMkrPause);
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

    function testChainLinkPaymentAdapterTreasury() public {
        _vote(address(spell));
        _scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        require(NetworkPaymentAdapterLike(wallets.addr("CHAINLINK_PAYMENT_ADAPTER")).treasury() == wallets.addr("CHAINLINK_TREASURY"), "ChainLink/incorrect-treasury");
    }

    string OLD_RWA007_DOC      = "QmejL1CKKN5vCwp9QD1gebnnAM2MJSt9XbF64uy4ptkJtR";
    string NEW_RWA007_DOC      = "QmY185L4tuxFkpSQ33cPHUHSNpwy8V6TMXbXvtVraxXtb5";

    function testRWA007DocChange() public {
        _checkRWADocUpdate("RWA007-A", OLD_RWA007_DOC, NEW_RWA007_DOC);
    }

    // RWA tests

    address RWA015_A_OPERATOR = addr.addr("RWA015_A_OPERATOR");
    address RWA015_A_CUSTODY  = addr.addr("RWA015_A_CUSTODY");

    RwaUrnLike               rwa015AUrn                 = RwaUrnLike(addr.addr("RWA015_A_URN"));
    RwaOutputConduitLike     rwa015AOutputConduit       = RwaOutputConduitLike(addr.addr("RWA015_A_OUTPUT_CONDUIT"));
    RwaOutputConduitLike     rwa015AOutputConduitLegacy = RwaOutputConduitLike(addr.addr("RWA015_A_OUTPUT_CONDUIT_LEGACY"));
    RwaLiquidationOracleLike oracle                     = RwaLiquidationOracleLike(addr.addr("MIP21_LIQUIDATION_ORACLE"));
    GemAbstract              psmGem                     = GemAbstract(rwa015AOutputConduit.gem());

    uint256 daiPsmGemDiffDecimals                   = 10 ** (dai.decimals() - psmGem.decimals());

    function testRWA015_OUTPUT_CONDUIT_DEPLOYMENT_SETUP() public {
        assertEq(rwa015AOutputConduit.dai(), addr.addr("MCD_DAI"),       "output-conduit-dai-not-match");
        assertEq(rwa015AOutputConduit.gem(), addr.addr("PAXUSD"),        "output-conduit-gem-not-match");
        assertEq(rwa015AOutputConduit.psm(), addr.addr("MCD_PSM_PAX_A"), "output-conduit-psm-not-match");
    }

    function testRWA015_REVOKE_OPERATOR_ON_LEGACY_OUTPUT_CONDUIT() public {
        _vote(address(spell));
        _scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        assertEq(rwa015AOutputConduitLegacy.can(RWA015_A_OPERATOR), 0, "OutputConduitLegacy/operator-hoped");
        assertEq(rwa015AOutputConduitLegacy.may(RWA015_A_OPERATOR), 0, "OutputConduitLegacy/operator-mated");
    }

    function testRWA015_INTEGRATION_CONDUITS_SETUP() public {
        _vote(address(spell));
        _scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        assertEq(rwa015AUrn.outputConduit(), address(rwa015AOutputConduit), "RwaUrn/urn-outputconduit-not-match");

        assertEq(rwa015AOutputConduit.wards(pauseProxy),      1, "OutputConduit/ward-pause-proxy-not-set");
        assertEq(rwa015AOutputConduit.wards(address(esm)),    1, "OutputConduit/ward-esm-not-set");
        assertEq(rwa015AOutputConduit.can(pauseProxy),        0, "OutputConduit/pause-proxy-hoped");
        assertEq(rwa015AOutputConduit.can(RWA015_A_OPERATOR), 1, "OutputConduit/operator-not-hope");
        assertEq(rwa015AOutputConduit.may(pauseProxy),        0, "OutputConduit/pause-proxy-mated");
        assertEq(rwa015AOutputConduit.may(RWA015_A_OPERATOR), 1, "OutputConduit/operator-not-mate");
        assertEq(rwa015AOutputConduit.bud(RWA015_A_CUSTODY),  1, "OutputConduit/destination-address-not-whitelisted-for-pick");

        assertEq(rwa015AOutputConduit.quitTo(), address(rwa015AUrn), "OutputConduit/quit-to-not-urn");
    }

    function testRWA015_OPERATOR_DRAW_CONDUIT_PUSH() public {
        _vote(address(spell));
        _scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        uint256 drawAmount = 1_000_000 * WAD;

        // Increas line of RWA015 to be able to draw some DAI
        GodMode.setWard(address(vat), address(this), 1);
        vat.file("RWA015-A", "line", 3_500_000 * RAD);

        // setting address(this) as operator
        vm.store(address(rwa015AUrn), keccak256(abi.encode(address(this), uint256(1))), bytes32(uint256(1)));
        assertEq(rwa015AUrn.can(address(this)), 1);

        // 0 DAI in Output Conduit
        assertEq(dai.balanceOf(address(rwa015AOutputConduit)), 0, "RWA015-A: Dangling Dai in input conduit before draw()");

        // Draw 1m to test output conduit
        rwa015AUrn.draw(drawAmount);

        // DAI in Output Conduit
        assertEq(dai.balanceOf(address(rwa015AOutputConduit)), drawAmount, "RWA015-A: Dai drawn was not send to the recipient");

        // wards
        GodMode.setWard(address(rwa015AOutputConduit), address(this), 1);
        // may
        rwa015AOutputConduit.mate(address(this));
        assertEq(rwa015AOutputConduit.may(address(this)), 1);
        rwa015AOutputConduit.hope(address(this));
        assertEq(rwa015AOutputConduit.can(address(this)), 1);

        rwa015AOutputConduit.kiss(address(this));
        assertEq(rwa015AOutputConduit.bud(address(this)), 1);
        rwa015AOutputConduit.pick(address(this));

        uint256 pushAmount = drawAmount;
        rwa015AOutputConduit.push(pushAmount);
        rwa015AOutputConduit.quit();

        assertEq(dai.balanceOf(address(rwa015AOutputConduit)), 0, "RWA015-A: Output conduit still holds Dai after quit()");
        assertEq(psmGem.balanceOf(address(this)), pushAmount / daiPsmGemDiffDecimals, "RWA015-A: Psm GEM not sent to destination after push()");
        assertEq(dai.balanceOf(address(rwa015AOutputConduit)), drawAmount - pushAmount, "RWA015-A: Dai not sent to destination after push()");
    }

    function testFailRWA015_A_OUTPUT_CONDUIT_PUSH_ABOVE_BALANCE() public {
        _vote(address(spell));
        _scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        uint256 drawAmount = 2_500_000 * WAD;

        // setting address(this) as operator
        vm.store(address(rwa015AUrn), keccak256(abi.encode(address(this), uint256(1))), bytes32(uint256(1)));

        // Draw line DAI
        rwa015AUrn.draw(drawAmount);

        // auth
        GodMode.setWard(address(rwa015AOutputConduit), address(this), 1);

        // pick address(this)
        rwa015AOutputConduit.hope(address(this)); // allow this to call pick
        rwa015AOutputConduit.kiss(address(this)); // allow this to be picked
        rwa015AOutputConduit.pick(address(this));

        // push above balance
        uint256 pushAmount = drawAmount + 1 * WAD;
        rwa015AOutputConduit.mate(address(this)); // allow this to call push
        rwa015AOutputConduit.push(pushAmount);    // fail
    }

    function test_RWA015_ORACLE_PRICE_BUMP() public {
        _vote(address(spell));
        _scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        // Get collateral's parameters
        (,, uint256 spot,,) = vat.ilks("RWA015-A");
        // Get the oracle address
        (,address pip,,  ) = oracle.ilks("RWA015-A");
        assertEq(uint256(DSValueAbstract(pip).read()), 1_280_000_000 * WAD, "RWA015: Bad PIP value after bump()");
        assertEq(spot, 1_280_000_000 * RAY, "RWA015: Bad spot value after bump()");  // got very close to line
    }
}

