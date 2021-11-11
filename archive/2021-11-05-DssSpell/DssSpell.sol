// SPDX-License-Identifier: AGPL-3.0-or-later
//
// Copyright (C) 2021 Dai Foundation
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

import "dss-exec-lib/DssExec.sol";
import "dss-exec-lib/DssAction.sol";

interface VatLike {
    function suck(address, address, uint256) external;
}

interface DaiJoinLike {
    function exit(address, uint256) external;
}

contract DssSpellAction is DssAction {

    uint256 constant MILLION  = 10**6;
    uint256 constant WAD      = 10**18;
    uint256 constant RAD      = 10**45;

    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/27b239b7a645afbd1f17f13e6cacdd06faf42009/governance/votes/Executive%20vote%20-%20November%205%2C%202021.md -q -O - 2>/dev/null)"
    string public constant override description =
        "2021-11-05 MakerDAO Executive Spell | Hash: 0xf08a48dc8c7dd0352f5e2329bd5f44d8769cf534106c0574e4bc675472fcfe7d";

    // Many of the settings that change weekly rely on the rate accumulator
    // described at https://docs.makerdao.com/smart-contract-modules/rates-module
    // To check this yourself, use the following rate calculation (example 8%):
    //
    // $ bc -l <<< 'scale=27; e( l(1.08)/(60 * 60 * 24 * 365) )'
    //
    // A table of rates can be found at
    //    https://ipfs.io/ipfs/QmefQMseb3AiTapiAKKexdKHig8wroKuZbmLtPLv4u2YwW
    //
    uint256 constant ONE_PCT_RATE      = 1000000000315522921573372069;
    uint256 constant ONE_FIVE_PCT_RATE = 1000000000472114805215157978;
    uint256 constant TWO_FIVE_PCT_RATE = 1000000000782997609082909351;
    uint256 constant SIX_PCT_RATE      = 1000000001847694957439350562;

    address constant MCD_PSM_USDC_A = 0x89B78CfA322F6C5dE0aBcEecab66Aee45393cC5A;
    address constant MCD_PSM_PAX_A  = 0x961Ae24a1Ceba861D1FDf723794f6024Dc5485Cf;

    address constant DUX_WALLET   = 0x5A994D8428CCEbCC153863CCdA9D2Be6352f89ad;
    address constant MCD_VAT      = 0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B;
    address constant MCD_VOW      = 0xA950524441892A31ebddF91d3cEEFa04Bf454466;
    address constant MCD_JOIN_DAI = 0x9759A6Ac90977b93B58547b4A71c78317f391A28;

    function officeHours() public override returns (bool) {
        return false;
    }

    function actions() public override {
        // ----------------------------- Stability Fee updates ----------------------------
        // https://vote.makerdao.com/polling/QmXDCCPH?network=mainnet#poll-detail
        DssExecLib.setIlkStabilityFee("ETH-A",          TWO_FIVE_PCT_RATE, true);
        DssExecLib.setIlkStabilityFee("ETH-B",          SIX_PCT_RATE,      true);
        DssExecLib.setIlkStabilityFee("WBTC-A",         TWO_FIVE_PCT_RATE, true);
        DssExecLib.setIlkStabilityFee("LINK-A",         ONE_FIVE_PCT_RATE, true);
        DssExecLib.setIlkStabilityFee("RENBTC-A",       TWO_FIVE_PCT_RATE, true);
        DssExecLib.setIlkStabilityFee("USDC-A",         ONE_PCT_RATE,      true);
        DssExecLib.setIlkStabilityFee("UNIV2WBTCETH-A", TWO_FIVE_PCT_RATE, true);

        // ------------------------------ Debt ceiling updates -----------------------------
        // https://vote.makerdao.com/polling/QmXDCCPH?network=mainnet#poll-detail
        DssExecLib.setIlkAutoLineDebtCeiling("MANA-A", 10 * MILLION);
        DssExecLib.setIlkAutoLineParameters("MATIC-A",        20 * MILLION, 20 * MILLION, 8 hours);
        DssExecLib.setIlkAutoLineParameters("UNIV2WBTCETH-A", 50 * MILLION,  5 * MILLION, 8 hours);

        // ------------------------------ PSM updates --------------------------------------
        // https://vote.makerdao.com/polling/QmSkYED5?network=mainnet#poll-detail
        DssExecLib.setValue(MCD_PSM_USDC_A, "tin", 0);
        DssExecLib.setValue(MCD_PSM_PAX_A,  "tin", 0);

        // ------------------------------ CU payments --------------------------------------
        // DssExecLib does not support less than one DAI of precision so we have to do this the old-fashioned way.
        VatLike(MCD_VAT).suck(MCD_VOW, address(this), 3591208 * RAD / 10);
        DaiJoinLike(MCD_JOIN_DAI).exit(DUX_WALLET, 3591208 * WAD / 10);
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) public {}
}
