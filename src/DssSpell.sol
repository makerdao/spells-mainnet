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

import "dss-exec-lib/DssExec.sol";
import "dss-exec-lib/DssAction.sol";
import { MCD, DssInstance } from "dss-test/MCD.sol";

// Note: code matches https://github.com/makerdao/chief-migration/blob/e4a820483694f015a2daf8b1dccc5548036d94d4/deploy/MigrationInit.sol
import { MigrationInstance, MigrationConfig, MigrationInit } from "./dependencies/chief-migration/MigrationInit.sol";

// Note: code matches https://github.com/makerdao/lockstake/blob/9cb25125bceb488f39dc4ddd3b54c05217a260d1/deploy/LockstakeInstance.sol
import { LockstakeInstance } from "./dependencies/lockstake/LockstakeInstance.sol";

// Note: code matches https://github.com/makerdao/lockstake/blob/9cb25125bceb488f39dc4ddd3b54c05217a260d1/deploy/LockstakeInit.sol
import { LockstakeConfig } from "./dependencies/lockstake/LockstakeInit.sol";

interface ProxyLike {
    function exec(address target, bytes calldata args) external payable returns (bytes memory out);
}

contract DssSpellAction is DssAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: cast keccak -- "$(wget 'https://raw.githubusercontent.com/makerdao/community/5ca420d2d2c0ad1a159914a7942eacc8b621ab7d/governance/votes/Executive%20vote%20-%20May%2015%2C%202025.md' -q -O - 2>/dev/null)"
    string public constant override description = "2025-05-15 MakerDAO Executive Spell | Hash: 0x59d2dd09c95fe525067a78e1df77fdc95dafa4da4c9c1e5dd1a783af1bb88e68";

    // Set office hours according to the summary
    function officeHours() public pure override returns (bool) {
        return true;
    }

    // ---------- Rates ----------
    // Many of the settings that change weekly rely on the rate accumulator
    // described at https://docs.makerdao.com/smart-contract-modules/rates-module
    // To check this yourself, use the following rate calculation (example 8%):
    //
    // $ bc -l <<< 'scale=27; e( l(1.08)/(60 * 60 * 24 * 365) )'
    //
    // A table of rates can be found at
    //    https://ipfs.io/ipfs/QmVp4mhhbwWGTfbh2BzwQB9eiBrQBKiqcPRZCaAxNUaar6
    //
    // uint256 internal constant X_PCT_RATE = ;
    uint256 internal constant TWENTY_PCT_RATE = 1000000005781378656804591712;

    // ---------- Math ----------
    uint256 internal constant WAD = 10 ** 18;
    uint256 internal constant RAY = 10 ** 27;
    uint256 internal constant RAD = 10 ** 45;

    // ---------- Contracts ----------
    address internal immutable CLIPPER_MOM          = DssExecLib.clipperMom();
    address internal constant MCD_ADM               = 0x929d9A1435662357F54AdcF64DcEE4d6b867a6f9;
    address internal constant VOTE_DELEGATE_FACTORY = 0x4Cf3DaeFA2683Cd18df00f7AFF5169C00a9EccD5;
    address internal constant MKR_SKY               = 0xA1Ea1bA18E88C381C724a75F23a130420C403f9a;
    address internal constant PIP_SKY               = 0x511485bBd96e7e3a056a8D1b84C5071071C52D6F;
    address internal constant REWARDS_LSSKY_USDS    = 0x38E4254bD82ED5Ee97CD1C4278FAae748d998865;
    address internal constant LOCKSTAKE_SKY         = 0xf9A9cfD3229E985B91F99Bc866d42938044FFa1C;
    address internal constant LOCKSTAKE_ENGINE      = 0xCe01C90dE7FD1bcFa39e237FE6D8D9F569e8A6a3;
    address internal constant LOCKSTAKE_CLIP        = 0x35526314F18FeB5b7F124e40D6A99d64F7D7e89a;
    address internal constant LOCKSTAKE_CLIP_CALC   = 0xB8f8c7caabFa320717E3e848948450e120F0D9BB;
    address internal constant LOCKSTAKE_MIGRATOR    = 0x473d777f608C3C24B441AB6bD4bBcA6b7F9AF90B;
    address internal constant FLAP_SKY_ORACLE       = 0xc2ffbbDCCF1466Eb8968a846179191cb881eCdff;
    address internal constant MCD_PROTEGO           = 0x5C9c3cb0490938c9234ABddeD37a191576ED8624;

    // ---------- Spark Proxy Spell ----------
    // Spark Proxy: https://github.com/marsfoundation/sparklend-deployments/blob/bba4c57d54deb6a14490b897c12a949aa035a99b/script/output/1/primary-sce-latest.json#L2
    address internal constant SPARK_PROXY = 0x3300f198988e4C9C63F75dF86De36421f06af8c4;
    address internal constant SPARK_SPELL = 0xC40611AC4Fff8572Dc5F02A238176edCF15Ea7ba;

    function actions() public override {
        // ---------- Initialize chief migration by calling MigrationInit.initMigration with the following parameters: ----------
        // Forum: https://forum.sky.money/t/atlas-edit-weekly-cycle-proposal-week-of-may-5-2025/26319
        // Atlas: https://sky-atlas.powerhouse.io/A.4.1.2.1_MKR_To_SKY_Upgrade/d5af8504-ddd6-416d-8429-897497b072dc%7Cb341f4c0b834
        // Forum: https://forum.sky.money/t/technical-scope-of-the-chief-migration/26361
        // Forum: https://forum.sky.money/t/technical-scope-of-the-chief-migration/26361/3
        // Forum: https://forum.sky.money/t/atlas-edit-weekly-cycle-proposal-week-of-may-12-2025/26364
        // Poll: https://vote.makerdao.com/polling/QmTVd4iq

        // Note: DssInstance is required by the MigrationInit library below
        DssInstance memory dss = MCD.loadFromChainlog(DssExecLib.LOG);

        // Note: `farms` array is required by the LockstakeConfig below
        address[] memory farms = new address[](1);
        farms[0] = REWARDS_LSSKY_USDS;

        MigrationInit.initMigration(

            // Note: this init library requires DssInstance
            dss,

            MigrationInstance({

                // inst.chief: 0x929d9A1435662357F54AdcF64DcEE4d6b867a6f9
                chief:               MCD_ADM,

                // inst.voteDelegateFactory: 0x4Cf3DaeFA2683Cd18df00f7AFF5169C00a9EccD5
                voteDelegateFactory: VOTE_DELEGATE_FACTORY,

                // inst.mkrSky: 0xA1Ea1bA18E88C381C724a75F23a130420C403f9a
                mkrSky:              MKR_SKY,

                // inst.skyOsm: 0x511485bBd96e7e3a056a8D1b84C5071071C52D6F
                skyOsm:              PIP_SKY,

                // inst.lsskyUsdsFarm: 0x38E4254bD82ED5Ee97CD1C4278FAae748d998865
                lsskyUsdsFarm:       REWARDS_LSSKY_USDS,

                lockstakeInstance: LockstakeInstance({

                    // inst.lockstakeInstance.lssky: 0xf9A9cfD3229E985B91F99Bc866d42938044FFa1C
                    lssky:           LOCKSTAKE_SKY,

                    // inst.lockstakeInstance.engine: 0xCe01C90dE7FD1bcFa39e237FE6D8D9F569e8A6a3
                    engine:          LOCKSTAKE_ENGINE,

                    // inst.lockstakeInstance.clipper:  0x35526314F18FeB5b7F124e40D6A99d64F7D7e89a
                    clipper:         LOCKSTAKE_CLIP,

                    // inst.lockstakeInstance.clipperCalc: 0xB8f8c7caabFa320717E3e848948450e120F0D9BB
                    clipperCalc:     LOCKSTAKE_CLIP_CALC,

                    // inst.lockstakeInstance.migrator: 0x473d777f608C3C24B441AB6bD4bBcA6b7F9AF90B
                    migrator:        LOCKSTAKE_MIGRATOR
                })
            }),

            MigrationConfig({

                // cfg.maxYays: 5
                maxYays:             5,

                // cfg.launchThreshold 2,400,000,000 SKY (equivalent to 100,000 MKR)
                launchThreshold:     2_400_000_000 * WAD,

                // cfg.liftCooldown: 10 blocks
                liftCooldown:        10,

                // cfg.skyOracle: 0xc2ffbbDCCF1466Eb8968a846179191cb881eCdff
                skyOracle:           FLAP_SKY_ORACLE,

                // cfg.rewardsDuration: equal to the splitter.hop (1,728 seconds)
                rewardsDuration:     1_728 seconds,

                lockstakeConfig: LockstakeConfig({

                    // cfg.lockstakeConfig.ilk: "LSEV2-SKY-A"
                    ilk :            "LSEV2-SKY-A",

                    // cfg.lockstakeConfig.farms: array [StakingRewards: 0x38E4254bD82ED5Ee97CD1C4278FAae748d998865]
                    farms:           farms,

                    // cfg.lockstakeConfig.fee: 0
                    fee:             0,

                    // cfg.lockstakeConfig.dust: 30,000
                    dust:            30_000 * RAD,

                    // cfg.lockstakeConfig.duty: 20%
                    duty:            TWENTY_PCT_RATE,

                    // cfg.lockstakeConfig.mat: 125%
                    mat:             125 * RAY / 100,

                    // cfg.lockstakeConfig.buf: 120%
                    buf:             120 * RAY / 100,

                    // cfg.lockstakeConfig.tail: 6,000 seconds
                    tail:            6_000 seconds,

                    // cfg.lockstakeConfig.cusp: 40%
                    cusp:            40 * RAY / 100,

                    // cfg.lockstakeConfig.chip: 0.1%
                    chip:            1 * WAD / 1000,

                    // cfg.lockstakeConfig.tip: 300 USDS
                    tip:             300 * RAD,

                    // cfg.lockstakeConfig.stopped: 3
                    stopped:         3,

                    // cfg.lockstakeConfig.chop: 13%
                    chop:            113 * WAD / 100,

                    // cfg.lockstakeConfig.hole: 250,000
                    hole:            250_000 * RAD,

                    // cfg.lockstakeConfig.tau: 0 days
                    tau:             0,

                    // cfg.lockstakeConfig.cut: 0.99
                    cut:             99 * RAY / 100,

                    // cfg.lockstakeConfig.step: 60 seconds
                    step:            60 seconds,

                    // cfg.lockstakeConfig.lineMom: true (as "added to LINE_MOM")
                    lineMom:         true,

                    // cfg.lockstakeConfig.tolerance: 0.5
                    tolerance:       5 * RAY / 10,

                    // cfg.lockstakeConfig.name: LockstakeSky
                    name:            "LockstakeSky",

                    // cfg.lockstakeConfig.symbol: lsSKY
                    symbol:          "lsSKY"
                })
            })
        );

        // ---------- Remove CLIPPER_MOM Access ----------
        // Forum: https://forum.sky.money/t/atlas-edit-weekly-cycle-proposal-week-of-may-5-2025/26319
        // Atlas: https://sky-atlas.powerhouse.io/A.4.1.2.1_MKR_To_SKY_Upgrade/d5af8504-ddd6-416d-8429-897497b072dc%7Cb341f4c0b834
        // Forum: https://forum.sky.money/t/technical-scope-of-the-chief-migration/26361
        // Forum: https://forum.sky.money/t/technical-scope-of-the-chief-migration/26361/3

        // Deny CLIPPER_MOM from the new LockstakeClipper
        DssExecLib.deauthorize(LOCKSTAKE_CLIP, CLIPPER_MOM);

        // ---------- Add Protego to Chainlog ----------
        // Forum: https://forum.sky.money/t/atlas-edit-weekly-cycle-proposal-week-of-may-5-2025/26319
        // Atlas: https://sky-atlas.powerhouse.io/A.1.9.4.3_Protego/1f1f2ff0-8d73-80be-9ace-f125242ede47%7C0db307588902
        // Forum: https://forum.sky.money/t/technical-scope-of-the-protego-deployment/26365
        // Forum: https://forum.sky.money/t/technical-scope-of-the-protego-deployment/26365/2

        // Add Protego (0x5C9c3cb0490938c9234ABddeD37a191576ED8624) to chainlog with key “MCD_PROTEGO”
        DssExecLib.setChangelogAddress("MCD_PROTEGO", MCD_PROTEGO);

        // Bump chainlog MINOR version
        DssExecLib.setChangelogVersion("1.20.0");

        // ---------- Spark Proxy Spell ----------
        // Forum: https://forum.sky.money/t/atlas-edit-weekly-cycle-proposal-week-of-may-5-2025/26319
        // Atlas: https://sky-atlas.powerhouse.io/A.4.1.2.1_MKR_To_SKY_Upgrade/d5af8504-ddd6-416d-8429-897497b072dc%7Cb341f4c0b834

        // Execute Spark Proxy spell at 0xC40611AC4Fff8572Dc5F02A238176edCF15Ea7ba
        ProxyLike(SPARK_PROXY).exec(SPARK_SPELL, abi.encodeWithSignature("execute()"));
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) {}
}
