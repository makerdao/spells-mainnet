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

interface RwaUrnLike {
    function can(address) external view returns (uint256);
    function gemJoin() external view returns (GemAbstract);
    function lock(uint256) external;
    function draw(uint256) external;
    function wipe(uint256) external;
    function free(uint256) external;
}

interface WriteableRwaLiquidationLike is RwaLiquidationLike {
    function bump(bytes32 ilk, uint256 val) external;
    function tell(bytes32) external;
    function cure(bytes32) external;
    function cull(bytes32, address) external;
    function good(bytes32) external view returns (bool);
}

interface Root {
    function wards(address) external view returns (uint256);
    function relyContract(address, address) external;
}

interface MemberList {
    function updateMember(address, uint256) external;
}

interface AssessorLike {
    function calcSeniorTokenPrice() external returns (uint256);
}

interface FileLike {
    function file(bytes32 what, address data) external;
}

interface TinlakeManagerLike {
    function gem() external view returns (address);
    function liq() external view returns (address);
    function urn() external view returns (address);
    function wards(address) external view returns (uint256);
    function lock(uint256 wad) external;
    function join(uint256 wad) external;
    function draw(uint256 wad) external;
    function wipe(uint256 wad) external;
    function exit(uint256 wad) external;
    function free(uint256 wad) external;
}

interface DropTokenAbstract is DSTokenAbstract {
    function wards(address) external view returns (uint256);
}

struct CentrifugeCollateralTestValues {
    bytes32 ilk;
    string ilkString;
    address LIQ;
    address DROP;
    address URN;
    address GEM_JOIN;
    uint256 CEIL;
    uint256 PRICE;
    string  DOC;
    uint256 TAU;

    address MGR;
    address ROOT;
    address MEMBERLIST;

    bytes32 pipID;
}

contract DssSpellTest is DssSpellTestBase {

    function testSpellIsCast_GENERAL() public {
        string memory description = new DssSpell().description();
        assertTrue(bytes(description).length > 0, "TestError/spell-description-length");
        // DS-Test can't handle strings directly, so cast to a bytes32.
        assertEq(stringToBytes32(spell.description()),
                stringToBytes32(description), "TestError/spell-description");

        if(address(spell) != address(spellValues.deployed_spell)) {
            assertEq(spell.expiration(), block.timestamp + spellValues.expiration_threshold, "TestError/spell-expiration");
        } else {
            assertEq(spell.expiration(), spellValues.deployed_spell_created + spellValues.expiration_threshold, "TestError/spell-expiration");
        }

        assertTrue(spell.officeHours() == spellValues.office_hours_enabled, "TestError/spell-office-hours");

        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done(), "TestError/spell-not-done");

        checkSystemValues(afterSpell);

        checkCollateralValues(afterSpell);
    }

    function testRemoveChainlogValues() private { // make private to disable
        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        // try chainLog.getAddress("RWA007_A_INPUT_CONDUIT_URN") {
        //     assertTrue(false);
        // } catch Error(string memory errmsg) {
        //     assertTrue(cmpStr(errmsg, "dss-chain-log/invalid-key"));
        // } catch {
        //     assertTrue(false);
        // }
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
        Payee[1] memory payees = [
           Payee(wallets.addr("XXX"),           0)
        ];

        uint256 prevBalance;
        uint256 totAmount;
        uint256[] memory prevAmounts = new uint256[](payees.length);

        for (uint256 i = 0; i < payees.length; i++) {
            totAmount += payees[i].amount;
            prevAmounts[i] = dai.balanceOf(payees[i].addr);
            prevBalance += prevAmounts[i];
        }

        vote(address(spell));
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

    function testCollateralIntegrations() public { // make private to disable
        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        // Insert new collateral tests here
        checkIlkIntegration(
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
        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        // XXX
        checkIlkClipper(
            "XXX-A",
            GemJoinAbstract(addr.addr("MCD_JOIN_XXX_A")),
            ClipAbstract(addr.addr("MCD_CLIP_XXX_A")),
            addr.addr("MCD_CLIP_CALC_XXX_A"),
            OsmAbstract(addr.addr("PIP_XXX")),
            5_000 * WAD
        );
    }

    function testNewChainlogValues() public { // make private to disable
        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        // checkChainlogKey("XXX");

        checkChainlogVersion("1.14.7");
    }

    function testNewIlkRegistryValues() public { // make private to disable
        vote(address(spell));
        scheduleWaitAndCast(address(spell));
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

    function testFailWrongDay() public {
        require(spell.officeHours() == spellValues.office_hours_enabled);
        if (spell.officeHours()) {
            vote(address(spell));
            scheduleWaitAndCastFailDay();
        } else {
            revert("Office Hours Disabled");
        }
    }

    function testFailTooEarly() public {
        require(spell.officeHours() == spellValues.office_hours_enabled);
        if (spell.officeHours()) {
            vote(address(spell));
            scheduleWaitAndCastFailEarly();
        } else {
            revert("Office Hours Disabled");
        }
    }

    function testFailTooLate() public {
        require(spell.officeHours() == spellValues.office_hours_enabled);
        if (spell.officeHours()) {
            vote(address(spell));
            scheduleWaitAndCastFailLate();
        } else {
            revert("Office Hours Disabled");
        }
    }

    function testOnTime() public {
        vote(address(spell));
        scheduleWaitAndCast(address(spell));
    }

    function testCastCost() public {
        vote(address(spell));
        spell.schedule();

        castPreviousSpell();
        vm.warp(spell.nextCastTime());
        uint256 startGas = gasleft();
        spell.cast();
        uint256 endGas = gasleft();
        uint256 totalGas = startGas - endGas;

        assertTrue(spell.done());
        // Fail if cast is too expensive
        assertLe(totalGas, 15 * MILLION);
    }

    function testDeployCost() public {
        uint256 startGas = gasleft();
        new DssSpell();
        uint256 endGas = gasleft();
        uint256 totalGas = startGas - endGas;

        // Warn if deploy exceeds block target size
        if (totalGas > 15 * MILLION) {
            emit log("Warn: deploy gas exceeds average block target");
            emit log_named_uint("    deploy gas", totalGas);
            emit log_named_uint("  block target", 15 * MILLION);
        }

        // Fail if deploy is too expensive
        assertLe(totalGas, 30 * MILLION, "testDeployCost/DssSpell-exceeds-max-block-size");
    }


    // Fail when contract code size exceeds 24576 bytes (a limit introduced in Spurious Dragon).
    // This contract may not be deployable.
    // Consider enabling the optimizer (with a low "runs" value!),
    //   turning off revert strings, or using libraries.
    function testContractSize() public {
        uint256 _sizeSpell;
        address _spellAddr  = address(spell);
        assembly {
            _sizeSpell := extcodesize(_spellAddr)
        }
        assertLe(_sizeSpell, 24576, "testContractSize/DssSpell-exceeds-max-contract-size");

        uint256 _sizeAction;
        address _actionAddr = spell.action();
        assembly {
            _sizeAction := extcodesize(_actionAddr)
        }
        assertLe(_sizeAction, 24576, "testContractSize/DssSpellAction-exceeds-max-contract-size");

    }

    // The specific date doesn't matter that much since function is checking for difference between warps
    function test_nextCastTime() public {
        vm.warp(1606161600); // Nov 23, 20 UTC (could be cast Nov 26)

        vote(address(spell));
        spell.schedule();

        uint256 monday_1400_UTC = 1606744800; // Nov 30, 2020
        uint256 monday_2100_UTC = 1606770000; // Nov 30, 2020

        // Day tests
        vm.warp(monday_1400_UTC);                                      // Monday,   14:00 UTC
        assertEq(spell.nextCastTime(), monday_1400_UTC);               // Monday,   14:00 UTC

        if (spell.officeHours()) {
            vm.warp(monday_1400_UTC - 1 days);                         // Sunday,   14:00 UTC
            assertEq(spell.nextCastTime(), monday_1400_UTC);           // Monday,   14:00 UTC

            vm.warp(monday_1400_UTC - 2 days);                         // Saturday, 14:00 UTC
            assertEq(spell.nextCastTime(), monday_1400_UTC);           // Monday,   14:00 UTC

            vm.warp(monday_1400_UTC - 3 days);                         // Friday,   14:00 UTC
            assertEq(spell.nextCastTime(), monday_1400_UTC - 3 days);  // Able to cast

            vm.warp(monday_2100_UTC);                                  // Monday,   21:00 UTC
            assertEq(spell.nextCastTime(), monday_1400_UTC + 1 days);  // Tuesday,  14:00 UTC

            vm.warp(monday_2100_UTC - 1 days);                         // Sunday,   21:00 UTC
            assertEq(spell.nextCastTime(), monday_1400_UTC);           // Monday,   14:00 UTC

            vm.warp(monday_2100_UTC - 2 days);                         // Saturday, 21:00 UTC
            assertEq(spell.nextCastTime(), monday_1400_UTC);           // Monday,   14:00 UTC

            vm.warp(monday_2100_UTC - 3 days);                         // Friday,   21:00 UTC
            assertEq(spell.nextCastTime(), monday_1400_UTC);           // Monday,   14:00 UTC

            // Time tests
            uint256 castTime;

            for(uint256 i = 0; i < 5; i++) {
                castTime = monday_1400_UTC + i * 1 days; // Next day at 14:00 UTC
                vm.warp(castTime - 1 seconds); // 13:59:59 UTC
                assertEq(spell.nextCastTime(), castTime);

                vm.warp(castTime + 7 hours + 1 seconds); // 21:00:01 UTC
                if (i < 4) {
                    assertEq(spell.nextCastTime(), monday_1400_UTC + (i + 1) * 1 days); // Next day at 14:00 UTC
                } else {
                    assertEq(spell.nextCastTime(), monday_1400_UTC + 7 days); // Next monday at 14:00 UTC (friday case)
                }
            }
        }
    }

    function testFail_notScheduled() public view {
        spell.nextCastTime();
    }

    function test_use_eta() public {
        vm.warp(1606161600); // Nov 23, 20 UTC (could be cast Nov 26)

        vote(address(spell));
        spell.schedule();

        uint256 castTime = spell.nextCastTime();
        assertEq(castTime, spell.eta());
    }

    function testOSMs() private { // make private to disable
        address READER = address(0);

        // Track OSM authorizations here
        assertEq(OsmAbstract(addr.addr("PIP_TOKEN")).bud(READER), 0);

        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        assertEq(OsmAbstract(addr.addr("PIP_TOKEN")).bud(READER), 1);
    }

    function testMedianizers() private { // make private to disable
        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        // Track Median authorizations here
        address SET_TOKEN    = address(0);
        address TOKENUSD_MED = OsmAbstract(addr.addr("PIP_TOKEN")).src();
        assertEq(MedianAbstract(TOKENUSD_MED).bud(SET_TOKEN), 1);
    }

    function testPSMs() public {

        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        bytes32 _ilk = "PSM-PAX-A";
        assertEq(addr.addr("MCD_JOIN_PSM_PAX_A"), reg.join(_ilk));
        assertEq(addr.addr("MCD_CLIP_PSM_PAX_A"), reg.xlip(_ilk));
        assertEq(addr.addr("PIP_PAX"), reg.pip(_ilk));
        assertEq(addr.addr("MCD_PSM_PAX_A"), chainLog.getAddress("MCD_PSM_PAX_A"));
        checkPsmIlkIntegration(
            _ilk,
            GemJoinAbstract(addr.addr("MCD_JOIN_PSM_PAX_A")),
            ClipAbstract(addr.addr("MCD_CLIP_PSM_PAX_A")),
            addr.addr("PIP_PAX"),
            PsmAbstract(addr.addr("MCD_PSM_PAX_A")),
            calcPSMRateFromBPS(10),
            calcPSMRateFromBPS(0)
        );

        _ilk = "PSM-GUSD-A";
        assertEq(addr.addr("MCD_JOIN_PSM_GUSD_A"), reg.join(_ilk));
        assertEq(addr.addr("MCD_CLIP_PSM_GUSD_A"), reg.xlip(_ilk));
        assertEq(addr.addr("PIP_GUSD"), reg.pip(_ilk));
        assertEq(addr.addr("MCD_PSM_GUSD_A"), chainLog.getAddress("MCD_PSM_GUSD_A"));
        checkPsmIlkIntegration(
            _ilk,
            GemJoinAbstract(addr.addr("MCD_JOIN_PSM_GUSD_A")),
            ClipAbstract(addr.addr("MCD_CLIP_PSM_GUSD_A")),
            addr.addr("PIP_GUSD"),
            PsmAbstract(addr.addr("MCD_PSM_GUSD_A")),
            calcPSMRateFromBPS(10),
            calcPSMRateFromBPS(10)
        );
    }

    // Use for PSM tin/tout. Calculations are slightly different from elsewhere in MCD
    function calcPSMRateFromBPS(uint256 _bps) internal pure returns (uint256 _amt) {
        return _bps * WAD / 10000;
    }

    function test_auth() public {
        checkAuth(false);
    }

    function test_auth_in_sources() public {
        checkAuth(true);
    }

    // Verifies that the bytecode of the action of the spell used for testing
    // matches what we'd expect.
    //
    // Not a complete replacement for Etherscan verification, unfortunately.
    // This is because the DssSpell bytecode is non-deterministic because it
    // deploys the action in its constructor and incorporates the action
    // address as an immutable variable--but the action address depends on the
    // address of the DssSpell which depends on the address+nonce of the
    // deploying address. If we had a way to simulate a contract creation by
    // an arbitrary address+nonce, we could verify the bytecode of the DssSpell
    // instead.
    //
    // Vacuous until the deployed_spell value is non-zero.
    function test_bytecode_matches() public {
        // The DssSpell bytecode is non-deterministic, compare only code size
        DssSpell expectedSpell = new DssSpell();
        assertEq(getExtcodesize(address(spell)), getExtcodesize(address(expectedSpell)), "TestError/spell-codesize");

        // The SpellAction bytecode can be compared after chopping off the metada
        address expectedAction = expectedSpell.action();
        address actualAction   = spell.action();
        uint256 expectedBytecodeSize;
        uint256 actualBytecodeSize;
        assembly {
            expectedBytecodeSize := extcodesize(expectedAction)
            actualBytecodeSize   := extcodesize(actualAction)
        }

        uint256 metadataLength = getBytecodeMetadataLength(expectedAction);
        assertTrue(metadataLength <= expectedBytecodeSize);
        expectedBytecodeSize -= metadataLength;

        metadataLength = getBytecodeMetadataLength(actualAction);
        assertTrue(metadataLength <= actualBytecodeSize);
        actualBytecodeSize -= metadataLength;

        assertEq(actualBytecodeSize, expectedBytecodeSize);
        uint256 size = actualBytecodeSize;
        uint256 expectedHash;
        uint256 actualHash;
        assembly {
            let ptr := mload(0x40)

            extcodecopy(expectedAction, ptr, 0, size)
            expectedHash := keccak256(ptr, size)

            extcodecopy(actualAction, ptr, 0, size)
            actualHash := keccak256(ptr, size)
        }
        assertEq(actualHash, expectedHash);
    }

    // Validate addresses in test harness match chainlog
    function test_chainlog_values() public {
        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        for(uint256 i = 0; i < chainLog.count(); i++) {
            (bytes32 _key, address _val) = chainLog.get(i);
            assertEq(_val, addr.addr(_key), concat("TestError/chainlog-addr-mismatch-", _key));
        }
    }

    // Ensure version is updated if chainlog changes
    function test_chainlog_version_bump() public {

        uint256                   _count = chainLog.count();
        string    memory        _version = chainLog.version();
        address[] memory _chainlog_addrs = new address[](_count);

        for(uint256 i = 0; i < _count; i++) {
            (, address _val) = chainLog.get(i);
            _chainlog_addrs[i] = _val;
        }

        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        if (keccak256(abi.encodePacked(_version)) == keccak256(abi.encodePacked(chainLog.version()))) {
            // Fail if the version is not updated and the chainlog count has changed
            if (_count != chainLog.count()) {
                emit log_named_string("Error", concat("TestError/chainlog-version-not-updated-count-change-", _version));
                fail();
                return;
            }
            // Fail if the chainlog is the same size but local keys don't match the chainlog.
            for(uint256 i = 0; i < _count; i++) {
                (, address _val) = chainLog.get(i);
                if (_chainlog_addrs[i] != _val) {
                    emit log_named_string("Error", concat("TestError/chainlog-version-not-updated-address-change-", _version));
                    fail();
                    return;
                }
            }
        }
    }

    function tryVest(address vest, uint256 id) internal returns (bool ok) {
        (ok,) = vest.call(abi.encodeWithSignature("vest(uint256)", id));
    }

    // @dev when testing new vest contracts, use the explicit id when testing to assist in
    //      identifying streams later for modification or removal
    function testVestDAI() private { // make private to disable
        // VestAbstract vest = VestAbstract(addr.addr("MCD_VEST_DAI"));

        // All times in GMT
        // uint256 OCT_01_2022 = 1664582400; // Saturday, October   1, 2022 12:00:00 AM
        // uint256 OCT_31_2022 = 1667260799; // Monday,   October  31, 2022 11:59:59 PM

        // assertEq(vest.ids(), 9);

        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        // assertEq(vest.ids(), 9 + 1);

        // assertEq(vest.cap(), 1 * MILLION * WAD / 30 days);

        // assertTrue(vest.valid(10)); // check for valid contract
        // checkDaiVest({
        //     _index:      10,                                             // id
        //     _wallet:     wallets.addr("DAIF_WALLET"),                    // usr
        //     _start:      OCT_01_2022,                                    // bgn
        //     _cliff:      OCT_01_2022,                                    // clf
        //     _end:        OCT_31_2022,                                    // fin
        //     _days:       31 days,                                        // fin
        //     _manager:    address(0),                                     // mgr
        //     _restricted: 1,                                              // res
        //     _reward:     67_863 * WAD,                                   // tot
        //     _claimed:    0                                               // rxd
        // });

        // // Give admin powers to Test contract address and make the vesting unrestricted for testing
        // giveAuth(address(vest), address(this));
        // uint256 prevBalance;

        // vest.unrestrict(10);
        // prevBalance = dai.balanceOf(wallets.addr("DAIF_WALLET"));
        // vm.warp(OCT_01_2022 + 31 days);
        // assertTrue(tryVest(address(vest), 10));
        // assertEq(dai.balanceOf(wallets.addr("DAIF_WALLET")), prevBalance + 67_863 * WAD);
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

        vote(address(spell));
        scheduleWaitAndCast(address(spell));
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

        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        // assertEq(vestTreas.fin(23), block.timestamp);
    }

    function testVestMKR() private { // make private to disable
        // VestAbstract vest = VestAbstract(addr.addr("MCD_VEST_MKR_TREASURY"));
        // assertEq(vest.ids(), 24);

        // uint256 prevAllowance = gov.allowance(pauseProxy, addr.addr("MCD_VEST_MKR_TREASURY"));

        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        // assertEq(gov.allowance(pauseProxy, addr.addr("MCD_VEST_MKR_TREASURY")), prevAllowance + 787.70 ether);

        // assertEq(vest.cap(), 1_100 * WAD / 365 days);
        // assertEq(vest.ids(), 28);

        // uint256 AUG_01_2022 = 1659312000;
        // uint256 AUG_01_2023 = 1690848000;
        // uint256 SEP_28_2022 = 1664323200;
        // uint256 SEP_28_2024 = 1727481600;

        // address GOV_WALLET1 = 0xbfDD0E744723192f7880493b66501253C34e1241;
        // address GOV_WALLET2 = 0xbb147E995c9f159b93Da683dCa7893d6157199B9;
        // address GOV_WALLET3 = 0x01D26f8c5cC009868A4BF66E268c17B057fF7A73;
        // address SNE_WALLET = wallets.addr("SNE_WALLET");

        // // -----
        // assertEq(vest.usr(25), GOV_WALLET1);
        // assertEq(vest.bgn(25), AUG_01_2022);
        // assertEq(vest.clf(25), AUG_01_2023);
        // assertEq(vest.fin(25), AUG_01_2022 + 365 days);
        // assertEq(vest.fin(25), AUG_01_2023);
        // assertEq(vest.mgr(25), address(0));
        // assertEq(vest.res(25), 1);
        // assertEq(vest.tot(25), 62.50 ether);
        // assertEq(vest.rxd(25), 0);

        // assertEq(vest.usr(26), GOV_WALLET2);
        // assertEq(vest.bgn(26), AUG_01_2022);
        // assertEq(vest.clf(26), AUG_01_2023);
        // assertEq(vest.fin(26), AUG_01_2022 + 365 days);
        // assertEq(vest.fin(26), AUG_01_2023);
        // assertEq(vest.mgr(26), address(0));
        // assertEq(vest.res(26), 1);
        // assertEq(vest.tot(26), 32.69 ether);
        // assertEq(vest.rxd(26), 0);

        // assertEq(vest.usr(27), GOV_WALLET3);
        // assertEq(vest.bgn(27), AUG_01_2022);
        // assertEq(vest.clf(27), AUG_01_2023);
        // assertEq(vest.fin(27), AUG_01_2022 + 365 days);
        // assertEq(vest.fin(27), AUG_01_2023);
        // assertEq(vest.mgr(27), address(0));
        // assertEq(vest.res(27), 1);
        // assertEq(vest.tot(27), 152.51 ether);
        // assertEq(vest.rxd(27), 0);

        // assertEq(vest.usr(28), SNE_WALLET);
        // assertEq(vest.bgn(28), SEP_28_2022);
        // assertEq(vest.clf(28), SEP_28_2022);
        // assertEq(vest.fin(28), SEP_28_2022 + 731 days);
        // assertEq(vest.fin(28), SEP_28_2024);
        // assertEq(vest.mgr(28), address(0));
        // assertEq(vest.res(28), 1);
        // assertEq(vest.tot(28), 540.00 ether);
        // assertEq(vest.rxd(28), 0);

        // uint256 prevBalance = gov.balanceOf(GOV_WALLET1);

        // // Give admin powers to test contract address and make the vesting unrestricted for testing
        // giveAuth(address(vest), address(this));
        // vest.unrestrict(25);

        // vm.warp(AUG_01_2022 + 365 days);
        // vest.vest(25);
        // assertEq(gov.balanceOf(GOV_WALLET1), prevBalance + 62.50 ether);

        // vm.warp(AUG_01_2022 + 365 days + 10 days);
        // vest.vest(25);
        // assertEq(gov.balanceOf(GOV_WALLET1), prevBalance + 62.50 ether);

        // prevBalance = gov.balanceOf(GOV_WALLET2);
        // vest.unrestrict(26);

        // vm.warp(AUG_01_2022 + 365 days);
        // vest.vest(26);
        // assertEq(gov.balanceOf(GOV_WALLET2), prevBalance + 32.69 ether);

        // vm.warp(AUG_01_2022 + 365 days + 10 days);
        // vest.vest(26);
        // assertEq(gov.balanceOf(GOV_WALLET2), prevBalance + 32.69 ether);

        // prevBalance = gov.balanceOf(GOV_WALLET3);
        // vest.unrestrict(27);

        // vm.warp(AUG_01_2022 + 365 days);
        // vest.vest(27);
        // assertEq(gov.balanceOf(GOV_WALLET3), prevBalance + 152.51 ether);

        // vm.warp(AUG_01_2022 + 365 days + 10 days);
        // vest.vest(27);
        // assertEq(gov.balanceOf(GOV_WALLET3), prevBalance + 152.51 ether);

        // prevBalance = gov.balanceOf(SNE_WALLET);
        // vest.unrestrict(28);

        // vm.warp(SEP_28_2022 + 731 days);
        // vest.vest(28);
        // assertEq(gov.balanceOf(SNE_WALLET), prevBalance + 540.00 ether);

        // vm.warp(SEP_28_2022 + 731 days + 10 days);
        // vest.vest(28);
        // assertEq(gov.balanceOf(SNE_WALLET), prevBalance + 540.00 ether);
    }

    function testMKRPayments() private { // make private to disable
        uint256 prevMkrPause = gov.balanceOf(address(pauseProxy));
        uint256 prevMkrXXX  = gov.balanceOf(wallets.addr("XXX_WALLET"));

        uint256 amountXXX = 0 ether;

        uint256 total     = 0 ether;

        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        assertEq(gov.balanceOf(address(pauseProxy)), prevMkrPause - total);
        assertEq(gov.balanceOf(wallets.addr("XXX_WALLET")), prevMkrXXX + amountXXX);
    }

    function testMKRVestFix() private { // make private to disable
        // uint256 prevMkrPause  = gov.balanceOf(address(pauseProxy));
        // VestAbstract vest = VestAbstract(addr.addr("MCD_VEST_MKR_TREASURY"));

        // address usr = vest.usr(2);
        // assertEq(usr, pauseProxy, "usr of id 2 is pause proxy");

        // uint256 unpaid = vest.unpaid(2);
        // assertEq(unpaid, 63180000000000000000, "amount doesn't match expectation");

        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        // unpaid = vest.unpaid(2);
        // assertEq(unpaid, 0, "vest still has a balance");
        // assertEq(gov.balanceOf(address(pauseProxy)), prevMkrPause);
    }
}
