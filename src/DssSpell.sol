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
import { VatAbstract } from "dss-interfaces/dss/VatAbstract.sol";

interface RwaLiquidationOracleLike {
    function bump(bytes32 ilk, uint256 val) external;
}

interface ProxyLike {
    function exec(address target, bytes calldata args) external payable returns (bytes memory out);
}

contract DssSpellAction is DssAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: cast keccak -- "$(wget 'TODO' -q -O - 2>/dev/null)"
    string public constant override description =
        "2023-11-29 MakerDAO Executive Spell | Hash: TODO";

    // Set office hours according to the summary
    function officeHours() public pure override returns (bool) {
        return false;
    }

    // ---------- RWA Foundation Service Provider Changes ----------
    // Forum: https://forum.makerdao.com/t/dao-resolution-rwa-foundation-service-provider-changes/22866

    // Approve Dao resolution with IPFS hash QmPiEHtt8rkVtSibBXMrhEzHUmSriXWz4AL2bjscq8dUvU
    // Note: by the previous convention it is comma-separated list of DAO resolutions IPFS hashes
    string public constant dao_resolutions = "QmPiEHtt8rkVtSibBXMrhEzHUmSriXWz4AL2bjscq8dUvU";

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
    uint256 internal constant FIVE_PT_FIVE_FOUR_PCT_RATE  = 1000000001709786974743980088;
    uint256 internal constant FIVE_PT_SEVEN_NINE_PCT_RATE = 1000000001784811360376128985;
    uint256 internal constant SIX_PT_TWO_NINE_PCT_RATE    = 1000000001934329706253075715;

    // ---------- Math ----------
    uint256 internal constant THOUSAND = 10 ** 3;
    uint256 internal constant MILLION  = 10 ** 6;
    uint256 internal constant BILLION  = 10 ** 9;
    uint256 internal constant WAD      = 10 ** 18;
    uint256 internal constant RAD      = 10 ** 45;

    // ---------- SBE parameter changes ----------
    address internal immutable MCD_VOW            = DssExecLib.vow();
    address internal immutable MCD_FLAP           = DssExecLib.flap();

    // ---------- Reduce PSM-GUSD-A Debt Ceiling ----------
    VatAbstract internal immutable vat            = VatAbstract(DssExecLib.vat());

    // ---------- Increase RWA014-A (Coinbase Custody) Debt Ceiling ----------
    address internal immutable MIP21_LIQUIDATION_ORACLE = DssExecLib.getChangelogAddress("MIP21_LIQUIDATION_ORACLE");

    // ---------- Andromeda Legal Expenses ----------
    address internal constant BLOCKTOWER_WALLET_2 = 0xc4dB894A11B1eACE4CDb794d0753A3cB7A633767;

    // ---------- Trigger Spark Proxy Spell ----------
    // Spark Proxy: https://github.com/marsfoundation/sparklend/blob/d42587ba36523dcff24a4c827dc29ab71cd0808b/script/output/1/primary-sce-latest.json#L2
    address internal constant SPARK_PROXY = 0x3300f198988e4C9C63F75dF86De36421f06af8c4;
    address internal constant SPARK_SPELL = 0x68a075249fA77173b8d1B92750c9920423997e2B;

    function actions() public override {
        // ---------- Stability Fee Changes ----------
        // Forum: https://forum.makerdao.com/t/stability-scope-parameter-changes-7/22882#increase-rwa014-a-coinbase-custody-debt-ceiling-9

        // Decrease the WBTC-A Stability Fee (SF) by 0.07%, from 5.86% to 5.79%
        DssExecLib.setIlkStabilityFee("WBTC-A", FIVE_PT_SEVEN_NINE_PCT_RATE, /* doDrip = */ true);

        // Decrease the WBTC-B Stability Fee (SF) by 0.07%, from 6.36% to 6.29%
        DssExecLib.setIlkStabilityFee("WBTC-B", SIX_PT_TWO_NINE_PCT_RATE, /* doDrip = */ true);

        // Decrease the WBTC-C Stability Fee (SF) by 0.07%, from 5.61% to 5.54%
        DssExecLib.setIlkStabilityFee("WBTC-C", FIVE_PT_FIVE_FOUR_PCT_RATE, /* doDrip = */ true);

        // ---------- Reduce PSM-GUSD-A Debt Ceiling ----------
        // Forum: https://forum.makerdao.com/t/stability-scope-parameter-changes-7/22882/2

        // Note: record currently set debt ceiling for PSM-GUSD-A
        (,,,uint256 lineReduction,) = vat.ilks("PSM-GUSD-A");

        // Remove PSM-GUSD-A from `Autoline`
        DssExecLib.removeIlkFromAutoLine("PSM-GUSD-A");

        // Set PSM-GUSD-A debt ceiling to 0
        DssExecLib.setIlkDebtCeiling("PSM-GUSD-A", 0);

        // Reduce Global Debt Ceiling? Yes
        vat.file("Line", vat.Line() - lineReduction);

        // ---------- Increase RWA014-A (Coinbase Custody) Debt Ceiling ----------
        // Forum: https://forum.makerdao.com/t/stability-scope-parameter-changes-7/22882#increase-rwa014-a-coinbase-custody-debt-ceiling-9

        // Increase the RWA014-A (Coinbase Custody) debt ceiling by 1b DAI, from 500M to 1.5b
        DssExecLib.increaseIlkDebtCeiling("RWA014-A", 1 * BILLION, /* global = */ true);

        // Note: we have to bump the oracle price to account for the new DC
        // Note: the formula is `Debt ceiling * [ (1 + RWA stability fee ) ^ (minimum deal duration in years) ] * liquidation ratio`
        // Note: as stability fee is 0 for this deal, this should be equal to ilk DC
        RwaLiquidationOracleLike(MIP21_LIQUIDATION_ORACLE).bump(
            "RWA014-A",
            1_500 * MILLION * WAD
        );

        // Note: we have to update collateral price to propagate the changes
        DssExecLib.updateCollateralPrice("RWA014-A");

        // ---------- SBE parameter changes ----------
        // Forum: https://forum.makerdao.com/t/smart-burn-engine-transaction-analysis-parameter-reconfiguration-update-3/22876

        // Increase bump by 10,000, from 20,000 to 30,000
        DssExecLib.setValue(MCD_VOW, "bump", 30 * THOUSAND * RAD);

        // Increase hop by 9,460, from 6,308 to 15,768
        DssExecLib.setValue(MCD_FLAP, "hop", 15_768);

        // ---------- Andromeda Legal Expenses ----------
        // Forum: https://forum.makerdao.com/t/project-andromeda-legal-expenses-ii/22577/4

        // Transfer 201,738 Dai to 0xc4dB894A11B1eACE4CDb794d0753A3cB7A633767
        DssExecLib.sendPaymentFromSurplusBuffer(BLOCKTOWER_WALLET_2, 201_738);

        // ---------- Trigger Spark Proxy Spell ----------
        // Forum: https://forum.makerdao.com/t/accounting-discrepancy-in-the-dai-market/22845/2

        // Mainnet - 0x68a075249fA77173b8d1B92750c9920423997e2B
        ProxyLike(SPARK_PROXY).exec(SPARK_SPELL, abi.encodeWithSignature("execute()"));
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) {}
}
