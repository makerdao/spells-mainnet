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

interface VestLike {
    function restrict(uint256) external;
    function create(address, uint256, uint256, uint256, uint256, address) external returns (uint256);
}

interface GemLike {
    function allowance(address, address) external view returns (uint256);
    function approve(address, uint256) external returns (bool);
}

contract DssSpellAction is DssAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: cast keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/TODO/governance/votes/TODO.md -q -O - 2>/dev/null)"
    string public constant override description =
        "2023-02-22 MakerDAO Executive Spell | Hash: TODO";

    // Turn office hours on
    function officeHours() public pure override returns (bool) {
        return true;
    }

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

    uint256 constant ZERO_FIVE_PCT_RATE         = 1000000000158153903837946257;
    uint256 constant ONE_SEVENTY_FIVE_PCT_RATE  = 1000000000550121712943459312;
    uint256 constant THREE_TWENTY_FIVE_PCT_RATE = 1000000001014175731521720677;

    // Tuesday, 1 March 2022 00:00:00 UTC
    uint256 constant public MAR_01_2022 = 1646092800;
    // Saturday, 1 March 2025 00:00:00 UTC
    uint256 constant public MAR_01_2025 = 1740787200;

    uint256 internal constant MILLION = 10 ** 6;
    // uint256 internal constant RAY     = 10 ** 27;
    // uint256 internal constant WAD     = 10 ** 18;

    GemLike  internal immutable MKR          = GemLike(DssExecLib.mkr());
    VestLike internal immutable MCD_VEST_MKR = VestLike(DssExecLib.getChangelogAddress("MCD_VEST_MKR_TREASURY"));

    function actions() public override {

        // ---- New Aave v2 D3M ----
        // https://vote.makerdao.com/polling/QmUMyywc#poll-detail
        // TODO

        // ---- MOMC Parameter Changes ----
        // https://vote.makerdao.com/polling/QmUMyywc#poll-detail

        // Stability Fee Changes

        //Increase WSTETH-B Stability Fee to 0.5%
        DssExecLib.setIlkStabilityFee("WSTETH-B", ZERO_FIVE_PCT_RATE, true);

        // Reduce RETH-A Stability Fee to 0.5%
        DssExecLib.setIlkStabilityFee("RETH-A", ZERO_FIVE_PCT_RATE, true);

        // Reduce WBTC-A Stability Fee to 1.75%
        DssExecLib.setIlkStabilityFee("WBTC-A", ONE_SEVENTY_FIVE_PCT_RATE, true);

        // Reduce WBTC-B Stability Fee to 3.25%
        DssExecLib.setIlkStabilityFee("WBTC-B", THREE_TWENTY_FIVE_PCT_RATE, true);

        // line changes

        // Increase CRVV1ETHSTETH-A line to 100 million DAI
        DssExecLib.setIlkAutoLineDebtCeiling("CRVV1ETHSTETH-A", 100 * MILLION);

        // Increase RETH-A line to 10 million DAI
        DssExecLib.setIlkAutoLineDebtCeiling("RETH-A", 10 * MILLION);

        // Increase MATIC-A line to 15 million DAI
        DssExecLib.setIlkAutoLineDebtCeiling("MATIC-A", 15 * MILLION);

        // Increase DIRECT-COMPV2-DAI line to 30 million DAI
        DssExecLib.setIlkAutoLineDebtCeiling("DIRECT-COMPV2-DAI", 30 * MILLION);

        // ---- SF-001 Contributor Vesting ----

        // Increase allowance by new vesting delta
        MKR.approve(address(MCD_VEST_MKR), MKR.allowance(address(this), address(MCD_VEST_MKR)) + 435 ether);

        // Cliff: 2023-03-01 | 2022-03-01 to 2025-03-01 | 240 MKR | 0x31C01e90Edcf8602C1A18B2aE4e5A72D8DCE76bD
        MCD_VEST_MKR.restrict(
            MCD_VEST_MKR.create(
                0x31C01e90Edcf8602C1A18B2aE4e5A72D8DCE76bD, // usr
                240 ether,                                  // tot
                MAR_01_2022,                                // bgn
                MAR_01_2025 - MAR_01_2022,                  // tau
                365 days,                                   // eta
                address(0)                                  // mgr // TODO - need a manager?
            )
        );

        // Cliff: 2023-03-01 | 2022-03-01 to 2025-03-01 | 195 MKR | 0x12b19C5857CF92AaE5e5e5ADc6350e25e4C902e9
        MCD_VEST_MKR.restrict(
            MCD_VEST_MKR.create(
                0x12b19C5857CF92AaE5e5e5ADc6350e25e4C902e9, // usr
                195 ether,                                  // tot
                MAR_01_2022,                                // bgn
                MAR_01_2025 - MAR_01_2022,                  // tau
                365 days,                                   // eta
                address(0)                                  // mgr // TODO - need a manager?
            )
        );
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) {}
}
