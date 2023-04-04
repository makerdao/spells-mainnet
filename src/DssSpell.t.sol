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

// For PE-1208
interface RwaUrnLike {
    function hope(address) external;
    function draw(uint256) external;
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

    function testESMWards() public {
        _checkESMWards();
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
            1    // tout
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
    function testVestDAI() public { // make private to disable
        VestAbstract vest = VestAbstract(addr.addr("MCD_VEST_DAI"));

        // All times in GMT
        // $ make time stamp=<STAMP>
        uint256 MAR_01_2023 = 1677628800; // 01 Mar 2023 00:00:00 UTC
        uint256 APR_01_2023 = 1680307200; // 01 Apr 2023 00:00:00 UTC
        uint256 FEB_29_2024 = 1709251199; // 29 Feb 2024 23:59:59 UTC
        uint256 MAR_31_2024 = 1711929599; // 31 Mar 2024 23:59:59 UTC
        uint256 APR_01_2024 = 1712015999; // 01 Apr 2024 23:59:59 UTC

        assertEq(vest.ids(), 16);

        _vote(address(spell));
        _scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        assertEq(vest.ids(), 16 + 9);

        assertEq(vest.cap(), 1 * MILLION * WAD / 30 days);

        assertTrue(vest.valid(17)); // check for valid contract
        _checkDaiVest({
            _index:      17,                                             // id
            _wallet:     wallets.addr("GOV_ALPHA"),                      // usr
            _start:      APR_01_2023,                                    // bgn
            _cliff:      APR_01_2023,                                    // clf
            _end:        MAR_31_2024,                                    // fin
            _days:       366 days,                                       // fin
            _manager:    address(0),                                     // mgr
            _restricted: 1,                                              // res
            _reward:     900_000 * WAD,                                  // tot
            _claimed:    0                                               // rxd
        });

        // Give admin powers to Test contract address and make the vesting unrestricted for testing
        GodMode.setWard(address(vest), address(this), 1);
        uint256 prevGovAlphaBalance = dai.balanceOf(wallets.addr("GOV_ALPHA"));

        vest.unrestrict(17);
        vm.warp(APR_01_2023 + 366 days);
        vest.vest(17);
        assertEq(dai.balanceOf(wallets.addr("GOV_ALPHA")), prevGovAlphaBalance + 900_000 * WAD);

        assertTrue(vest.valid(18)); // check for valid contract
        _checkDaiVest({
            _index:      18,                                             // id
            _wallet:     wallets.addr("TECH"),                    // usr
            _start:      APR_01_2023,                                    // bgn
            _cliff:      APR_01_2023,                                    // clf
            _end:        MAR_31_2024,                                    // fin
            _days:       366 days,                                       // fin
            _manager:    address(0),                                     // mgr
            _restricted: 1,                                              // res
            _reward:     1_380_000 * WAD,                                // tot
            _claimed:    0                                               // rxd
        });

        // Give admin powers to Test contract address and make the vesting unrestricted for testing
        GodMode.setWard(address(vest), address(this), 1);
        uint256 prevTechBalance = dai.balanceOf(wallets.addr("TECH"));

        vest.unrestrict(18);
        vm.warp(APR_01_2023 + 366 days);
        vest.vest(18);
        assertEq(dai.balanceOf(wallets.addr("TECH")), prevTechBalance + 1_380_000 * WAD);

        assertTrue(vest.valid(19)); // check for valid contract
        _checkDaiVest({
            _index:      19,                                             // id
            _wallet:     wallets.addr("STEAKHOUSE"),                     // usr
            _start:      APR_01_2023,                                    // bgn
            _cliff:      APR_01_2023,                                    // clf
            _end:        MAR_31_2024,                                    // fin
            _days:       366 days,                                       // fin
            _manager:    address(0),                                     // mgr
            _restricted: 1,                                              // res
            _reward:     2_220_000 * WAD,                                // tot
            _claimed:    0                                               // rxd
        });

        // Give admin powers to Test contract address and make the vesting unrestricted for testing
        GodMode.setWard(address(vest), address(this), 1);
        uint256 prevSteakhouseBalance = dai.balanceOf(wallets.addr("STEAKHOUSE"));

        vest.unrestrict(19);
        vm.warp(APR_01_2023 + 366 days);
        vest.vest(19);
        assertEq(dai.balanceOf(wallets.addr("STEAKHOUSE")), prevSteakhouseBalance + 2_220_000 * WAD);

        assertTrue(vest.valid(20)); // check for valid contract
        _checkDaiVest({
            _index:      20,                                             // id
            _wallet:     wallets.addr("BA_LABS"),                        // usr
            _start:      MAR_01_2023,                                    // bgn
            _cliff:      MAR_01_2023,                                    // clf
            _end:        FEB_29_2024,                                    // fin
            _days:       366 days,                                       // fin
            _manager:    address(0),                                     // mgr
            _restricted: 1,                                              // res
            _reward:     2_484_000 * WAD,                                // tot
            _claimed:    0                                               // rxd
        });

        // Give admin powers to Test contract address and make the vesting unrestricted for testing
        GodMode.setWard(address(vest), address(this), 1);
        uint256 prevBALabsBalance = dai.balanceOf(wallets.addr("BA_LABS"));

        vest.unrestrict(20);
        vm.warp(MAR_01_2023 + 366 days);
        vest.vest(20);
        assertEq(dai.balanceOf(wallets.addr("BA_LABS")), prevBALabsBalance + 2_484_000 * WAD);

        assertTrue(vest.valid(21)); // check for valid contract
        _checkDaiVest({
            _index:      21,                                             // id
            _wallet:     wallets.addr("BA_LABS"),                        // usr
            _start:      APR_01_2023,                                    // bgn
            _cliff:      APR_01_2023,                                    // clf
            _end:        MAR_31_2024,                                    // fin
            _days:       366 days,                                       // fin
            _manager:    address(0),                                     // mgr
            _restricted: 1,                                              // res
            _reward:     876_000 * WAD,                                  // tot
            _claimed:    0                                               // rxd
        });

        // Give admin powers to Test contract address and make the vesting unrestricted for testing
        GodMode.setWard(address(vest), address(this), 1);
        prevBALabsBalance = dai.balanceOf(wallets.addr("BA_LABS"));

        vest.unrestrict(21);
        vm.warp(APR_01_2023 + 366 days);
        vest.vest(21);
        assertEq(dai.balanceOf(wallets.addr("BA_LABS")), prevBALabsBalance + 876_000 * WAD);

        assertTrue(vest.valid(22)); // check for valid contract
        _checkDaiVest({
            _index:      22,                                             // id
            _wallet:     wallets.addr("PHOENIX_LABS_STREAM"),            // usr
            _start:      APR_01_2023,                                    // bgn
            _cliff:      APR_01_2023,                                    // clf
            _end:        APR_01_2024,                                    // fin
            _days:       367 days,                                       // fin
            _manager:    address(0),                                     // mgr
            _restricted: 1,                                              // res
            _reward:     204_000 * WAD,                                  // tot
            _claimed:    0                                               // rxd
        });

        // Give admin powers to Test contract address and make the vesting unrestricted for testing
        GodMode.setWard(address(vest), address(this), 1);
        uint256 prevPhoenixBalance = dai.balanceOf(wallets.addr("PHOENIX_LABS_STREAM"));

        vest.unrestrict(22);
        vm.warp(APR_01_2023 + 367 days);
        vest.vest(22);
        assertEq(dai.balanceOf(wallets.addr("PHOENIX_LABS_STREAM")), prevPhoenixBalance + 204_000 * WAD);

        assertTrue(vest.valid(23)); // check for valid contract
        _checkDaiVest({
            _index:      23,                                             // id
            _wallet:     wallets.addr("VIRIDIAN_STREAM"),                // usr
            _start:      APR_01_2023,                                    // bgn
            _cliff:      APR_01_2023,                                    // clf
            _end:        APR_01_2024,                                    // fin
            _days:       367 days,                                       // fin
            _manager:    address(0),                                     // mgr
            _restricted: 1,                                              // res
            _reward:     1_029_000 * WAD,                                // tot
            _claimed:    0                                               // rxd
        });

        // Give admin powers to Test contract address and make the vesting unrestricted for testing
        GodMode.setWard(address(vest), address(this), 1);
        uint256 prevViridianBalance = dai.balanceOf(wallets.addr("VIRIDIAN_STREAM"));

        vest.unrestrict(23);
        vm.warp(APR_01_2023 + 367 days);
        vest.vest(23);
        assertEq(dai.balanceOf(wallets.addr("VIRIDIAN_STREAM")), prevViridianBalance + 1_029_000 * WAD);

        assertTrue(vest.valid(24)); // check for valid contract
        _checkDaiVest({
            _index:      24,                                             // id
            _wallet:     wallets.addr("DEWIZ"),                          // usr
            _start:      APR_01_2023,                                    // bgn
            _cliff:      APR_01_2023,                                    // clf
            _end:        APR_01_2024,                                    // fin
            _days:       367 days,                                       // fin
            _manager:    address(0),                                     // mgr
            _restricted: 1,                                              // res
            _reward:     1_800_000 * WAD,                                // tot
            _claimed:    0                                               // rxd
        });

        // Give admin powers to Test contract address and make the vesting unrestricted for testing
        GodMode.setWard(address(vest), address(this), 1);
        uint256 prevDewizBalance = dai.balanceOf(wallets.addr("DEWIZ"));

        vest.unrestrict(24);
        vm.warp(APR_01_2023 + 367 days);
        vest.vest(24);
        assertEq(dai.balanceOf(wallets.addr("DEWIZ")), prevDewizBalance + 1_800_000 * WAD);

        assertTrue(vest.valid(25)); // check for valid contract
        _checkDaiVest({
            _index:      25,                                             // id
            _wallet:     wallets.addr("SIDESTREAM"),                     // usr
            _start:      APR_01_2023,                                    // bgn
            _cliff:      APR_01_2023,                                    // clf
            _end:        APR_01_2024,                                    // fin
            _days:       367 days,                                       // fin
            _manager:    address(0),                                     // mgr
            _restricted: 1,                                              // res
            _reward:     850_950 * WAD,                                  // tot
            _claimed:    0                                               // rxd
        });

        // Give admin powers to Test contract address and make the vesting unrestricted for testing
        GodMode.setWard(address(vest), address(this), 1);
        uint256 prevSidestreamBalance = dai.balanceOf(wallets.addr("SIDESTREAM"));

        vest.unrestrict(25);
        vm.warp(APR_01_2023 + 367 days);
        vest.vest(25);
        assertEq(dai.balanceOf(wallets.addr("SIDESTREAM")), prevSidestreamBalance + 850_950 * WAD);
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
        Payee[18] memory payees = [
            // DELEGATE PAYMENTS
            Payee(wallets.addr("COLDIRON"),              10_452),
            Payee(wallets.addr("FLIPFLOPFLAP"),          10_452),
            Payee(wallets.addr("GFXLABS"),               10_452),
            Payee(wallets.addr("MHONKASALOTEEMULAU"),     9_929),
            Payee(wallets.addr("PENNBLOCKCHAIN"),         9_568),
            Payee(wallets.addr("FEEDBLACKLOOPS"),         9_408),
            Payee(wallets.addr("STABLELAB"),              3_282),
            Payee(wallets.addr("LBSBLOCKCHAIN"),          3_045),
            Payee(wallets.addr("HKUSTEPI"),               2_607),
            Payee(wallets.addr("JUSTINCASE"),             2_488),
            Payee(wallets.addr("FRONTIERRESEARCH"),       2_421),
            Payee(wallets.addr("CODEKNIGHT"),               630),
            Payee(wallets.addr("FLIPSIDE"),                 541),
            Payee(wallets.addr("ONESTONE"),                 314),
            Payee(wallets.addr("CONSENSYS"),                154),
            Payee(wallets.addr("ACREINVEST"),                33),
            // ECOSYSTEM ACTOR DAI TRANSFERS
            Payee(wallets.addr("PHOENIX_LABS_STREAM"),  347_100),
            Payee(wallets.addr("VIRIDIAN_TRANSFER"),    257_250)
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

    function testYankMKR() public { // make private to disable

        VestAbstract vestTreas = VestAbstract(addr.addr("MCD_VEST_MKR_TREASURY"));
        // VestAbstract vestMint  = VestAbstract(addr.addr("MCD_VEST_MKR"));

        assertGt(vestTreas.fin(18), block.timestamp);
        assertGt(vestTreas.fin(19), block.timestamp);
        assertGt(vestTreas.fin(30), block.timestamp);
        assertGt(vestTreas.fin(31), block.timestamp);

        _vote(address(spell));
        _scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        assertEq(vestTreas.fin(18), block.timestamp);
        assertEq(vestTreas.fin(19), block.timestamp);
        assertEq(vestTreas.fin(30), block.timestamp);
        assertEq(vestTreas.fin(31), block.timestamp);
    }

    function testVestMKR() public { // make private to disable
        VestAbstract vest = VestAbstract(addr.addr("MCD_VEST_MKR_TREASURY"));
        assertEq(vest.ids(), 31);

        uint256 prevAllowance = gov.allowance(pauseProxy, addr.addr("MCD_VEST_MKR_TREASURY"));

        _vote(address(spell));
        _scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        uint256 newAllowance = 690 ether; // Steakhouse
               newAllowance += 432 ether; // TECH
               newAllowance += 340 ether; // GovAlpha
               newAllowance += 180 ether; // BA Labs
               newAllowance += 252 ether; // Dewiz
               newAllowance += 120 ether; // Phoenix Labs

        assertEq(gov.allowance(pauseProxy, addr.addr("MCD_VEST_MKR_TREASURY")), prevAllowance + newAllowance);

        assertEq(vest.cap(), 1_100 * WAD / 365 days);
        assertEq(vest.ids(), 31 + 6);

        uint256 APR_01_2023 = 1680307200; // 01 Apr 2023 12:00:00 AM UTC
        uint256 MAR_31_2024 = 1711929599; // 31 Mar 2024 11:59:59 PM UTC
        uint256 APR_01_2024 = 1712015999; // 01 Apr 2024 11:59:59 PM UTC

        uint256 facilitator_FIN   = APR_01_2023 + (366 days) - 1; // -1 because we are going to 11:59:59 on Mar 31 24
        uint256 ecosystem_FIN     = APR_01_2023 + (367 days) - 1; // -1 because we are going to 11:59:59 on Apr 01 24

        assertEq(vest.usr(32), wallets.addr("STEAKHOUSE"));
        assertEq(vest.bgn(32), APR_01_2023);
        assertEq(vest.clf(32), APR_01_2023);
        assertEq(vest.fin(32), facilitator_FIN);
        assertEq(vest.fin(32), MAR_31_2024);
        assertEq(vest.mgr(32), address(0));
        assertEq(vest.res(32), 1);
        assertEq(vest.tot(32), 690 ether);
        assertEq(vest.rxd(32), 0);

        assertEq(vest.usr(33), wallets.addr("TECH"));
        assertEq(vest.bgn(33), APR_01_2023);
        assertEq(vest.clf(33), APR_01_2023);
        assertEq(vest.fin(33), facilitator_FIN);
        assertEq(vest.fin(33), MAR_31_2024);
        assertEq(vest.mgr(33), address(0));
        assertEq(vest.res(33), 1);
        assertEq(vest.tot(33), 432 ether);
        assertEq(vest.rxd(33), 0);

        assertEq(vest.usr(34), wallets.addr("GOV_ALPHA"));
        assertEq(vest.bgn(34), APR_01_2023);
        assertEq(vest.clf(34), APR_01_2023);
        assertEq(vest.fin(34), facilitator_FIN);
        assertEq(vest.fin(34), MAR_31_2024);
        assertEq(vest.mgr(34), address(0));
        assertEq(vest.res(34), 1);
        assertEq(vest.tot(34), 340 ether);
        assertEq(vest.rxd(34), 0);

        assertEq(vest.usr(35), wallets.addr("BA_LABS"));
        assertEq(vest.bgn(35), APR_01_2023);
        assertEq(vest.clf(35), APR_01_2023);
        assertEq(vest.fin(35), facilitator_FIN);
        assertEq(vest.fin(35), MAR_31_2024);
        assertEq(vest.mgr(35), address(0));
        assertEq(vest.res(35), 1);
        assertEq(vest.tot(35), 180 ether);
        assertEq(vest.rxd(35), 0);

        assertEq(vest.usr(36), wallets.addr("DEWIZ"));
        assertEq(vest.bgn(36), APR_01_2023);
        assertEq(vest.clf(36), APR_01_2023);
        assertEq(vest.fin(36), ecosystem_FIN);
        assertEq(vest.fin(36), APR_01_2024);
        assertEq(vest.mgr(36), address(0));
        assertEq(vest.res(36), 1);
        assertEq(vest.tot(36), 252 ether);
        assertEq(vest.rxd(36), 0);

        assertEq(vest.usr(37), wallets.addr("PHOENIX_LABS_STREAM"));
        assertEq(vest.bgn(37), APR_01_2023);
        assertEq(vest.clf(37), APR_01_2023);
        assertEq(vest.fin(37), ecosystem_FIN);
        assertEq(vest.fin(37), APR_01_2024);
        assertEq(vest.mgr(37), address(0));
        assertEq(vest.res(37), 1);
        assertEq(vest.tot(37), 120 ether);
        assertEq(vest.rxd(37), 0);

        uint256 prevBalance0 = gov.balanceOf(wallets.addr("STEAKHOUSE"));
        uint256 prevBalance1 = gov.balanceOf(wallets.addr("TECH"));
        uint256 prevBalance2 = gov.balanceOf(wallets.addr("GOV_ALPHA"));
        uint256 prevBalance3 = gov.balanceOf(wallets.addr("BA_LABS"));
        uint256 prevBalance4 = gov.balanceOf(wallets.addr("DEWIZ"));
        uint256 prevBalance5 = gov.balanceOf(wallets.addr("PHOENIX_LABS_STREAM"));

        // Give admin powers to test contract address and make the vesting unrestricted for testing
        GodMode.setWard(address(vest), address(this), 1);
        vest.unrestrict(32);
        vest.unrestrict(33);
        vest.unrestrict(34);
        vest.unrestrict(35);
        vest.unrestrict(36);
        vest.unrestrict(37);

        vm.warp(facilitator_FIN);

        vest.vest(32);
        assertEq(gov.balanceOf(wallets.addr("STEAKHOUSE")), prevBalance0 + 690 ether);

        vest.vest(33);
        assertEq(gov.balanceOf(wallets.addr("TECH")), prevBalance1 + 432 ether);

        vest.vest(34);
        assertEq(gov.balanceOf(wallets.addr("GOV_ALPHA")), prevBalance2 + 340 ether);

        vest.vest(35);
        assertEq(gov.balanceOf(wallets.addr("BA_LABS")), prevBalance3 + 180 ether);

        vm.warp(ecosystem_FIN);

        vest.vest(36);
        assertEq(gov.balanceOf(wallets.addr("DEWIZ")), prevBalance4 + 252 ether);

        vest.vest(37);
        assertEq(gov.balanceOf(wallets.addr("PHOENIX_LABS_STREAM")), prevBalance5 + 120 ether);
    }

    function testMKRPayments() public { // make private to disable
        uint256 prevMkrPause    = gov.balanceOf(address(pauseProxy));
        uint256 prevMkrGovAlpha = gov.balanceOf(wallets.addr("GOV_ALPHA"));

        uint256 amountGovAlpha = 226.64 ether;
        uint256 total          = 226.64 ether;

        _vote(address(spell));
        _scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        assertEq(gov.balanceOf(address(pauseProxy)), prevMkrPause - total);
        assertEq(gov.balanceOf(wallets.addr("GOV_ALPHA")), prevMkrGovAlpha + amountGovAlpha);
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

    function testNewModulesAuthorizingEsm() public {
        uint256 ward;
        address ESM = addr.addr("MCD_ESM");

        ward = WardsAbstract(addr.addr("MIP21_LIQUIDATION_ORACLE")).wards(ESM);
        assertEq(ward, 0, "unexpected ward");

        _vote(address(spell));
        _scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        ward = WardsAbstract(addr.addr("MIP21_LIQUIDATION_ORACLE")).wards(ESM);
        assertEq(ward, 1, "MIP21_LIQUIDATION_ORACLE does not authorize ESM");
    }
}
