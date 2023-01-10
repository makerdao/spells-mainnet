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

contract DssSpellTest is DssSpellTestBase {
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

    function testNewChainlogValues() private { // make private to disable
        _vote(address(spell));
        _scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        // _checkChainlogKey("XXX");

        _checkChainlogVersion("1.14.7");
    }

    function testNewIlkRegistryValues() private { // make private to disable
        _vote(address(spell));
        _scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        // Insert new ilk registry values tests here
        // GNO-A
        assertEq(reg.pos("GNO-A"),    56);
        assertEq(reg.join("GNO-A"),   addr.addr("MCD_JOIN_GNO_A"));
        assertEq(reg.gem("GNO-A"),    addr.addr("GNO"));
        assertEq(reg.dec("GNO-A"),    GemAbstract(addr.addr("GNO")).decimals());
        assertEq(reg.class("GNO-A"),  1);
        assertEq(reg.pip("GNO-A"),    addr.addr("PIP_GNO"));
        assertEq(reg.name("GNO-A"),   "Gnosis Token");
        assertEq(reg.symbol("GNO-A"), GemAbstract(addr.addr("GNO")).symbol());
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

    function testPSMs() private { // make private to disable
        _vote(address(spell));
        _scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        bytes32 _ilk = "PSM-PAX-A";
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
            10,
            0
        );

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
            10,
            10
        );
    }

    // @dev when testing new vest contracts, use the explicit id when testing to assist in
    //      identifying streams later for modification or removal
    function testVestDAI() public { // make private to disable
        VestAbstract vest = VestAbstract(addr.addr("MCD_VEST_DAI"));

        // All times in GMT
        uint256 FEB_01_2023 = 1675209600; // Wednesday, February  1, 2023 00:00:00
        uint256 JAN_31_2024 = 1706745599; //  Thursday, January  31, 2024 23:59:59

        assertEq(vest.ids(), 13);

        _vote(address(spell));
        _scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        assertEq(vest.ids(), 13 + 2);

        assertEq(vest.cap(), 1 * MILLION * WAD / 30 days);

        assertTrue(vest.valid(14)); // check for valid contract
        _checkDaiVest({
            _index:      14,                                             // id
            _wallet:     wallets.addr("DUX_WALLET"),                     // usr
            _start:      FEB_01_2023,                                    // bgn
            _cliff:      FEB_01_2023,                                    // clf
            _end:        JAN_31_2024,                                    // fin
            _days:       365 days,                                       // fin
            _manager:    address(0),                                     // mgr
            _restricted: 1,                                              // res
            _reward:     1_611_420 * WAD,                                // tot
            _claimed:    0                                               // rxd
        });

        assertTrue(vest.valid(15)); // check for valid contract
        _checkDaiVest({
            _index:      15,                                             // id
            _wallet:     wallets.addr("SES_WALLET"),                     // usr
            _start:      FEB_01_2023,                                    // bgn
            _cliff:      FEB_01_2023,                                    // clf
            _end:        JAN_31_2024,                                    // fin
            _days:       365 days,                                       // fin
            _manager:    address(0),                                     // mgr
            _restricted: 1,                                              // res
            _reward:     3_199_200 * WAD,                                // tot
            _claimed:    0                                               // rxd
        });

        // // Give admin powers to Test contract address and make the vesting unrestricted for testing
        _giveAuth(address(vest), address(this));
        uint256 prevDuxBalance = dai.balanceOf(wallets.addr("DUX_WALLET"));
        uint256 prevSesBalance = dai.balanceOf(wallets.addr("SES_WALLET"));

        vest.unrestrict(14);
        vest.unrestrict(15);
        vm.warp(FEB_01_2023 + 365 days);
        vest.vest(14);
        assertEq(dai.balanceOf(wallets.addr("DUX_WALLET")), prevDuxBalance + 1_611_420 * WAD);
        vest.vest(15);
        assertEq(dai.balanceOf(wallets.addr("SES_WALLET")), prevSesBalance + 3_199_200 * WAD);
    }

    struct Payee {
        address addr;
        uint256 amount;
    }

    function testPayments() public { // make private to disable

        // For each payment, create a Payee obj ect with
        //    the Payee address,
        //    the amount to be paid in whole Dai units
        // Initialize the array with the number of payees
        Payee[18] memory payees = [
           Payee(wallets.addr("STABLENODE"),         12_000),
           Payee(wallets.addr("ULTRASCHUPPI"),       12_000),
           Payee(wallets.addr("FLIPFLOPFLAP"),       12_000),
           Payee(wallets.addr("FLIPSIDE"),           11_400),
           Payee(wallets.addr("FEEDBLACKLOOPS"),     10_808),
           Payee(wallets.addr("PENNBLOCKCHAIN"),     10_385),
           Payee(wallets.addr("MHONKASALOTEEMULAU"),  9_484),
           Payee(wallets.addr("GFXLABS"),             8_903),
           Payee(wallets.addr("JUSTINCASE"),          7_235),
           Payee(wallets.addr("LBSBLOCKCHAIN"),       3_798),
           Payee(wallets.addr("CALBLOCKCHAIN"),       3_421),
           Payee(wallets.addr("BLOCKCHAINCOLUMBIA"),  2_851),
           Payee(wallets.addr("FRONTIERRESEARCH"),    2_285),
           Payee(wallets.addr("CHRISBLEC"),           1_334),
           Payee(wallets.addr("CODEKNIGHT"),            355),
           Payee(wallets.addr("ONESTONE"),              342),
           Payee(wallets.addr("PVL"),                    56),
           Payee(wallets.addr("CONSENSYS"),              33)
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

    function testVestMKR() public { // make private to disable
        VestAbstract vest = VestAbstract(addr.addr("MCD_VEST_MKR_TREASURY"));
        assertEq(vest.ids(), 28);

        uint256 prevAllowance = gov.allowance(pauseProxy, addr.addr("MCD_VEST_MKR_TREASURY"));

        _vote(address(spell));
        _scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        assertEq(gov.allowance(pauseProxy, addr.addr("MCD_VEST_MKR_TREASURY")), prevAllowance + 675 ether);

        assertEq(vest.cap(), 1_100 * WAD / 365 days);
        assertEq(vest.ids(), 29);

        uint256 MAY_01_2021 = 1619827200;
        uint256 AUG_01_2022 = 1659312000;
        uint256 PE_CLIFF = AUG_01_2022 + 365 days;
        uint256 PE_FIN = MAY_01_2021 + 365 days * 4;

        address PE_IC_WALLET = 0xa91c40621D63599b00476eC3e528E06940B03B9D;

        assertEq(vest.usr(29), PE_IC_WALLET);
        assertEq(vest.bgn(29), AUG_01_2022);
        assertEq(vest.clf(29), PE_CLIFF);
        assertEq(vest.fin(29), PE_FIN);
        assertEq(vest.mgr(29), wallets.addr("PE_WALLET"));
        assertEq(vest.res(29), 1);
        assertEq(vest.tot(29), 675 ether);
        assertEq(vest.rxd(29), 0);

        uint256 prevBalance = gov.balanceOf(PE_IC_WALLET);

        // Give admin powers to test contract address and make the vesting unrestricted for testing
        _giveAuth(address(vest), address(this));
        vest.unrestrict(29);

        vm.warp(PE_FIN);
        vest.vest(29);
        assertEq(gov.balanceOf(PE_IC_WALLET), prevBalance + 675 ether);

    }

    function testMKRPayments() public { // make private to disable
        uint256 prevMkrPause  = gov.balanceOf(address(pauseProxy));
        uint256 prevMkrDeco   = gov.balanceOf(wallets.addr("DECO_WALLET"));
        uint256 prevMkrRisk   = gov.balanceOf(wallets.addr("RISK_WALLET_VEST"));
        uint256 prevMkrOracle = gov.balanceOf(wallets.addr("ORA_WALLET"));

        uint256 amountDeco   = 125    ether;
        uint256 amountRisk   = 175    ether;
        uint256 amountOracle = 843.69 ether;

        uint256 total      = 1_143.69 ether;

        _vote(address(spell));
        _scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        assertEq(gov.balanceOf(address(pauseProxy)), prevMkrPause - total);
        assertEq(gov.balanceOf(wallets.addr("DECO_WALLET")), prevMkrDeco + amountDeco);
        assertEq(gov.balanceOf(wallets.addr("RISK_WALLET_VEST")), prevMkrRisk + amountRisk);
        assertEq(gov.balanceOf(wallets.addr("ORA_WALLET")), prevMkrOracle + amountOracle);
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
}
