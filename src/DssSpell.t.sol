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

interface D3MHubLike {
    function exec(bytes32) external;
    function vow() external view returns (address);
    function end() external view returns (address);
    function ilks(bytes32) external view returns (address, address, uint256, uint256, uint256);
}

interface D3MMomLike {
    function authority() external view returns (address);
    function disable(address) external;
}

interface D3MAavePlan {
    function bar() external view returns (uint256);
}

interface D3MAavePool {
    function redeemable() external view returns (address);
}

interface D3MCompPlan {
    function barb() external view returns (uint256);
}

interface D3MCompPool {
    function redeemable() external view returns (address);
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

    function testIlkClipper() private { // make private to disable
        _vote(address(spell));
        _scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        // XXX
        _checkIlkClipper(
            "XXX-A",
            GemJoinAbstract(addr.addr("MCD_JOIN_XXX_A")),
            ClipAbstract(addr.addr("MCD_CLIP_XXX_A")),
            addr.addr("MCD_CLIP_CALC_XXX_A"),
            OsmAbstract(addr.addr("PIP_XXX")),
            5_000 * WAD
        );
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

    function testNewIlkRegistryValues() private { // make private to disable
        _vote(address(spell));
        _scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        // Insert new ilk registry values tests here
        // DIRECT-AAVEV2-DAI
        assertEq(reg.pos("DIRECT-AAVEV2-DAI"),    60);
        assertEq(reg.join("DIRECT-AAVEV2-DAI"),   addr.addr("DIRECT_HUB"));
        assertEq(reg.gem("DIRECT-AAVEV2-DAI"),    addr.addr("ADAI"));
        assertEq(reg.dec("DIRECT-AAVEV2-DAI"),    18);
        assertEq(reg.class("DIRECT-AAVEV2-DAI"),  4);
        assertEq(reg.pip("DIRECT-AAVEV2-DAI"),    addr.addr("DIRECT_AAVEV2_DAI_ORACLE"));
        assertEq(reg.name("DIRECT-AAVEV2-DAI"),   "Aave interest bearing DAI");
        assertEq(reg.symbol("DIRECT-AAVEV2-DAI"), "aDAI");
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

    // leave public for now as this is acting like a config tests
    function testPSMs() private { // Disabled since some PSMs are maxed out
        _vote(address(spell));
        _scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        bytes32 _ilk = "PSM-GUSD-A";
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
            10,  // tin
            0    // tout
        );

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
            20,  // tin
            0    // tout
        );

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
    }

    // @dev when testing new vest contracts, use the explicit id when testing to assist in
    //      identifying streams later for modification or removal
    function testVestDAI() private { // make private to disable
        VestAbstract vest = VestAbstract(addr.addr("MCD_VEST_DAI"));

        // All times in GMT
        // $ make time stamp=<STAMP>
        uint256 FEB_01_2023 = 1675209600; // Wed 01 Feb 2023 12:00:00 AM UTC
        uint256 AUG_01_2023 = 1690847999; // Mon 31 Jul 2023 11:59:59 PM UTC

        assertEq(vest.ids(), 15);

        _vote(address(spell));
        _scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        assertEq(vest.ids(), 15 + 1);

        assertEq(vest.cap(), 1 * MILLION * WAD / 30 days);

        assertTrue(vest.valid(16)); // check for valid contract
        _checkDaiVest({
            _index:      16,                                             // id
            _wallet:     wallets.addr("CHAINLINK_AUTOMATION"),                     // usr
            _start:      FEB_01_2023,                                    // bgn
            _cliff:      FEB_01_2023,                                    // clf
            _end:        AUG_01_2023,                                    // fin
            _days:       181 days,                                       // fin
            _manager:    address(0),                                     // mgr
            _restricted: 1,                                              // res
            _reward:     181_000 * WAD,                                  // tot
            _claimed:    0                                               // rxd
        });


        // // Give admin powers to Test contract address and make the vesting unrestricted for testing
        GodMode.setWard(address(vest), address(this), 1);
        uint256 prevChainlinkBalance = dai.balanceOf(wallets.addr("CHAINLINK_AUTOMATION"));

        vest.unrestrict(16);
        vm.warp(FEB_01_2023 + 365 days);
        vest.vest(16);
        assertEq(dai.balanceOf(wallets.addr("CHAINLINK_AUTOMATION")), prevChainlinkBalance + 181_000 * WAD);
    }

    struct Payee {
        address addr;
        uint256 amount;
    }

    function testPayments() private { // make private to disable

        // For each payment, create a Payee obj ect with
        //    the Payee address,
        //    the amount to be paid in whole Dai units
        // Initialize the array with the number of payees
        Payee[15] memory payees = [
            Payee(wallets.addr("GRO_WALLET"),         648_134),
            Payee(wallets.addr("COLDIRON"),            12_000),
            Payee(wallets.addr("FLIPFLOPFLAP"),        12_000),
            Payee(wallets.addr("GFXLABS"),             12_000),
            Payee(wallets.addr("MHONKASALOTEEMULAU"),  11_447),
            Payee(wallets.addr("PENNBLOCKCHAIN"),      11_178),
            Payee(wallets.addr("FEEDBLACKLOOPS"),      10_802),
            Payee(wallets.addr("FLIPSIDE"),            10_347),
            Payee(wallets.addr("JUSTINCASE"),           8_680),
            Payee(wallets.addr("STABLELAB"),            3_961),
            Payee(wallets.addr("FRONTIERRESEARCH"),     2_455),
            Payee(wallets.addr("CHRISBLEC"),              951),
            Payee(wallets.addr("CODEKNIGHT"),             939),
            Payee(wallets.addr("ONESTONE"),               360),
            Payee(wallets.addr("HKUSTEPI"),               348)
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

        _vote(address(spell));
        _scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        // assertEq(vest.fin(4), block.timestamp);
        // assertEq(vest.fin(5), block.timestamp);
        // assertEq(vestLegacy.fin(35), block.timestamp);
    }

    function testYankMKR() private { // make private to disable

        // VestAbstract vestTreas = VestAbstract(addr.addr("MCD_VEST_MKR_TREASURY"));
        // //VestAbstract vestMint  = VestAbstract(addr.addr("MCD_VEST_MKR"));

        // // Sunday, May 31, 2026 12:00:00 AM
        // uint256 MAY_31_2026 = 1780185600;

        // assertEq(vestTreas.usr(23), wallets.addr("SH_WALLET"));
        // assertEq(vestTreas.fin(23), MAY_31_2026);

        _vote(address(spell));
        _scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        // assertEq(vestTreas.fin(23), block.timestamp);
    }

    function testVestMKR() private { // make private to disable
        VestAbstract vest = VestAbstract(addr.addr("MCD_VEST_MKR_TREASURY"));
        assertEq(vest.ids(), 29);

        uint256 prevAllowance = gov.allowance(pauseProxy, addr.addr("MCD_VEST_MKR_TREASURY"));

        _vote(address(spell));
        _scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        assertEq(gov.allowance(pauseProxy, addr.addr("MCD_VEST_MKR_TREASURY")), prevAllowance + 240 ether + 195 ether);

        assertEq(vest.cap(), 1_100 * WAD / 365 days);
        assertEq(vest.ids(), 31);

        uint256 MAR_01_2022 = 1646092800;
        uint256 MAR_01_2025 = 1740787200;

        uint256 CLIFF = MAR_01_2022 + 365 days;
        uint256 FIN   = MAR_01_2022 + (365 days) * 3 + 1 days ; // adding 1 day since 2024 is a leap year

        address SF_IC_WALLET_0 = 0x31C01e90Edcf8602C1A18B2aE4e5A72D8DCE76bD;
        address SF_IC_WALLET_1 = 0x12b19C5857CF92AaE5e5e5ADc6350e25e4C902e9;

        assertEq(vest.usr(30), SF_IC_WALLET_0);
        assertEq(vest.bgn(30), MAR_01_2022);
        assertEq(vest.clf(30), CLIFF);
        assertEq(vest.fin(30), FIN);
        assertEq(vest.fin(30), MAR_01_2025);
        assertEq(vest.mgr(30), address(0));
        assertEq(vest.res(30), 1);
        assertEq(vest.tot(30), 240 ether);
        assertEq(vest.rxd(30), 0);

        assertEq(vest.usr(31), SF_IC_WALLET_1);
        assertEq(vest.bgn(31), MAR_01_2022);
        assertEq(vest.clf(31), CLIFF);
        assertEq(vest.fin(31), FIN);
        assertEq(vest.fin(31), MAR_01_2025);
        assertEq(vest.mgr(31), address(0));
        assertEq(vest.res(31), 1);
        assertEq(vest.tot(31), 195 ether);
        assertEq(vest.rxd(31), 0);

        uint256 prevBalance0 = gov.balanceOf(SF_IC_WALLET_0);
        uint256 prevBalance1 = gov.balanceOf(SF_IC_WALLET_1);

        // Give admin powers to test contract address and make the vesting unrestricted for testing
        GodMode.setWard(address(vest), address(this), 1);
        vest.unrestrict(30);
        vest.unrestrict(31);

        vm.warp(FIN);

        vest.vest(30);
        assertEq(gov.balanceOf(SF_IC_WALLET_0), prevBalance0 + 240 ether);

        vest.vest(31);
        assertEq(gov.balanceOf(SF_IC_WALLET_1), prevBalance1 + 195 ether);
    }

    function testMKRPayments() private { // make private to disable
        uint256 prevMkrPause  = gov.balanceOf(address(pauseProxy));
        uint256 prevMkrTECH   = gov.balanceOf(wallets.addr("TECH_WALLET"));
        uint256 prevMkrDECO   = gov.balanceOf(wallets.addr("DECO_WALLET"));
        uint256 prevMkrRISK   = gov.balanceOf(wallets.addr("RISK_WALLET_VEST"));

        uint256 amountTECH    = 67.9579 ether;
        uint256 amountDECO    = 125 ether;
        uint256 amountRISK    = 175 ether;
        uint256 total         = 367.9579 ether;

        _vote(address(spell));
        _scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        assertEq(gov.balanceOf(address(pauseProxy)), prevMkrPause - total);
        assertEq(gov.balanceOf(wallets.addr("TECH_WALLET")), prevMkrTECH + amountTECH);
        assertEq(gov.balanceOf(wallets.addr("DECO_WALLET")), prevMkrDECO + amountDECO);
        assertEq(gov.balanceOf(wallets.addr("RISK_WALLET_VEST")), prevMkrRISK + amountRISK);
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

    function testAAVEDirectBarChange() public {
        D3MHubLike  hub  = D3MHubLike(addr.addr("DIRECT_HUB"));
        D3MAavePlan plan = D3MAavePlan(addr.addr("DIRECT_AAVEV2_DAI_PLAN"));
        D3MAavePool pool = D3MAavePool(addr.addr("DIRECT_AAVEV2_DAI_POOL"));

        DSTokenAbstract adai = DSTokenAbstract(pool.redeemable());

        assertEq(plan.bar(), 2.00 * 10**27 / 100);

        _vote(address(spell));
        spell.schedule();

        // bar should now be 0
        assertEq(plan.bar(), 0);

        // this should make sure the position is winded down
        hub.exec("DIRECT-AAVEV2-DAI");
        assertEq(adai.balanceOf(address(pool)), 0);

        vm.warp(DssSpell(spell).nextCastTime());
        DssSpell(spell).cast();
        assertTrue(spell.done());
    }

    function testCompoundDirectBarbChange() public {
        D3MHubLike  hub  = D3MHubLike(addr.addr("DIRECT_HUB"));
        D3MCompPlan plan = D3MCompPlan(addr.addr("DIRECT_COMPV2_DAI_PLAN"));
        D3MCompPool pool = D3MCompPool(addr.addr("DIRECT_COMPV2_DAI_POOL"));

        DSTokenAbstract cdai = DSTokenAbstract(pool.redeemable());

        assertEq(plan.barb(), 7535450719);

        _vote(address(spell));
        spell.schedule();

        // barb should now be 0
        assertEq(plan.barb(), 0);

        // this should unwind the position
        assertTrue(cdai.balanceOf(address(pool)) > 1);
        hub.exec("DIRECT-COMPV2-DAI");
        assertTrue(cdai.balanceOf(address(pool)) <= 1); // rounding error

        vm.warp(DssSpell(spell).nextCastTime());
        DssSpell(spell).cast();
        assertTrue(spell.done());
    }

    function testPSMTinTout() public {
        PsmAbstract psmUsdc = PsmAbstract(addr.addr("MCD_PSM_USDC_A"));
        PsmAbstract psmPax  = PsmAbstract(addr.addr("MCD_PSM_PAX_A"));

        assertEq(psmUsdc.tin(), 0);
        assertEq(psmPax.tin(), 0.002 * 10**18);
        assertEq(psmPax.tout(), 0);

        _vote(address(spell));
        _scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        assertEq(psmUsdc.tin(), 0.01 * 10**18);
        assertEq(psmPax.tin(), 0);
        assertEq(psmPax.tout(), 0.01 * 10**18);

    }
}
