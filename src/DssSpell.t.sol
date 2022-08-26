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

interface CureLike {
    function tCount() external view returns (uint256);
    function srcs(uint256) external view returns (address);
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

            // If the spell is deployed compare the on-chain bytecode size with the generated bytecode size.
            // extcodehash doesn't match, potentially because it's address-specific, avenue for further research.
            address depl_spell = spellValues.deployed_spell;
            address code_spell = address(new DssSpell());
            assertEq(getExtcodesize(depl_spell), getExtcodesize(code_spell), "TestError/spell-codesize");
        }

        assertTrue(spell.officeHours() == spellValues.office_hours_enabled, "TestError/spell-office-hours");

        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done(), "TestError/spell-not-done");

        checkSystemValues(afterSpell);

        checkCollateralValues(afterSpell);
    }

    struct Payee {
        address addr;
        uint256 amount;
    }

    function testPayments() private { // make public to use
        uint256 prevSin = vat.sin(address(vow));

        // For each payment, create a Payee object with
        //    the Payee address,
        //    the amount to be paid in whole Dai units
        // Initialize the array with the number of payees
        Payee[14] memory payees = [
            Payee(wallets.addr("FLIPFLOPFLAP"),      12_000),
            Payee(wallets.addr("FEEDBLACKLOOPS"),    12_000),
            Payee(wallets.addr("JUSTINCASE"),        12_000),
            Payee(wallets.addr("DOO"),               12_000),
            Payee(wallets.addr("ULTRASCHUPPI"),      11_918),
            Payee(wallets.addr("FLIPSIDE"),          11_387),
            Payee(wallets.addr("PENNBLOCKCHAIN"),     9_438),
            Payee(wallets.addr("CHRISBLEC"),          9_174),
            Payee(wallets.addr("GFXLABS"),            8_512),
            Payee(wallets.addr("MAKERMAN"),           6_912),
            Payee(wallets.addr("ACREINVEST"),         6_628),
            Payee(wallets.addr("MHONKASALOTEEMULAU"), 4_029),
            Payee(wallets.addr("LLAMA"),              3_797),
            Payee(wallets.addr("BLOCKCHAINCOLUMBIA"), 2_013)
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
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        assertEq(vat.sin(address(vow)) - prevSin, totAmount * RAD);

        for (uint256 i = 0; i < payees.length; i++) {
            assertEq(
                dai.balanceOf(payees[i].addr) - prevAmounts[i],
                payees[i].amount * WAD
            );
        }
    }

    function testCollateralIntegrations() private { // make public to use
        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        // Insert new collateral tests here
        checkIlkIntegration(
             "TOKEN-X",
             GemJoinAbstract(addr.addr("MCD_JOIN_TOKEN_X")),
             ClipAbstract(addr.addr("MCD_CLIP_TOKEN_X")),
             addr.addr("PIP_TOKEN"),
             true,
             true,
             false
        );
    }

    function testIlkClipper() private { // make public to use
        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        // Insert new ilk clipper tests here
        checkIlkClipper(
            "TOKEN-X",
            GemJoinAbstract(addr.addr("MCD_JOIN_TOKEN_X")),
            ClipAbstract(addr.addr("MCD_CLIP_TOKEN_X")),
            addr.addr("MCD_CLIP_CALC_TOKEN_X"),
            OsmAbstract(addr.addr("PIP_TOKEN")),
            20_000 * WAD
        );
    }

    function testNewChainlogValues() public { // make public to use
        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        checkChainlogKey("MCD_JOIN_TELEPORT_FW_A");
        checkChainlogKey("MCD_ORACLE_AUTH_TELEPORT_FW_A");
        checkChainlogKey("MCD_ROUTER_TELEPORT_FW_A");
        checkChainlogKey("OPTIMISM_TELEPORT_BRIDGE");
        checkChainlogKey("OPTIMISM_TELEPORT_FEE");
        checkChainlogKey("OPTIMISM_DAI_BRIDGE");
        checkChainlogKey("OPTIMISM_ESCROW");
        checkChainlogKey("OPTIMISM_GOV_RELAY");
        checkChainlogKey("ARBITRUM_TELEPORT_BRIDGE");
        checkChainlogKey("ARBITRUM_TELEPORT_FEE");
        checkChainlogKey("ARBITRUM_DAI_BRIDGE");
        checkChainlogKey("ARBITRUM_ESCROW");
        checkChainlogKey("ARBITRUM_GOV_RELAY");

        checkChainlogVersion("1.14.0");
    }

    function testNewIlkRegistryValues() public { // make public to use
        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        // Insert new ilk registry values tests here
        assertEq(reg.pos("TELEPORT-FW-A"), 52);
        assertEq(reg.join("TELEPORT-FW-A"), addr.addr("MCD_JOIN_TELEPORT_FW_A"));
        assertEq(reg.gem("TELEPORT-FW-A"), addr.addr("MCD_DAI"));
        assertEq(reg.dec("TELEPORT-FW-A"), GemAbstract(addr.addr("MCD_DAI")).decimals());
        assertEq(reg.class("TELEPORT-FW-A"), 4);
        assertEq(reg.pip("TELEPORT-FW-A"), address(0));
        assertEq(reg.xlip("TELEPORT-FW-A"), address(0));
        assertEq(reg.name("TELEPORT-FW-A"), "Dai Stablecoin");
        assertEq(reg.symbol("TELEPORT-FW-A"), "DAI");

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
        assertTrue(totalGas <= 10 * MILLION);
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
        address READER = address(0);

        // Track OSM authorizations here
        assertEq(OsmAbstract(addr.addr("PIP_TOKEN")).bud(READER), 0);

        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        assertEq(OsmAbstract(addr.addr("PIP_TOKEN")).bud(READER), 1);
    }

    function testMedianizers() private { // make public to use
        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        // Track Median authorizations here
        address PIP     = addr.addr("PIP_XXX");
        address MEDIAN  = OsmAbstract(PIP).src();
        assertEq(MedianAbstract(MEDIAN).bud(PIP), 1);
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
        address expectedAction = (new DssSpell()).action();
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
        assertEq(expectedHash, actualHash);
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

    function testVestDAI() private {
        VestAbstract vest = VestAbstract(addr.addr("MCD_VEST_DAI"));

        address KEEP3R_VEST_STREAMING = wallets.addr("KEEP3R_VEST_STREAMING");

        // Friday, 1 July 2022 00:00:00
        uint256 JUL_01_2022 = 1656633600;
        // Wednesday, 1 February 2023 00:00:00
        uint256 FEB_01_2023 = 1675209600;

        assertEq(vest.ids(), 8);

        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        assertEq(vest.ids(), 9);

        assertEq(vest.cap(), 1 * MILLION * WAD / 30 days);

        assertEq(vest.usr(9), KEEP3R_VEST_STREAMING);
        assertEq(vest.bgn(9), JUL_01_2022);
        assertEq(vest.clf(9), JUL_01_2022);
        assertEq(vest.fin(9), FEB_01_2023);
        assertEq(vest.fin(9), JUL_01_2022 + 215 days);
        assertEq(vest.mgr(9), 0x45fEEBbd5Cf86dF61be8F81025E22Ae07a07cB23);
        assertEq(vest.res(9), 1);
        assertEq(vest.tot(9), 215000 * WAD);
        assertEq(vest.rxd(9), 0);

        // Give admin powers to Test contract address and make the vesting unrestricted for testing
        giveAuth(address(vest), address(this));
        vest.unrestrict(9);

        uint256 prevBalance = dai.balanceOf(KEEP3R_VEST_STREAMING);
        hevm.warp(JUL_01_2022 + 215 days);
        assertTrue(tryVest(address(vest), 9));
        assertEq(dai.balanceOf(KEEP3R_VEST_STREAMING), prevBalance + 215000 * WAD);
    }

    function testYankDAI() private { // make private if not in use

        VestAbstract vest = VestAbstract(addr.addr("MCD_VEST_DAI"));
        address KEEP3R_VEST_STREAMING_LEGACY = wallets.addr("KEEP3R_VEST_STREAMING_LEGACY");
        // Tuesday, 31 January 2023 00:00:00
        uint256 JAN_31_2023 = 1675123200;

        assertEq(vest.usr(8), KEEP3R_VEST_STREAMING_LEGACY);
        assertEq(vest.fin(8), JAN_31_2023);

        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        assertEq(vest.fin(8), block.timestamp);
    }

    function testVestMKR() private {
        VestAbstract vest = VestAbstract(addr.addr("MCD_VEST_MKR_TREASURY"));
        assertEq(vest.ids(), 22);

        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        assertEq(vest.cap(), 1_100 * WAD / 365 days);
        assertEq(vest.ids(), 23);

        // Wed 01 Jun 2022 12:00:00 AM UTC
        uint256 JUN_01_2022 = 1654041600;
        // Thu 23 Nov 2023 12:00:00 AM UTC
        uint256 NOV_23_2023 = 1700697600;
        address SH_WALLET = wallets.addr("SH_WALLET");

        // -----
        assertEq(vest.usr(23), SH_WALLET);
        assertEq(vest.bgn(23), JUN_01_2022);
        assertEq(vest.clf(23), NOV_23_2023);
        assertEq(vest.fin(23), JUN_01_2022 + 4 * 365 days);
        assertEq(vest.mgr(23), wallets.addr("SH_WALLET"));
        assertEq(vest.res(23), 1);
        assertEq(vest.tot(23), 250 * 10**18);
        assertEq(vest.rxd(23), 0);


        uint256 prevBalance = gov.balanceOf(SH_WALLET);
        // 20220608 exec: Warp 2 years since cliff here is 18 months
        hevm.warp(JUN_01_2022 + 2 * 365 days);

        // // Give admin powers to Test contract address and make the vesting unrestricted for testing
        giveAuth(address(vest), address(this));
        vest.unrestrict(23);

        vest.vest(23);
        // 20220608 exec: Ensure 2 years vest accumulated
        assertEq(gov.balanceOf(SH_WALLET), prevBalance + (250 * WAD / 4) * 2);
    }

    function testMKRPayments() private {

        uint256 prevMkrPause = gov.balanceOf(address(pauseProxy));
        uint256 prevMkrRisk = gov.balanceOf(wallets.addr("RISK_WALLET_VEST"));

        uint256 amountRisk  = 175 * WAD;

        uint256 total = amountRisk;

        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        assertEq(gov.balanceOf(address(pauseProxy)), prevMkrPause - total);
        assertEq(gov.balanceOf(wallets.addr("RISK_WALLET_VEST")), prevMkrRisk + amountRisk);
    }

    function testRWA009_SPELL_DRAW() public {
        address rwaUrn009       = addr.addr("RWA009_A_URN");
        address rwaUrn009Output = addr.addr("RWA009_A_OUTPUT_CONDUIT"); 

        (uint256 pink, uint256 part) = vat.urns("RWA009-A", address(rwaUrn009));
        uint256 prevBalance = dai.balanceOf(address(rwaUrn009Output));

        assertEq(pink, 1 * WAD, "RWA009/bad-ink-before-spell");

        uint256 drawAmount = 25_000_000 * WAD;

        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        // Check if spell draw 25mm DAI to Output Conduit
        assertEq(dai.balanceOf(address(rwaUrn009Output)), prevBalance + drawAmount, "RWA009/dai-drawn-was-not-sent-to-the-recipient");

        (uint256 ink, uint256 art) = vat.urns("RWA009-A", address(rwaUrn009));
        assertEq(art, part + drawAmount, "RWA009/bad-art-after-spell"); // DAI drawn == art as rate should always be 1 RAY
        assertEq(ink, pink,              "RWA009/bad-ink-after-spell"); // Whole unit of collateral is locked. should not change
    }

    // NOTE: Only executable by forge
    function testTeleportFW() public {
        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        TeleportJoinLike join = TeleportJoinLike(addr.addr("MCD_JOIN_TELEPORT_FW_A"));
        TeleportOracleAuthLike oracleAuth = TeleportOracleAuthLike(addr.addr("MCD_ORACLE_AUTH_TELEPORT_FW_A"));
        TeleportRouterLike router = TeleportRouterLike(addr.addr("MCD_ROUTER_TELEPORT_FW_A"));

        bytes32 ilk = "TELEPORT-FW-A";
        bytes23 domain = "ETH-MAIN-A";

        // Sanity checks
        assertEq(vat.wards(address(join)), 1);

        assertEq(join.wards(address(oracleAuth)), 1);
        assertEq(join.wards(address(router)), 1);
        assertEq(join.vow(), address(vow));
        assertEq(join.daiJoin(), address(daiJoin));
        assertEq(join.vat(), address(vat));
        assertEq(join.ilk(), ilk);
        assertEq(join.domain(), domain);

        assertEq(oracleAuth.signers(0xaC8519b3495d8A3E3E44c041521cF7aC3f8F63B3), 1);
        assertEq(oracleAuth.signers(0x4f95d9B4D842B2E2B1d1AC3f2Cf548B93Fd77c67), 1);
        assertEq(oracleAuth.signers(0xE6367a7Da2b20ecB94A25Ef06F3b551baB2682e6), 1);
        assertEq(oracleAuth.signers(0xFbaF3a7eB4Ec2962bd1847687E56aAEE855F5D00), 1);
        assertEq(oracleAuth.signers(0x16655369Eb59F3e1cAFBCfAC6D3Dd4001328f747), 1);
        assertEq(oracleAuth.signers(0xC9508E9E3Ccf319F5333A5B8c825418ABeC688BA), 1);
        assertEq(oracleAuth.signers(0xA8EB82456ed9bAE55841529888cDE9152468635A), 1);
        assertEq(oracleAuth.signers(0x83e23C207a67a9f9cB680ce84869B91473403e7d), 1);
        assertEq(oracleAuth.signers(0xDA1d2961Da837891f43235FddF66BAD26f41368b), 1);
        assertEq(oracleAuth.signers(0x4b0E327C08e23dD08cb87Ec994915a5375619aa2), 1);
        assertEq(oracleAuth.signers(0xfeEd00AA3F0845AFE52Df9ECFE372549B74C69D2), 1);
        assertEq(oracleAuth.signers(0x8aFBD9c3D794eD8DF903b3468f4c4Ea85be953FB), 1);
        assertEq(oracleAuth.signers(0x8de9c5F1AC1D4d02bbfC25fD178f5DAA4D5B26dC), 1);
        assertEq(oracleAuth.signers(0xd94BBe83b4a68940839cD151478852d16B3eF891), 1);
        assertEq(oracleAuth.signers(0xa580BBCB1Cee2BCec4De2Ea870D20a12A964819e), 1);
        assertEq(oracleAuth.signers(0x75ef8432566A79C86BBF207A47df3963B8Cf0753), 1);
        assertEq(oracleAuth.signers(0xD27Fa2361bC2CfB9A591fb289244C538E190684B), 1);
        assertEq(oracleAuth.signers(0x60da93D9903cb7d3eD450D4F81D402f7C4F71dd9), 1);
        assertEq(oracleAuth.signers(0x71eCFF5261bAA115dcB1D9335c88678324b8A987), 1);
        assertEq(oracleAuth.signers(0x77EB6CF8d732fe4D92c427fCdd83142DB3B742f7), 1);
        assertEq(oracleAuth.signers(0x8ff6a38A1CD6a42cAac45F08eB0c802253f68dfD), 1);
        assertEq(oracleAuth.signers(0x130431b4560Cd1d74A990AE86C337a33171FF3c6), 1);
        assertEq(oracleAuth.signers(0x3CB645a8f10Fb7B0721eaBaE958F77a878441Cb9), 1);
        assertEq(oracleAuth.signers(0xd72BA9402E9f3Ff01959D6c841DDD13615FFff42), 1);

        assertEq(oracleAuth.teleportJoin(), address(join));
        assertEq(oracleAuth.threshold(), 13);

        assertEq(router.gateways(domain), address(join));
        assertEq(router.domains(address(join)), domain);
        assertEq(router.dai(), address(dai));

        assertEq(CureLike(cure).srcs(CureLike(cure).tCount() - 1), address(join));

        checkTeleportFWIntegration(
            "OPT-MAIN-A",
            domain,
            1_000_000 * WAD,
            addr.addr("OPTIMISM_TELEPORT_BRIDGE"),
            addr.addr("OPTIMISM_TELEPORT_FEE"),
            addr.addr("OPTIMISM_ESCROW"),
            100 * WAD,
            WAD / 10000,   // 1bps
            8 days
        );

        checkTeleportFWIntegration(
            "ARB-ONE-A",
            domain,
            1_000_000 * WAD,
            addr.addr("ARBITRUM_TELEPORT_BRIDGE"),
            addr.addr("ARBITRUM_TELEPORT_FEE"),
            addr.addr("ARBITRUM_ESCROW"),
            100 * WAD,
            WAD / 10000,   // 1bps
            8 days
        );
    }
}
