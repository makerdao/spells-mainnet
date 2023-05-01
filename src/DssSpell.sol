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

import { DssInstance, MCD } from "dss-test/MCD.sol";
import { D3MInit, D3MCommonConfig, D3MAavePoolConfig, D3MAaveBufferPlanConfig } from "src/dependencies/dss-direct-deposit/D3MInit.sol";
import { D3MInstance } from "src/dependencies/dss-direct-deposit/D3MInstance.sol";

interface PoolConfiguratorLike {
    function setReserveFreeze(address asset, bool freeze) external;
    function setReserveInterestRateStrategyAddress(address asset, address newRateStrategyAddress) external;
    function setReserveFactor(address asset, uint256 newReserveFactor) external;
}

contract DssSpellAction is DssAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: cast keccak -- "$(wget 'https://raw.githubusercontent.com/makerdao/community/98e98eae03662eeab0dd2092ccc7edafb2dd75d3/governance/votes/Executive%20vote%20-%20April%2028%2C%202023.md' -q -O - 2>/dev/null)"
    string public constant override description =
        "2023-04-28 MakerDAO Executive Spell | Hash: 0xc42b83cc4f41bb759b62ac255533edba2a11195092d219b1eca54819d64069ca";

    // Many of the settings that change weekly rely on the rate accumulator
    // described at https://docs.makerdao.com/smart-contract-modules/rates-module
    // To check this yourself, use the following rate calculation (example 8%):
    //
    // $ bc -l <<< 'scale=27; e( l(1.08)/(60 * 60 * 24 * 365) )'
    //
    // A table of rates can be found at
    //    https://ipfs.io/ipfs/QmVp4mhhbwWGTfbh2BzwQB9eiBrQBKiqcPRZCaAxNUaar6
    //
    // uint256 internal constant X_PCT_RATE      = ;

    // Turn office hours on
    function officeHours() public pure override returns (bool) {
        return true;
    }

    address internal immutable D3M_HUB                  = DssExecLib.getChangelogAddress("DIRECT_HUB");
    address internal immutable D3M_MOM                  = DssExecLib.getChangelogAddress("DIRECT_MOM");

    address internal constant SPARK_D3M_PLAN            = 0x104FaDbb7e17db1A685bBa61007DfB015206a4D2;
    address internal constant SPARK_D3M_POOL            = 0xAfA2DD8a0594B2B24B59de405Da9338C4Ce23437;
    address internal constant SPARK_D3M_ORACLE          = 0xCBD53B683722F82Dc82EBa7916065532980d4833;

    address internal constant SPARK_ADAI                = 0x4DEDf26112B3Ec8eC46e7E31EA5e123490B05B8B;
    address internal constant SPARK_DAI_STABLE_DEBT     = 0xfe2B7a7F4cC0Fb76f7Fc1C6518D586F1e4559176;
    address internal constant SPARK_DAI_VARIABLE_DEBT   = 0xf705d2B7e92B3F38e6ae7afaDAA2fEE110fE5914;
    address internal constant SPARK_POOL_CONFIGURATOR   = 0x542DBa469bdE58FAeE189ffB60C6b49CE60E0738;

    address internal constant WBTC                      = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
    address internal constant INTEREST_RATE_STRATEGY    = 0x113dc45c524404F91DcbbAbB103506bABC8Df0FE;

    uint256 internal constant MILLION = 10 ** 6;
    uint256 internal constant WAD = 10 ** 18;
    uint256 internal constant RAD = 10 ** 45;

    function actions() public override {

        // ---- Spark D3M ----
        // https://mips.makerdao.com/mips/details/MIP106
        // https://mips.makerdao.com/mips/details/MIP104
        // dss-direct-deposit @ 665afffea10c71561bd234a88caf6586bf46ada2

        DssInstance memory dss = MCD.loadFromChainlog(DssExecLib.LOG);
        D3MInstance memory d3m = D3MInstance({
            plan:   SPARK_D3M_PLAN,
            pool:   SPARK_D3M_POOL,
            oracle: SPARK_D3M_ORACLE
        });
        D3MCommonConfig memory cfg = D3MCommonConfig({
            hub:         D3M_HUB,
            mom:         D3M_MOM,
            ilk:         "DIRECT-SPARK-DAI",
            existingIlk: false,
            maxLine:     5 * MILLION * RAD, // Set line to 5 million DAI
            gap:         5 * MILLION * RAD, // Set gap to 5 million DAI
            ttl:         8 hours,           // Set ttl to 8 hours
            tau:         7 days             // Set tau to 7 days
        });
        D3MAavePoolConfig memory poolCfg = D3MAavePoolConfig({
            king:         DssExecLib.getChangelogAddress("MCD_PAUSE_PROXY"),
            adai:         SPARK_ADAI,
            stableDebt:   SPARK_DAI_STABLE_DEBT,
            variableDebt: SPARK_DAI_VARIABLE_DEBT
        });
        D3MAaveBufferPlanConfig memory planCfg = D3MAaveBufferPlanConfig({
            buffer:       30 * MILLION * WAD,
            adai:         SPARK_ADAI
        });

        D3MInit.initCommon({
            dss:     dss,
            d3m:     d3m,
            cfg:     cfg
        });
        D3MInit.initAavePool({
            dss:     dss,
            d3m:     d3m,
            cfg:     cfg,
            aaveCfg: poolCfg
        });
        D3MInit.initAaveBufferPlan({
            d3m:     d3m,
            aaveCfg: planCfg
        });

        // ---- Spark Lend Parameter Adjustments ----
        PoolConfiguratorLike(SPARK_POOL_CONFIGURATOR).setReserveFreeze(WBTC, true);
        PoolConfiguratorLike(SPARK_POOL_CONFIGURATOR).setReserveInterestRateStrategyAddress(address(dss.dai), INTEREST_RATE_STRATEGY);
        PoolConfiguratorLike(SPARK_POOL_CONFIGURATOR).setReserveFactor(address(dss.dai), 0);

        // Bump the chainlog
        DssExecLib.setChangelogVersion("1.14.11");
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) {}
}
