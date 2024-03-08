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

interface PauseLike {
    function setDelay(uint256 delay_) external;
}

interface ProxyLike {
    function exec(address target, bytes calldata args) external payable returns (bytes memory out);
}

contract DssSpellAction is DssAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: cast keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/298421e90b51a0459148b3d41c558d291eeb0b1f/governance/votes/Executive%20vote%20-%20March%208%2C%202024.md -q -O - 2>/dev/null)"
    string public constant override description =
        "2024-03-08 MakerDAO Executive Spell | Hash: 0x94608a6337c99fc128873534fb5e2dbced316e9212500dfc53b989d08ad3dbdd";

    // Set office hours according to the summary
    function officeHours() public pure override returns (bool) {
        return false;
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
    uint256 internal constant FIFTEEN_PCT               = 1000000004431822129783699001;
    uint256 internal constant FIFTEEN_PT_TWO_FIVE_PCT   = 1000000004500681640286189459;
    uint256 internal constant FIFTEEN_PT_SEVEN_FIVE_PCT = 1000000004637953682059597074;
    uint256 internal constant SIXTEEN_PCT               = 1000000004706367499604668374;
    uint256 internal constant SIXTEEN_PT_TWO_FIVE_PCT   = 1000000004774634032180348552;
    uint256 internal constant SIXTEEN_PT_FIVE_PCT       = 1000000004842753912590664903;
    uint256 internal constant SIXTEEN_PT_SEVEN_FIVE_PCT = 1000000004910727769570159235;
    uint256 internal constant SEVENTEEN_PT_TWO_FIVE_PCT = 1000000005046239908035965222;

    // ---------- Math ----------
    uint256 internal constant MILLION = 10 ** 6;
    uint256 internal constant BILLION = 10 ** 9;

    // ---------- Contracts ----------
    address internal immutable MCD_PAUSE = DssExecLib.getChangelogAddress("MCD_PAUSE");

    // ---------- Trigger Spark Proxy Spell ----------
    // Spark Proxy: https://github.com/marsfoundation/sparklend/blob/d42587ba36523dcff24a4c827dc29ab71cd0808b/script/output/1/primary-sce-latest.json#L2
    address internal constant SPARK_PROXY = 0x3300f198988e4C9C63F75dF86De36421f06af8c4;
    address internal constant SPARK_SPELL = 0xFc72De9b361dB85F1d126De9cac51A1aEe8Ce126;

    function actions() public override {
        // ---------- DSR Change ----------
        // Forum: https://forum.makerdao.com/t/accelerated-proposal-rate-system-gsm-delay-psm-usdc-a-ttl-changes/23824

        // Increase the DSR by 10% from 5% to 15%
        DssExecLib.setDSR(FIFTEEN_PCT, /* doDrip = */ true);

        // ---------- Stability Fee Changes ----------
        // Forum: https://forum.makerdao.com/t/accelerated-proposal-rate-system-gsm-delay-psm-usdc-a-ttl-changes/23824

        // Increase the ETH-A Stability Fee by 8.84% from 6.41% to 15.25%
        DssExecLib.setIlkStabilityFee("ETH-A", FIFTEEN_PT_TWO_FIVE_PCT, /* doDrip = */ true);

        // Increase the ETH-B Stability Fee by 8.84% from 6.91% to 15.75%
        DssExecLib.setIlkStabilityFee("ETH-B", FIFTEEN_PT_SEVEN_FIVE_PCT, /* doDrip = */ true);

        // Increase the ETH-C Stability Fee by 8.84% from 6.16% to 15%
        DssExecLib.setIlkStabilityFee("ETH-C", FIFTEEN_PCT, /* doDrip = */ true);

        // Increase the WSTETH-A Stability Fee by 9.6% from 6.65% to 16.25%
        DssExecLib.setIlkStabilityFee("WSTETH-A", SIXTEEN_PT_TWO_FIVE_PCT, /* doDrip = */ true);

        // Increase the WSTETH-B Stability Fee by 9.6% from 6.4% to 16%
        DssExecLib.setIlkStabilityFee("WSTETH-B", SIXTEEN_PCT, /* doDrip = */ true);

        // Increase the WBTC-A Stability Fee by 10.07% from 6.68% to 16.75%
        DssExecLib.setIlkStabilityFee("WBTC-A", SIXTEEN_PT_SEVEN_FIVE_PCT, /* doDrip = */ true);

        // Increase the WBTC-B Stability Fee by 10.07% from 7.18% to 17.25%
        DssExecLib.setIlkStabilityFee("WBTC-B", SEVENTEEN_PT_TWO_FIVE_PCT, /* doDrip = */ true);

        // Increase the WBTC-C Stability Fee by 10.07% from 6.43% to 16.5%
        DssExecLib.setIlkStabilityFee("WBTC-C", SIXTEEN_PT_FIVE_PCT, /* doDrip = */ true);

        // ---------- GSM Change ----------
        // Forum: https://forum.makerdao.com/t/accelerated-proposal-rate-system-gsm-delay-psm-usdc-a-ttl-changes/23824

        // Decrease the GSM Delay by 32 hours from 48 hours to 16 hours
        PauseLike(MCD_PAUSE).setDelay(16 hours);

        // ---------- USDC PSM ttl Change ----------
        // Forum: https://forum.makerdao.com/t/accelerated-proposal-rate-system-gsm-delay-psm-usdc-a-ttl-changes/23824

        // Decrease the ttl by 12 hours from 24 hours to 12 hours
        DssExecLib.setIlkAutoLineParameters("PSM-USDC-A", 10 * BILLION, 400 * MILLION, 12 hours);

        // ---------- Trigger Spark Proxy Spell ----------
        // Forum: https://forum.makerdao.com/t/accelerated-proposal-rate-system-gsm-delay-psm-usdc-a-ttl-changes/23824

        // Trigger Spark Proxy Spell at 0xFc72De9b361dB85F1d126De9cac51A1aEe8Ce126
        ProxyLike(SPARK_PROXY).exec(SPARK_SPELL, abi.encodeWithSignature("execute()"));
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) {}
}
