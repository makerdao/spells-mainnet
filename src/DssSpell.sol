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

interface VatLike {
    function Line() external view returns (uint256);
    function ilks(bytes32 ilk) external view returns (uint256 Art, uint256 rate, uint256 spot, uint256 line, uint256 dust);
}

interface VestLike {
    function create(address _usr, uint256 _tot, uint256 _bgn, uint256 _tau, uint256 _eta, address _mgr) external returns (uint256 id);
    function restrict(uint256 _id) external;
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
    // Hash: cast keccak -- "$(wget 'https://raw.githubusercontent.com/makerdao/community/c0eb5feb51cf5a8d0dcdcd4436976d3b4f3da913/governance/votes/Executive%20vote%20-%20September%2027%2C%202023.md' -q -O - 2>/dev/null)"
    string public constant override description =
        "2023-10-11 MakerDAO Executive Spell | Hash: TODO";

    // Set office hours according to the summary
    function officeHours() public pure override returns (bool) {
        return false;
    }

    // ----- USDP-PSM Facilitation Incentives -----
    // Forum: https://forum.makerdao.com/t/usdp-psm-facilitation-incentives/22331
    // Approve DAO Resolution hash QmWg43PNNGfEyXnTv1qN8dRXFJz5ZchrmZU8qH57Ki6D62

    // Comma-separated list of DAO resolutions IPFS hashes.
    string public constant dao_resolutions = "QmWg43PNNGfEyXnTv1qN8dRXFJz5ZchrmZU8qH57Ki6D62";

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
    uint256 internal constant FIVE_PCT_RATE                = 1000000001547125957863212448;
    uint256 internal constant FIVE_PT_TWO_FIVE_PCT_RATE    = 1000000001622535724756171269;
    uint256 internal constant FIVE_PT_SIX_ONE_PCT_RATE     = 1000000001730811701469052906;
    uint256 internal constant FIVE_PT_SEVEN_FIVE_PCT_RATE  = 1000000001772819380639683201;
    uint256 internal constant FIVE_PT_EIGHT_SIX_PCT_RATE   = 1000000001805786418479434295;
    uint256 internal constant SIX_PT_THREE_SIX_PCT_RATE    = 1000000001955206127822364746;

    //  ---------- Math ----------
    uint256 internal constant WAD      = 10 ** 18;
    uint256 internal constant MILLION  = 10 ** 6;
    uint256 internal constant BILLION  = 10 ** 9;

    // ----------- MKR transfer Addresses -----------

    // BA Labs address
    address internal constant RISK_WALLET_VEST  = 0x5d67d5B1fC7EF4bfF31967bE2D2d7b9323c1521c;
    // AVC's
    address internal constant OPENSKY           = 0x8e67eE3BbEb1743dc63093Af493f67C3c23C6f04;
    address internal constant DAI_VINCI         = 0x9ee47F0f82F1A6F45C4E1D25Ce95C321D8C8356a;
    address internal constant IAMMEEOH          = 0x47f7A5d8D27f259582097E1eE59a07a816982AE9;
    address internal constant ACREDAOS          = 0xBF9226345F601150F64Ea4fEaAE7E40530763cbd;
    address internal constant HARMONY           = 0xE20A2e231215e9b7Aa308463F1A7490b2ECE55D3;
    address internal constant RES               = 0x8c5c8d76372954922400e4654AF7694e158AB784;
    address internal constant SEEDLATAMETH      = 0x0087a081a9B430fd8f688c6ac5dD24421BfB060D;
    // Delegates
    address internal constant DEFENSOR          = 0x9542b441d65B6BF4dDdd3d4D2a66D8dCB9EE07a9;
    address internal constant TRUENAME          = 0x612F7924c367575a0Edf21333D96b15F1B345A5d;
    address internal constant BONAPUBLICA       = 0x167c1a762B08D7e78dbF8f24e5C3f1Ab415021D3;
    address internal constant NAVIGATOR         = 0x11406a9CC2e37425F15f920F494A51133ac93072;
    address internal constant VIGILANT          = 0x2474937cB55500601BCCE9f4cb0A0A72Dc226F61;
    address internal constant CLOAKY            = 0x869b6d5d8FA7f4FFdaCA4D23FFE0735c5eD1F818;
    address internal constant UPMAKER           = 0xbB819DF169670DC71A16F58F55956FE642cc6BcD;
    address internal constant PALC              = 0x78Deac4F87BD8007b9cb56B8d53889ed5374e83A;
    address internal constant BLUE              = 0xb6C09680D822F162449cdFB8248a7D3FC26Ec9Bf;
    address internal constant PBG               = 0x8D4df847dB7FfE0B46AF084fE031F7691C6478c2;

    // ----------- MKR & DAI Payment streams
    address internal constant JANSKY            = 0xf3F868534FAD48EF5a228Fe78669cf242745a755;
    address internal constant VOTEWIZARD        = 0x9E72629dF4fcaA2c2F5813FbbDc55064345431b1;

    // 2023-10-01 00:00:00 UTC
    uint256 internal constant OCT_01_2023       = 1696118400;
    // 2024-09-30 23:59:59 UTC
    uint256 internal constant SEP_30_2024       = 1727740799;

    // ---------- Spark Proxy ----------
    // Spark Proxy: https://github.com/marsfoundation/sparklend/blob/d42587ba36523dcff24a4c827dc29ab71cd0808b/script/output/1/primary-sce-latest.json#L2
    address internal constant SPARK_PROXY = 0x3300f198988e4C9C63F75dF86De36421f06af8c4;

    // ---------- Trigger Spark Proxy Spell ----------
    address internal constant SPARK_SPELL = 0xDE7C2758db29B53cbD2898a5584d6A719C17815E;

    //  ---------- MCD Contracts ----------
    address internal immutable MCD_VAT                  = DssExecLib.vat();
    address internal immutable MCD_VEST_DAI             = DssExecLib.getChangelogAddress("MCD_VEST_DAI");
    address internal immutable MCD_VEST_MKR_TREASURY    = DssExecLib.getChangelogAddress("MCD_VEST_MKR_TREASURY");
    address internal immutable MIP21_LIQUIDATION_ORACLE = DssExecLib.getChangelogAddress("MIP21_LIQUIDATION_ORACLE");
    GemAbstract internal immutable MKR                  = GemAbstract(DssExecLib.mkr());


    function actions() public override {
        // ---------- Non-Scope Defined Parameter Changes - WBTC DC-IAM Changes ----------
        // Forum: https://forum.makerdao.com/t/stability-scope-parameter-changes-6/22231
        // Poll: https://vote.makerdao.com/polling/QmNty2pa#poll-detail

        // Reduce the WBTC-A DC-IAM Target Available Debt from 10 million DAI to 2 million DAI.
        DssExecLib.setIlkAutoLineParameters("WBTC-A", /* line = */ 500 * MILLION, /* gap = */ 2 * MILLION, /* ttl = */ 24 hours);

        // Reduce the WBTC-B DC-IAM Target Available Debt from 5 million DAI to 2 million DAI.
        DssExecLib.setIlkAutoLineParameters("WBTC-B", /* line = */ 250 * MILLION, /* gap = */ 2 * MILLION, /* ttl = */ 24 hours);

        // Reduce the WBTC-C DC-IAM Target Available Debt from 10 million DAI to 2 million DAI.
        DssExecLib.setIlkAutoLineParameters("WBTC-C", /* line = */ 500 * MILLION, /* gap = */ 2 * MILLION, /* ttl = */ 24 hours);


        // ---------- Stability Fee Changes ----------
        // Forum: https://forum.makerdao.com/t/stability-scope-parameter-changes-6/22231

        // Increase the ETH-A Stability Fee (SF) by 1.55%, from 3.70% to 5.25%.
        DssExecLib.setIlkStabilityFee("ETH-A", FIVE_PT_TWO_FIVE_PCT_RATE, /* doDrip = */ true);

        // Increase the ETH-B Stability Fee (SF) by 1.55%, from 4.20% to 5.75%.
        DssExecLib.setIlkStabilityFee("ETH-B", FIVE_PT_SEVEN_FIVE_PCT_RATE, /* doDrip = */ true);

        // Increase the ETH-C Stability Fee (SF) by 1.55%, from 3.45% to 5.00%.
        DssExecLib.setIlkStabilityFee("ETH-C", FIVE_PCT_RATE, /* doDrip = */ true);

        // Increase WBTC-A Stability Fee (SF) by 0.06%, from 5.8% to 5.86%
        DssExecLib.setIlkStabilityFee("WBTC-A", FIVE_PT_EIGHT_SIX_PCT_RATE, /* doDrip = */ true);

        // Increase WBTC-B Stability Fee (SF) by 0.06%, from 6.3% to 6.36%
        DssExecLib.setIlkStabilityFee("WBTC-B", SIX_PT_THREE_SIX_PCT_RATE, /* doDrip = */ true);

        // Increase WBTC-C Stability Fee (SF) by 0.06%, from 5.55% to 5.61%
        DssExecLib.setIlkStabilityFee("WBTC-C", FIVE_PT_SIX_ONE_PCT_RATE, /* doDrip = */ true);


        // ---------- Initial RETH-A Offboarding  ----------
        // Forum: https://forum.makerdao.com/t/stability-scope-parameter-changes-6/22231

        // Set DC to 0.
        (,,,uint256 line,) = VatLike(MCD_VAT).ilks("RETH-A");
        DssExecLib.removeIlkFromAutoLine("RETH-A");
        DssExecLib.setValue(MCD_VAT, "RETH-A", "line", 0);
        // NOTE: decreasing global line using the low level API because of precision loss when using DssExecLib
        DssExecLib.setValue(MCD_VAT, "Line", VatLike(MCD_VAT).Line() - line);


        // ---------- Reconfiguring Andromeda RWA015-A  ----------
        // Forum: https://forum.makerdao.com/t/poll-request-reconfiguring-rwa-allocator-vaults/22159
        // Poll: https://vote.makerdao.com/polling/QmPoLbah

        // Set the Maximum Debt Ceiling (line) to 3 billion DAI.
        DssExecLib.setIlkAutoLineDebtCeiling("RWA015-A", 3 * BILLION);

        // Bump Oracle price to account for new DC and SF
        // NOTE: the formula is `Debt ceiling * [ (1 + RWA stability fee ) ^ (minimum deal duration in years) ] * liquidation ratio`
        // NOTE: As we have SF 0 for this deal, this should be equal to ilk DC
        RwaLiquidationLike(MIP21_LIQUIDATION_ORACLE).bump(
            "RWA015-A",
            3 * BILLION * WAD
        );

        // NOTE: Update collateral price to propagate the changes
        DssExecLib.updateCollateralPrice("RWA015-A");


        // ---------- Reconfiguring Clydesdale RWA007-A  ----------
        // Forum: https://forum.makerdao.com/t/poll-request-reconfiguring-rwa-allocator-vaults/22159
        // Poll: https://vote.makerdao.com/polling/QmPoLbah

        // Reactivate the Debt Ceiling Instant Access Module for this vault type.
        // Set the Maximum Debt Ceiling (line) to 3 billion DAI.
        // Set the Target Available Debt (gap) to 50 million DAI.
        // Set the Ceiling Increase Cooldown (ttl) to 86400 (24 hours).
        DssExecLib.setIlkAutoLineParameters("RWA007-A", /* line = */ 3 * BILLION, /* gap = */ 50 * MILLION, /* ttl = */ 24 hours);

        // Bump Oracle price to account for new DC and SF
        // NOTE: the formula is `Debt ceiling * [ (1 + RWA stability fee ) ^ (minimum deal duration in years) ] * liquidation ratio`
        // NOTE: As we have SF 0 for this deal, this should be equal to ilk DC
        RwaLiquidationLike(MIP21_LIQUIDATION_ORACLE).bump(
            "RWA007-A",
            3 * BILLION * WAD
        );

        // NOTE: Update collateral price to propagate the changes
        DssExecLib.updateCollateralPrice("RWA007-A");

        // ---------- Set up Governance Facilitator Streams  ----------
        // Forum: https://forum.makerdao.com/t/mip102c2-sp16-mip-amendment-subproposal/21579
        // Poll: https://vote.makerdao.com/polling/QmSovaxn

        // JanSky | 2023-10-01 00:00:00 to 2024-09-30 23:59:59 | 504,000.00 DAI | 0xf3F868534FAD48EF5a228Fe78669cf242745a755
        VestLike(MCD_VEST_DAI).restrict(
            VestLike(MCD_VEST_DAI).create(
                JANSKY,                    // usr
                504_000 * WAD,             // tot
                OCT_01_2023,               // bgn
                SEP_30_2024 - OCT_01_2023, // tau
                0,                         // eta
                address(0)                 // mgr
            )
        );
        // VoteWizard | 2023-10-01 00:00:00 to 2024-09-30 23:59:59 | 504,000.00 DAI | 0x9E72629dF4fcaA2c2F5813FbbDc55064345431b1
        VestLike(MCD_VEST_DAI).restrict(
            VestLike(MCD_VEST_DAI).create(
                VOTEWIZARD,                // usr
                504_000 * WAD,             // tot
                OCT_01_2023,               // bgn
                SEP_30_2024 - OCT_01_2023, // tau
                0,                         // eta
                address(0)                 // mgr
            )
        );

        // Increase allowance by new vesting delta
        uint256 newVesting = 216 ether; // JANSKY; note: ether is a keyword helper, only MKR is transferred here
               newVesting += 216 ether; // VOTEWIZARD; note: ether is a keyword helper, only MKR is transferred here
        MKR.approve(address(MCD_VEST_MKR_TREASURY), MKR.allowance(address(this), (address(MCD_VEST_MKR_TREASURY))) + newVesting);

        // JanSky | 2023-10-01 00:00:00 to 2024-09-30 23:59:59 | 216.00 MKR | 0xf3F868534FAD48EF5a228Fe78669cf242745a755
        VestLike(MCD_VEST_MKR_TREASURY).restrict(
            VestLike(MCD_VEST_MKR_TREASURY).create(
                JANSKY,                    // usr
                216 ether,                 // tot
                OCT_01_2023,               // bgn
                SEP_30_2024 - OCT_01_2023, // tau
                0,                         // eta
                address(0)                 // mgr
            )
        );
        // VoteWizard | 2023-10-01 00:00:00 to 2024-09-30 23:59:59 | 216.00 MKR | 0x9E72629dF4fcaA2c2F5813FbbDc55064345431b1
        VestLike(MCD_VEST_MKR_TREASURY).restrict(
            VestLike(MCD_VEST_MKR_TREASURY).create(
                VOTEWIZARD,                // usr
                216 ether,                 // tot
                OCT_01_2023,               // bgn
                SEP_30_2024 - OCT_01_2023, // tau
                0,                         // eta
                address(0)                 // mgr
            )
        );

        // ---------- BA Labs MKR Distribution  ----------
        // Forum: https://forum.makerdao.com/t/mip40c3-sp25-risk-core-unit-mkr-compensation-risk-001/9788
        // Poll: https://vote.makerdao.com/polling/QmUAXKm4

        // BA Labs - 175 MKR - 0x5d67d5B1fC7EF4bfF31967bE2D2d7b9323c1521c
        MKR.transfer(RISK_WALLET_VEST, 175 ether); // NOTE: ether is a keyword helper, only MKR is transferred here


        // ---------- AVC Member Compensation  ----------
        // Forum: https://forum.makerdao.com/t/avc-member-participation-rewards-q3-2023/22349
        // Poll: https://vote.makerdao.com/polling/QmSovaxn#poll-detail

        // opensky - 20.85 MKR - 0x8e67ee3bbeb1743dc63093af493f67c3c23c6f04
        MKR.transfer(OPENSKY, 20.85 ether); // NOTE: ether is a keyword helper, only MKR is transferred here
        // DAI-Vinci - 12.51 MKR - 0x9ee47F0f82F1A6F45C4E1D25Ce95C321D8C8356a
        MKR.transfer(DAI_VINCI, 12.51 ether); // NOTE: ether is a keyword helper, only MKR is transferred here
        // IamMeeoh - 20.85 MKR - 0x47f7A5d8D27f259582097E1eE59a07a816982AE9
        MKR.transfer(IAMMEEOH, 20.85 ether); // NOTE: ether is a keyword helper, only MKR is transferred here
        // ACRE DAOs - 20.85 MKR - 0xBF9226345F601150F64Ea4fEaAE7E40530763cbd
        MKR.transfer(ACREDAOS, 20.85 ether); // NOTE: ether is a keyword helper, only MKR is transferred here
        // Harmony - 20.85 MKR - 0xE20A2e231215e9b7Aa308463F1A7490b2ECE55D3
        MKR.transfer(HARMONY, 20.85 ether); // NOTE: ether is a keyword helper, only MKR is transferred here
        // Res - 20.85 MKR - 0x8c5c8d76372954922400e4654AF7694e158AB784
        MKR.transfer(RES, 20.85 ether); // NOTE: ether is a keyword helper, only MKR is transferred here
        // seedlatam.eth - 20.85 MKR - 0x0087a081a9b430fd8f688c6ac5dd24421bfb060d
        MKR.transfer(SEEDLATAMETH, 20.85 ether); // NOTE: ether is a keyword helper, only MKR is transferred here

        // ---------- Delegate Compensation  ----------
        // Forum: https://forum.makerdao.com/t/september-2023-aligned-delegate-compensation/22367

        // 0xDefensor - 41.67 MKR - 0x9542b441d65B6BF4dDdd3d4D2a66D8dCB9EE07a9
        MKR.transfer(DEFENSOR, 41.67 ether); // NOTE: ether is a keyword helper, only MKR is transferred here
        // TRUE NAME - 41.67 MKR - 0x612F7924c367575a0Edf21333D96b15F1B345A5d
        MKR.transfer(TRUENAME, 41.67 ether); // NOTE: ether is a keyword helper, only MKR is transferred here
        // BONAPUBLICA - 41.67 MKR - 0x167c1a762B08D7e78dbF8f24e5C3f1Ab415021D3
        MKR.transfer(BONAPUBLICA, 41.67 ether); // NOTE: ether is a keyword helper, only MKR is transferred here
        // Navigator - 41.67 MKR - 0x11406a9CC2e37425F15f920F494A51133ac93072
        MKR.transfer(NAVIGATOR, 41.67 ether); // NOTE: ether is a keyword helper, only MKR is transferred here
        // vigilant - 34.5 MKR - 0x2474937cB55500601BCCE9f4cb0A0A72Dc226F61
        MKR.transfer(VIGILANT, 34.55 ether); // NOTE: ether is a keyword helper, only MKR is transferred here
        // Cloaky - 21.06 MKR - 0x869b6d5d8FA7f4FFdaCA4D23FFE0735c5eD1F818
        MKR.transfer(CLOAKY, 21.06 ether); // NOTE: ether is a keyword helper, only MKR is transferred here
        // UPMaker - 13.89 MKR - 0xbB819DF169670DC71A16F58F55956FE642cc6BcD
        MKR.transfer(UPMAKER, 13.89 ether); // NOTE: ether is a keyword helper, only MKR is transferred here
        // PALC - 13.89 MKR - 0x78Deac4F87BD8007b9cb56B8d53889ed5374e83A
        MKR.transfer(PALC, 13.89 ether); // NOTE: ether is a keyword helper, only MKR is transferred here
        // BLUE - 12.78 MKR - 0xb6C09680D822F162449cdFB8248a7D3FC26Ec9Bf
        MKR.transfer(BLUE, 12.78 ether); // NOTE: ether is a keyword helper, only MKR is transferred here
        // PBG - 6.48 MKR - 0x8D4df847dB7FfE0B46AF084fE031F7691C6478c2
        MKR.transfer(PBG, 6.48 ether); // NOTE: ether is a keyword helper, only MKR is transferred here

        // ---------- Trigger Spark Proxy Spell ----------
        // Poll: https://vote.makerdao.com/polling/QmVcxd7J
        // Forum: https://forum.makerdao.com/t/proposal-for-activation-of-gnosis-chain-instance/22098/8
        ProxyLike(SPARK_PROXY).exec(SPARK_SPELL, abi.encodeWithSignature("execute()"));
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) {}
}
