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
import { MigrationInstance, MigrationConfig, MigrationInit } from "./dependencies/chief-migration/MigrationInit.sol";
import { LockstakeInstance } from "./dependencies/lockstake/LockstakeInstance.sol";
import { LockstakeConfig } from "./dependencies/lockstake/LockstakeInit.sol";

contract DssSpellAction is DssAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: cast keccak -- "$(wget 'TODO' -q -O - 2>/dev/null)"
    string public constant override description = "2025-05-15 MakerDAO Executive Spell | Hash: TODO";

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
    address internal immutable CLIPPER_MOM              = DssExecLib.getChangelogAddress("CLIPPER_MOM");
    address internal constant MCD_ADM_NEW               = 0x929d9A1435662357F54AdcF64DcEE4d6b867a6f9;
    address internal constant VOTE_DELEGATE_FACTORY_NEW = 0x4Cf3DaeFA2683Cd18df00f7AFF5169C00a9EccD5;
    address internal constant MKR_SKY_NEW               = 0xA1Ea1bA18E88C381C724a75F23a130420C403f9a;
    address internal constant PIP_SKY                   = 0x511485bBd96e7e3a056a8D1b84C5071071C52D6F;
    address internal constant REWARDS_LSSKY_USDS        = 0x38E4254bD82ED5Ee97CD1C4278FAae748d998865;
    address internal constant LOCKSTAKE_SKY             = 0xf9A9cfD3229E985B91F99Bc866d42938044FFa1C;
    address internal constant LOCKSTAKE_ENGINE_NEW      = 0xCe01C90dE7FD1bcFa39e237FE6D8D9F569e8A6a3;
    address internal constant LOCKSTAKE_CLIP_NEW        = 0x35526314F18FeB5b7F124e40D6A99d64F7D7e89a;
    address internal constant LOCKSTAKE_CLIP_CALC_NEW   = 0xB8f8c7caabFa320717E3e848948450e120F0D9BB;
    address internal constant LOCKSTAKE_MIGRATOR        = 0x473d777f608C3C24B441AB6bD4bBcA6b7F9AF90B;

    function actions() public override {
        // Note: multple actions in the spell depend on DssInstance
        DssInstance memory dss = MCD.loadFromChainlog(DssExecLib.LOG);

        // Note: prepare `farms` variable used inside LockstakeConfig below
        address[] memory farms = new address[](1);
        farms[0] = REWARDS_LSSKY_USDS;

        MigrationInit.initMigration(
            dss,
            MigrationInstance({
                chief:               MCD_ADM_NEW,
                voteDelegateFactory: VOTE_DELEGATE_FACTORY_NEW,
                mkrSky:              MKR_SKY_NEW,
                skyOsm:              PIP_SKY,
                lsskyUsdsFarm:       REWARDS_LSSKY_USDS,
                lockstakeInstance: LockstakeInstance({
                    lssky:           LOCKSTAKE_SKY,
                    engine:          LOCKSTAKE_ENGINE_NEW,
                    clipper:         LOCKSTAKE_CLIP_NEW,
                    clipperCalc:     LOCKSTAKE_CLIP_CALC_NEW,
                    migrator:        LOCKSTAKE_MIGRATOR
                })
            }),
            MigrationConfig({
                maxYays:             5,
                launchThreshold:     2_400_000_000 * WAD,
                liftCooldown:        10,
                skyOracle:           0xc2ffbbDCCF1466Eb8968a846179191cb881eCdff,
                rewardsDuration:     1728 seconds,
                lockstakeConfig: LockstakeConfig({
                    ilk :            "LSEV2-SKY-A",
                    farms:           farms,
                    fee:             0,
                    dust:            30_000 * RAD,
                    duty:            TWENTY_PCT_RATE,
                    mat:             125 * RAY / 100,
                    buf:             120 * RAY / 100,
                    tail:            6_000 seconds,
                    cusp:            40 * RAY / 100,
                    chip:            1 * WAD / 1000,
                    tip:             300 * RAD,
                    stopped:         3,
                    chop:            113 * WAD / 100,
                    hole:            250_000 * RAD,
                    tau:             0,
                    cut:             99 * RAY / 100,
                    step:            60 seconds,
                    lineMom:         true,
                    tolerance:       5 * RAY / 10,
                    name:            "LockstakeSky",
                    symbol:          "lsSKY"
                })
            })
        );

        // Deny `CLIPPER_MOM` from the new `LockstakeClipper`
        DssExecLib.deauthorize(LOCKSTAKE_CLIP_NEW, CLIPPER_MOM);

        // ---------- Chainlog bump ----------

        // Note: we have to bump minor chainlog version as MCD_ADM address is being updated
        DssExecLib.setChangelogVersion("1.20.0");
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) {}
}
