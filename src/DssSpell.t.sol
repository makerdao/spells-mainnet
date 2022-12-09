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

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

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

    function testRemoveChainlogValues() private { // make public to enable
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

        // try chainLog.getAddress("RWA007_A_INPUT_CONDUIT_JAR") {
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

    function testPayments() public { // make public to enable

        // For each payment, create a Payee obj ect with
        //    the Payee address,
        //    the amount to be paid in whole Dai units
        // Initialize the array with the number of payees
        //Payee[1] memory payees = [
        //    Payee(wallets.addr("XXX"),           1)
        //];

        Payee[20] memory payees = [
            Payee(wallets.addr("STABLENODE"),        12000),
            Payee(wallets.addr("ULTRASCHUPPI"),      12000),
            Payee(wallets.addr("FLIPFLOPFLAP"),      12000),
            Payee(wallets.addr("FLIPSIDE"),          11396),
            Payee(wallets.addr("FEEDBLACKLOOPS"),    10900),
            Payee(wallets.addr("PENNBLOCKCHAIN"),    10385),
            Payee(wallets.addr("MHONKASALOTEEMULAU"), 8945),
            Payee(wallets.addr("BLOCKCHAINCOLUMBIA"), 5109),
            Payee(wallets.addr("ACREINVEST"),         4568),
            Payee(wallets.addr("LBSBLOCKCHAIN"),      3797),
            Payee(wallets.addr("CALBLOCKCHAIN"),      3421),
            Payee(wallets.addr("JUSTINCASE"),         3208),
            Payee(wallets.addr("FRONTIERRESEARCH"),   2278),
            Payee(wallets.addr("CHRISBLEC"),          1883),
            Payee(wallets.addr("GFXLABS"),             532),
            Payee(wallets.addr("ONESTONE"),            299),
            Payee(wallets.addr("CODEKNIGHT"),          271),
            Payee(wallets.addr("LLAMA"),               145),
            Payee(wallets.addr("PVL"),                  65),
            Payee(wallets.addr("CONSENSYS"),            28)
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
        hevm.warp(spell.nextCastTime());
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

    function testIlkClipper() public { // make private to disable
        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        checkIlkClipper(
            "GNO-A",
            GemJoinAbstract(addr.addr("MCD_JOIN_GNO_A")),
            ClipAbstract(addr.addr("MCD_CLIP_GNO_A")),
            addr.addr("MCD_CLIP_CALC_GNO_A"),
            OsmAbstract(addr.addr("PIP_GNO")),
            5_000 * WAD
        );

        checkIlkClipper(
            "RENBTC-A",
            GemJoinAbstract(addr.addr("MCD_JOIN_RENBTC_A")),
            ClipAbstract(addr.addr("MCD_CLIP_RENBTC_A")),
            addr.addr("MCD_CLIP_CALC_RENBTC_A"),
            OsmAbstract(addr.addr("PIP_RENBTC")),
            5 * WAD
        );
    }

    function testNewChainlogValues() public { // make private to disable
        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        checkChainlogKey("GNO");
        checkChainlogKey("PIP_GNO");
        checkChainlogKey("MCD_JOIN_GNO_A");
        checkChainlogKey("MCD_CLIP_GNO_A");
        checkChainlogKey("MCD_CLIP_CALC_GNO_A");

        checkChainlogKey("RWA010");
        checkChainlogKey("PIP_RWA010");
        checkChainlogKey("MCD_JOIN_RWA010_A");
        checkChainlogKey("RWA010_A_URN");
        checkChainlogKey("RWA010_A_INPUT_CONDUIT");
        checkChainlogKey("RWA010_A_OUTPUT_CONDUIT");

        checkChainlogKey("RWA011");
        checkChainlogKey("PIP_RWA011");
        checkChainlogKey("MCD_JOIN_RWA011_A");
        checkChainlogKey("RWA011_A_URN");
        checkChainlogKey("RWA011_A_INPUT_CONDUIT");
        checkChainlogKey("RWA011_A_OUTPUT_CONDUIT");

        checkChainlogKey("RWA012");
        checkChainlogKey("PIP_RWA012");
        checkChainlogKey("MCD_JOIN_RWA012_A");
        checkChainlogKey("RWA012_A_URN");
        checkChainlogKey("RWA012_A_INPUT_CONDUIT");
        checkChainlogKey("RWA012_A_OUTPUT_CONDUIT");

        checkChainlogKey("RWA013");
        checkChainlogKey("PIP_RWA013");
        checkChainlogKey("MCD_JOIN_RWA013_A");
        checkChainlogKey("RWA013_A_URN");
        checkChainlogKey("RWA013_A_INPUT_CONDUIT");
        checkChainlogKey("RWA013_A_OUTPUT_CONDUIT");

        checkChainlogVersion("1.14.7");
    }

    function testNewIlkRegistryValues() public { // make private to disable
        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        // GNO-A
        assertEq(reg.pos("GNO-A"),    56);
        assertEq(reg.join("GNO-A"),   addr.addr("MCD_JOIN_GNO_A"));
        assertEq(reg.gem("GNO-A"),    addr.addr("GNO"));
        assertEq(reg.dec("GNO-A"),    GemAbstract(addr.addr("GNO")).decimals());
        assertEq(reg.class("GNO-A"),  1);
        assertEq(reg.pip("GNO-A"),    addr.addr("PIP_GNO"));
        assertEq(reg.name("GNO-A"),   "Gnosis Token");
        assertEq(reg.symbol("GNO-A"), GemAbstract(addr.addr("GNO")).symbol());

        // RWA010-A
        assertEq(reg.pos("RWA010-A"),    57);
        assertEq(reg.join("RWA010-A"),   addr.addr("MCD_JOIN_RWA010_A"));
        assertEq(reg.gem("RWA010-A"),    addr.addr("RWA010"));
        assertEq(reg.dec("RWA010-A"),    GemAbstract(addr.addr("RWA010")).decimals());
        assertEq(reg.class("RWA010-A"),  3);
        assertEq(reg.pip("RWA010-A"),    addr.addr("PIP_RWA010"));
        assertEq(reg.name("RWA010-A"),   "RWA010-A: Centrifuge: BlockTower Credit (I)");
        assertEq(reg.symbol("RWA010-A"), GemAbstract(addr.addr("RWA010")).symbol());

        // RWA011-A
        assertEq(reg.pos("RWA011-A"),    58);
        assertEq(reg.join("RWA011-A"),   addr.addr("MCD_JOIN_RWA011_A"));
        assertEq(reg.gem("RWA011-A"),    addr.addr("RWA011"));
        assertEq(reg.dec("RWA011-A"),    GemAbstract(addr.addr("RWA011")).decimals());
        assertEq(reg.class("RWA011-A"),  3);
        assertEq(reg.pip("RWA011-A"),    addr.addr("PIP_RWA011"));
        assertEq(reg.name("RWA011-A"),   "RWA011-A: Centrifuge: BlockTower Credit (II)");
        assertEq(reg.symbol("RWA011-A"), GemAbstract(addr.addr("RWA011")).symbol());

        // RWA012-A
        assertEq(reg.pos("RWA012-A"),    59);
        assertEq(reg.join("RWA012-A"),   addr.addr("MCD_JOIN_RWA012_A"));
        assertEq(reg.gem("RWA012-A"),    addr.addr("RWA012"));
        assertEq(reg.dec("RWA012-A"),    GemAbstract(addr.addr("RWA012")).decimals());
        assertEq(reg.class("RWA012-A"),  3);
        assertEq(reg.pip("RWA012-A"),    addr.addr("PIP_RWA012"));
        assertEq(reg.name("RWA012-A"),   "RWA012-A: Centrifuge: BlockTower Credit (III)");
        assertEq(reg.symbol("RWA012-A"), GemAbstract(addr.addr("RWA012")).symbol());

        // RWA012-A
        assertEq(reg.pos("RWA013-A"),    60);
        assertEq(reg.join("RWA013-A"),   addr.addr("MCD_JOIN_RWA013_A"));
        assertEq(reg.gem("RWA013-A"),    addr.addr("RWA013"));
        assertEq(reg.dec("RWA013-A"),    GemAbstract(addr.addr("RWA013")).decimals());
        assertEq(reg.class("RWA013-A"),  3);
        assertEq(reg.pip("RWA013-A"),    addr.addr("PIP_RWA013"));
        assertEq(reg.name("RWA013-A"),   "RWA013-A: Centrifuge: BlockTower Credit (IV)");
        assertEq(reg.symbol("RWA013-A"), GemAbstract(addr.addr("RWA013")).symbol());
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
        hevm.warp(spell.nextCastTime());
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
            emit log("Warn: deploy gas > average block target");
            emit log_named_uint("    deploy gas", totalGas);
            emit log_named_uint("  block target", 15 * MILLION);
        }

        // Fail if deploy is too expensive
        assertLe(totalGas, 30 * MILLION, "testDeployCost/DssSpell-exceeds-max-block-size");
    }


    // Fail when contract code size exceeds 24576 bytes (a limit introduced in Spurious Dragon).
    //  This contract may not be deployable on mainnet.
    //  Consider enabling the optimizer (with a low "runs" value!),
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
        hevm.warp(1606161600); // Nov 23, 20 UTC (could be cast Nov 26)

        vote(address(spell));
        spell.schedule();

        uint256 monday_1400_UTC = 1606744800; // Nov 30, 2020
        uint256 monday_2100_UTC = 1606770000; // Nov 30, 2020

        // Day tests
        hevm.warp(monday_1400_UTC);                                    // Monday,   14:00 UTC
        assertEq(spell.nextCastTime(), monday_1400_UTC);               // Monday,   14:00 UTC

        if (spell.officeHours()) {
            hevm.warp(monday_1400_UTC - 1 days);                       // Sunday,   14:00 UTC
            assertEq(spell.nextCastTime(), monday_1400_UTC);           // Monday,   14:00 UTC

            hevm.warp(monday_1400_UTC - 2 days);                       // Saturday, 14:00 UTC
            assertEq(spell.nextCastTime(), monday_1400_UTC);           // Monday,   14:00 UTC

            hevm.warp(monday_1400_UTC - 3 days);                       // Friday,   14:00 UTC
            assertEq(spell.nextCastTime(), monday_1400_UTC - 3 days);  // Able to cast

            hevm.warp(monday_2100_UTC);                                // Monday,   21:00 UTC
            assertEq(spell.nextCastTime(), monday_1400_UTC + 1 days);  // Tuesday,  14:00 UTC

            hevm.warp(monday_2100_UTC - 1 days);                       // Sunday,   21:00 UTC
            assertEq(spell.nextCastTime(), monday_1400_UTC);           // Monday,   14:00 UTC

            hevm.warp(monday_2100_UTC - 2 days);                       // Saturday, 21:00 UTC
            assertEq(spell.nextCastTime(), monday_1400_UTC);           // Monday,   14:00 UTC

            hevm.warp(monday_2100_UTC - 3 days);                       // Friday,   21:00 UTC
            assertEq(spell.nextCastTime(), monday_1400_UTC);           // Monday,   14:00 UTC

            // Time tests
            uint256 castTime;

            for(uint256 i = 0; i < 5; i++) {
                castTime = monday_1400_UTC + i * 1 days; // Next day at 14:00 UTC
                hevm.warp(castTime - 1 seconds); // 13:59:59 UTC
                assertEq(spell.nextCastTime(), castTime);

                hevm.warp(castTime + 7 hours + 1 seconds); // 21:00:01 UTC
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
        hevm.warp(1606161600); // Nov 23, 20 UTC (could be cast Nov 26)

        vote(address(spell));
        spell.schedule();

        uint256 castTime = spell.nextCastTime();
        assertEq(castTime, spell.eta());
    }

    function testOSMs() private { // make public to use
        // address READER = address(0);

        // Track OSM authorizations here
        // assertEq(OsmAbstract(addr.addr("PIP_TOKEN")).bud(READER), 0);

        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        // assertEq(OsmAbstract(addr.addr("PIP_TOKEN")).bud(READER), 1);
    }

    function testMedianizers() private { // make private to disable
        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        // Track Median authorizations here
        // address PIP     = addr.addr("PIP_RETH");
        // address MEDIAN  = OsmAbstract(PIP).src();
        // assertEq(MedianAbstract(MEDIAN).orcl(0xa580BBCB1Cee2BCec4De2Ea870D20a12A964819e), 1);
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
    function testVestDAI() private { // make public to use
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
        // hevm.warp(OCT_01_2022 + 31 days);
        // assertTrue(tryVest(address(vest), 10));
        // assertEq(dai.balanceOf(wallets.addr("DAIF_WALLET")), prevBalance + 67_863 * WAD);

    }

    function testYankDAI() private { // make public to use

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

    function testYankMKR() private { // make public to use

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

    function testVestMKR() private { // make public to use
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

        // hevm.warp(AUG_01_2022 + 365 days);
        // vest.vest(25);
        // assertEq(gov.balanceOf(GOV_WALLET1), prevBalance + 62.50 ether);

        // hevm.warp(AUG_01_2022 + 365 days + 10 days);
        // vest.vest(25);
        // assertEq(gov.balanceOf(GOV_WALLET1), prevBalance + 62.50 ether);

        // prevBalance = gov.balanceOf(GOV_WALLET2);
        // vest.unrestrict(26);

        // hevm.warp(AUG_01_2022 + 365 days);
        // vest.vest(26);
        // assertEq(gov.balanceOf(GOV_WALLET2), prevBalance + 32.69 ether);

        // hevm.warp(AUG_01_2022 + 365 days + 10 days);
        // vest.vest(26);
        // assertEq(gov.balanceOf(GOV_WALLET2), prevBalance + 32.69 ether);

        // prevBalance = gov.balanceOf(GOV_WALLET3);
        // vest.unrestrict(27);

        // hevm.warp(AUG_01_2022 + 365 days);
        // vest.vest(27);
        // assertEq(gov.balanceOf(GOV_WALLET3), prevBalance + 152.51 ether);

        // hevm.warp(AUG_01_2022 + 365 days + 10 days);
        // vest.vest(27);
        // assertEq(gov.balanceOf(GOV_WALLET3), prevBalance + 152.51 ether);

        // prevBalance = gov.balanceOf(SNE_WALLET);
        // vest.unrestrict(28);

        // hevm.warp(SEP_28_2022 + 731 days);
        // vest.vest(28);
        // assertEq(gov.balanceOf(SNE_WALLET), prevBalance + 540.00 ether);

        // hevm.warp(SEP_28_2022 + 731 days + 10 days);
        // vest.vest(28);
        // assertEq(gov.balanceOf(SNE_WALLET), prevBalance + 540.00 ether);
    }

    function testMKRPayments() public { // make private to disable
        uint256 prevMkrPause = gov.balanceOf(address(pauseProxy));
        uint256 prevMkrTECH  = gov.balanceOf(wallets.addr("TECH_WALLET"));

        uint256 amountTECH = 257.31 ether;

        uint256 total      = 257.31 ether;

        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        assertEq(gov.balanceOf(address(pauseProxy)), prevMkrPause - total);
        assertEq(gov.balanceOf(wallets.addr("TECH_WALLET")), prevMkrTECH + amountTECH);
    }

    function testMKRVestFix() private { // make public to use
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


    // ---------------------- Centrifuge-Blocktower Vaults ----------------------

    uint256 constant INITIAL_THIS_DAI_BALANCE  =   1_000_000 * WAD;
    uint256 constant INITIAL_THIS_DROP_BALANCE = 100_000_000 * WAD;
    uint256 constant DAI_DRAW_AMOUNT           =  10_000_000 * WAD;
    uint256 constant DROP_JOIN_AMOUNT          =  20_000_000 * WAD;

    CentrifugeCollateralTestValues[] collaterals;

    function _setupCentrifugeCollaterals() internal {
        // Give Dai to this contract
        hevm.store(address(dai), keccak256(abi.encode(address(this), uint256(2))), bytes32(uint256(INITIAL_THIS_DAI_BALANCE)));
        assertEq(dai.balanceOf(address(this)), INITIAL_THIS_DAI_BALANCE);

        collaterals.push(CentrifugeCollateralTestValues({
            pipID:      "PIP_RWA010",
            ilk:        "RWA010-A",
            ilkString:  "RWA010",
            LIQ:        addr.addr("MIP21_LIQUIDATION_ORACLE"),
            GEM_JOIN:   addr.addr("MCD_JOIN_RWA010_A"),
            URN:        addr.addr("RWA010_A_URN"),
            CEIL:       20_000_000 * WAD,
            PRICE:      24_333_058 * WAD,
            DOC:        "QmRqsQRnLfaRuhFr5wCfDQZKzNo7FRVUyTJPhS76nfz6nX",
            TAU:        0,
            ROOT:       0x4597f91cC06687Bdb74147C80C097A79358Ed29b,
            DROP:       0x0b304DfFa350B32f608FF3c69f1cE511c11554cF,
            MEMBERLIST: 0xb4d81aF1E56A7AC07f2ea3cEe7A215deFECF9Bbb,
            MGR:        0x1F5C294EF3Ff2d2Da30ea9EDAd490C28096C91dF
        }));

        collaterals.push(CentrifugeCollateralTestValues({
            pipID:      "PIP_RWA011",
            ilk:        "RWA011-A",
            ilkString:  "RWA011",
            LIQ:        addr.addr("MIP21_LIQUIDATION_ORACLE"),
            GEM_JOIN:   addr.addr("MCD_JOIN_RWA011_A"),
            URN:        addr.addr("RWA011_A_URN"),
            CEIL:       30_000_000 * WAD,
            PRICE:      36_499_587 * WAD,
            DOC:        "QmRqsQRnLfaRuhFr5wCfDQZKzNo7FRVUyTJPhS76nfz6nX",
            TAU:        0,
            ROOT:       0xB5c08534d1E73582FBd79e7C45694CAD6A5C5aB2,
            DROP:       0x1a9cfB3c4D7202a428955D2baBdE5Bbb19621170,
            MEMBERLIST: 0x3Ab4F9dB708621248bC5A1578E34640423ccC273,
            MGR:        0x8e74e529049bB135CF72276C1845f5bD779749b0
        }));

        collaterals.push(CentrifugeCollateralTestValues({
            pipID:      "PIP_RWA012",
            ilk:        "RWA012-A",
            ilkString:  "RWA012",
            LIQ:        addr.addr("MIP21_LIQUIDATION_ORACLE"),
            GEM_JOIN:   addr.addr("MCD_JOIN_RWA012_A"),
            URN:        addr.addr("RWA012_A_URN"),
            CEIL:       30_000_000 * WAD,
            PRICE:      36_499_587 * WAD,
            DOC:        "QmRqsQRnLfaRuhFr5wCfDQZKzNo7FRVUyTJPhS76nfz6nX",
            TAU:        0,
            ROOT:       0x90040F96aB8f291b6d43A8972806e977631aFFdE,
            DROP:       0x1407e60059121780f05e90D4bCE14B14D003b8EF,
            MEMBERLIST: 0xF25d10F303FFD2Fa50Ef5F8C1Bc257195B301432,
            MGR:        0x795b917eBe0a812D406ae0f99D71caf36C307e21
        }));

        collaterals.push(CentrifugeCollateralTestValues({
            pipID:      "PIP_RWA013",
            ilk:        "RWA013-A",
            ilkString:  "RWA013",
            LIQ:        addr.addr("MIP21_LIQUIDATION_ORACLE"),
            GEM_JOIN:   addr.addr("MCD_JOIN_RWA013_A"),
            URN:        addr.addr("RWA013_A_URN"),
            CEIL:       70_000_000 * WAD,
            PRICE:      85_165_703 * WAD,
            DOC:        "QmRqsQRnLfaRuhFr5wCfDQZKzNo7FRVUyTJPhS76nfz6nX",
            TAU:        0,
            ROOT:       0x55d86d51Ac3bcAB7ab7d2124931FbA106c8b60c7,
            DROP:       0x306cC70e3BCB03f47586b83d35698dd783C91390,
            MEMBERLIST: 0x1Ab7c7d7b633E361F6f890E8004c66A2Bff55237,
            MGR:        0x615984F33604011Fcd76E9b89803Be3816276E61
        }));

        for (uint256 i = 0; i < collaterals.length; i++) {
            _setupCentrifugeCollateral(collaterals[i]);
        }

        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());
    }

    function _setupCentrifugeCollateral(CentrifugeCollateralTestValues memory collateral) internal {
        Root root = Root(collateral.ROOT);
        TinlakeManagerLike mgr = TinlakeManagerLike(collateral.MGR);
        DSTokenAbstract drop = DSTokenAbstract(collateral.DROP);
        MemberList memberlist = MemberList(collateral.MEMBERLIST);

        // Welcome to hevm KYC
        hevm.store(collateral.ROOT, keccak256(abi.encode(address(this), uint256(0))), bytes32(uint256(1)));
        assertEq(root.wards(address(this)), 1);

        root.relyContract(collateral.MEMBERLIST, address(this));

        memberlist.updateMember(address(this), type(uint256).max);
        memberlist.updateMember(collateral.MGR, type(uint256).max);

        // Set this contract as `ward` on `mgr`
        hevm.store(collateral.MGR, keccak256(abi.encode(address(this), uint256(0))), bytes32(uint256(1)));
        assertEq(mgr.wards(address(this)), 1);

        // Give some DROP tokens to the test contract
        hevm.store(collateral.DROP, keccak256(abi.encode(address(this), uint256(0))), bytes32(uint256(1)));
        assertEq(DropTokenAbstract(collateral.DROP).wards(address(this)), 1);

        DropTokenAbstract(collateral.DROP).mint(address(this), INITIAL_THIS_DROP_BALANCE);
        assertEq(drop.balanceOf(address(this)), INITIAL_THIS_DROP_BALANCE);

        // Approve the managers
        drop.approve(collateral.MGR, type(uint256).max);
        dai.approve(collateral.MGR, type(uint256).max);
    }

    function test_INTEGRATION_SETUP() public {
        _setupCentrifugeCollaterals();

        for (uint256 i = 0; i < collaterals.length; i++) {
            _testIntegrationSetup(collaterals[i]);
        }
    }

    function _testIntegrationSetup(CentrifugeCollateralTestValues memory collateral) internal {
        emit log_named_string("Test integration tinlake mgr setup", collateral.ilkString);

        TinlakeManagerLike mgr = TinlakeManagerLike(collateral.MGR);
        GemJoinAbstract rwaJoin = GemJoinAbstract(collateral.GEM_JOIN);
        GemAbstract rwa = GemAbstract(rwaJoin.gem());
        RwaUrnLike urn = RwaUrnLike(collateral.URN);

        assertEq(vat.wards(collateral.GEM_JOIN), 1, "Vat/gemjoin-not-ward");

        assertEq(rwa.balanceOf(collateral.GEM_JOIN), 1 * WAD, "RwaToken/not-locked");

        assertEq(rwaJoin.wards(address(urn)), 1, "Join/ward-urn-not-set");
        assertEq(urn.can(address(mgr)), 1, "Urn/operator-not-hoped");

        assertEq(mgr.liq(), collateral.LIQ, "TinlakeManager/liq-not-match");
        assertEq(mgr.urn(), collateral.URN, "TinlakeManager/urn-not-match");
        assertEq(mgr.wards(collateral.ROOT), 1, "TinlakeManager/root-not-ward");
        assertEq(mgr.wards(pauseProxy), 0, "TinlakeManager/pause-proxy-still-ward");

        RwaLiquidationLike oracle = RwaLiquidationLike(collateral.LIQ);
        (string memory doc, address pip, uint256 tau, uint256 toc) = oracle.ilks(collateral.ilk);

        assertEq(doc, collateral.DOC, "RwaLiquidationOracle/doc-not-init");
        assertTrue(pip != address(0), "RwaLiquidationOracle/ilk-not-init");
        assertEq(pip, addr.addr(collateral.pipID), "RwaLiquidationOracle/pip-not-match");
        assertEq(tau, collateral.TAU, "RwaLiquidationOracle/tau-not-match");
        assertEq(toc, 0, "RwaLiquidationOracle/unexpected-remediation");

        (pip, ) = spotter.ilks(collateral.ilk);
        assertEq(pip, addr.addr(collateral.pipID), "Spotter/pip-not-match");
    }

    function test_INTEGRATION_BUMP() public {
        _setupCentrifugeCollaterals();

        for (uint256 i = 0; i < collaterals.length; i++) {
            _testIntegrationBump(collaterals[i]);
        }
    }

    function _testIntegrationBump(CentrifugeCollateralTestValues memory collateral) internal {
        emit log_named_string("Test integration liquidation oracle bump", collateral.ilkString);

        WriteableRwaLiquidationLike oracle = WriteableRwaLiquidationLike(collateral.LIQ);
        giveAuth(address(oracle), address(this));

        (, address pip, , ) = oracle.ilks(collateral.ilk);

        assertEq(DSValueAbstract(pip).read(), bytes32(collateral.PRICE), "Bad initial PIP value");

        oracle.bump(collateral.ilk, collateral.PRICE + 10_000_000 * WAD);

        assertEq(DSValueAbstract(pip).read(), bytes32(collateral.PRICE + 10_000_000 * WAD), "Bad PIP value after bump()");
    }

    function test_INTEGRATION_TELL() public {
        _setupCentrifugeCollaterals();

        for (uint256 i = 0; i < collaterals.length; i++) {
            _testIntegrationTell(collaterals[i]);
        }
    }

    function _testIntegrationTell(CentrifugeCollateralTestValues memory collateral) internal {
        emit log_named_string("Test integration liquidation oracle tell", collateral.ilkString);

        WriteableRwaLiquidationLike oracle = WriteableRwaLiquidationLike(collateral.LIQ);

        giveAuth(address(vat), address(this));
        giveAuth(address(oracle), address(this));

        (, , , uint48 tocPre) = oracle.ilks(collateral.ilk);
        assertEq(uint256(tocPre), 0, "`toc` is not 0 before tell()");
        assertTrue(oracle.good(collateral.ilk), "Oracle not good before tell()");

        vat.file(collateral.ilk, "line", 0);
        oracle.tell(collateral.ilk);

        (, , , uint48 tocPost) = oracle.ilks(collateral.ilk);
        assertGt(uint256(tocPost), 0, "`toc` is not set after tell()");
        assertTrue(!oracle.good(collateral.ilk), "Oracle still good after tell()");
    }

    function test_INTEGRATION_TELL_CURE_GOOD() public {
        _setupCentrifugeCollaterals();

        for (uint256 i = 0; i < collaterals.length; i++) {
            _testIntegrationTellCureGood(collaterals[i]);
        }
    }

    function _testIntegrationTellCureGood(CentrifugeCollateralTestValues memory collateral) internal {
        emit log_named_string("Test integration liquidation oracle is good after tell followed by cure", collateral.ilkString);

        WriteableRwaLiquidationLike oracle = WriteableRwaLiquidationLike(collateral.LIQ);

        giveAuth(address(vat), address(this));
        giveAuth(address(oracle), address(this));

        vat.file(collateral.ilk, "line", 0);
        oracle.tell(collateral.ilk);

        assertTrue(!oracle.good(collateral.ilk), "Oracle still good after tell()");

        oracle.cure(collateral.ilk);

        assertTrue(oracle.good(collateral.ilk), "Oracle not good after cure()");
        (, , , uint48 toc) = oracle.ilks(collateral.ilk);
        assertEq(uint256(toc), 0, "`toc` not zero after cure()");
    }

    function test_INTEGRATION_TELL_CULL() public {
        _setupCentrifugeCollaterals();

        for (uint256 i = 0; i < collaterals.length; i++) {
            _testIntegrationTellCull(collaterals[i]);
        }
    }

    function _testIntegrationTellCull(CentrifugeCollateralTestValues memory collateral) internal {
        emit log_named_string("Test integration liquidation tell followed by cull", collateral.ilkString);

        WriteableRwaLiquidationLike oracle = WriteableRwaLiquidationLike(collateral.LIQ);

        giveAuth(address(vat), address(this));
        giveAuth(address(oracle), address(this));

        assertTrue(oracle.good(collateral.ilk));

        vat.file(collateral.ilk, "line", 0);
        oracle.tell(collateral.ilk);

        assertTrue(!oracle.good(collateral.ilk), "Oracle still good after tell()");

        oracle.cull(collateral.ilk, collateral.URN);

        assertTrue(!oracle.good(collateral.ilk), "Oracle still good after cull()");
        (, address pip, , ) = oracle.ilks(collateral.ilk);
        assertEq(DSValueAbstract(pip).read(), bytes32(0), "Oracle PIP value not set to zero after cull()");
    }

    function test_PAUSE_PROXY_OWNS_RWA_TOKEN_BEFORE_SPELL() public {
        for (uint256 i = 0; i < collaterals.length; i++) {
            _testPauseProxyOwnsRwaTokenBeforeSpell(collaterals[i]);
        }
    }

    function _testPauseProxyOwnsRwaTokenBeforeSpell(CentrifugeCollateralTestValues memory collateral) internal {
        emit log_named_string("Test MCD_PAUSE_PROXY owns the RWA token before the spell", collateral.ilkString);

        GemJoinAbstract gemJoin = GemJoinAbstract(collateral.GEM_JOIN);
        GemAbstract gem = GemAbstract(gemJoin.gem());

        assertEq(gem.balanceOf(pauseProxy), 1 * WAD);
    }

    function test_TINLAKE_MGR_JOIN_DRAW_WIPE_EXIT_FREE() public {
        _setupCentrifugeCollaterals();

        for (uint256 i = 0; i < collaterals.length; i++) {
            _testTinlakeMgrJoinDraw(collaterals[i]);
        }

        // Accrue some stability fees
        hevm.warp(block.timestamp + 10 days);
        for (uint256 i = 0; i < collaterals.length; i++) {
            jug.drip(collaterals[i].ilk);
        }

        for (uint256 i = 0; i < collaterals.length; i++) {
            _testTinlakeMgrWipeExitFree(collaterals[i]);
        }
    }

    function _testTinlakeMgrJoinDraw(CentrifugeCollateralTestValues memory collateral) internal {
        emit log_named_string("Test tinlake mgr join and draw", collateral.ilkString);

        TinlakeManagerLike mgr = TinlakeManagerLike(collateral.MGR);
        DSTokenAbstract drop = DSTokenAbstract(collateral.DROP);
        GemJoinAbstract gemJoin = GemJoinAbstract(collateral.GEM_JOIN);
        GemAbstract gem = GemAbstract(gemJoin.gem());

        uint256 preThisDaiBalance = dai.balanceOf(address(this));
        uint256 preMgrDropBalance = drop.balanceOf(collateral.MGR);
        assertEq(
            drop.balanceOf(address(this)),
            INITIAL_THIS_DROP_BALANCE,
            "Pre-condition: initial address(this) drop balance mismatch"
        );

        // Check if the RWA token is locked into the Urn
        assertEq(gem.balanceOf(address(gemJoin)), 1 * WAD, "Pre-condition: gem not locked into the urn");
        // 0 DAI in mgr
        assertEq(dai.balanceOf(address(mgr)), 0, "Dangling Dai in mgr before draw()");

        mgr.join(DROP_JOIN_AMOUNT);
        mgr.draw(DAI_DRAW_AMOUNT);

        assertEq(
            dai.balanceOf(address(this)),
            preThisDaiBalance + DAI_DRAW_AMOUNT,
            "Post-condition: invalid Dai balance on address(this)"
        );
        assertEq(
            drop.balanceOf(address(this)),
            INITIAL_THIS_DROP_BALANCE - DROP_JOIN_AMOUNT,
            "Post-condition: invalid Drop balance on address(this)"
        );
        assertEq(
            drop.balanceOf(address(mgr)),
            preMgrDropBalance + DROP_JOIN_AMOUNT,
            "Post-condition: invalid Drop balance on mgr"
        );

        (uint256 ink, uint256 art) = vat.urns(collateral.ilk, collateral.URN);
        assertEq(art, DAI_DRAW_AMOUNT, "Post-condition: bad art on vat"); // DAI drawn == art as rate should always be 1 RAY
        assertEq(ink, 1 * WAD, "Post-condition: bad ink on vat"); // Whole unit of collateral is locked
    }

    function _testTinlakeMgrWipeExitFree(CentrifugeCollateralTestValues memory collateral) internal {
        emit log_named_string("Test tinlake mgr wipe and exit", collateral.ilkString);

        TinlakeManagerLike mgr = TinlakeManagerLike(collateral.MGR);
        DSTokenAbstract drop = DSTokenAbstract(collateral.DROP);
        GemJoinAbstract gemJoin = GemJoinAbstract(collateral.GEM_JOIN);
        GemAbstract gem = GemAbstract(gemJoin.gem());

        uint256 preThisDaiBalance = dai.balanceOf(address(this));
        uint256 preThisDropBalance = drop.balanceOf(address(this));
        uint256 preThisGemBalance = gem.balanceOf(address(this));

        uint256 daiToPay = 100 * WAD;
        uint256 dropToExit = 100 * WAD;
        uint256 gemToFree = 1 * WAD / 10**3; // 0.001 RWA

        mgr.wipe(daiToPay);
        mgr.exit(dropToExit);
        mgr.free(gemToFree);

        assertEq(
            dai.balanceOf(address(this)),
            preThisDaiBalance - daiToPay,
            "Post-condition: invalid Dai balance on address(this)"
        );
        assertEq(
            drop.balanceOf(address(this)),
            preThisDropBalance + dropToExit,
            "Post-condition: invalid DROP balance on address(this)"
        );
        assertEq(
            gem.balanceOf(address(mgr)),
            preThisGemBalance + gemToFree,
            "Post-condition: invalid Gem balance on mgr"
        );
    }

    function testFail_DRAW_ABOVE_LINE() public {
        _setupCentrifugeCollaterals();

        // A better way to write this would be to leverage Foundry vm.expectRevert,
        // however since we are still using DappTools compatibility mode, we need a way
        // to assert agains multiple reversions.
        uint256 failCount = 0;
        for (uint256 i = 0; i < collaterals.length; i++) {
            try this._testFailDrawAboveLine(collaterals[i]) {
                emit log_named_string("Able to draw above line", collaterals[i].ilkString);
            } catch {
                failCount++;
            }
        }

        if (failCount == collaterals.length) {
            revert("Draw above line");
        }
    }

    // Needs to be external to be able to use try...catch above.
    function _testFailDrawAboveLine(CentrifugeCollateralTestValues memory collateral) external {
        emit log_named_string("Test tinlake draw above line", collateral.ilkString);

        TinlakeManagerLike mgr = TinlakeManagerLike(collateral.MGR);

        uint256 drawAmount = collateral.CEIL + 100_000_000;

        mgr.join(DROP_JOIN_AMOUNT);
        mgr.draw(drawAmount);
    }

    function test_TINLAKE_MGR_LOCK_DRAW_CAGE() public {
        _setupCentrifugeCollaterals();

        for (uint256 i = 0; i < collaterals.length; i++) {
            _testTinlakeMgrJoinDraw(collaterals[i]);
        }

        // Accrue some stability fees
        hevm.warp(block.timestamp + 10 days);
        for (uint256 i = 0; i < collaterals.length; i++) {
            jug.drip(collaterals[i].ilk);
        }

        // END
        giveAuth(address(end), address(this));
        end.cage();
        hevm.warp(block.timestamp + end.wait());

        for (uint256 i = 0; i < collaterals.length; i++) {
            _testTinlakeMgrCageSkim(collaterals[i]);
        }

        vow.heal(min(vat.dai(address(vow)), sub(sub(vat.sin(address(vow)), vow.Sin()), vow.Ash())));

        // Removing the surplus to allow continuing the execution.
        hevm.store(
            address(vat),
            keccak256(abi.encode(address(vow), uint256(5))),
            bytes32(uint256(0))
        );

        end.thaw();

        for (uint256 i = 0; i < collaterals.length; i++) {
            _testTinlakeMgrPostCageFlow(collaterals[i]);
        }
    }

    function _testTinlakeMgrCageSkim(CentrifugeCollateralTestValues memory collateral) internal {
        emit log_named_string("Test tinlake post-cage skim", collateral.ilkString);

        end.cage(collateral.ilk);
        end.skim(collateral.ilk, collateral.URN);

        (uint256 ink, uint256 art) = vat.urns(collateral.ilk, collateral.URN);
        uint256 skimmedInk = DAI_DRAW_AMOUNT * WAD / collateral.PRICE;
        uint256 remainingInk = 1 * WAD - skimmedInk;
        // Cope with rounding errors
        assertLt(remainingInk - ink, 10**16, "wrong ink in urn after skim");
        assertEq(art, 0, "wrong art in urn after skim");
    }

    function _testTinlakeMgrPostCageFlow(CentrifugeCollateralTestValues memory collateral) internal {
        GemJoinAbstract gemJoin = GemJoinAbstract(collateral.GEM_JOIN);
        GemAbstract gem = GemAbstract(gemJoin.gem());

        end.flow(collateral.ilk);

        giveTokens(address(dai), 1_000_000 * WAD);
        dai.approve(address(daiJoin), 1_000_000 * WAD);
        daiJoin.join(address(this), 1_000_000 * WAD);

        vat.hope(address(end));
        end.pack(1_000_000 * WAD);

        // Check DAI redemption after "cage()"
        assertEq(vat.gem(collateral.ilk, address(this)), 0, "wrong vat gem");
        assertEq(gem.balanceOf(address(this)), 0, "wrong gem balance");
        end.cash(collateral.ilk, 1_000_000 * WAD);
        assertGt(vat.gem(collateral.ilk, address(this)), 0, "wrong vat gem after cash");
        assertEq(gem.balanceOf(address(this)), 0, "wrong gem balance after cash");
        gemJoin.exit(address(this), vat.gem(collateral.ilk, address(this)));
        assertEq(vat.gem(collateral.ilk, address(this)), 0, "wrong vat gem after exit");
        assertGt(gem.balanceOf(address(this)), 0, "wrong gem balance after exit");
    }
}
