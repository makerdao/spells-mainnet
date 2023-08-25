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
    function ilks(bytes32 ilk) external view returns (string memory doc, address pip, uint48 tau, uint48 toc);
    function good(bytes32 ilk) external view returns (bool);
}

interface RwaInputConduitLike {
    function dai() external view returns (address);
    function gem() external view returns (address);
    function psm() external view returns (address);
    function to() external view returns (address);
    function wards(address) external view returns (uint256);
    function may(address) external view returns (uint256);
    function quitTo() external view returns (address);
    function mate(address) external;
    function push() external;
}

interface ProxyLike {
    function exec(address target, bytes calldata args) external payable returns (bytes memory out);
}

interface ERC20Proxy {
    function erc20Impl() external returns (address);

    function totalSupply() external returns (uint256);
}

interface ERC20Impl {
    function erc20Store() external returns (address);
}

interface ERC20Store {
    function setTotalSupply(uint256 _newTotalSupply) external;

    function setBalance(address _owner, uint256 _newBalance) external;
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

    function testRemoveChainlogValues() public { // make private to disable
        _vote(address(spell));
        _scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        try chainLog.getAddress("FLIPPER_MOM") {
            assertTrue(false);
        } catch Error(string memory errmsg) {
            assertTrue(_cmpStr(errmsg, "dss-chain-log/invalid-key"));
        } catch {
            assertTrue(false);
        }

        try chainLog.getAddress("FLIP_FAB") {
            assertTrue(false);
        } catch Error(string memory errmsg) {
            assertTrue(_cmpStr(errmsg, "dss-chain-log/invalid-key"));
        } catch {
            assertTrue(false);
        }

        try chainLog.getAddress("RWA015_A_INPUT_CONDUIT_URN") {
            assertTrue(false);
        } catch Error(string memory errmsg) {
            assertTrue(_cmpStr(errmsg, "dss-chain-log/invalid-key"));
        } catch {
            assertTrue(false);
        }

        try chainLog.getAddress("RWA015_A_INPUT_CONDUIT_JAR") {
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

    function testNewChainlogValues() public { // make private to disable
        _vote(address(spell));
        _scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        _checkChainlogKey("RWA015_A_INPUT_CONDUIT_URN_GUSD");
        _checkChainlogKey("RWA015_A_INPUT_CONDUIT_JAR_GUSD");
        _checkChainlogKey("RWA015_A_INPUT_CONDUIT_URN_PAX");
        _checkChainlogKey("RWA015_A_INPUT_CONDUIT_JAR_PAX");
        _checkChainlogKey("RWA015_A_INPUT_CONDUIT_URN_USDC");
        _checkChainlogKey("RWA015_A_INPUT_CONDUIT_JAR_USDC");
        _checkChainlogVersion("1.16.0");
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
        // 2023-07-01 00:00:00 UTC
        uint256 JUL_01_2023 = 1688169600;
        // 2024-06-30 23:59:59 UTC
        uint256 JUN_30_2024 = 1719791999;
        // 2024-12-31 23:59:59 UTC
        uint256 DEC_31_2024 = 1735689599;

        uint256 prevBalance;

        // Store previous amount of streams
        uint256 prevStreamCount = vest.ids();

        // Cast the spell
        _vote(address(spell));
        _scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        // Check that 2 new streams are added
        assertEq(vest.ids(), prevStreamCount + 2);

        // Check the first stream
        uint256 chronicleStreamId = prevStreamCount + 1;
        assertTrue(vest.valid(chronicleStreamId)); // check for valid contract
        _checkDaiVest({
            _index:      chronicleStreamId,                              // id
            _wallet:     wallets.addr("CHRONICLE_LABS"),                 // usr
            _start:      JUL_01_2023,                                    // bgn
            _cliff:      JUL_01_2023,                                    // clf
            _end:        JUN_30_2024,                                    // fin
            _days:       366 days,                                       // fin
            _manager:    address(0),                                     // mgr
            _restricted: 1,                                              // res
            _reward:     3_721_800 * WAD,                                // tot
            _claimed:    0                                               // rxd
        });
        GodMode.setWard(address(vest), address(this), 1);
        prevBalance = dai.balanceOf(wallets.addr("CHRONICLE_LABS"));
        vest.unrestrict(chronicleStreamId);
        vm.warp(JUL_01_2023 + 366 days);
        vest.vest(chronicleStreamId);
        assertEq(dai.balanceOf(wallets.addr("CHRONICLE_LABS")), prevBalance + 3_721_800 * WAD);

        // Check the second stream
        uint256 jetstreamStreamId = prevStreamCount + 2;
        assertTrue(vest.valid(jetstreamStreamId)); // check for valid contract
        _checkDaiVest({
            _index:      jetstreamStreamId,                              // id
            _wallet:     wallets.addr("JETSTREAM"),                      // usr
            _start:      JUL_01_2023,                                    // bgn
            _cliff:      JUL_01_2023,                                    // clf
            _end:        DEC_31_2024,                                    // fin
            _days:       550 days,                                       // fin
            _manager:    address(0),                                     // mgr
            _restricted: 1,                                              // res
            _reward:     2_964_006 * WAD,                                // tot
            _claimed:    0                                               // rxd
        });
        GodMode.setWard(address(vest), address(this), 1);
        prevBalance = dai.balanceOf(wallets.addr("JETSTREAM"));
        vest.unrestrict(jetstreamStreamId);
        vm.warp(JUL_01_2023 + 550 days);
        vest.vest(jetstreamStreamId);
        assertEq(dai.balanceOf(wallets.addr("JETSTREAM")), prevBalance + 2_964_006 * WAD);
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
            Payee(wallets.addr("LAUNCH_PROJECT_FUNDING"), 941_993)
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

        // 31 Mar 2024 23:59:59 UTC
        uint256 MARCH_31_2024 = 1711929599;
        uint256 streamId = 17;
        address expectedWallet = wallets.addr("GOV_ALPHA");

        assertEq(vest.usr(streamId), expectedWallet, "testYankDAI/unexpected-address");
        assertEq(vest.fin(streamId), MARCH_31_2024, "testYankDAI/unpected-fin-date");

        _vote(address(spell));
        _scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        assertEq(vest.fin(streamId), block.timestamp, "testYankDAI/steam-not-yanked");
    }

    function testYankMKR() public { // make private to disable
        VestAbstract vestTreasury = VestAbstract(addr.addr("MCD_VEST_MKR_TREASURY"));

        // 31 Mar 2024 23:59:59 PM UTC
        uint256 MAR_31_2024 = 1711929599;

        assertEq(vestTreasury.usr(34), wallets.addr("GOV_ALPHA"));
        assertEq(vestTreasury.fin(34),  MAR_31_2024);

        _vote(address(spell));
        _scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        assertEq(vestTreasury.fin(34),  block.timestamp);

        // Give admin powers to test contract address and make the vesting unrestricted for testing
        GodMode.setWard(address(vestTreasury), address(this), 1);

        vestTreasury.unrestrict(34);

        vestTreasury.vest(34);

        assertTrue(!vestTreasury.valid(34));
        assertEq(vestTreasury.fin(34), block.timestamp);
    }

    function testVestMKR() private { // make private to disable
        VestAbstract vest = VestAbstract(addr.addr("MCD_VEST_MKR_TREASURY"));

        // 2023-06-26 00:00:00 UTC
        uint256 JUN_26_2023 = 1687737600;
        // 2023-07-01 00:00:00 UTC
        uint256 JUL_01_2023 = 1688169600;
        // 2024-06-30 23:59:59 UTC
        uint256 JUN_30_2024 = 1719791999;
        // 2024-12-31 23:59:59 UTC
        uint256 DEC_31_2024 = 1735689599;

        uint256 prevStreamCount = vest.ids();
        uint256 prevAllowance = gov.allowance(pauseProxy, addr.addr("MCD_VEST_MKR_TREASURY"));
        uint256 prevBalance;

        _vote(address(spell));
        _scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        // check new allowance
        uint256 newVesting = 2_216.4  ether; // CHRONICLE_LABS; note: ether is a keyword helper, only MKR is transferred here
               newVesting += 1_619.93 ether; // JETSTREAM; note: ether is a keyword helper, only MKR is transferred here
        assertEq(gov.allowance(pauseProxy, addr.addr("MCD_VEST_MKR_TREASURY")), prevAllowance + newVesting, "testVestMKR/invalid-allowance");

        assertEq(vest.cap(), 2_220 * WAD / 365 days, "testVestMKR/invalid-cap");
        assertEq(vest.ids(), prevStreamCount + 2, "testVestMKR/invalid-stream-count");

        { // check CHRONICLE_LABS stream
            address chronicleAddress = wallets.addr("CHRONICLE_LABS");
            uint256 chronicleStreamId = prevStreamCount + 1;
            uint256 chronicleFin = JUL_01_2023 + 366 days - 1;
            assertEq(vest.usr(chronicleStreamId), chronicleAddress, "testVestMKR/invalid-address");
            assertEq(vest.bgn(chronicleStreamId), JUL_01_2023, "testVestMKR/invalid-bgn");
            assertEq(vest.clf(chronicleStreamId), JUL_01_2023, "testVestMKR/invalid-clif");
            assertEq(vest.fin(chronicleStreamId), chronicleFin, "testVestMKR/invalid-calculated-fin");
            assertEq(vest.fin(chronicleStreamId), JUN_30_2024, "testVestMKR/invalid-fin-variable");
            assertEq(vest.mgr(chronicleStreamId), address(0), "testVestMKR/invalid-manager");
            assertEq(vest.res(chronicleStreamId), 1, "testVestMKR/invalid-res");
            assertEq(vest.tot(chronicleStreamId), 2_216.4 ether, "testVestMKR/invalid-total"); // note: ether is a keyword helper, only MKR is transferred here
            assertEq(vest.rxd(chronicleStreamId), 0, "testVestMKR/invalid-rxd");
            prevBalance = gov.balanceOf(chronicleAddress);
            GodMode.setWard(address(vest), address(this), 1);
            vest.unrestrict(chronicleStreamId);
            vm.warp(chronicleFin);
            vest.vest(chronicleStreamId);
            assertEq(gov.balanceOf(chronicleAddress), prevBalance + 2_216.4 ether, "testVestMKR/invalid-received-amount");
        }

        { // check JETSTREAM stream
            address jetstreamAddress = wallets.addr("JETSTREAM");
            uint256 jetstreamStreamId = prevStreamCount + 2;
            uint256 jetstreamFin = JUN_26_2023 + 6 days + 366 days + 183 days - 1;
            assertEq(vest.usr(jetstreamStreamId), jetstreamAddress, "testVestMKR/invalid-address");
            assertEq(vest.bgn(jetstreamStreamId), JUN_26_2023, "testVestMKR/invalid-bgn");
            assertEq(vest.clf(jetstreamStreamId), JUN_26_2023, "testVestMKR/invalid-clif");
            assertEq(vest.fin(jetstreamStreamId), jetstreamFin, "testVestMKR/invalid-calculated-fin");
            assertEq(vest.fin(jetstreamStreamId), DEC_31_2024, "testVestMKR/invalid-fin-variable");
            assertEq(vest.mgr(jetstreamStreamId), address(0), "testVestMKR/invalid-manager");
            assertEq(vest.res(jetstreamStreamId), 1, "testVestMKR/invalid-res");
            assertEq(vest.tot(jetstreamStreamId), 1_619.93 ether, "testVestMKR/invalid-total"); // note: ether is a keyword helper, only MKR is transferred here
            assertEq(vest.rxd(jetstreamStreamId), 0, "testVestMKR/invalid-rxd");
            prevBalance = gov.balanceOf(jetstreamAddress);
            GodMode.setWard(address(vest), address(this), 1);
            vest.unrestrict(jetstreamStreamId);
            vm.warp(jetstreamFin);
            vest.vest(jetstreamStreamId);
            assertEq(gov.balanceOf(jetstreamAddress), prevBalance + 1_619.93 ether, "testVestMKR/invalid-received-amount");
        }
    }

    function testMKRPayments() public { // make public to enable
        // For each payment, create a Payee object with
        //    the Payee address,
        //    the amount to be paid
        // Initialize the array with the number of payees
        Payee[1] memory payees = [
            Payee(wallets.addr("LAUNCH_PROJECT_FUNDING"),   210.83 ether) // NOTE: ether is a keyword helper, only MKR is transferred here
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

    // Spark Tests
    function testSparkSpellIsExecuted() public { // make private to disable
        address SUBPROXY_SPARK = 0x3300f198988e4C9C63F75dF86De36421f06af8c4;
        address SPARK_SPELL    = 0xFBdB6C5596Fc958B432Bf1c99268C72B1515DFf0;

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

    function testVowEsmRely() public {
        _vote(address(spell));
        _scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        assertEq(vow.wards(address(esm)),      1, "VOW/ward-esm-not-set");
    }

    // RWA tests
    address RWA015_A_OPERATOR = addr.addr("RWA015_A_OPERATOR");
    address RWA015_A_CUSTODY  = addr.addr("RWA015_A_CUSTODY");

    address                  rwa015AUrn                 = addr.addr("RWA015_A_URN");
    address                  rwa015AJar                 = addr.addr("RWA015_A_JAR");
    RwaLiquidationOracleLike oracle                     = RwaLiquidationOracleLike(addr.addr("MIP21_LIQUIDATION_ORACLE"));
    RwaInputConduitLike      rwa015AInputConduitUrnGUSD = RwaInputConduitLike(addr.addr("RWA015_A_INPUT_CONDUIT_URN_GUSD"));
    RwaInputConduitLike      rwa015AInputConduitJarGUSD = RwaInputConduitLike(addr.addr("RWA015_A_INPUT_CONDUIT_JAR_GUSD"));
    RwaInputConduitLike      rwa015AInputConduitUrnPAX  = RwaInputConduitLike(addr.addr("RWA015_A_INPUT_CONDUIT_URN_PAX"));
    RwaInputConduitLike      rwa015AInputConduitJarPAX  = RwaInputConduitLike(addr.addr("RWA015_A_INPUT_CONDUIT_JAR_PAX"));
    GemAbstract              gusd                       = GemAbstract(rwa015AInputConduitUrnGUSD.gem());
    GemAbstract              pax                        = GemAbstract(rwa015AInputConduitUrnPAX.gem());

    function testRWA015_CONTRACT_DEPLOYMENT_SETUP() public {
        assertEq(rwa015AInputConduitUrnGUSD.psm(), addr.addr("MCD_PSM_GUSD_A"), "input-conduit-gusd-urn-psm-not-match");
        assertEq(rwa015AInputConduitUrnGUSD.to(),  rwa015AUrn,                  "input-conduit-urn-gusd-to-not-match");
        assertEq(rwa015AInputConduitUrnGUSD.dai(), addr.addr("MCD_DAI"),        "input-conduit-urn-gusd-dai-not-match");
        assertEq(rwa015AInputConduitUrnGUSD.gem(), addr.addr("GUSD"),           "input-conduit-urn-gusd-gem-not-match");

        assertEq(rwa015AInputConduitJarGUSD.psm(), addr.addr("MCD_PSM_GUSD_A"), "input-conduit-jar-gusd-psm-not-match");
        assertEq(rwa015AInputConduitJarGUSD.to(),  rwa015AJar,                  "input-conduit-jar-gusd-to-not-match");
        assertEq(rwa015AInputConduitJarGUSD.dai(), addr.addr("MCD_DAI"),        "input-conduit-jar-gusd-dai-not-match");
        assertEq(rwa015AInputConduitJarGUSD.gem(), addr.addr("GUSD"),           "input-conduit-jar-gusd-gem-not-match");

        assertEq(rwa015AInputConduitUrnPAX.psm(), addr.addr("MCD_PSM_PAX_A"),   "input-conduit-urn-pax-psm-not-match");
        assertEq(rwa015AInputConduitUrnPAX.to(),  rwa015AUrn,                   "input-conduit-urn-pax-to-not-match");
        assertEq(rwa015AInputConduitUrnPAX.dai(), addr.addr("MCD_DAI"),         "input-conduit-urn-pax-dai-not-match");
        assertEq(rwa015AInputConduitUrnPAX.gem(), addr.addr("PAX"),             "input-conduit-urn-pax-gem-not-match");

        assertEq(rwa015AInputConduitJarPAX.psm(), addr.addr("MCD_PSM_PAX_A"),   "input-conduit-jar-pax-psm-not-match");
        assertEq(rwa015AInputConduitJarPAX.to(),  rwa015AJar,                   "input-conduit-jar-pax-to-not-match");
        assertEq(rwa015AInputConduitJarPAX.dai(), addr.addr("MCD_DAI"),         "input-conduit-jar-pax-dai-not-match");
        assertEq(rwa015AInputConduitJarPAX.gem(), addr.addr("PAX"),             "input-conduit-jar-pax-gem-not-match");
    }

    function testRWA015_INTEGRATION_CONDUITS_SETUP() public {
        _vote(address(spell));
        _scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        assertEq(rwa015AInputConduitUrnGUSD.wards(pauseProxy),      1, "InputConduitUrnGUSD/ward-pause-proxy-not-set");
        assertEq(rwa015AInputConduitUrnGUSD.wards(address(esm)),    1, "InputConduitUrnGUSD/ward-esm-not-set");
        assertEq(rwa015AInputConduitUrnGUSD.may(pauseProxy),        0, "InputConduitUrnGUSD/pause-proxy-mated");
        assertEq(rwa015AInputConduitUrnGUSD.may(RWA015_A_OPERATOR), 1, "InputConduitUrnGUSD/operator-not-mate");

        assertEq(rwa015AInputConduitUrnGUSD.quitTo(), RWA015_A_CUSTODY, "InputConduitUrnGUSD/quit-to-not-set");

        assertEq(rwa015AInputConduitJarGUSD.wards(pauseProxy),      1, "InputConduitJarGUSD/ward-pause-proxy-not-set");
        assertEq(rwa015AInputConduitJarGUSD.wards(address(esm)),    1, "InputConduitJarGUSD/ward-esm-not-set");
        assertEq(rwa015AInputConduitJarGUSD.may(pauseProxy),        0, "InputConduitJarGUSD/pause-proxy-mated");
        assertEq(rwa015AInputConduitJarGUSD.may(RWA015_A_OPERATOR), 1, "InputConduitJarGUSD/operator-not-mate");

        assertEq(rwa015AInputConduitJarGUSD.quitTo(), RWA015_A_CUSTODY, "InputConduitJarGUSD/quit-to-not-set");

        assertEq(rwa015AInputConduitUrnPAX.wards(pauseProxy),      1, "InputConduitUrnPAX/ward-pause-proxy-not-set");
        assertEq(rwa015AInputConduitUrnPAX.wards(address(esm)),    1, "InputConduitUrnPAX/ward-esm-not-set");
        assertEq(rwa015AInputConduitUrnPAX.may(pauseProxy),        0, "InputConduitUrnPAX/pause-proxy-mated");
        assertEq(rwa015AInputConduitUrnPAX.may(RWA015_A_OPERATOR), 1, "InputConduitUrnPAX/operator-not-mate");

        assertEq(rwa015AInputConduitUrnPAX.quitTo(), RWA015_A_CUSTODY, "InputConduitUrnPAX/quit-to-not-set");

        assertEq(rwa015AInputConduitJarPAX.wards(pauseProxy),      1, "InputConduitJarPAX/ward-pause-proxy-not-set");
        assertEq(rwa015AInputConduitJarPAX.wards(address(esm)),    1, "InputConduitJarPAX/ward-esm-not-set");
        assertEq(rwa015AInputConduitJarPAX.may(pauseProxy),        0, "InputConduitJarPAX/pause-proxy-mated");
        assertEq(rwa015AInputConduitJarPAX.may(RWA015_A_OPERATOR), 1, "InputConduitJarPAX/operator-not-mate");

        assertEq(rwa015AInputConduitJarPAX.quitTo(), RWA015_A_CUSTODY, "InputConduitJarPAX/quit-to-not-set");
    }

    function testRWA015_INPUT_CONDUITS() public {
        // We set DC to 1b as DC For PAX is currently 0 and for GUSD is maxed
        vm.startPrank(pauseProxy);
        vat.file("PSM-GUSD-A", "line", 1_000_000_000 * (10**45));
        vat.file("PSM-PAX-A", "line",  1_000_000_000 * (10**45));
        vm.stopPrank();

        _vote(address(spell));
        _scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        uint256 gusdAmt = 1000 * 10**2;
        uint256 paxAmt  = 1000 * 10**18;
        uint256 urnBalanceBefore = dai.balanceOf(rwa015AUrn);
        uint256 jarBalanceBefore = dai.balanceOf(rwa015AJar);

        // Add GUSD blance
        address impl = ERC20Proxy(address(gusd)).erc20Impl();
        ERC20Store store = ERC20Store(ERC20Impl(impl).erc20Store());

        vm.startPrank(impl);
        store.setBalance(address(this), 2 * gusdAmt);
        store.setTotalSupply(gusd.totalSupply() + 2 * gusdAmt);
        vm.stopPrank();

        GodMode.setBalance(address(pax), address(this), 2 * paxAmt);

        // transfer GUSD to input conduit's
        gusd.transfer(address(rwa015AInputConduitUrnGUSD), gusdAmt);
        assertEq(gusd.balanceOf(address(rwa015AInputConduitUrnGUSD)), gusdAmt, "RWA015-A: GUSD not sent to input conduit urn");

        gusd.transfer(address(rwa015AInputConduitJarGUSD), gusdAmt);
        assertEq(gusd.balanceOf(address(rwa015AInputConduitJarGUSD)), gusdAmt, "RWA015-A: GUSD not sent to input conduit jar");

        // input conduit 'push()' to the urn
        rwa015AInputConduitUrnGUSD.push();

        // input conduit 'push()' to the jar
        rwa015AInputConduitJarGUSD.push();

        assertEq(dai.balanceOf(address(rwa015AUrn)), urnBalanceBefore + 1000 * 10**18, "GUSD-Input-Conduit/Balance of the URN doesnt match");
        assertEq(dai.balanceOf(address(rwa015AJar)), jarBalanceBefore + 1000 * 10**18, "GUSD-Input-Conduit/Balance of the JAR doesnt match");

        urnBalanceBefore = dai.balanceOf(rwa015AUrn);
        jarBalanceBefore = dai.balanceOf(rwa015AJar);

        // transfer PAX to input conduit's
        pax.transfer(address(rwa015AInputConduitUrnPAX), paxAmt);
        assertEq(pax.balanceOf(address(rwa015AInputConduitUrnPAX)), paxAmt, "RWA015-A: PAX not sent to input conduit urn");

        pax.transfer(address(rwa015AInputConduitJarPAX), paxAmt);
        assertEq(pax.balanceOf(address(rwa015AInputConduitJarPAX)), paxAmt, "RWA015-A: PAX not sent to input conduit jar");

        // input conduit 'push()' to the urn
        rwa015AInputConduitUrnPAX.push();

        // input conduit 'push()' to the jar
        rwa015AInputConduitJarPAX.push();

        assertEq(dai.balanceOf(address(rwa015AUrn)), urnBalanceBefore + 1000 * 10**18, "PAX-Input-Conduit/Balance of the URN doesnt match");
        assertEq(dai.balanceOf(address(rwa015AJar)), jarBalanceBefore + 1000 * 10**18, "PAX-Input-Conduit/Balance of the JAR doesnt match");
    }

    function testRWA003OracleTell() public {
        _vote(address(spell));
        _scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        (, , uint tau, uint toc) = oracle.ilks("RWA003-A");
        assertGt(toc, 0, "RWA003-A: bad `toc` after `tell()`");

        skip(tau);
        assertEq(oracle.good("RWA003-A"), false, "RWA003-A: still `good` after `tell()` + `tau`");
    }
}
