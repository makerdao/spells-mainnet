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

import {GemAbstract} from "dss-interfaces/ERC/GemAbstract.sol";

interface ProxyLike {
    function exec(address target, bytes calldata args) external payable returns (bytes memory out);
}

interface DaiUsdsLike {
    function daiToUsds(address usr, uint256 wad) external;
}

interface MkrSkyLike {
    function mkrToSky(address usr, uint256 wad) external;
    function rate() external view returns (uint256);
}

interface OsmAbstractLike {
    function change(address) external;
}

contract DssSpellAction is DssAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: cast keccak -- "$(wget 'TODO' -q -O - 2>/dev/null)"
    string public constant override description = "TODO MakerDAO Executive Spell | Hash: TODO";

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
    // uint256 internal constant X_PCT_RATE = ;

    // --- Math ---
    uint256 internal constant BILLION  = 10 ** 9;
    uint256 internal constant WAD      = 10 ** 18;

    // ---------- MCD Addresses ----------
    GemAbstract internal immutable MKR                 = GemAbstract(DssExecLib.mkr());
    GemAbstract internal immutable DAI                 = GemAbstract(DssExecLib.dai());
    address internal immutable DAI_USDS                = DssExecLib.getChangelogAddress("DAI_USDS");
    address internal immutable MKR_SKY                 = DssExecLib.getChangelogAddress("MKR_SKY");
    address internal immutable PIP_WBTC                = DssExecLib.getChangelogAddress("PIP_WBTC");

    // ---------- Constant Values ----------
    uint256 internal immutable MKR_SKY_RATE            = MkrSkyLike(DssExecLib.getChangelogAddress("MKR_SKY")).rate();


    // ---------- Wallets ----------
    address internal constant BLUE                         = 0xb6C09680D822F162449cdFB8248a7D3FC26Ec9Bf;
    address internal constant BONAPUBLICA                  = 0x167c1a762B08D7e78dbF8f24e5C3f1Ab415021D3;
    address internal constant BYTERON                      = 0xc2982e72D060cab2387Dba96b846acb8c96EfF66;
    address internal constant CLOAKY                       = 0x869b6d5d8FA7f4FFdaCA4D23FFE0735c5eD1F818;
    address internal constant CLOAKY_ENNOIA                = 0xA7364a1738D0bB7D1911318Ca3FB3779A8A58D7b;
    address internal constant JULIACHANG                   = 0x252abAEe2F4f4b8D39E5F12b163eDFb7fac7AED7;
    address internal constant VIGILANT                     = 0x2474937cB55500601BCCE9f4cb0A0A72Dc226F61;
    address internal constant ROCKY                        = 0xC31637BDA32a0811E39456A59022D2C386cb2C85;
    address internal constant CLOAKY_KOHLA_2               = 0x73dFC091Ad77c03F2809204fCF03C0b9dccf8c7a;
    address internal constant INTEGRATION_BOOST_INITIATIVE = 0xD6891d1DFFDA6B0B1aF3524018a1eE2E608785F7;
    address internal constant IMMUNEFI_COMISSION           = 0x7119f398b6C06095c6E8964C1f58e7C1BAa79E18;
    address internal constant WHITEHAT                     = 0xB5BB14252099CAef65912ad2F1BBd9434cF24c38;
    address internal constant RESILIENCE_RESEARCH_FUNDING  = 0x1378056c0cdd771de52A111E2777293516fA910c;

    // ---------- Spark Proxy Spell ----------
    // Spark Proxy: https://github.com/marsfoundation/sparklend-deployments/blob/bba4c57d54deb6a14490b897c12a949aa035a99b/script/output/1/primary-sce-latest.json#L2
    address internal constant SPARK_PROXY = 0x3300f198988e4C9C63F75dF86De36421f06af8c4;
    address internal constant SPARK_SPELL = 0x7fb2967cDC6816Dc508f35C5A6CB035C8B6507Ec;

    function actions() public override {
        // ---------- WBTC Oracle Migration ----------
        // Forum: https://forum.sky.money/t/technical-scope-of-the-wbtc-oracle-migration/25715

        //Change WBTC OSM source to 0x24C392CDbF32Cf911B258981a66d5541d85269ce
        OsmAbstractLike(PIP_WBTC).change(0x24C392CDbF32Cf911B258981a66d5541d85269ce);

        // ---------- Increase ALLOCATOR-SPARK-A Maximum Debt Ceiling (line) ----------
        // Forum: https://forum.sky.money/t/27-dec-2024-proposed-changes-to-spark-for-upcoming-spell/25760
        // Poll: https://vote.makerdao.com/polling/QmQ6bYou

        // Increase the Spark Liquidity Layer Allocation Vault (ALLOCATOR-SPARK-A) Maximum Debt Ceiling (line) by 900 million USDS from 100 million USDS to 1 billion USDS.
        DssExecLib.setIlkAutoLineDebtCeiling("ALLOCATOR-SPARK-A", BILLION);

        // ---------- Rates Adjustment ----------
        // Note: Eventually, no Rates Adjustment needed in this spell, the section is kept here as it also exists in the exec sheet.

        // ---------- Integration Boost Funding ----------
        // Forum: https://forum.sky.money/t/utilization-of-the-integration-boost-budget-a-5-2-1-2/25536/3
        // Atlas: https://sky-atlas.powerhouse.io/A.5.2.1.2_Integration_Boost/129f2ff0-8d73-8057-850b-d32304e9c91a%7C8d5a9e88cf49

        // Integration Boost - 3000000 USDS - 0xD6891d1DFFDA6B0B1aF3524018a1eE2E608785F7
        _transferUsds(INTEGRATION_BOOST_INITIATIVE, 3_000_000 * WAD);

        // ---------- Bug Bounty Payouts ----------
        // Forum: https://forum.sky.money/t/bounty-payout-request-for-immunefi-bug-37383/25728
        // Atlas: https://sky-atlas.powerhouse.io/A.2.9.1.1.3.3.2_Rewards_Payout_Process/c4f5fe0d-a3cc-491d-b3af-db4176ad74cf%7C9e1f4492c8ce0c250f1a4db7

        // Whitehat Bug Bounty  - 1000 USDS - 0xB5BB14252099CAef65912ad2F1BBd9434cF24c38
        _transferUsds(WHITEHAT, 1_000 * WAD);

        // Immunefi Bug Bounty - 100 USDS - 0x7119f398b6C06095c6E8964C1f58e7C1BAa79E18
        _transferUsds(IMMUNEFI_COMISSION, 100 * WAD);

        // ---------- Resilience Research Project Application Funding ----------
        // Forum: https://forum.sky.money/t/resilience-research-project-application-legal-opinion-on-mica-compliance-for-cex-listings-of-usds-and-dai/25759
        // Poll: https://vote.makerdao.com/polling/QmdKkyYb

        // Resilience Research Funding - 32000 USDS - 0x1378056c0cdd771de52A111E2777293516fA910c
        _transferUsds(RESILIENCE_RESEARCH_FUNDING, 32_000 * WAD);

        // ---------- Aligned Delegate USDS Compensation ----------
        // Forum: https://forum.sky.money/t/november-2024-aligned-delegate-compensation/25740
        // Atlas: https://sky-atlas.powerhouse.io/A.1.5.8_Budget_For_Prime_Delegate_Slots/e3e420fc-9b1f-4fdc-9983-fcebc45dd3aa%7C0db3af4ece0c

        //BLUE - 4000 USDS - 0xb6C09680D822F162449cdFB8248a7D3FC26Ec9Bf
        _transferUsds(BLUE,        4_000 * WAD);

        //Bonapublica - 4000 USDS - 0x167c1a762B08D7e78dbF8f24e5C3f1Ab415021D3
        _transferUsds(BONAPUBLICA, 4_000 * WAD);

        // Byteron - 533 USDS - 0xc2982e72D060cab2387Dba96b846acb8c96EfF66
        _transferUsds(BYTERON,       533 * WAD);

        // Cloaky - 4000 USDS - 0x869b6d5d8FA7f4FFdaCA4D23FFE0735c5eD1F818
        _transferUsds(CLOAKY,      4_000 * WAD);

        // JuliaChang - 4000 USDS - 0x252abAEe2F4f4b8D39E5F12b163eDFb7fac7AED7
        _transferUsds(JULIACHANG,  4_000 * WAD);

        // Rocky - 2790 USDS - 0xC31637BDA32a0811E39456A59022D2C386cb2C85
        _transferUsds(ROCKY,       2_790 * WAD);

        // vigilant - 4000 USDS - 0x2474937cB55500601BCCE9f4cb0A0A72Dc226F61
        _transferUsds(VIGILANT,    4_000 * WAD);

        // ---------- Atlas Core Development USDS Payments ----------
        // Forum: https://forum.sky.money/t/atlas-core-development-payment-requests-december-2024/25741
        // Atlas: https://sky-atlas.powerhouse.io/A.2.2.1_Atlas_Core_Development/1542d2db-be91-46f5-9d13-3a86c78b9af1%7C9e1f3b56

        // BLUE (Team) - 83602 USDS - 0xb6C09680D822F162449cdFB8248a7D3FC26Ec9Bf
        _transferUsds(BLUE,           83_602 * WAD);

        // Kohla (Cloaky) - 10000 USDS - 0x73dFC091Ad77c03F2809204fCF03C0b9dccf8c7a
        _transferUsds(CLOAKY_KOHLA_2, 10_000 * WAD);

        // Ennoia (Cloaky) - 10000 USDS - 0xA7364a1738D0bB7D1911318Ca3FB3779A8A58D7b
        _transferUsds(CLOAKY_ENNOIA,  10_000 * WAD);

        // Cloaky (Team) - 22836 USDS - 0x869b6d5d8FA7f4FFdaCA4D23FFE0735c5eD1F818
        _transferUsds(CLOAKY,         22_836 * WAD);

        // ---------- Atlas Core Development SKY Payments ----------
        // Forum: https://forum.sky.money/t/atlas-core-development-payment-requests-december-2024/25741
        // Atlas: https://sky-atlas.powerhouse.io/A.2.2.1_Atlas_Core_Development/1542d2db-be91-46f5-9d13-3a86c78b9af1%7C9e1f3b56

        // BLUE (Team) - 550000.00 SKY - 0xb6C09680D822F162449cdFB8248a7D3FC26Ec9Bf
        _transferSky(BLUE,   550_000 * WAD);

        // Cloaky (Team) - 438000.00 SKY - 0x869b6d5d8FA7f4FFdaCA4D23FFE0735c5eD1F818
        _transferSky(CLOAKY, 438_000 * WAD);

        // Trigger Spark Proxy Spell
        // Forum: https://forum.sky.money/t/27-dec-2024-proposed-changes-to-spark-for-upcoming-spell/25760
        // Poll: https://vote.makerdao.com/polling/QmYScEHT
        // Poll: https://vote.makerdao.com/polling/Qma1xA18
        // Poll: https://vote.makerdao.com/polling/QmeEvuG2
        // Poll: https://vote.makerdao.com/polling/QmVpv1G8
        // Poll: https://vote.makerdao.com/polling/QmZ2Qmy5
        // Poll: https://vote.makerdao.com/polling/QmSTYyW5
        // Poll: https://vote.makerdao.com/polling/QmTFsGw8
        // Poll: https://vote.makerdao.com/polling/QmYDGkjM
        // Poll: https://vote.makerdao.com/polling/QmZfSDMH
        // Poll: https://vote.makerdao.com/polling/QmeZTfHR
        // Poll: https://vote.makerdao.com/polling/QmQarR2U
        // Poll: https://vote.makerdao.com/polling/QmQ6bYou

        // Trigger Spark proxy spell at 0x7fb2967cDC6816Dc508f35C5A6CB035C8B6507Ec
        ProxyLike(SPARK_PROXY).exec(SPARK_SPELL, abi.encodeWithSignature("execute()"));

    }

    /// @notice wraps the operations required to transfer USDS from the surplus buffer.
    /// @param usr The USDS receiver.
    /// @param wad The USDS amount in wad precision (10 ** 18).
    function _transferUsds(address usr, uint256 wad) internal {
        // Note: Enforce whole units to avoid rounding errors
        require(wad % WAD == 0, "transferUsds/non-integer-wad");
        // Note: DssExecLib currently only supports Dai transfers from the surplus buffer.
        DssExecLib.sendPaymentFromSurplusBuffer(address(this), wad / WAD);
        // Note: Approve DAI_USDS for the amount sent to be able to convert it.
        DAI.approve(DAI_USDS, wad);
        // Note: Convert Dai to USDS for `usr`.
        DaiUsdsLike(DAI_USDS).daiToUsds(usr, wad);
    }

    /// @notice wraps the operations required to transfer SKY from the treasury.
    /// @param usr The SKY receiver.
    /// @param wad The SKY amount in wad precision (10 ** 18).
    function _transferSky(address usr, uint256 wad) internal {
        // Note: Enforce exact conversion to avoid rounding errors
        require(wad % MKR_SKY_RATE == 0, "transferSky/non-exact-conversion");
        // Note: Calculate the amount of MKR required
        uint256 mkrWad = wad / MKR_SKY_RATE;
        // Note: Approve MKR_SKY for the amount sent to be able to convert it
        MKR.approve(MKR_SKY, mkrWad);
        // Note: Convert the calculated amount to SKY for `usr`
        MkrSkyLike(MKR_SKY).mkrToSky(usr, mkrWad);
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) {}
}
