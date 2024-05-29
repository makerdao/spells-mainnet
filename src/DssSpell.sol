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

interface ProxyLike {
    function exec(address target, bytes calldata args) external payable returns (bytes memory out);
}

contract DssSpellAction is DssAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: cast keccak -- "$(wget 'https://raw.githubusercontent.com/makerdao/community/907dc444bc87c98bbc089c1eb8509a3c9781a11d/governance/votes/Executive%20vote%20-%20May%2030%2C%202024.md' -q -O - 2>/dev/null)"
    string public constant override description =
        "2024-05-30 MakerDAO Executive Spell | Hash: 0xc9c33a5946b4845d25097514e691b1398933e21103cd5264ed3bcef547515c15";

    // Set office hours according to the summary
    function officeHours() public pure override returns (bool) {
        return false;
    }

    // Note: by the previous convention it should be a comma-separated list of DAO resolutions IPFS hashes
    string public constant dao_resolutions = "Qmb8vLDH6wT4Y2axnJX1JSKVKHTG3jzX3U3novw886H8UR,QmUiYTRy4BkV681tfFe3Ksj6gdLEq27w34MqLw5LvRaBoD";

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
    // uint256 internal constant X_PCT_1000000003022265980097387650RATE = ;

    // ---------- Math ----------
    uint256 internal constant MILLION  = 10 ** 6;
    uint256 internal constant RAD      = 10 ** 45;

    // ---------- Contract addresses ----------
    address internal immutable MCD_VOW = DssExecLib.vow();

    // ---------- Spark Spell ----------
    // Spark Proxy: https://github.com/marsfoundation/sparklend-deployments/blob/bba4c57d54deb6a14490b897c12a949aa035a99b/script/output/1/primary-sce-latest.json#L2
    address internal constant SPARK_PROXY = 0x3300f198988e4C9C63F75dF86De36421f06af8c4;
    address internal constant SPARK_SPELL = 0x7bcDd1c8641F8a0Ef98572427FDdD8c26D642256;

    function actions() public override {
        // ---------- SBE Surplus Buffer Upper Limit Update ----------
        // Forum: https://forum.makerdao.com/t/smart-burn-engine-vow-hump-surplus-buffer-upper-limit-reconfiguration-update-7/24348

        //Increase vow.hump by 5 million DAI from 50 million DAI to 55 million DAI
        DssExecLib.setValue(MCD_VOW, "hump", 55 * MILLION * RAD);

        // ---------- RWAF DAO Resolution ----------
        // Forum: https://forum.makerdao.com/t/dao-resolution-banking-setup-for-rwa-foundation/24362

        //Approve RWAF Dao Resolution with IPFS hash Qmb8vLDH6wT4Y2axnJX1JSKVKHTG3jzX3U3novw886H8UR
        // Note: see `dao_resolutions` variable declared above

        // ---------- RWA004-A DAO Resolution ----------
        // Forum: https://forum.makerdao.com/t/harbor-trade-credit-workout-process/24367

        //Approve RWA004-A Dao Resolution with IPFS hash QmUiYTRy4BkV681tfFe3Ksj6gdLEq27w34MqLw5LvRaBoD
        // Note: see `dao_resolutions` variable declared above

        // ---------- Spark Spell ----------
        // Forum: https://forum.makerdao.com/t/may-21-2024-proposed-changes-to-sparklend-for-upcoming-spell/24327/3

        //Trigger Spark Proxy Spell at 0x7bcDd1c8641F8a0Ef98572427FDdD8c26D642256
        ProxyLike(SPARK_PROXY).exec(SPARK_SPELL, abi.encodeWithSignature("execute()"));
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) {}
}
