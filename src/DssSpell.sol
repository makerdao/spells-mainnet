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
    // Hash: cast keccak -- "$(wget 'TODO' -q -O - 2>/dev/null)"
    string public constant override description =
        "2024-07-11 MakerDAO Executive Spell | Hash: TODO";

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
    // uint256 internal constant X_PCT_1000000003022265980097387650RATE = ;
    uint256 internal constant SEVEN_PCT_RATE = 1000000002145441671308778766;
    uint256 internal constant SEVEN_PT_TWO_FIVE_PCT_RATE = 1000000002219443553326580536;
    uint256 internal constant SEVEN_PT_SEVEN_FIVE_PCT_RATE = 1000000002366931224128103346;
    uint256 internal constant EIGHT_PCT_RATE = 1000000002440418608258400030;
    uint256 internal constant EIGHT_PT_TWO_FIVE_PCT_RATE = 1000000002513736079215619839;
    uint256 internal constant EIGHT_PT_FIVE_PCT_RATE = 1000000002586884420913935572;
    uint256 internal constant EIGHT_PT_SEVEN_FIVE_PCT_RATE = 1000000002659864411854984565;
    uint256 internal constant NINE_PT_TWO_FIVE_PCT_RATE = 1000000002805322428706865331;

    // ---------- Payment addresses ----------
    address internal constant AAVE_V3_TREASURY = 0x464C71f6c2F760DdA6093dCB91C24c39e5d6e18c;

    // ---------- TODO Chainlink Automation Upgrade to V2.1 ----------
    address internal constant CHAINLINK_PAYMENT_ADAPTER = 0xfB5e1D841BDA584Af789bDFABe3c6419140EC065;
    address internal constant CHAINLINK_TREASURY_NEW = 0xBE1cE564574377Acb17C2b7628E4F6dd38067a55;

    // ---------- Spark Spell ----------
    // Spark Proxy: https://github.com/marsfoundation/sparklend-deployments/blob/bba4c57d54deb6a14490b897c12a949aa035a99b/script/output/1/primary-sce-latest.json#L2
    address internal constant SPARK_PROXY = 0x3300f198988e4C9C63F75dF86De36421f06af8c4;
    address internal constant SPARK_SPELL = 0x91824fa4fd51E8440a122ffDd49C701F5C56D58e;

    function actions() public override {
        // ---------- Spark - Aave Revenue Share Payment ----------
        // Forum: https://forum.makerdao.com/t/spark-aave-revenue-share-calculation-payment-4-q2-2024/24572

        // AAVE - 219125 DAI - 0x464C71f6c2F760DdA6093dCB91C24c39e5d6e18c
        DssExecLib.sendPaymentFromSurplusBuffer(AAVE_V3_TREASURY, 219_125);

        // ---------- TODO Chainlink Automation Upgrade to V2.1 ----------

        // TODO instruction to set treasury to new address
        DssExecLib.setContract(CHAINLINK_PAYMENT_ADAPTER, 'treasury', CHAINLINK_TREASURY_NEW);

        // ---------- TODO Rate changes ----------

        // TODO ETH-A: Decrease the Stability Fee by 1 percentage point from 8.25% to 7.25%
        DssExecLib.setIlkStabilityFee("ETH-A", SEVEN_PT_TWO_FIVE_PCT_RATE, /* doDrip = */ true);

        // TODO ETH-B: Decrease the Stability Fee by 1 percentage point from 8.75% to 7.75%
        DssExecLib.setIlkStabilityFee("ETH-B", SEVEN_PT_SEVEN_FIVE_PCT_RATE, /* doDrip = */ true);

        // TODO ETH-C: Decrease the Stability Fee by 1 percentage point from 8.00% to 7.00%
        DssExecLib.setIlkStabilityFee("ETH-C", SEVEN_PCT_RATE, /* doDrip = */ true);

        // TODO WSTETH-A: Decrease the Stability Fee by 1 percentage point from 9.25% to 8.25%
        DssExecLib.setIlkStabilityFee("WSTETH-A", EIGHT_PT_TWO_FIVE_PCT_RATE, /* doDrip = */ true);

        // TODO WSTETH-B: Decrease the Stability Fee by 1 percentage point from 9.00% to 8.00%
        DssExecLib.setIlkStabilityFee("WSTETH-B", EIGHT_PCT_RATE, /* doDrip = */ true);

        // TODO WBTC-A: Decrease the Stability Fee by 1 percentage point from 9.75% to 8.75%
        DssExecLib.setIlkStabilityFee("WBTC-A", EIGHT_PT_SEVEN_FIVE_PCT_RATE, /* doDrip = */ true);

        // TODO WBTC-B: Decrease the Stability Fee by 1 percentage point from 10.25% to 9.25%
        DssExecLib.setIlkStabilityFee("WBTC-B", NINE_PT_TWO_FIVE_PCT_RATE, /* doDrip = */ true);

        // TODO WBTC-C: Decrease the Stability Fee by 1 percentage point from 9.50% to 8.50%
        DssExecLib.setIlkStabilityFee("WBTC-C", EIGHT_PT_FIVE_PCT_RATE, /* doDrip = */ true);

        // TODO DSR: Decrease the Dai Savings Rate by 1 percentage points from 8.00% to 7.00%
        DssExecLib.setDSR(SEVEN_PCT_RATE, /* doDrip = */ true);

        // ---------- TODO Spark Spell ----------

        // TODO instruction for trigger
        ProxyLike(SPARK_PROXY).exec(SPARK_SPELL, abi.encodeWithSignature("execute()"));
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) {}
}
