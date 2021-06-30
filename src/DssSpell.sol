// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2021 Maker Ecosystem Growth Holdings, INC.
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

contract DssSpellAction is DssAction {


    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/<TODO>/governance/votes/Executive%20vote%20-%20June%2025%2C%202021.md -q -O - 2> /dev/null)"
    string public constant description =
        "2021-07-02 MakerDAO Executive Spell | Hash: 0x";

    // Turn off office hours
    function officeHours() public override returns (bool) {
        return false;
    }

    uint256 constant WAD = 10**18;
    uint256 constant RAY = 10**27;
    uint256 constant RAD = 10**45;

    bytes32 constant ILK_PSM_USDC_A     = "PSM-USDC-A";

    // Many of the settings that change weekly rely on the rate accumulator
    // described at https://docs.makerdao.com/smart-contract-modules/rates-module
    // To check this yourself, use the following rate calculation (example 8%):
    //
    // $ bc -l <<< 'scale=27; e( l(1.08)/(60 * 60 * 24 * 365) )'
    //
    // A table of rates can be found at
    //    https://ipfs.io/ipfs/QmefQMseb3AiTapiAKKexdKHig8wroKuZbmLtPLv4u2YwW
    //
    uint256 constant ZERO_PCT =            1000000000000000000000000000;
    uint256 constant ZERO_POINT_FIVE_PCT = 1000000000158153903837946257;
    uint256 constant ONE_PCT =             1000000000315522921573372069;
    uint256 constant ONE_POINT_FIVE_PCT =  1000000000472114805215157978;
    uint256 constant TWO_PCT =             1000000000627937192491029810;
    uint256 constant SIX_PCT =             1000000001847694957439350562;

    function actions() public override {

        // ----------- Auto-Line updates -----------
        // https://vote.makerdao.com/polling/QmZz4ssm?network=mainnet#poll-detail
        DssExecLib.setIlkAutoLineParameters(ILK_PSM_USDC_A, 10_000_000_000, 1_000_000_000, 24 hours);

        // ----------- Stability Fee updates -----------
        // https://vote.makerdao.com/polling/QmfZWY87?network=mainnet#poll-detail
        DssExecLib.setIlkStabilityFee("ETH-A", TWO_PCT, true);
        DssExecLib.setIlkStabilityFee("ETH-B", SIX_PCT, true);
        DssExecLib.setIlkStabilityFee("ETH-C", ZERO_POINT_FIVE_PCT, true);
        DssExecLib.setIlkStabilityFee("WBTC-A", TWO_PCT, true);
        DssExecLib.setIlkStabilityFee("LINK-A", ONE_PCT, true);
        DssExecLib.setIlkStabilityFee("YFI-A", ONE_PCT, true);
        DssExecLib.setIlkStabilityFee("UNI-A", ONE_PCT, true);
        DssExecLib.setIlkStabilityFee("AAVE-A", ONE_PCT, true);
        DssExecLib.setIlkStabilityFee("RENBTC-A", TWO_PCT, true);
        DssExecLib.setIlkStabilityFee("COMP-A", ONE_PCT, true);
        DssExecLib.setIlkStabilityFee("BAL-A", ONE_PCT, true);
        DssExecLib.setIlkStabilityFee("UNIV2DAIETH-A", ONE_POINT_FIVE_PCT, true);
        DssExecLib.setIlkStabilityFee("UNIV2USDCETH-A", TWO_PCT, true);
        DssExecLib.setIlkStabilityFee("UNIV2DAIUSDC-A", ZERO_PCT, true);
        DssExecLib.setIlkStabilityFee("UNIV2WBTCETH-A", TWO_PCT, true);
        DssExecLib.setIlkStabilityFee("UNIV2UNIETH-A", TWO_PCT, true);
        DssExecLib.setIlkStabilityFee("UNIV2ETHUSDT-A", TWO_PCT, true);

        // Core Unit Payments
        //DssExecLib.sendPaymentFromSurplusBuffer(TODO, TODO);

    }
}

contract DssSpell is DssExec {
    DssSpellAction internal action_ = new DssSpellAction();
    constructor() DssExec(action_.description(), block.timestamp + 30 days, address(action_)) public {}
}
