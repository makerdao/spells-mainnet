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
import { GemAbstract } from "dss-interfaces/ERC/GemAbstract.sol";

interface DssCronSequencerLike {
    function addJob(address job) external;
    function removeJob(address job) external;
}

interface RwaLiquidationLike {
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
        "2024-08-12 MakerDAO Executive Spell | Hash: TODO";

    // Set office hours according to the summary
    function officeHours() public pure override returns (bool) {
        return false;
    }

    // Note: by the previous convention it should be a comma-separated list of DAO resolutions IPFS hashes
    string public constant dao_resolutions = "QmaYKt61v6aCTNTYjuHm1Wjpe6JWBzCW2ZHR4XDEJhjm1R";

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
    uint256 internal constant SIX_PT_TWO_FIVE_PCT_RATE     = 1000000001922394148741344865;
    uint256 internal constant SIX_PT_SEVEN_FIVE_PCT_RATE   = 1000000002071266685321207000;
    uint256 internal constant SIX_PCT_RATE                 = 1000000001847694957439350562;
    uint256 internal constant SEVEN_PT_TWO_FIVE_PCT_RATE   = 1000000002219443553326580536;
    uint256 internal constant SEVEN_PCT_RATE               = 1000000002145441671308778766;
    uint256 internal constant SEVEN_PT_SEVEN_FIVE_PCT_RATE = 1000000002366931224128103346;
    uint256 internal constant EIGHT_PT_TWO_FIVE_PCT_RATE   = 1000000002513736079215619839;
    uint256 internal constant SEVEN_PT_FIVE_PCT_RATE       = 1000000002293273137447730714;
    uint256 internal constant NINE_PCT_RATE                = 1000000002732676825177582095;

    // ---------- Contracts ----------
    GemAbstract internal immutable MKR = GemAbstract(DssExecLib.mkr());

    // ---------- Bug Bounty Payout ----------
    address internal constant IMMUNEFI_COMISSION              = 0x7119f398b6C06095c6E8964C1f58e7C1BAa79E18;
    address internal constant IMMUNEFI_USER_PAYOUT_2024_08_08 = 0xA4a6B5f005cBd2eD38f49ac496d86d3528C7a1aa;

    // ---------- Update ClipperMomJob ----------
    address internal immutable CRON_SEQUENCER          = DssExecLib.getChangelogAddress("CRON_SEQUENCER");
    address internal immutable CRON_CLIPPER_MOM_JOB    = DssExecLib.getChangelogAddress("CRON_CLIPPER_MOM_JOB");
    address internal constant CRON_CLIPPER_MOM_JOB_NEW = 0x7E93C4f61C8E8874e7366cDbfeFF934Ed089f9fF;

    // ---------- Aligned Delegate Compensation ----------
    address internal constant BLUE           = 0xb6C09680D822F162449cdFB8248a7D3FC26Ec9Bf;
    address internal constant CLOAKY         = 0x869b6d5d8FA7f4FFdaCA4D23FFE0735c5eD1F818;
    address internal constant BYTERON        = 0xc2982e72D060cab2387Dba96b846acb8c96EfF66;
    address internal constant JULIACHANG     = 0x252abAEe2F4f4b8D39E5F12b163eDFb7fac7AED7;
    address internal constant ROCKY          = 0xC31637BDA32a0811E39456A59022D2C386cb2C85;
    address internal constant PBG            = 0x8D4df847dB7FfE0B46AF084fE031F7691C6478c2;
    address internal constant CLOAKY_KOHLA_2 = 0x73dFC091Ad77c03F2809204fCF03C0b9dccf8c7a;
    address internal constant CLOAKY_ENNOIA  = 0xA7364a1738D0bB7D1911318Ca3FB3779A8A58D7b;

    // ---------- RWA001-A Stability Fee Increase ----------
    address internal immutable MIP21_LIQUIDATION_ORACLE = DssExecLib.getChangelogAddress("MIP21_LIQUIDATION_ORACLE");

    // ---------- Spark Proxy Spell ----------
    // Spark Proxy: https://github.com/marsfoundation/sparklend-deployments/blob/bba4c57d54deb6a14490b897c12a949aa035a99b/script/output/1/primary-sce-latest.json#L2
    address internal constant SPARK_PROXY = 0x3300f198988e4C9C63F75dF86De36421f06af8c4;
    address internal constant SPARK_SPELL = 0x4622245a1aaf0fb752F9cAC0A29616792b33F089;

    function actions() public override {
        // ---------- Stability Fee Reductions ----------
        // Forum: https://forum.makerdao.com/t/stability-scope-parameter-changes-15-sfs-dsr-spark-effective-dai-borrow-rate-reduction/24834

        // ETH-A: Decrease SF by 1 percentage point, from 7.25% to 6.25%
        DssExecLib.setIlkStabilityFee("ETH-A", SIX_PT_TWO_FIVE_PCT_RATE, /* doDrip = */ true);

        // ETH-B: Decrease SF by 1 percentage point, from 7.75% to 6.75%
        DssExecLib.setIlkStabilityFee("ETH-B", SIX_PT_SEVEN_FIVE_PCT_RATE, /* doDrip = */ true);

        // ETH-C: Decrease SF by 1 percentage point, from 7% to 6%
        DssExecLib.setIlkStabilityFee("ETH-C", SIX_PCT_RATE, /* doDrip = */ true);

        // WSTETH-A: Decrease SF by 1 percentage point, from 8.25% to 7.25%
        DssExecLib.setIlkStabilityFee("WSTETH-A", SEVEN_PT_TWO_FIVE_PCT_RATE, /* doDrip = */ true);

        // WSTETH-B: Decrease SF by 1 percentage point, from 8% to 7%
        DssExecLib.setIlkStabilityFee("WSTETH-B", SEVEN_PCT_RATE, /* doDrip = */ true);

        // WBTC-A: Decrease SF by 1 percentage point, from 8.75% to 7.75%
        DssExecLib.setIlkStabilityFee("WBTC-A", SEVEN_PT_SEVEN_FIVE_PCT_RATE, /* doDrip = */ true);

        // WBTC-B: Decrease SF by 1 percentage point, from 9.25% to 8.25%
        DssExecLib.setIlkStabilityFee("WBTC-B", EIGHT_PT_TWO_FIVE_PCT_RATE, /* doDrip = */ true);

        // WBTC-C: Decrease SF by 1 percentage point, from 8.5% to 7.5%
        DssExecLib.setIlkStabilityFee("WBTC-C", SEVEN_PT_FIVE_PCT_RATE, /* doDrip = */ true);

        // ---------- DSR Reduction ----------
        // Forum: https://forum.makerdao.com/t/stability-scope-parameter-changes-15-sfs-dsr-spark-effective-dai-borrow-rate-reduction/24834

        // DSR: Decrease DSR by 1 percentage point, from 7% to 6%
        DssExecLib.setDSR(SIX_PCT_RATE, /* doDrip = */ true);

        // ---------- Bug Bounty Payout ----------
        // Forum: https://forum.makerdao.com/t/bounty-payout-request-for-immunefi-bug-32005/24605
        // MIP: https://mips.makerdao.com/mips/details/MIP106#13-1-bug-bounty-program-for-makerdao-critical-infrastructure

        // Transfer 100,000 DAI to bug reporter at 0xA4a6B5f005cBd2eD38f49ac496d86d3528C7a1aa
        DssExecLib.sendPaymentFromSurplusBuffer(IMMUNEFI_USER_PAYOUT_2024_08_08, 100_000);

        // Transfer 10,000 DAI to Immunefi at 0x7119f398b6C06095c6E8964C1f58e7C1BAa79E18
        DssExecLib.sendPaymentFromSurplusBuffer(IMMUNEFI_COMISSION, 10_000);

        // ---------- Update ClipperMomJob ----------
        // Forum: https://forum.makerdao.com/t/executive-inclusion-clippermomjob-update/24774

        // remove the old ClipperMomJob from the CronSequencer
        DssCronSequencerLike(CRON_SEQUENCER).removeJob(CRON_CLIPPER_MOM_JOB);

        // add the new ClipperMomJob (0x7E93C4f61C8E8874e7366cDbfeFF934Ed089f9fF) to the Cron Sequencer
        DssCronSequencerLike(CRON_SEQUENCER).addJob(CRON_CLIPPER_MOM_JOB_NEW);

        // Update CRON_CLIPPER_MOM_JOB to 0x7E93C4f61C8E8874e7366cDbfeFF934Ed089f9fF in the Chainlog
        DssExecLib.setChangelogAddress("CRON_CLIPPER_MOM_JOB", CRON_CLIPPER_MOM_JOB_NEW);

        // Note: bump chainlog version due to the updated CRON_CLIPPER_MOM_JOB address
        DssExecLib.setChangelogVersion("1.17.6");

        // ---------- Aligned Delegate MKR Compensation ----------
        // Forum: https://forum.makerdao.com/t/july-2024-aligned-delegate-payment-requests/24794
        // MIP: https://mips.makerdao.com/mips/details/MIP101#2-6-3-aligned-delegate-budget-and-participation-requirements

        // BLUE - 13.75 MKR - 0xb6C09680D822F162449cdFB8248a7D3FC26Ec9Bf
        MKR.transfer(BLUE, 13.75 ether); // Note: 'ether' is a keyword helper, only MKR is transferred here

        // Cloaky - 12.00 MKR - 0x869b6d5d8FA7f4FFdaCA4D23FFE0735c5eD1F818
        MKR.transfer(CLOAKY, 12.00 ether); // Note: 'ether' is a keyword helper, only MKR is transferred here

        // Byteron - 1.25 MKR - 0xc2982e72D060cab2387Dba96b846acb8c96EfF66
        MKR.transfer(BYTERON, 1.25 ether); // Note: 'ether' is a keyword helper, only MKR is transferred here

        // JuliaChang - 1.25 MKR - 0x252abAEe2F4f4b8D39E5F12b163eDFb7fac7AED7
        MKR.transfer(JULIACHANG, 1.25 ether); // Note: 'ether' is a keyword helper, only MKR is transferred here

        // Rocky - 1.13 MKR - 0xC31637BDA32a0811E39456A59022D2C386cb2C85
        MKR.transfer(ROCKY, 1.13 ether); // Note: 'ether' is a keyword helper, only MKR is transferred here

        // PBG - 1.00 MKR - 0x8D4df847dB7FfE0B46AF084fE031F7691C6478c2
        MKR.transfer(PBG, 1.00 ether); // Note: 'ether' is a keyword helper, only MKR is transferred here

        // ---------- Aligned Delegate DAI Compensation ----------
        // Forum: https://forum.makerdao.com/t/july-2024-aligned-delegate-payment-requests/24794
        // MIP: https://mips.makerdao.com/mips/details/MIP101#2-6-3-aligned-delegate-budget-and-participation-requirements

        // BLUE - 54167 DAI - 0xb6c09680d822f162449cdfb8248a7d3fc26ec9bf
        DssExecLib.sendPaymentFromSurplusBuffer(BLUE, 54_167);

        // Cloaky - 20417 DAI - 0x869b6d5d8FA7f4FFdaCA4D23FFE0735c5eD1F818
        DssExecLib.sendPaymentFromSurplusBuffer(CLOAKY, 20_417);

        // Kohla (Cloaky) [NEW ADDRESS] - 14172 DAI - 0x73dFC091Ad77c03F2809204fCF03C0b9dccf8c7a
        DssExecLib.sendPaymentFromSurplusBuffer(CLOAKY_KOHLA_2, 14_172);

        // Ennoia (Cloaky) - 9083 DAI - 0xA7364a1738D0bB7D1911318Ca3FB3779A8A58D7b
        DssExecLib.sendPaymentFromSurplusBuffer(CLOAKY_ENNOIA, 9_083);

        // Byteron - 8333 DAI - 0xc2982e72D060cab2387Dba96b846acb8c96EfF66
        DssExecLib.sendPaymentFromSurplusBuffer(BYTERON, 8_333);

        // JuliaChang - 8333 DAI - 0x252abAEe2F4f4b8D39E5F12b163eDFb7fac7AED7
        DssExecLib.sendPaymentFromSurplusBuffer(JULIACHANG, 8_333);

        // Rocky - 7500 DAI - 0xC31637BDA32a0811E39456A59022D2C386cb2C85
        DssExecLib.sendPaymentFromSurplusBuffer(ROCKY, 7_500);

        // PBG - 6667 DAI - 0x8D4df847dB7FfE0B46AF084fE031F7691C6478c2
        DssExecLib.sendPaymentFromSurplusBuffer(PBG, 6_667);

        // ---------- RWA001-A Stability Fee Increase ----------
        // Forum: https://forum.makerdao.com/t/rwa-001-6s-capital-update-and-stability-fee-proposal/24624

        // Increase the RWA001-A Stability Fee by 6 percentage points from 3% to 9%
        DssExecLib.setIlkStabilityFee("RWA001-A", NINE_PCT_RATE, /* doDrip = */ true);

        // Note: Bump Oracle price to account for new SF
        // Note: the formula is `Debt ceiling * [ (1 + RWA stability fee ) ^ (minimum deal duration in years) ] * liquidation ratio`
        // Since RWA001-A Termination Date is `July 29, 2025`, and spell execution time is `2024-08-12`, the distance is `356` days
        // bc -l <<< 'scale=18; 15000000 * e(l(1.09) * (352/365)) * 1.00' | cast --to-wei
        RwaLiquidationLike(MIP21_LIQUIDATION_ORACLE).bump(
            "RWA001-A",
            16_299_893_185222593795000000
        );

        // Note: Update collateral price to propagate the changes
        DssExecLib.updateCollateralPrice("RWA001-A");

        // ---------- Monetalis Clydesdale DAO Resolution ----------
        // Forum: https://forum.makerdao.com/t/clydesdale-vault-hq/17923/88

        // Approve DAO Resolution at QmaYKt61v6aCTNTYjuHm1Wjpe6JWBzCW2ZHR4XDEJhjm1R
        // Note: see `dao_resolutions` variable declared above

        // ---------- Spark Proxy Spell ----------
        // Forum: https://forum.makerdao.com/t/jul-27-2024-proposed-changes-to-spark-for-upcoming-spell/24755
        // Poll: https://vote.makerdao.com/polling/QmdFCRfK#poll-detail

        // Trigger Spark Proxy Spell at 0x4622245a1aaf0fb752F9cAC0A29616792b33F089
        ProxyLike(SPARK_PROXY).exec(SPARK_SPELL, abi.encodeWithSignature("execute()"));
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) {}
}
