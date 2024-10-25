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

interface SpellActionLike {
    function dao_resolutions() external view returns (string memory);
}

interface SequencerLike {
    function getMaster() external view returns (bytes32);
    function hasJob(address job) external view returns (bool);
}

interface AuthLike {
    function wards(address) external view returns (uint256);
}

interface L1TokenBridgeLike {
    function l1ToL2Token(address) external view returns (address);
    function isOpen() external view returns (uint256);
    function escrow() external view returns (address);
    function otherBridge() external view returns (address);
    function messenger() external view returns (address);
    function version() external view returns (string memory);
    function getImplementation() external view returns (address);
    function bridgeERC20To(
        address _localToken,
        address _remoteToken,
        address _to,
        uint256 _amount,
        uint32 _minGasLimit,
        bytes memory _extraData
    ) external;
}

interface L2TokenBridgeLike {
    function l1ToL2Token(address) external view returns (address);
    function isOpen() external view returns (uint256);
    function escrow() external view returns (address);
    function otherBridge() external view returns (address);
    function messenger() external view returns (address);
    function version() external view returns (string memory);
    function maxWithdraws(address) external view returns (uint256);
    function getImplementation() external view returns (address);
    function bridgeERC20To(
        address _localToken,
        address _remoteToken,
        address _to,
        uint256 _amount,
        uint32 _minGasLimit,
        bytes memory _extraData
    ) external;
}

interface BaseGovRelayLike {
    function l2GovernanceRelay() external view returns (address);
    function l1GovernanceRelay() external view returns (address);
    function messenger() external view returns (address);
}

interface L2BridgeSpell {
    function l2Bridge() external view returns (address);
}

interface AllocatorVaultLike {
    function buffer() external view returns (address);
    function draw(uint256 wad) external;
    function ilk() external view returns (bytes32);
    function jug() external view returns (address);
    function roles() external view returns (address);
    function usdsJoin() external view returns (address);
    function vat() external view returns (address);
    function wards(address) external view returns (uint256);
    function wipe(uint256 wad) external;
}

interface AllocatorRegistryLike {
    function buffers(bytes32) external view returns (address);
}

interface AllocatorRolesLike {
    function ilkAdmins(bytes32) external view returns (address);
}

interface DssLitePsm {
    function bud(address) external view returns (uint256);
}

interface MedianLike {
    function orcl(address) external view returns (uint256);
}

contract DssSpellTest is DssSpellTestBase {
    string         config;
    RootDomain     rootDomain;
    OptimismDomain optimismDomain;
    ArbitrumDomain arbitrumDomain;
    OptimismDomain baseDomain;

    // DO NOT TOUCH THE FOLLOWING TESTS, THEY SHOULD BE RUN ON EVERY SPELL
    function testGeneral() public {
        _testGeneral();
    }

    function testOfficeHours() public {
        _testOfficeHours();
    }

    function testCastOnTime() public {
        _testCastOnTime();
    }

    function testNextCastTime() public {
        _testNextCastTime();
    }

    function testRevertIfNotScheduled() public {
        _testRevertIfNotScheduled();
    }

    function testUseEta() public {
        _testUseEta();
    }

    function testContractSize() public skippedWhenDeployed {
        _testContractSize();
    }

    function testDeployCost() public skippedWhenDeployed {
        _testDeployCost();
    }

    function testBytecodeMatches() public skippedWhenNotDeployed {
        _testBytecodeMatches();
    }

    function testCastCost() public {
        _testCastCost();
    }

    function testChainlogIntegrity() public {
        _testChainlogIntegrity();
    }

    function testChainlogValues() public {
        _testChainlogValues();
    }

    function testSplitter() public {
        _testSplitter();
    }

    function testSystemTokens() public {
        _testSystemTokens();
    }

    // Leave this test always enabled as it acts as a config test
    function testPSMs() public {
        _vote(address(spell));
        _scheduleWaitAndCast(address(spell));
        assertTrue(spell.done(), "TestError/spell-not-done");

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

    // Leave this test always enabled as it acts as a config test
    function testLitePSMs() public {
        _vote(address(spell));
        _scheduleWaitAndCast(address(spell));
        assertTrue(spell.done(), "TestError/spell-not-done");

        bytes32 _ilk;

        // USDC
        _ilk = "LITE-PSM-USDC-A";
        assertEq(addr.addr("PIP_USDC"),            reg.pip(_ilk));
        assertEq(addr.addr("MCD_LITE_PSM_USDC_A"), chainLog.getAddress("MCD_LITE_PSM_USDC_A"));
        _checkLitePsmIlkIntegration(
            LitePsmIlkIntegrationParams({
                ilk:      _ilk,
                pip:      addr.addr("PIP_USDC"),
                litePsm:  addr.addr("MCD_LITE_PSM_USDC_A"),
                pocket:   addr.addr("MCD_LITE_PSM_USDC_A_POCKET"),
                bufUnits: 400_000_000,
                tinBps:             0,
                toutBps:            0
            })
        );
    }

    // END OF TESTS THAT SHOULD BE RUN ON EVERY SPELL

    // TESTS BELOW CAN BE ENABLED/DISABLED ON DEMAND

    function testOracleList() public skipped { // TODO: check if this test can be removed for good.
        // address ORACLE_WALLET01 = 0x4D6fbF888c374D7964D56144dE0C0cFBd49750D3;

        //assertEq(OsmAbstract(0xF15993A5C5BE496b8e1c9657Fd2233b579Cd3Bc6).wards(ORACLE_WALLET01), 0);

        //_vote(address(spell));
        //_scheduleWaitAndCast(address(spell));
        //assertTrue(spell.done());

        //assertEq(OsmAbstract(0xF15993A5C5BE496b8e1c9657Fd2233b579Cd3Bc6).wards(ORACLE_WALLET01), 1);
    }

    function testRemoveChainlogValues() public skipped { // add the `skipped` modifier to skip
        string[1] memory removedKeys = [
            "VOTE_DELEGATE_PROXY_FACTORY"
        ];

        for (uint256 i = 0; i < removedKeys.length; i++) {
            try chainLog.getAddress(_stringToBytes32(removedKeys[i])) {
            } catch Error(string memory errmsg) {
                if (_cmpStr(errmsg, "dss-chain-log/invalid-key")) {
                    revert(_concat("TestError/key-to-remove-does-not-exist: ", removedKeys[i]));
                } else {
                    revert(errmsg);
                }
            }
        }

        _vote(address(spell));
        _scheduleWaitAndCast(address(spell));
        assertTrue(spell.done(), "TestError/spell-not-done");

        for (uint256 i = 0; i < removedKeys.length; i++) {
            try chainLog.getAddress(_stringToBytes32(removedKeys[i])) {
                revert(_concat("TestError/key-not-removed: ", removedKeys[i]));
            } catch Error(string memory errmsg) {
                assertTrue(
                    _cmpStr(errmsg, "dss-chain-log/invalid-key"),
                    _concat("TestError/key-not-removed: ", removedKeys[i])
                );
            } catch {
                revert(_concat("TestError/unknown-reason: ", removedKeys[i]));
            }
        }
    }

    function testCollateralIntegrations() public skipped { // add the `skipped` modifier to skip
        _vote(address(spell));
        _scheduleWaitAndCast(address(spell));
        assertTrue(spell.done(), "TestError/spell-not-done");

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

    function testIlkClipper() public skipped { // add the `skipped` modifier to skip
        _vote(address(spell));
        _scheduleWaitAndCast(address(spell));
        assertTrue(spell.done(), "TestError/spell-not-done");

       _checkIlkClipper(
            "RETH-A",
            GemJoinAbstract(addr.addr("MCD_JOIN_RETH_A")),
            ClipAbstract(addr.addr("MCD_CLIP_RETH_A")),
            addr.addr("MCD_CLIP_CALC_RETH_A"),
            OsmAbstract(addr.addr("PIP_RETH")),
            1_000 * WAD
        );
    }

    function testLockstakeIlkIntegration() public skipped { // add the `skipped` modifier to skip
        _vote(address(spell));
        _scheduleWaitAndCast(address(spell));
        assertTrue(spell.done(), "TestError/spell-not-done");

        _checkLockstakeIlkIntegration(
            LockstakeIlkParams({
                ilk:    "LSE-MKR-A",
                fee:    5_00,
                pip:    addr.addr("PIP_MKR"),
                lsmkr:  addr.addr("LOCKSTAKE_MKR"),
                engine: addr.addr("LOCKSTAKE_ENGINE"),
                clip:   addr.addr("LOCKSTAKE_CLIP"),
                calc:   addr.addr("LOCKSTAKE_CLIP_CALC"),
                farm:   addr.addr("REWARDS_LSMKR_USDS"),
                rToken: addr.addr("USDS"),
                rDistr: addr.addr("MCD_SPLIT"),
                rDur:   15_649 seconds
            })
        );
    }

    function testLerpSurplusBuffer() public skipped { // add the `skipped` modifier to skip
        _vote(address(spell));
        _scheduleWaitAndCast(address(spell));
        assertTrue(spell.done(), "TestError/spell-not-done");

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

    function testEsmAuth() public skipped { // add the `skipped` modifier to skip
        string[1] memory esmAuthorisedContractKeys = [
            "MCD_LITE_PSM_USDC_A_IN_CDT_JAR"
        ];

        for (uint256 i = 0; i < esmAuthorisedContractKeys.length; i++) {
            assertEq(
                WardsAbstract(addr.addr(_stringToBytes32(esmAuthorisedContractKeys[i]))).wards(address(esm)),
                0,
                _concat("TestError/esm-is-ward-before-spell: ", esmAuthorisedContractKeys[i])
            );
        }

        _vote(address(spell));
        _scheduleWaitAndCast(address(spell));
        assertTrue(spell.done(), "TestError/spell-not-done");

        for (uint256 i = 0; i < esmAuthorisedContractKeys.length; i++) {
            assertEq(
                WardsAbstract(addr.addr(_stringToBytes32(esmAuthorisedContractKeys[i]))).wards(address(esm)),
                1,
                _concat("TestError/esm-is-not-ward-after-spell: ", esmAuthorisedContractKeys[i])
            );
        }
    }

    function testOsmReaders() public skipped { // add the `skipped` modifier to skip
        address OSM = addr.addr("PIP_MKR");
        address[4] memory newReaders = [
            addr.addr("MCD_SPOT"),
            addr.addr("LOCKSTAKE_CLIP"),
            addr.addr("CLIPPER_MOM"),
            addr.addr("MCD_END")
        ];

        for (uint256 i = 0; i < newReaders.length; i++) {
            assertEq(OsmAbstract(OSM).bud(newReaders[i]), 0);
        }

        _vote(address(spell));
        _scheduleWaitAndCast(address(spell));
        assertTrue(spell.done(), "TestError/spell-not-done");

        for (uint256 i = 0; i < newReaders.length; i++) {
            assertEq(OsmAbstract(OSM).bud(newReaders[i]), 1);
        }
    }

    function testMedianReaders() public skipped { // add the `skipped` modifier to skip
        address median = chainLog.getAddress("PIP_MKR"); // PIP_MKR before spell
        address[1] memory newReaders = [
            addr.addr('PIP_MKR') // PIP_MKR after spell
        ];

        for (uint256 i = 0; i < newReaders.length; i++) {
            assertEq(MedianAbstract(median).bud(newReaders[i]), 0);
        }

        _vote(address(spell));
        _scheduleWaitAndCast(address(spell));
        assertTrue(spell.done(), "TestError/spell-not-done");

        for (uint256 i = 0; i < newReaders.length; i++) {
            assertEq(MedianAbstract(median).bud(newReaders[i]), 1);
        }
    }

    struct Authorization {
        bytes32 base;
        bytes32 ward;
    }

    function testNewAuthorizations() public skipped { // add the `skipped` modifier to skip
        Authorization[9] memory newAuthorizations = [
            Authorization({ base: "MCD_VAT",          ward: "LOCKSTAKE_ENGINE" }),
            Authorization({ base: "MCD_VAT",          ward: "LOCKSTAKE_CLIP" }),
            Authorization({ base: "PIP_MKR",          ward: "OSM_MOM" }),
            Authorization({ base: "MCD_DOG",          ward: "LOCKSTAKE_CLIP" }),
            Authorization({ base: "LOCKSTAKE_MKR",    ward: "LOCKSTAKE_ENGINE" }),
            Authorization({ base: "LOCKSTAKE_ENGINE", ward: "LOCKSTAKE_CLIP" }),
            Authorization({ base: "LOCKSTAKE_CLIP",   ward: "MCD_DOG" }),
            Authorization({ base: "LOCKSTAKE_CLIP",   ward: "MCD_END" }),
            Authorization({ base: "LOCKSTAKE_CLIP",   ward: "CLIPPER_MOM" })
        ];

        for (uint256 i = 0; i < newAuthorizations.length; i++) {
            address base = addr.addr(newAuthorizations[i].base);
            address ward = addr.addr(newAuthorizations[i].ward);
            assertEq(WardsAbstract(base).wards(ward), 0, _concat("testNewAuthorizations/already-authorized-", newAuthorizations[i].base));
        }

        _vote(address(spell));
        _scheduleWaitAndCast(address(spell));
        assertTrue(spell.done(), "TestError/spell-not-done");

        for (uint256 i = 0; i < newAuthorizations.length; i++) {
            address base = addr.addr(newAuthorizations[i].base);
            address ward = addr.addr(newAuthorizations[i].ward);
            assertEq(WardsAbstract(base).wards(ward), 1, _concat("testNewAuthorizations/not-authorized-", newAuthorizations[i].base));
        }
    }

    function testVestDAI() public skipped { // add the `skipped` modifier to skip
        // Provide human-readable names for timestamps
        uint256 DEC_01_2023 = 1701385200;
        uint256 NOV_30_2024 = 1733007599;

        // For each new stream, provide Stream object
        // and initialize the array with the corrent number of new streams
        VestStream[] memory streams = new VestStream[](1);
        streams[0] = VestStream({
            id:  38,
            usr: wallets.addr("ECOSYSTEM_FACILITATOR"),
            bgn: DEC_01_2023,
            clf: DEC_01_2023,
            fin: NOV_30_2024,
            tau: 366 days,
            mgr: address(0),
            res: 1,
            tot: 504_000 * WAD,
            rxd: 0
        });

        _checkVestDai(streams);
    }

    function testVestMKR() public skipped { // add the `skipped` modifier to skip
        // Provide human-readable names for timestamps
        uint256 DEC_01_2023 = 1701385200;
        uint256 NOV_30_2024 = 1733007599;

        // For each new stream, provide Stream object
        // and initialize the array with the corrent number of new streams
        VestStream[] memory streams = new VestStream[](1);
        streams[0] = VestStream({
            id:  44,
            usr: wallets.addr("ECOSYSTEM_FACILITATOR"),
            bgn: DEC_01_2023,
            clf: DEC_01_2023,
            fin: NOV_30_2024,
            tau: 366 days,
            mgr: address(0),
            res: 1,
            tot: 216 * WAD,
            rxd: 0
        });

        _checkVestMkr(streams);
    }

    function testVestSKY() public skipped { // add the `skipped` modifier to skip
        // Provide human-readable names for timestamps
        // uint256 DEC_01_2023 = 1701385200;

        // For each new stream, provide Stream object
        // and initialize the array with the corrent number of new streams
        VestStream[] memory streams = new VestStream[](1);

        // This stream is configured in relative to the spell casting time.
        {
            uint256 before = vm.snapshot();
            _vote(address(spell));
            spell.schedule();
            vm.warp(spell.nextCastTime());

            streams[0] = VestStream({
                id:  1,
                usr: addr.addr("REWARDS_DIST_USDS_SKY"),
                bgn: block.timestamp - 7 days,
                clf: block.timestamp - 7 days,
                fin: block.timestamp - 7 days + 365 days - 1,
                tau: 365 days - 1,
                mgr: address(0),
                res: 1,
                tot: 600_000_000 * WAD,
                // Note: the accumulated vested amount is claimed during the spell (`REWARDS_DIST_USDS_SKY.distribute()`)
                rxd: 600_000_000 * WAD * 7 days / (365 days - 1)
            });

            vm.revertTo(before);
        }

        _checkVestSky(streams);
    }

    struct Yank {
        uint256 streamId;
        address addr;
        uint256 finPlanned;
    }

    function testYankDAI() public skipped { // add the `skipped` modifier to skip
        // Provide human-readable names for timestamps
        uint256 FEB_29_2024 = 1709251199;
        uint256 MAR_31_2024 = 1711929599;

        // For each yanked stream, provide Yank object with:
        //   the stream id
        //   the address of the stream
        //   the planned fin of the stream (via variable defined above)
        // Initialize the array with the corrent number of yanks
        Yank[2] memory yanks = [
            Yank(20, wallets.addr("BA_LABS"), FEB_29_2024),
            Yank(21, wallets.addr("BA_LABS"), MAR_31_2024)
        ];

        // Test stream id matches `addr` and `fin`
        VestAbstract vest = VestAbstract(addr.addr("MCD_VEST_DAI")); // or "MCD_VEST_DAI_LEGACY"
        for (uint256 i = 0; i < yanks.length; i++) {
            assertEq(vest.usr(yanks[i].streamId), yanks[i].addr, "testYankDAI/unexpected-address");
            assertEq(vest.fin(yanks[i].streamId), yanks[i].finPlanned, "testYankDAI/unexpected-fin-date");
        }

        _vote(address(spell));
        _scheduleWaitAndCast(address(spell));
        assertTrue(spell.done(), "TestError/spell-not-done");
        for (uint256 i = 0; i < yanks.length; i++) {
            // Test stream.fin is set to the current block after the spell
            assertEq(vest.fin(yanks[i].streamId), block.timestamp, "testYankDAI/steam-not-yanked");
        }
    }

    function testYankMKR() public skipped { // add the `skipped` modifier to skip
        // Provide human-readable names for timestamps
        uint256 MAR_31_2024 = 1711929599;

        // For each yanked stream, provide Yank object with:
        //   the stream id
        //   the address of the stream
        //   the planned fin of the stream (via variable defined above)
        // Initialize the array with the corrent number of yanks
        Yank[1] memory yanks = [
            Yank(35, wallets.addr("BA_LABS"), MAR_31_2024)
        ];

        // Test stream id matches `addr` and `fin`
        VestAbstract vestTreasury = VestAbstract(addr.addr("MCD_VEST_MKR_TREASURY"));
        for (uint256 i = 0; i < yanks.length; i++) {
            assertEq(vestTreasury.usr(yanks[i].streamId), yanks[i].addr, "testYankMKR/unexpected-address");
            assertEq(vestTreasury.fin(yanks[i].streamId), yanks[i].finPlanned, "testYankMKR/unexpected-fin-date");
        }

        _vote(address(spell));
        _scheduleWaitAndCast(address(spell));
        assertTrue(spell.done(), "TestError/spell-not-done");
        for (uint256 i = 0; i < yanks.length; i++) {
            // Test stream.fin is set to the current block after the spell
            assertEq(vestTreasury.fin(yanks[i].streamId), block.timestamp, "testYankMKR/steam-not-yanked");

            // Give admin powers to test contract address and make the vesting unrestricted for testing
            GodMode.setWard(address(vestTreasury), address(this), 1);

            // Test vest can still be called, making stream "invalid" and not changing `fin` timestamp
            vestTreasury.unrestrict(yanks[i].streamId);
            vestTreasury.vest(yanks[i].streamId);
            assertTrue(!vestTreasury.valid(yanks[i].streamId));
            assertEq(vestTreasury.fin(yanks[i].streamId), block.timestamp, "testYankMKR/steam-fin-changed");
        }
    }

    struct Payee {
        address token;
        address addr;
        int256 amount;
    }

    struct PaymentAmounts {
        int256 dai;
        int256 mkr;
        int256 usds;
        int256 sky;
    }

    function testPayments() public skipped { // add the `skipped` modifier to skip
        // For each payment, create a Payee object with:
        //    the address of the transferred token,
        //    the destination address,
        //    the amount to be paid
        // Initialize the array with the number of payees
        Payee[2] memory payees = [
            Payee(address(dai), wallets.addr("AAVE_V3_TREASURY"), 234_089 ether), // Note: ether is only a keyword helper
            Payee(address(sky), wallets.addr("EARLY_BIRD_REWARDS"), 27_222_832.80 ether) // Note: ether is only a keyword helper
        ];
        // Fill the total values from exec sheet
        PaymentAmounts memory expectedTotalDiff = PaymentAmounts({
            dai: 234_089 ether, // Note: ether is only a keyword helper
            mkr: 0 ether, // Note: ether is only a keyword helper
            usds: 0 ether, // Note: ether is only a keyword helper
            sky: 27_222_832.80 ether // Note: ether is only a keyword helper
        });

        // Vote, schedule and warp, but not yet cast (to get correct surplus balance)
        _vote(address(spell));
        spell.schedule();
        vm.warp(spell.nextCastTime());
        pot.drip();

        // Calculate and save previous balances
        uint256 previousSurplusBalance = vat.sin(address(vow));
        PaymentAmounts memory previousTotalSupply = PaymentAmounts({
            dai: int256(dai.totalSupply()),
            mkr: int256(mkr.totalSupply()),
            usds: int256(usds.totalSupply()),
            sky: int256(sky.totalSupply())
        });
        PaymentAmounts memory calculatedTotalDiff;
        PaymentAmounts[] memory previousPayeeBalances = new PaymentAmounts[](payees.length);
        for (uint256 i = 0; i < payees.length; i++) {
            if (payees[i].token == address(dai)) {
                calculatedTotalDiff.dai += payees[i].amount;
            } else if (payees[i].token == address(mkr)) {
                calculatedTotalDiff.mkr += payees[i].amount;
            } else if (payees[i].token == address(usds)) {
                calculatedTotalDiff.usds += payees[i].amount;
            } else if (payees[i].token == address(sky)) {
                calculatedTotalDiff.sky += payees[i].amount;
            } else {
                revert('TestPayments/unexpected-payee-token');
            }
            previousPayeeBalances[i] = PaymentAmounts({
                dai: int256(dai.balanceOf(payees[i].addr)),
                mkr: int256(mkr.balanceOf(payees[i].addr)),
                usds: int256(usds.balanceOf(payees[i].addr)),
                sky: int256(sky.balanceOf(payees[i].addr))
            });
        }

        // Check calculated vs expected totals
        assertEq(
            calculatedTotalDiff.dai,
            expectedTotalDiff.dai,
            "TestPayments/calculated-vs-expected-dai-total-mismatch"
        );
        assertEq(
            calculatedTotalDiff.usds,
            expectedTotalDiff.usds,
            "TestPayments/calculated-vs-expected-usds-total-mismatch"
        );
        assertEq(
            calculatedTotalDiff.mkr,
            expectedTotalDiff.mkr,
            "TestPayments/calculated-vs-expected-mkr-total-mismatch"
        );
        assertEq(
            calculatedTotalDiff.sky,
            expectedTotalDiff.sky,
            "TestPayments/calculated-vs-expected-sky-total-mismatch"
        );

        // Cast spell
        spell.cast();
        assertTrue(spell.done(), "TestPayments/spell-not-done");

        // Check calculated vs actual totals
        PaymentAmounts memory actualTotalDiff = PaymentAmounts({
            dai: int256(dai.totalSupply()) - previousTotalSupply.dai,
            mkr: int256(mkr.totalSupply()) - previousTotalSupply.mkr,
            usds: int256(usds.totalSupply()) - previousTotalSupply.usds,
            sky: int256(sky.totalSupply()) - previousTotalSupply.sky
        });
        assertEq(
            actualTotalDiff.dai + actualTotalDiff.usds,
            calculatedTotalDiff.dai + calculatedTotalDiff.usds,
            "TestPayments/invalid-dai-usds-total"
        );
        assertEq(
            actualTotalDiff.mkr * int256(afterSpell.sky_mkr_rate) + actualTotalDiff.sky,
            calculatedTotalDiff.mkr * int256(afterSpell.sky_mkr_rate) +  calculatedTotalDiff.sky,
            "TestPayments/invalid-mkr-sky-total"
        );
        // Check that dai/usds transfers modify surplus buffer
        assertEq(vat.sin(address(vow)) - previousSurplusBalance, uint256(calculatedTotalDiff.dai + calculatedTotalDiff.usds) * RAY);

        // Check that payees received their payments
        for (uint256 i = 0; i < payees.length; i++) {
            if (payees[i].token == address(dai)) {
                assertEq(
                    int256(dai.balanceOf(payees[i].addr)),
                    previousPayeeBalances[i].dai + payees[i].amount,
                    "TestPayments/invalid-payee-dai-balance"
                );
            } else if (payees[i].token == address(mkr)) {
                assertEq(
                    int256(mkr.balanceOf(payees[i].addr)),
                    previousPayeeBalances[i].mkr + payees[i].amount,
                    "TestPayments/invalid-payee-mkr-balance"
                );
            } else if (payees[i].token == address(usds)) {
                assertEq(
                    int256(usds.balanceOf(payees[i].addr)),
                    previousPayeeBalances[i].usds + payees[i].amount,
                    "TestPayments/invalid-payee-usds-balance"
                );
            } else if (payees[i].token == address(sky)) {
                assertEq(
                    int256(sky.balanceOf(payees[i].addr)),
                    previousPayeeBalances[i].sky + payees[i].amount,
                    "TestPayments/invalid-payee-sky-balance"
                );
            } else {
                revert('TestPayments/unexpected-payee-token');
            }
        }
    }

    function testNewCronJobs() public skipped { // add the `skipped` modifier to skip
        SequencerLike seq = SequencerLike(addr.addr("CRON_SEQUENCER"));
        address[1] memory newJobs = [
            addr.addr("CRON_REWARDS_DIST_JOB")
        ];

        for (uint256 i = 0; i < newJobs.length; i++) {
            assertFalse(seq.hasJob(newJobs[i]), "TestError/cron-job-already-in-sequencer");
        }

        _vote(address(spell));
        _scheduleWaitAndCast(address(spell));
        assertTrue(spell.done(), "TestError/spell-not-done");

        for (uint256 i = 0; i < newJobs.length; i++) {
            assertTrue(seq.hasJob(newJobs[i]), "TestError/cron-job-not-added-to-sequencer");
        }
    }

    function _setupRootDomain() internal {
        vm.makePersistent(address(spell), address(spell.action()), address(addr));

        string memory root = string.concat(vm.projectRoot(), "/lib/dss-test");
        config = ScriptTools.readInput(root, "integration");

        rootDomain = new RootDomain(config, getRelativeChain("mainnet"));
    }

    function testL2OptimismSpell() public skipped { // TODO: check if this test can be removed for good.
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
        assertTrue(spell.done(), "TestError/spell-not-done");

        // switch to Optimism domain and relay the spell from L1
        // the `true` keeps us on Optimism rather than `rootDomain.selectFork()
        optimismDomain.relayFromHost(true);

        // Validate post-spell state
        assertEq(optimismGateway.validDomains(optDstDomain), 0, "l2-optimism-invalid-dst-domain");
    }

    function testL2ArbitrumSpell() public skipped { // TODO: check if this test can be removed for good.
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
        assertTrue(spell.done(), "TestError/spell-not-done");

        // switch to Arbitrum domain and relay the spell from L1
        // the `true` keeps us on Arbitrum rather than `rootDomain.selectFork()
        arbitrumDomain.relayFromHost(true);

        // Validate post-spell state
        assertEq(arbitrumGateway.validDomains(arbDstDomain), 0, "l2-arbitrum-invalid-dst-domain");
    }

    function testOffboardings() public skipped { // add the `skipped` modifier to skip
        uint256 Art;
        (Art,,,,) = vat.ilks("USDC-A");
        assertGt(Art, 0);
        (Art,,,,) = vat.ilks("PAXUSD-A");
        assertGt(Art, 0);
        (Art,,,,) = vat.ilks("GUSD-A");
        assertGt(Art, 0);

        _vote(address(spell));
        _scheduleWaitAndCast(address(spell));
        assertTrue(spell.done(), "TestError/spell-not-done");

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

    function testDaoResolutions() public skipped { // add the `skipped` modifier to skip
        // For each resolution, add IPFS hash as item to the resolutions array
        // Initialize the array with the number of resolutions
        string[1] memory resolutions = [
            "QmYJUvw5xbAJmJknG2xUKDLe424JSTWQQhbJCnucRRjUv7"
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
    function testSparkSpellIsExecuted() public skipped { // add the `skipped` modifier to skip
        address SPARK_PROXY = addr.addr('SPARK_PROXY');
        address SPARK_SPELL = 0xcc3B9e79261A7064A0f734Cc749A8e3762e0a187;

        vm.expectCall(
            SPARK_PROXY,
            /* value = */ 0,
            abi.encodeCall(
                ProxyLike(SPARK_PROXY).exec,
                (SPARK_SPELL, abi.encodeWithSignature("execute()"))
            )
        );

        _vote(address(spell));
        _scheduleWaitAndCast(address(spell));
        assertTrue(spell.done(), "TestError/spell-not-done");
    }

    // SPELL-SPECIFIC TESTS GO BELOW
    L2TokenBridgeLike  immutable l2bridge               = L2TokenBridgeLike( 0xee44cdb68D618d58F75d9fe0818B640BD7B8A7B7);
    BaseGovRelayLike   immutable l2govRelay             = BaseGovRelayLike(  0xdD0BCc201C9E47c6F6eE68E4dB05b652Bb6aC255);
    L2BridgeSpell      immutable l2spell                = L2BridgeSpell(     0x6f29C3A29A3F056A71FB0714551C8D3547268D62);
    GemAbstract        immutable l2usds                 = GemAbstract(       0x820C137fa70C8691f0e44Dc420a5e53c168921Dc);
    GemAbstract        immutable l2susds                = GemAbstract(       0x5875eEE11Cf8398102FdAd704C9E96607675467a);
    GemAbstract        immutable susd                   = GemAbstract(       addr.addr("SUSDS"));
    L1TokenBridgeLike  immutable l1bridge               = L1TokenBridgeLike( addr.addr("BASE_TOKEN_BRIDGE"));
    BaseGovRelayLike   immutable l1govRelay             = BaseGovRelayLike(  addr.addr("BASE_GOV_RELAY"));
    address            immutable L1_ESCROW              =                    addr.addr("BASE_ESCROW");
    address            immutable L1_BRIDGE_IMP          =                    addr.addr("BASE_TOKEN_BRIDGE_IMP");
    address            constant  L2_BRIDGE_IMP          =                    0x289A37BE5D6CCeF7A8f2b90535B3BB6bD3905f72;
    address            constant  MESSENGER              =                    0x866E82a600A1414e583f7F13623F1aC5d58b0Afa;
    address            constant  L2_MESSANGER           =                    0x4200000000000000000000000000000000000007;

    address            immutable PIP_ALLOCATOR_SPARK    =                    addr.addr("PIP_ALLOCATOR_SPARK_A");
    address            immutable ALLOCATOR_ROLES        =                    addr.addr("ALLOCATOR_ROLES");
    address            immutable ALLOCATOR_REGISTRY     =                    addr.addr("ALLOCATOR_REGISTRY");
    address            immutable ALLOCATOR_SPARK_BUFFER =                    addr.addr("ALLOCATOR_SPARK_A_BUFFER");
    address            immutable ALLOCATOR_SPARK_VAULT  =                    addr.addr("ALLOCATOR_SPARK_A_VAULT");
    address            immutable ALLOCATOR_SPARK_PROXY  =                    0x1601843c5E9bC251A3272907010AFa41Fa18347E;
    bytes32            constant  ALLOCATOR_ILK          =                    "ALLOCATOR-SPARK-A";

    address            immutable LITE_PSM               =                    addr.addr("MCD_LITE_PSM_USDC_A");

    // ---------- Medians and Validators  ----------
    address           constant ETH_GLOBAL_VALIDATOR     =                    0xcfC62b2269521e3212Ce1b6670caE6F0e34E8bF3;
    address           constant MANTLE_VALIDATOR         =                    0xFa6eb665e067759ADdE03a8E6bD259adBd1D70c9;
    address           constant NETHERMIND_VALIDATOR     =                    0x91242198eD62F9255F2048935D6AFb0C2302D147;
    address           constant EULER_VALIDATOR          =                    0x1DCB8CcC022938e102814F1A299C7ae48A8BAAf6;
    address           constant BTC_USD_MEDIAN           =                    0xe0F30cb149fAADC7247E953746Be9BbBB6B5751f;
    address           constant ETH_USD_MEDIAN           =                    0x64DE91F5A373Cd4c28de3600cB34C7C6cE410C85;
    address           constant WSTETH_USD_MEDIAN        =                    0x2F73b6567B866302e132273f67661fB89b5a66F2;
    address           constant MKR_USD_MEDIAN           =                    0xdbBe5e9B1dAa91430cF0772fCEbe53F6c6f137DF;

    function testBaseTokenBridge() public {
        _setupRootDomain();
        baseDomain = new OptimismDomain(config, getChain("base"), rootDomain);

        // ------ Sanity checks -------

        baseDomain.selectFork();

        require(l2bridge.isOpen() == 1, "L2BaseTokenBridge/not-open");
        require(l2bridge.otherBridge() == address(l1bridge), "L2BaseTokenBridge/other-bridge-mismatch");
        require(keccak256(bytes(l2bridge.version())) == keccak256("1"), "L2BaseTokenBridge/version-does-not-match");
        require(l2bridge.getImplementation() == L2_BRIDGE_IMP, "L2BaseTokenBridge/imp-does-not-match");
        require(l2bridge.messenger() == L2_MESSANGER, "L2BaseTokenBridge/l2-bridge-messenger-mismatch");
        require(l2govRelay.l1GovernanceRelay() == address(l1govRelay), "L2BaseGovRelay/l2-gov-relay-mismatch");
        require(l2govRelay.messenger() == L2_MESSANGER, "L2BaseGovRelay/l2-gov-relay-messenger-mismatch");
        require(l2spell.l2Bridge() == address(l2bridge), "L2Spell/l2-bridge-mismatch");

        rootDomain.selectFork();

        require(keccak256(bytes(l1bridge.version())) == keccak256("1"), "BaseTokenBridge/version-does-not-match");
        require(l1bridge.getImplementation() == L1_BRIDGE_IMP, "BaseTokenBridge/imp-does-not-match");
        require(l1bridge.isOpen() == 1, "BaseTokenBridge/not-open");
        require(l1bridge.otherBridge() == address(l2bridge), "BaseTokenBridge/other-bridge-mismatch");
        require(l1bridge.messenger() == MESSENGER, "BaseTokenBridge/l1-bridge-messenger-mismatch");
        require(l1govRelay.l2GovernanceRelay() == address(l2govRelay), "BaseGovRelay/l2-gov-relay-mismatch");
        require(l1govRelay.messenger() == MESSENGER, "BaseGovRelay/l1-gov-relay-messenger-mismatch");


        _vote(address(spell));
        _scheduleWaitAndCast(address(spell));
        assertTrue(spell.done(), "TestError/spell-not-done");


        require(l1bridge.escrow() == L1_ESCROW, "BaseTokenBridge/escrow-does-not-match");
        // // test tokens
        assertEq(usds.allowance(L1_ESCROW, address(l1bridge)), type(uint256).max);
        assertEq(l1bridge.l1ToL2Token(address(address(usds))), address(l2usds));

        assertEq(susds.allowance(L1_ESCROW, address(l1bridge)), type(uint256).max);
        assertEq(l1bridge.l1ToL2Token(address(address(susds))), address(l2susds));


        // switch to Optimism domain and relay the spell from L1
        // the `true` keeps us on Optimism rather than `rootDomain.selectFork()
        baseDomain.relayFromHost(true);

        // // test L2 side of initBridges
        assertEq(l2bridge.l1ToL2Token(address(susds)), address(l2susds));
        assertEq(l2bridge.maxWithdraws(address(l2susds)), type(uint256).max);

        assertEq(l2bridge.l1ToL2Token(address(usds)), address(l2usds));
        assertEq(l2bridge.maxWithdraws(address(l2usds)), type(uint256).max);

        assertEq(AuthLike(address(l2susds)).wards(address(l2bridge)), 1);
        assertEq(AuthLike(address(l2usds)).wards(address(l2bridge)), 1);


        // ------- Test Deposit -------

        rootDomain.selectFork();

        deal(address(usds), address(this), 100 ether);
        deal(address(susds), address(this), 100 ether);
        assertEq(usds.balanceOf(address(this)), 100 ether);
        assertEq(susds.balanceOf(address(this)), 100 ether);

        usds.approve(address(l1bridge), 100 ether);
        susds.approve(address(l1bridge), 100 ether);
        uint256 escrowBeforeUsds = usds.balanceOf(L1_ESCROW);
        uint256 escrowBeforesUsds = susds.balanceOf(L1_ESCROW);

        l1bridge.bridgeERC20To(
            address(usds),
            address(l2usds),
            address(0xb0b),
            100 ether,
            1_000_000,
            ""
        );
        l1bridge.bridgeERC20To(
            address(susds),
            address(l2susds),
            address(0xb0b),
            100 ether,
            1_000_000,
            ""
        );

        assertEq(usds.balanceOf(address(this)), 0);
        assertEq(usds.balanceOf(L1_ESCROW), escrowBeforeUsds + 100 ether);
        assertEq(susds.balanceOf(address(this)), 0);
        assertEq(susds.balanceOf(L1_ESCROW), escrowBeforesUsds + 100 ether);

        baseDomain.relayFromHost(true);

        assertEq(l2usds.balanceOf(address(0xb0b)), 100 ether);
        assertEq(l2susds.balanceOf(address(0xb0b)), 100 ether);

       // ------- Test Withdrawal -------

        vm.startPrank(address(0xb0b));

        l2usds.approve(address(l2bridge), 100 ether);
        l2susds.approve(address(l2bridge), 100 ether);

        l2bridge.bridgeERC20To(
            address(l2usds),
            address(usds),
            address(0xced),
            100 ether,
            1_000_000,
            ""
        );
        l2bridge.bridgeERC20To(
            address(l2susds),
            address(susds),
            address(0xced),
            100 ether,
            1_000_000,
            ""
        );
        vm.stopPrank();

        assertEq(l2usds.balanceOf(address(0xb0b)), 0);
        assertEq(l2susds.balanceOf(address(0xb0b)), 0);

        baseDomain.relayToHost(true);

        assertEq(usds.balanceOf(address(0xced)), 100 ether);
        assertEq(susds.balanceOf(address(0xced)), 100 ether);
    }

    function testSparkAllocator() public {
        uint256 previousIlkRegistryCount = reg.count();

        // Sanity checks
        require(AllocatorVaultLike(ALLOCATOR_SPARK_VAULT).ilk()      == ALLOCATOR_ILK,           "AllocatorInit/vault-ilk-mismatch");
        require(AllocatorVaultLike(ALLOCATOR_SPARK_VAULT).roles()    == ALLOCATOR_ROLES,         "AllocatorInit/vault-roles-mismatch");
        require(AllocatorVaultLike(ALLOCATOR_SPARK_VAULT).buffer()   == ALLOCATOR_SPARK_BUFFER,  "AllocatorInit/vault-buffer-mismatch");
        require(AllocatorVaultLike(ALLOCATOR_SPARK_VAULT).vat()      == address(vat),            "AllocatorInit/vault-vat-mismatch");
        require(AllocatorVaultLike(ALLOCATOR_SPARK_VAULT).usdsJoin() == address(usdsJoin),       "AllocatorInit/vault-usds-join-mismatch");

        _vote(address(spell));
        _scheduleWaitAndCast(address(spell));
        assertTrue(spell.done(), "TestError/spell-not-done");


        (, uint256 rate, uint256 spot,,) = vat.ilks(ALLOCATOR_ILK);
        assertEq(rate, RAY);
        assertEq(spot, 10**18 * RAY * 10**9 / spotter.par());

        (address pip,) = spotter.ilks(ALLOCATOR_ILK);
        assertEq(pip, PIP_ALLOCATOR_SPARK);

        assertEq(vat.gem(ALLOCATOR_ILK, ALLOCATOR_SPARK_VAULT), 0);
        (uint256 ink, uint256 art) = vat.urns(ALLOCATOR_ILK, ALLOCATOR_SPARK_VAULT);
        assertEq(ink, 1_000_000_000_000 * WAD);
        assertEq(art, 0);

        assertEq(AllocatorRegistryLike(ALLOCATOR_REGISTRY).buffers(ALLOCATOR_ILK), ALLOCATOR_SPARK_BUFFER);
        assertEq(address(AllocatorVaultLike(ALLOCATOR_SPARK_VAULT).jug()), address(jug));

        assertEq(usds.allowance(ALLOCATOR_SPARK_BUFFER, ALLOCATOR_SPARK_VAULT), type(uint256).max);

        assertEq(AllocatorRolesLike(ALLOCATOR_ROLES).ilkAdmins(ALLOCATOR_ILK), ALLOCATOR_SPARK_PROXY);

        assertEq(AllocatorVaultLike(ALLOCATOR_SPARK_VAULT).wards(pauseProxy),  0);
        assertEq(AllocatorVaultLike(ALLOCATOR_SPARK_VAULT).wards(ALLOCATOR_SPARK_PROXY), 1);

        assertEq(AuthLike(ALLOCATOR_SPARK_BUFFER).wards(pauseProxy),  0);
        assertEq(AuthLike(ALLOCATOR_SPARK_BUFFER).wards(ALLOCATOR_SPARK_PROXY), 1);

        assertEq(reg.count(),               previousIlkRegistryCount + 1);
        assertEq(reg.pos(ALLOCATOR_ILK),    previousIlkRegistryCount);
        assertEq(reg.join(ALLOCATOR_ILK),   address(0));
        assertEq(reg.gem(ALLOCATOR_ILK),    address(0));
        assertEq(reg.dec(ALLOCATOR_ILK),    0);
        assertEq(reg.class(ALLOCATOR_ILK),  5);
        assertEq(reg.pip(ALLOCATOR_ILK),    PIP_ALLOCATOR_SPARK);
        assertEq(reg.xlip(ALLOCATOR_ILK),   address(0));
        assertEq(reg.name(ALLOCATOR_ILK),   string("ALLOCATOR-SPARK-A"));
        assertEq(reg.symbol(ALLOCATOR_ILK), string("ALLOCATOR-SPARK-A"));

        // Draw & Wipe from Vault
        vm.prank(address(ALLOCATOR_SPARK_PROXY));
        AllocatorVaultLike(ALLOCATOR_SPARK_VAULT).draw(1_000 * WAD);
        assertEq(usds.balanceOf(ALLOCATOR_SPARK_BUFFER), 1_000 * WAD);

        vm.prank(address(ALLOCATOR_SPARK_PROXY));
        AllocatorVaultLike(ALLOCATOR_SPARK_VAULT).wipe(1_000 * WAD);
        assertEq(usds.balanceOf(ALLOCATOR_SPARK_BUFFER), 0);
    }

    function testsWhitelistSparkProxyOnLitePsm() public {
         _vote(address(spell));
        _scheduleWaitAndCast(address(spell));
        assertTrue(spell.done(), "TestError/spell-not-done");

        assertEq(LitePsmLike(LITE_PSM).bud(ALLOCATOR_SPARK_PROXY), 1);
    }

    function testMedianValidators() public {
         _vote(address(spell));
        _scheduleWaitAndCast(address(spell));
        assertTrue(spell.done(), "TestError/spell-not-done");

        address[] memory validators = new address[](4);
        validators[0] = ETH_GLOBAL_VALIDATOR;
        validators[1] = MANTLE_VALIDATOR;
        validators[2] = NETHERMIND_VALIDATOR;
        validators[3] = EULER_VALIDATOR;

        for (uint i = 0; i < validators.length; i++) {
            assertEq(MedianLike(BTC_USD_MEDIAN).orcl(validators[1]), 1);
            assertEq(MedianLike(ETH_USD_MEDIAN).orcl(validators[1]), 1);
            assertEq(MedianLike(WSTETH_USD_MEDIAN).orcl(validators[1]), 1);
            assertEq(MedianLike(MKR_USD_MEDIAN).orcl(validators[1]), 1);
         }
    }
}
