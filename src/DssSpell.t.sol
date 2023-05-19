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

interface NetworkPaymentAdapterLike {
    function vestId() external view returns (uint256);
    function treasury() external view returns (address);
}
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
// interface RwaUrnLike {
//     function hope(address) external;
//     function draw(uint256) external;
// }

interface RwaLiquidationOracleLike {
    function ilks(bytes32) external view returns (string memory, address, uint48 toc, uint48 tau);
    function bump(bytes32 ilk, uint256 val) external;
    function tell(bytes32) external;
    function cure(bytes32) external;
    function cull(bytes32, address) external;
    function good(bytes32) external view returns (bool);
}

interface RwaUrnLike {
    function wards(address) external view returns (uint256);
    function can(address) external view returns (uint256);
    function gemJoin() external view returns (GemAbstract);
    function lock(uint256) external;
    function draw(uint256) external;
    function wipe(uint256) external;
    function free(uint256) external;
}

interface RwaOutputConduitLike {
    function wards(address) external view returns (uint256);
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
    function quitTo() external view returns (address);
}

interface RwaInputConduitLike {
    function wards(address) external view returns (uint256);
    function may(address) external view returns (uint256);
    function quitTo() external view returns (address);
    function mate(address) external;
    function push() external;
}

interface PoolLike {
    struct ReserveData {
        //stores the reserve configuration
        uint256 configuration;
        //the liquidity index. Expressed in ray
        uint128 liquidityIndex;
        //the current supply rate. Expressed in ray
        uint128 currentLiquidityRate;
        //variable borrow index. Expressed in ray
        uint128 variableBorrowIndex;
        //the current variable borrow rate. Expressed in ray
        uint128 currentVariableBorrowRate;
        //the current stable borrow rate. Expressed in ray
        uint128 currentStableBorrowRate;
        //timestamp of last update
        uint40 lastUpdateTimestamp;
        //the id of the reserve. Represents the position in the list of the active reserves
        uint16 id;
        //aToken address
        address aTokenAddress;
        //stableDebtToken address
        address stableDebtTokenAddress;
        //variableDebtToken address
        address variableDebtTokenAddress;
        //address of the interest rate strategy
        address interestRateStrategyAddress;
        //the current treasury balance, scaled
        uint128 accruedToTreasury;
        //the outstanding unbacked aTokens minted through the bridging feature
        uint128 unbacked;
        //the outstanding debt borrowed against this asset in isolation mode
        uint128 isolationModeTotalDebt;
    }
    function getReserveData(address asset) external view returns (ReserveData memory);
    function supply(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;
    function borrow(
        address asset,
        uint256 amount,
        uint256 interestRateMode,
        uint16 referralCode,
        address onBehalfOf
    ) external;
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

         // RWA014
        // _checkChainlogKey("RWA014_A_JAR");
        // _checkChainlogKey("RWA014");
        // _checkChainlogKey("MCD_JOIN_RWA014_A");
        // _checkChainlogKey("RWA014_A_URN");
        // _checkChainlogKey("RWA014_A_INPUT_CONDUIT_URN");
        // _checkChainlogKey("RWA014_A_INPUT_CONDUIT_JAR");
        // _checkChainlogKey("RWA014_A_OUTPUT_CONDUIT");
        // _checkChainlogKey("PIP_RWA014");

        _checkChainlogVersion("1.14.12");
    }

    function testNewIlkRegistryValues() public { // make private to disable
        _vote(address(spell));
        _scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        // Insert new ilk registry values tests here
        // RWA014
        // assertEq(reg.pos("RWA014-A"),    61);
        // assertEq(reg.join("RWA014-A"),   addr.addr("MCD_JOIN_RWA014_A"));
        // assertEq(reg.gem("RWA014-A"),    addr.addr("RWA014"));
        // assertEq(reg.dec("RWA014-A"),    GemAbstract(addr.addr("RWA014")).decimals());
        // assertEq(reg.class("RWA014-A"),  3);
        // assertEq(reg.pip("RWA014-A"),    addr.addr("PIP_RWA014"));
        // assertEq(reg.name("RWA014-A"),   "RWA014-A: Coinbase Custody");
        // assertEq(reg.symbol("RWA014-A"), GemAbstract(addr.addr("RWA014")).symbol());
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
            Payee(wallets.addr("ECOSYSTEM_SCOPE_WALLET"), 100_000)
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

    function testYankDAI() public { // make private to disable
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

    function testMKRPayments() private { // make public to enable
        // For each payment, create a Payee object with
        //    the Payee address,
        //    the amount to be paid
        // Initialize the array with the number of payees
        Payee[12] memory payees = [
            Payee(wallets.addr("DEFENSOR"),         23.8 ether), // note: ether is a keyword helper, only MKR is transferred here
            Payee(wallets.addr("BONAPUBLICA"),      23.8 ether), // note: ether is a keyword helper, only MKR is transferred here
            Payee(wallets.addr("FRONTIERRESEARCH"), 23.8 ether), // note: ether is a keyword helper, only MKR is transferred here
            Payee(wallets.addr("GFXLABS_2"),        23.8 ether), // note: ether is a keyword helper, only MKR is transferred here
            Payee(wallets.addr("QGOV"),             23.8 ether), // note: ether is a keyword helper, only MKR is transferred here
            Payee(wallets.addr("TRUENAME"),         23.8 ether), // note: ether is a keyword helper, only MKR is transferred here
            Payee(wallets.addr("VIGILANT"),         23.8 ether), // note: ether is a keyword helper, only MKR is transferred here
            Payee(wallets.addr("CODEKNIGHT"),       5.95 ether), // note: ether is a keyword helper, only MKR is transferred here
            Payee(wallets.addr("FLIPFLOPFLAP_2"),   5.95 ether), // note: ether is a keyword helper, only MKR is transferred here
            Payee(wallets.addr("PBG"),              5.95 ether), // note: ether is a keyword helper, only MKR is transferred here
            Payee(wallets.addr("UPMAKER"),          5.95 ether), // note: ether is a keyword helper, only MKR is transferred here
            Payee(wallets.addr("DIN_WALLET"),       103.16 ether) // note: ether is a keyword helper, only MKR is transferred here
        ];

        // Calculate and save previous balances
        uint256 totalAmountToTransfer;
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

    function testDssCronPaymentAdaptersParams() public {
        VestAbstract vest = VestAbstract(addr.addr("MCD_VEST_DAI"));

        // Store previous amount of streams
        uint256 prevStreamCount = vest.ids();

        uint256 gelatoVestId = prevStreamCount + 1;
        uint256 keeperVestId = prevStreamCount + 2;
        uint256 chainlinkVestId = prevStreamCount + 3;

        _vote(address(spell));
        _scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());


        require(NetworkPaymentAdapterLike(wallets.addr("GELATO_PAYMENT_ADAPTER")).vestId() == gelatoVestId, "Gelato/incorrect-vestId");
        require(NetworkPaymentAdapterLike(wallets.addr("GELATO_PAYMENT_ADAPTER")).treasury() == wallets.addr("GELATO_TREASURY"), "Gelato/incorrect-treasury");

        require(NetworkPaymentAdapterLike(wallets.addr("KEEP3R_PAYMENT_ADAPTER")).vestId() == keeperVestId, "Keeper/incorrect-vestId");
        require(NetworkPaymentAdapterLike(wallets.addr("KEEP3R_PAYMENT_ADAPTER")).treasury() == wallets.addr("KEEP3R_TREASURY"), "Keeper/incorrect-treasury");

        require(NetworkPaymentAdapterLike(wallets.addr("CHAINLINK_PAYMENT_ADAPTER")).vestId() == chainlinkVestId, "Chainlionk/incorrect-vestId");
    }

    // RWA tests

    // address RWA014_A_OPERATOR                  = addr.addr("RWA014_A_OPERATOR");
    // address RWA014_A_COINBASE_CUSTODY          = addr.addr("RWA014_A_COINBASE_CUSTODY");
    
    // address ESM                                = addr.addr("MCD_ESM");
    // RwaLiquidationOracleLike oracle            = RwaLiquidationOracleLike(addr.addr("MIP21_LIQUIDATION_ORACLE"));

    // GemAbstract          rwagem_014            = GemAbstract(addr.addr("RWA014"));
    // GemJoinAbstract      rwajoin_014           = GemJoinAbstract(addr.addr("MCD_JOIN_RWA014_A"));
    // RwaUrnLike           rwaurn_014            = RwaUrnLike(addr.addr("RWA014_A_URN"));
    // RwaOutputConduitLike rwaconduitout_014     = RwaOutputConduitLike(addr.addr("RWA014_A_OUTPUT_CONDUIT"));
    // GemAbstract          psmGem                = rwaconduitout_014.gem();
    // RwaInputConduitLike  rwaconduitinurn_014   = RwaInputConduitLike(addr.addr("RWA014_A_INPUT_CONDUIT_URN"));
    // RwaInputConduitLike  rwaconduitinjar_014   = RwaInputConduitLike(addr.addr("RWA014_A_INPUT_CONDUIT_JAR"));
    // uint256 daiPsmGemDiffDecimals              = 10 ** (dai.decimals() - psmGem.decimals());

    // function testRWA014_INTEGRATION_CONDUITS_SETUP() public {
    //     _vote(address(spell));
    //     _scheduleWaitAndCast(address(spell));
    //     assertTrue(spell.done());

    //     assertEq(rwaconduitout_014.wards(ESM), 1, "OutputConduit/ward-esm-not-set");
    //     assertEq(rwaconduitout_014.can(pauseProxy), 1, "OutputConduit/pause-proxy-not-operator");
    //     assertEq(rwaconduitout_014.can(RWA014_A_OPERATOR), 1, "OutputConduit/monetalis-not-operator");
    //     assertEq(rwaconduitout_014.may(pauseProxy), 1, "OutputConduit/pause-proxy-not-mate");
    //     assertEq(rwaconduitout_014.may(RWA014_A_OPERATOR), 1, "OutputConduit/monetalis-not-mate");
    //     assertEq(rwaconduitout_014.quitTo(), address(rwaurn_014), "OutputConduit/quit-to-not-urn");     
    //     assertEq(rwaconduitout_014.bud(RWA014_A_COINBASE_CUSTODY), 1, "OutputConduit/coinbase-custody-not-whitelisted-for-pick");

    //     assertEq(rwaconduitinurn_014.wards(ESM), 1, "InputConduitUrn/ward-esm-not-set");
    //     assertEq(rwaconduitinurn_014.may(pauseProxy), 1, "InputConduitUrn/pause-proxy-not-mate");
    //     assertEq(rwaconduitinurn_014.may(RWA014_A_OPERATOR), 1, "InputConduitUrn/monetalis-not-mate");
    //     assertEq(rwaconduitinurn_014.quitTo(), RWA014_A_COINBASE_CUSTODY, "InputConduitUrn/quit-to-not-set");

    //     assertEq(rwaconduitinjar_014.wards(ESM), 1, "InputConduitJar/ward-esm-not-set");
    //     assertEq(rwaconduitinjar_014.may(pauseProxy), 1, "InputConduitJar/pause-proxy-not-mate");
    //     assertEq(rwaconduitinjar_014.may(RWA014_A_OPERATOR), 1, "InputConduitJar/monetalis-not-mate");
    //     assertEq(rwaconduitinjar_014.quitTo(), RWA014_A_COINBASE_CUSTODY, "InputConduitJar/quit-to-not-set");

    //     assertEq(rwajoin_014.wards(address(rwaurn_014)), 1, "Join/ward-urn-not-set");
    //     assertEq(rwajoin_014.wards(ESM), 1, "Join/ward-esm-not-set");

    //     assertEq(rwaurn_014.wards(ESM), 1, "Urn/ward-esm-not-set");
    //     assertEq(rwaurn_014.can(pauseProxy), 1, "Urn/pause-proxy-not-hoped");
    //     assertEq(rwaurn_014.can(RWA014_A_OPERATOR), 1, "Urn/operator-not-hoped");
    // }

    // function testRWA014_INTEGRATION_BUMP() public {
    //     _vote(address(spell));
    //     _scheduleWaitAndCast(address(spell));
    //     assertTrue(spell.done());

    //     GodMode.setWard(address(oracle), address(this), 1);

    //     (, address pip, , ) = oracle.ilks("RWA014-A");

    //     assertEq(DSValueAbstract(pip).read(), bytes32(500 * MILLION * WAD), "RWA014: Bad initial PIP value");

    //     oracle.bump("RWA014-A", 510 * MILLION * WAD);

    //     assertEq(DSValueAbstract(pip).read(), bytes32(510 * MILLION * WAD), "RWA014: Bad PIP value after bump()");
    // }

    // function testRWA014_INTEGRATION_TELL() public {
    //     _vote(address(spell));
    //     _scheduleWaitAndCast(address(spell));
    //     assertTrue(spell.done());

    //     GodMode.setWard(address(vat), address(this), 1);
    //     GodMode.setWard(address(oracle), address(this), 1);

    //     (, , , uint48 tocPre) = oracle.ilks("RWA014-A");
    //     assertEq(uint256(tocPre), 0, "RWA014: `toc` is not 0 before tell()");
    //     assertTrue(oracle.good("RWA014-A"), "RWA014: Oracle not good before tell()");

    //     vat.file("RWA014-A", "line", 0);
    //     oracle.tell("RWA014-A");

    //     (, , , uint48 tocPost) = oracle.ilks("RWA014-A");
    //     assertGt(uint256(tocPost), 0, "RWA014: `toc` is not set after tell()");
    //     assertTrue(!oracle.good("RWA014-A"), "RWA014: Oracle still good after tell()");
    // }

    // function testRWA014_INTEGRATION_TELL_CURE_GOOD() public {
    //     _vote(address(spell));
    //     _scheduleWaitAndCast(address(spell));
    //     assertTrue(spell.done());

    //     GodMode.setWard(address(vat), address(this), 1);
    //     GodMode.setWard(address(oracle), address(this), 1);

    //     vat.file("RWA014-A", "line", 0);
    //     oracle.tell("RWA014-A");

    //     assertTrue(!oracle.good("RWA014-A"), "RWA014: Oracle still good after tell()");

    //     oracle.cure("RWA014-A");

    //     assertTrue(oracle.good("RWA014-A"), "RWA014: Oracle not good after cure()");
    //     (, , , uint48 toc) = oracle.ilks("RWA014-A");
    //     assertEq(uint256(toc), 0, "RWA014: `toc` not zero after cure()");
    // }

    // function testFailRWA014_INTEGRATION_CURE_BEFORE_TELL() public {
    //     _vote(address(spell));
    //     _scheduleWaitAndCast(address(spell));
    //     assertTrue(spell.done());

    //     GodMode.setWard(address(oracle), address(this), 1);

    //     oracle.cure("RWA014-A");
    // }

    // function testRWA014_INTEGRATION_TELL_CULL() public {
    //     _vote(address(spell));
    //     _scheduleWaitAndCast(address(spell));
    //     assertTrue(spell.done());

    //     GodMode.setWard(address(vat), address(this), 1);
    //     GodMode.setWard(address(oracle), address(this), 1);

    //     assertTrue(oracle.good("RWA014-A"));

    //     vat.file("RWA014-A", "line", 0);
    //     oracle.tell("RWA014-A");

    //     assertTrue(!oracle.good("RWA014-A"), "RWA014: Oracle still good after tell()");

    //     oracle.cull("RWA014-A", addr.addr("RWA014_A_URN"));

    //     assertTrue(!oracle.good("RWA014-A"), "RWA014: Oracle still good after cull()");
    //     (, address pip, , ) = oracle.ilks("RWA014-A");
    //     assertEq(DSValueAbstract(pip).read(), bytes32(0), "RWA014: Oracle PIP value not set to zero after cull()");
    // }

    // function testRWA014_PAUSE_PROXY_OWNS_RWA014_TOKEN_BEFORE_SPELL() public {
    //     assertEq(rwagem_014.balanceOf(addr.addr('MCD_PAUSE_PROXY')), 1 * WAD);
    // }

    // function testRWA014_SPELL_LOCK_OPERATOR_DRAW_WIPE_FREE() public {
    //     _vote(address(spell));
    //     _scheduleWaitAndCast(address(spell));
    //     assertTrue(spell.done());

    //     uint256 drawAmount = 500_000_000 * WAD;

    //     // setting address(this) as operator
    //     vm.store(address(rwaurn_014), keccak256(abi.encode(address(this), uint256(1))), bytes32(uint256(1)));
    //     assertEq(rwaurn_014.can(address(this)), 1);

    //     // Check if spell lock 1 * WAD of RWA009
    //     assertEq(rwagem_014.balanceOf(addr.addr('MCD_PAUSE_PROXY')), 0, "RWA014: gem not transfered from the pause proxy");
    //     assertEq(rwagem_014.balanceOf(address(rwajoin_014)), 1 * WAD, "RWA014: gem not locked into the urn");

    //     // 0 DAI in Output Conduit
    //     assertEq(dai.balanceOf(address(rwaconduitout_014)), 0, "RWA014: Dangling Dai in input conduit before draw()");

    //     // Draw 500mm
    //     rwaurn_014.draw(drawAmount);

    //     // 1mm DAI in Output Conduit
    //     assertEq(dai.balanceOf(address(rwaconduitout_014)), drawAmount, "RWA014: Dai drawn was not send to the recipient");

    //     (uint256 ink, uint256 art) = vat.urns("RWA014-A", address(rwaurn_014));
    //     assertEq(art, drawAmount, "RWA014: bad `art` after spell"); // DAI drawn == art as rate should always be 1 RAY
    //     assertEq(ink, 1 * WAD, "RWA014: bad `ink` after spell"); // Whole unit of collateral is locked

    //     vm.warp(block.timestamp + 10 days);
    //     jug.drip("RWA014-A");

    //     (, uint256 rate,,,) = vat.ilks("RWA014-A");
    //     assertEq(rate, RAY, 'RWA014: bad `rate`'); // rate keeps being 1 RAY

    //     // wards
    //     GodMode.setWard(address(rwaconduitout_014), address(this), 1);
    //     // may
    //     rwaconduitout_014.mate(address(this));
    //     assertEq(rwaconduitout_014.may(address(this)), 1);
    //     rwaconduitout_014.hope(address(this));
    //     assertEq(rwaconduitout_014.can(address(this)), 1);

    //     rwaconduitout_014.kiss(address(this));
    //     assertEq(rwaconduitout_014.bud(address(this)), 1);
    //     rwaconduitout_014.pick(address(this));

    //     uint256 pushAmount = 100 * WAD; // We push only 100 DAI on Görli
    //     rwaconduitout_014.push(pushAmount);
    //     rwaconduitout_014.quit();

    //     assertEq(dai.balanceOf(address(rwaconduitout_014)), 0, "RWA014: Output conduit still holds Dai after quit()");
    //     assertEq(psmGem.balanceOf(address(this)), pushAmount / daiPsmGemDiffDecimals, "RWA014: Psm GEM not sent to destination after push()");
    //     assertEq(dai.balanceOf(address(rwaurn_014)), drawAmount - pushAmount, "RWA014: Dai not sent to destination after push()");

    //     // as we have SF 0 we need to pay exectly the same amount of DAI we have drawn
    //     uint256 daiToPay = drawAmount;

    //     // // wards
    //     // GodMode.setWard(address(rwaconduitinurn_014), address(this), 1);
    //     // // may
    //     // rwaconduitinurn_014.mate(address(this));
    //     // assertEq(rwaconduitinurn_014.may(address(this)), 1);

    //     // transfer PSM GEM to input conduit
    //     psmGem.transfer(address(rwaconduitinurn_014), pushAmount / daiPsmGemDiffDecimals);
    //     assertEq(psmGem.balanceOf(address(rwaconduitinurn_014)), pushAmount / daiPsmGemDiffDecimals, "RWA014: Psm GEM not sent to input conduit");
        
    //     // input conduit 'push()' to the urn
    //     rwaconduitinurn_014.push();

    //     assertEq(dai.balanceOf(address(rwaurn_014)), daiToPay, "Balance of the URN doesnt match");

    //     // repay debt and free our collateral
    //     rwaurn_014.wipe(daiToPay);
    //     rwaurn_014.free(1 * WAD);

    //     // check if we get back RWA009 Tokens
    //     assertEq(rwagem_014.balanceOf(address(this)), 1 * WAD, "RWA014: gem not sent back to the caller");

    //     // check if we have 0 collateral and outstanding debt in the VAT
    //     (ink, art) = vat.urns("RWA014-A", address(rwaurn_014));
    //     assertEq(ink, 0, "RWA014: bad `ink` after free()");
    //     assertEq(art, 0, "RWA014: bad `art` after wipe()");
    // }

    // function testFailRWA014_DRAW_ABOVE_LINE() public {
    //     _vote(address(spell));
    //     _scheduleWaitAndCast(address(spell));
    //     assertTrue(spell.done());

    //     uint256 drawAmount = 500_000_001 * WAD;

    //     // setting address(this) as operator
    //     vm.store(address(rwaurn_014), keccak256(abi.encode(address(this), uint256(1))), bytes32(uint256(1)));

    //     // Draw 2mm
    //     rwaurn_014.draw(drawAmount);
    // }

    // function testFailRWA014_PUSH_ABOVE_LINE() public {
    //     _vote(address(spell));
    //     _scheduleWaitAndCast(address(spell));
    //     assertTrue(spell.done());

    //     uint256 drawAmount = 1_000_000 * WAD;

    //     // setting address(this) as operator
    //     vm.store(address(rwaurn_014), keccak256(abi.encode(address(this), uint256(1))), bytes32(uint256(1)));

    //     // Draw 1mm
    //     rwaurn_014.draw(drawAmount);

    //     // auth
    //     GodMode.setWard(address(rwaconduitout_014), address(this), 1);

    //     // pick address(this)
    //     rwaconduitout_014.hope(address(this)); // allow this to call pick
    //     rwaconduitout_014.kiss(address(this)); // allow this to be picked
    //     rwaconduitout_014.pick(address(this));

    //     // push above line
    //     uint256 pushAmount = 2_000_000 * WAD;
    //     rwaconduitout_014.mate(address(this)); // allow this to call push
    //     rwaconduitout_014.push(pushAmount);    // fail
    // }

    // function testRWA014_OPERATOR_LOCK_DRAW_CAGE() public {
    //     _vote(address(spell));
    //     _scheduleWaitAndCast(address(spell));
    //     assertTrue(spell.done());

    //     uint256 drawAmount = 1_000_000 * WAD;

    //     // setting address(this) as operator
    //     vm.store(address(rwaurn_014), keccak256(abi.encode(address(this), uint256(1))), bytes32(uint256(1)));
    //     assertEq(rwaurn_014.can(address(this)), 1);

    //     // Check if spell lock 1 * WAD of RWA009
    //     assertEq(rwagem_014.balanceOf(addr.addr('MCD_PAUSE_PROXY')), 0, "RWA014: gem not transfered from the pause proxy");
    //     assertEq(rwagem_014.balanceOf(address(rwajoin_014)), 1 * WAD, "RWA014: gem not locked into the urn");

    //     // 0 DAI in Output Conduit
    //     assertEq(dai.balanceOf(address(rwaconduitout_014)), 0, "RWA014: Dangling Dai in input conduit before draw()");

    //     // Draw 500mm
    //     rwaurn_014.draw(drawAmount);

    //     // 500mm DAI in Output Conduit
    //     assertEq(dai.balanceOf(address(rwaconduitout_014)), drawAmount, "RWA014: Dai drawn was not send to the recipient");

    //     (uint256 ink, uint256 art) = vat.urns("RWA014-A", address(rwaurn_014));
    //     assertEq(art, drawAmount, "RWA014: bad `art` after spell"); // DAI drawn == art as rate should always be 1 RAY
    //     assertEq(ink, 1 * WAD, "RWA014: bad `ink` after spell"); // Whole unit of collateral is locked

    //     vm.warp(block.timestamp + 10 days);
    //     jug.drip("RWA014-A");

    //     (, uint256 rate,,,) = vat.ilks("RWA014-A");
    //     assertEq(rate, RAY, 'RWA014: bad `rate`'); // rate keeps being 1 RAY

    //     // wards
    //     GodMode.setWard(address(rwaconduitout_014), address(this), 1);
    //     // may
    //     rwaconduitout_014.mate(address(this));
    //     rwaconduitout_014.hope(address(this));

    //     rwaconduitout_014.kiss(address(this));
    //     assertEq(rwaconduitout_014.bud(address(this)), 1);
    //     rwaconduitout_014.pick(address(this));

    //     uint256 pushAmount = 100 * WAD; // We push only 100 DAI on Görli
    //     rwaconduitout_014.push(pushAmount);
    //     rwaconduitout_014.quit();

    //     assertEq(dai.balanceOf(address(rwaconduitout_014)), 0, "RWA014: Output conduit still holds Dai after quit()");
    //     assertEq(psmGem.balanceOf(address(this)), pushAmount / daiPsmGemDiffDecimals, "RWA014: Psm GEM not sent to destination after push()");
    //     assertEq(dai.balanceOf(address(rwaurn_014)), drawAmount - pushAmount, "RWA014: Dai not sent to destination after push()");

    //     // END
    //     GodMode.setWard(address(end), address(this), 1);
    //     end.cage();
    //     end.cage("RWA014-A");

    //     end.skim("RWA014-A", address(rwaurn_014));

    //     (ink, art) = vat.urns("RWA014-A", address(rwaurn_014));
    //     uint256 skimmedInk = drawAmount / 500_000_000;
    //     assertEq(ink, 1 * WAD - skimmedInk, "RWA014: wrong ink in urn after skim");
    //     assertEq(art, 0, "RWA014: wrong art in urn after skim");
    //     vm.warp(block.timestamp + end.wait());

    //     // Removing the surplus to allow continuing the execution.
    //     vm.store(
    //         address(vat),
    //         keccak256(abi.encode(address(vow), uint256(5))),
    //         bytes32(uint256(0))
    //     );

    //     end.thaw();

    //     end.flow("RWA014-A");

    //     GodMode.setBalance(address(dai), address(this), 1_000_000 * WAD);
    //     dai.approve(address(daiJoin), 1_000_000 * WAD);
    //     daiJoin.join(address(this), 1_000_000 * WAD);

    //     vat.hope(address(end));
    //     end.pack(1_000_000 * WAD);

    //     // Check DAI redemption after "cage()"
    //     assertEq(vat.gem("RWA014-A", address(this)), 0, "RWA014: wrong vat gem");
    //     assertEq(rwagem_014.balanceOf(address(this)), 0, "RWA014: wrong gem balance");
    //     end.cash("RWA014-A", 1_000_000 * WAD);
    //     assertGt(vat.gem("RWA014-A", address(this)), 0, "RWA014: wrong vat gem after cash");
    //     assertEq(rwagem_014.balanceOf(address(this)), 0, "RWA014: wrong gem balance after cash");
    //     rwajoin_014.exit(address(this), vat.gem("RWA014-A", address(this)));
    //     assertEq(vat.gem("RWA014-A", address(this)), 0, "RWA014: wrong vat gem after exit");
    //     assertGt(rwagem_014.balanceOf(address(this)), 0, "RWA014: wrong gem balance after exit");
    // }

    // function testRWA014_SPELL_LOCK() public {
    //     (uint256 pink, uint256 part) = vat.urns("RWA014-A", address(rwaurn_014));
    //     uint256 prevBalance = rwagem_014.balanceOf(address(rwaurn_014.gemJoin()));

    //     assertEq(part, 0, "RWA014/bad-art-before-spell");
    //     assertEq(pink, 0, "RWA014/bad-ink-before-spell");

    //     uint256 lockAmount = 1 * WAD;

    //     _vote(address(spell));
    //     _scheduleWaitAndCast(address(spell));
    //     assertTrue(spell.done());

    //     // Check if spell lock whole unit of RWA014 Token to the Urn
    //     assertEq(rwagem_014.balanceOf(address(rwaurn_014.gemJoin())), prevBalance + lockAmount, "RWA014/spell-do-not-lock-rwa014-token");
        
    //     (uint256 ink, uint256 art) = vat.urns("RWA014-A", address(rwaurn_014));
    //     assertEq(art, 0, "RWA014/bad-art-after-spell");
    //     assertEq(ink, lockAmount, "RWA014/bad-ink-after-spell"); // Whole unit of collateral is locked
    // }

    function testSparkLendCollateralOnboarding() public {
        // Configuration masking parameters pulled from https://github.com/aave/aave-v3-core/blob/62dfda56bd884db2c291560c03abae9727a7635e/contracts/protocol/libraries/configuration/ReserveConfiguration.sol
        uint256 BORROWABLE_IN_ISOLATION_MASK = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFDFFFFFFFFFFFFFFF;
        PoolLike pool = PoolLike(0xC13e21B648A5Ee794902342038FF3aDAB66BE987);
        address token = addr.addr("GNO");
        MedianAbstract medianizer = MedianAbstract(0x31BFA908637C29707e155Cfac3a50C9823bF8723);
        address oracleAdapter = 0xe7fB468e1514267B2c92074852FDe750C6e97668;
        address interestRateStrategy = 0x554265A713D6746A62d86A797254590784D436AA;
        address wstETH = 0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0;

        PoolLike.ReserveData memory daiReserveData = pool.getReserveData(address(dai));
        PoolLike.ReserveData memory tokenReserveData = pool.getReserveData(token);
        assertEq((daiReserveData.configuration & ~BORROWABLE_IN_ISOLATION_MASK) != 0, false);
        assertTrue(tokenReserveData.aTokenAddress == address(0));   // Not set yet
        assertEq(medianizer.bud(oracleAdapter), 0);

        _vote(address(spell));
        _scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        daiReserveData = pool.getReserveData(address(dai));
        tokenReserveData = pool.getReserveData(token);
        assertEq((daiReserveData.configuration & ~BORROWABLE_IN_ISOLATION_MASK) != 0, true);
        assertTrue(tokenReserveData.aTokenAddress != address(0));
        assertEq(tokenReserveData.interestRateStrategyAddress, interestRateStrategy);
        assertEq(medianizer.bud(oracleAdapter), 1);

        // Integration test - take out a maximum loan

        // Make sure there is enough liquidity to borrow
        deal(address(dai), address(123), 50 * MILLION * WAD);
        vm.prank(address(123)); dai.approve(address(pool), type(uint256).max);
        vm.prank(address(123)); pool.supply(address(dai), 50 * MILLION * WAD, address(123), 0);

        deal(token, address(this), 50 * MILLION * WAD);
        GemAbstract(token).approve(address(pool), type(uint256).max);

        pool.supply(token, 50 * MILLION * WAD, address(this), 0);
        pool.borrow(address(dai), 4 * MILLION * WAD, 2, 0, address(this));
        vm.expectRevert(bytes('53'));   // 'Debt ceiling is exceeded'
        pool.borrow(address(dai), 1_100_000 * WAD, 2, 0, address(this));    // Over 5m limit
        vm.expectRevert(bytes('60'));   // 'Asset is not borrowable in isolation mode'
        pool.borrow(wstETH, 1 ether, 2, 0, address(this));  // Can't borrow another asset in isolation mode (wstETH)
    }
}
