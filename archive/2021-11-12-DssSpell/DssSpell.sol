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

import "dss-interfaces/dapp/DSTokenAbstract.sol";

interface DaiJoinLike {
    function join(address, uint256) external;
}

contract DssSpellAction is DssAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/cea20bbd8e9b1c4a30dd5770b73162393af8360c/governance/votes/Executive%20Vote%20-%20November%2012%2C%202021.md -q -O - 2>/dev/null)"
    string public constant override description =
        "2021-11-12 MakerDAO Executive Spell | Hash: 0x0875eb8fbd80dc06ec296cd7e7411f086487f2fb71a8bfd7dd2c258ebb461a03";

    // Many of the settings that change weekly rely on the rate accumulator
    // described at https://docs.makerdao.com/smart-contract-modules/rates-module
    // To check this yourself, use the following rate calculation (example 8%):
    //
    // $ bc -l <<< 'scale=27; e( l(1.08)/(60 * 60 * 24 * 365) )'
    //
    // A table of rates can be found at
    //    https://ipfs.io/ipfs/QmefQMseb3AiTapiAKKexdKHig8wroKuZbmLtPLv4u2YwW
    //
    uint256 constant ZERO_FIVE_PCT_RATE = 1000000000158153903837946257;

    uint256 constant MILLION  = 10**6;

    function officeHours() public override returns (bool) {
        return false;
    }

    function actions() public override {
        // GUNIV3DAIUSDC-A Parameter Adjustments
        // https://vote.makerdao.com/polling/QmemHGSM?network=mainnet
        // https://forum.makerdao.com/t/request-to-raise-the-guniv3daiusdc1-a-dc-to-500m/11394
        DssExecLib.setIlkAutoLineDebtCeiling("GUNIV3DAIUSDC1-A", 500 * MILLION);     // Set DCIAM Max debt ceiling to 500 M
        DssExecLib.setIlkLiquidationRatio("GUNIV3DAIUSDC1-A", 10200);                // Set LR to 102 %
        DssExecLib.setIlkStabilityFee("GUNIV3DAIUSDC1-A", ZERO_FIVE_PCT_RATE, true); // Set stability fee to 0.5 %

        // WSTETH-A Parameter Adjustments
        // https://vote.makerdao.com/polling/QmeQUKFm?network=mainnet
        // https://forum.makerdao.com/t/request-to-raise-staked-eth-dc-to-50m/11402
        DssExecLib.setIlkAutoLineDebtCeiling("WSTETH-A", 50 * MILLION);

        // DIRECT-AAVEV2-DAI Parameter Adjustments
        // https://vote.makerdao.com/polling/QmNbTzG1?network=mainnet
        // https://forum.makerdao.com/t/discussion-direct-deposit-dai-module-d3m/7357
        DssExecLib.setIlkAutoLineParameters("DIRECT-AAVEV2-DAI", 50 * MILLION, 25 * MILLION, 12 hours);
        DssExecLib.setValue(DssExecLib.getChangelogAddress("MCD_JOIN_DIRECT_AAVEV2_DAI"), "bar", 3.9 * 10**27 / 100); // 3.9%

        // Send funds in the PAUSE_PROXY to the surplus buffer
        address daiJoin = DssExecLib.getChangelogAddress("MCD_JOIN_DAI");
        uint256 amount = 218_059.1 * 10**18;
        DSTokenAbstract(DssExecLib.getChangelogAddress("MCD_DAI")).approve(daiJoin, amount);
        DaiJoinLike(daiJoin).join(DssExecLib.getChangelogAddress("MCD_VOW"), amount);
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) public {}
}
