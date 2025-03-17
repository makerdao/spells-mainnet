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
import { OsmAbstract } from "dss-interfaces/dss/OsmAbstract.sol";
import { GemAbstract } from "dss-interfaces/ERC/GemAbstract.sol";

interface SUsdsLike {
    function drip() external returns (uint256);
    function file(bytes32 what, uint256 data) external;
}

interface DaiUsdsLike {
    function daiToUsds(address usr, uint256 wad) external;
}

interface MkrSkyLike {
    function mkrToSky(address usr, uint256 wad) external;
    function rate() external view returns (uint256);
}

interface StakingRewardsLike {
    function setRewardsDuration(uint256) external;
}

contract DssSpellAction is DssAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: cast keccak -- "$(wget 'TODO' -q -O - 2>/dev/null)"
    string public constant override description = "2025-03-20 MakerDAO Executive Spell | Hash: TODO";

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
    uint256 internal constant TWO_PT_SIX_TWO_PCT_RATE     = 1000000000820099554044024241;
    uint256 internal constant THREE_PT_FIVE_PCT_RATE      = 1000000001090862085746321732;
    uint256 internal constant FOUR_PT_FIVE_PCT_RATE       = 1000000001395766281313196627;
    uint256 internal constant FIVE_PT_SEVEN_FIVE_PCT_RATE = 1000000001772819380639683201;
    uint256 internal constant SIX_PCT_RATE                = 1000000001847694957439350562;
    uint256 internal constant SIX_PT_FIVE_PCT_RATE        = 1000000001996917783620820123;
    uint256 internal constant SIX_PT_SEVEN_FIVE_PCT_RATE  = 1000000002071266685321207000;
    uint256 internal constant SEVEN_PCT_RATE              = 1000000002145441671308778766;
    uint256 internal constant TEN_PT_SEVEN_FIVE_PCT_RATE  = 1000000003237735385034516037;
    uint256 internal constant ELEVEN_PCT_RATE             = 1000000003309234382829738808;
    uint256 internal constant ELEVEN_PT_FIVE_PCT_RATE     = 1000000003451750542235895695;

    // ---------- Math ----------
    uint256 internal constant WAD = 10 ** 18;

    // ---------- Contracts ----------
    GemAbstract internal immutable DAI                = GemAbstract(DssExecLib.dai());
    GemAbstract internal immutable MKR                = GemAbstract(DssExecLib.mkr());
    GemAbstract internal immutable SKY                = GemAbstract(DssExecLib.getChangelogAddress("SKY"));
    address internal immutable     PIP_ETH            = DssExecLib.getChangelogAddress("PIP_ETH");
    address internal immutable     PIP_WSTETH         = DssExecLib.getChangelogAddress("PIP_WSTETH");
    address internal immutable     SUSDS              = DssExecLib.getChangelogAddress("SUSDS");
    address internal immutable     MCD_SPLIT          = DssExecLib.getChangelogAddress("MCD_SPLIT");
    address internal immutable     REWARDS_LSMKR_USDS = DssExecLib.getChangelogAddress("REWARDS_LSMKR_USDS");
    address internal immutable     DAI_USDS           = DssExecLib.getChangelogAddress("DAI_USDS");
    address internal immutable     MKR_SKY            = DssExecLib.getChangelogAddress("MKR_SKY");

    // ---------- Wallets ----------
    address internal constant BLUE                            = 0xb6C09680D822F162449cdFB8248a7D3FC26Ec9Bf;
    address internal constant BONAPUBLICA                     = 0x167c1a762B08D7e78dbF8f24e5C3f1Ab415021D3;
    address internal constant BYTERON                         = 0xc2982e72D060cab2387Dba96b846acb8c96EfF66;
    address internal constant CLOAKY_2                        = 0x9244F47D70587Fa2329B89B6f503022b63Ad54A5;
    address internal constant CLOAKY_KOHLA_2                  = 0x73dFC091Ad77c03F2809204fCF03C0b9dccf8c7a;
    address internal constant CLOAKY_ENNOIA                   = 0xA7364a1738D0bB7D1911318Ca3FB3779A8A58D7b;
    address internal constant INTEGRATION_BOOST_INITIATIVE    = 0xD6891d1DFFDA6B0B1aF3524018a1eE2E608785F7;
    address internal constant IMMUNEFI_COMISSION              = 0x7119f398b6C06095c6E8964C1f58e7C1BAa79E18;
    address internal constant IMMUNEFI_USER_PAYOUT_2025_03_20 = 0x29d17B5AcB1C68C574712B11F36C859F6FbdBe32;
    address internal constant JULIACHANG                      = 0x252abAEe2F4f4b8D39E5F12b163eDFb7fac7AED7;
    address internal constant WBC                             = 0xeBcE83e491947aDB1396Ee7E55d3c81414fB0D47;
    address internal constant PBG                             = 0x8D4df847dB7FfE0B46AF084fE031F7691C6478c2;

    // ---------- Constant Values ----------
    uint256 internal immutable MKR_SKY_RATE = MkrSkyLike(DssExecLib.getChangelogAddress("MKR_SKY")).rate();

    function actions() public override {
        // ---------- ETH and WSTETH Oracle Migration ----------
        // Forum: https://forum.sky.money/t/march-20-2025-final-native-vault-engine-oracle-migration-proposal-eth-steth/26110?u=votewizard
        // Forum: https://forum.sky.money/t/technical-scope-of-the-eth-and-wsteth-oracles-migration/26128
        // Forum: https://forum.sky.money/t/march-20-2025-final-native-vault-engine-oracle-migration-proposal-eth-steth/26110/2

        // Change ETH OSM source to 0x46ef0071b1E2fF6B42d36e5A177EA43Ae5917f4E
        OsmAbstract(PIP_ETH).change(0x46ef0071b1E2fF6B42d36e5A177EA43Ae5917f4E);

        // Change WSTETH OSM source to 0xA770582353b573CbfdCC948751750EeB3Ccf23CF
        OsmAbstract(PIP_WSTETH).change(0xA770582353b573CbfdCC948751750EeB3Ccf23CF);

        // ---------- Rates Changes  ----------
        // Forum: https://forum.sky.money/t/mar-20-2025-stability-scope-parameter-changes-24/26129
        // Forum: https://forum.sky.money/t/mar-20-2025-stability-scope-parameter-changes-24/26129/2

        // Reduce ETH-A Stability Fee by 1.75 percentage points from 7.75% to 6.00%
        DssExecLib.setIlkStabilityFee("ETH-A", SIX_PCT_RATE, /* doDrip = */ true);

        // Reduce ETH-B Stability Fee by 1.75 percentage points from 8.25% to 6.50%
        DssExecLib.setIlkStabilityFee("ETH-B", SIX_PT_FIVE_PCT_RATE, /* doDrip = */ true);

        // Reduce ETH-C Stability Fee by 1.75 percentage points from 7.50% to 5.75%
        DssExecLib.setIlkStabilityFee("ETH-C", FIVE_PT_SEVEN_FIVE_PCT_RATE, /* doDrip = */ true);

        // Reduce WSTETH-A Stability Fee by 1.75 percentage points from 8.75% to 7.00%
        DssExecLib.setIlkStabilityFee("WSTETH-A", SEVEN_PCT_RATE, /* doDrip = */ true);

        // Reduce WSTETH-B Stability Fee by 1.75 percentage points from 8.50% to 6.75%
        DssExecLib.setIlkStabilityFee("WSTETH-B", SIX_PT_SEVEN_FIVE_PCT_RATE, /* doDrip = */ true);

        // Reduce WBTC-A Stability Fee by 1.75 percentage points from 12.75% to 11.00%
        DssExecLib.setIlkStabilityFee("WBTC-A", ELEVEN_PCT_RATE, /* doDrip = */ true);

        // Reduce WBTC-B Stability Fee by 1.75 percentage points from 13.25% to 11.50%
        DssExecLib.setIlkStabilityFee("WBTC-B", ELEVEN_PT_FIVE_PCT_RATE, /* doDrip = */ true);

        // Reduce WBTC-C Stability Fee by 1.75 percentage points from 12.50% to 10.75%
        DssExecLib.setIlkStabilityFee("WBTC-C", TEN_PT_SEVEN_FIVE_PCT_RATE, /* doDrip = */ true);

        // Reduce ALLOCATOR-SPARK-A Stability Fee by 1.12 percentage points from 3.74% to 2.62%
        DssExecLib.setIlkStabilityFee("ALLOCATOR-SPARK-A", TWO_PT_SIX_TWO_PCT_RATE, /* doDrip = */ true);

        // Reduce DSR by 2.00 percentage points from 5.50% to 3.50%
        DssExecLib.setDSR(THREE_PT_FIVE_PCT_RATE, /* doDrip = */ true);

        // Reduce SSR by 2.00 percentage points from 6.50% to 4.50%
        SUsdsLike(SUSDS).drip();
        SUsdsLike(SUSDS).file("ssr", FOUR_PT_FIVE_PCT_RATE);

        // ---------- Smart Burn Engine Parameter Update ----------
        // Forum: https://forum.sky.money/t/smart-burn-engine-parameter-update-march-20-spell/26130
        // Forum: https://forum.sky.money/t/smart-burn-engine-parameter-update-march-20-spell/26130/3

        // Splitter: decrease hop for 432 seconds, from 2,160 seconds to 1,728 seconds
        DssExecLib.setValue(MCD_SPLIT, "hop", 1728);

        // Note: Update farm rewards duration
        StakingRewardsLike(REWARDS_LSMKR_USDS).setRewardsDuration(1728);

        // ---------- Bug Bounty Payout ----------
        // Forum: https://forum.sky.money/t/bounty-payout-request-for-immunefi-bug-38567/26072
        // Atlas: https://sky-atlas.powerhouse.io/A.2.9.1.1_Bug_Bounty_Program_For_Critical_Infrastructure/7d58645d-713c-4c54-a2ee-e0c948fb0c25%7C9e1f4492c8ce

        // Transfer 50,000 USDS to bug reporter at 0x29d17B5AcB1C68C574712B11F36C859F6FbdBe32
        _transferUsds(IMMUNEFI_USER_PAYOUT_2025_03_20, 50_000 * WAD);

        // Transfer 5,000 USDS to Immunefi at 0x7119f398b6C06095c6E8964C1f58e7C1BAa79E18
        _transferUsds(IMMUNEFI_COMISSION, 5_000 * WAD);

        // ---------- AD February 2025 Compensation ----------
        // Forum: https://forum.sky.money/t/february-2025-aligned-delegate-compensation/26131
        // Atlas: https://sky-atlas.powerhouse.io/A.1.5.8_Budget_For_Prime_Delegate_Slots/e3e420fc-9b1f-4fdc-9983-fcebc45dd3aa%7C0db3af4ece0c

        // BLUE - 4,000 USDS - 0xb6C09680D822F162449cdFB8248a7D3FC26Ec9Bf
        _transferUsds(BLUE, 4_000 * WAD);

        // Bonapublica - 4,000 USDS - 0x167c1a762B08D7e78dbF8f24e5C3f1Ab415021D3
        _transferUsds(BONAPUBLICA, 4_000 * WAD);

        // Cloaky - 4,000 USDS - 0x9244F47D70587Fa2329B89B6f503022b63Ad54A5
        _transferUsds(CLOAKY_2, 4_000 * WAD);

        // JuliaChang - 4,000 USDS - 0x252abAEe2F4f4b8D39E5F12b163eDFb7fac7AED7
        _transferUsds(JULIACHANG, 4_000 * WAD);

        // WBC - 3,613 USDS - 0xeBcE83e491947aDB1396Ee7E55d3c81414fB0D47
        _transferUsds(WBC, 3_613 * WAD);

        // PBG - 3,429 USDS - 0x8D4df847dB7FfE0B46AF084fE031F7691C6478c2
        _transferUsds(PBG, 3_429 * WAD);

        // Byteron - 571 USDS - 0xc2982e72D060cab2387Dba96b846acb8c96EfF66
        _transferUsds(BYTERON, 571 * WAD);

        // ---------- Atlas Core Development March 2025 USDS Payments ----------
        // Forum: https://forum.sky.money/t/atlas-core-development-payment-requests-march-2025/26077
        // Forum: https://forum.sky.money/t/atlas-core-development-payment-requests-february-2025/25921/6

        // BLUE - 50,167 USDS - 0xb6C09680D822F162449cdFB8248a7D3FC26Ec9Bf
        _transferUsds(BLUE, 50_167 * WAD);

        // Cloaky - 16,417 USDS - 0x9244F47D70587Fa2329B89B6f503022b63Ad54A5
        _transferUsds(CLOAKY_2, 16_417 * WAD);

        // Kohla - 10,000 USDS - 0x73dFC091Ad77c03F2809204fCF03C0b9dccf8c7a
        _transferUsds(CLOAKY_KOHLA_2, 10_000 * WAD);

        // Ennoia - 10,055 USDS - 0xA7364a1738D0bB7D1911318Ca3FB3779A8A58D7b
        _transferUsds(CLOAKY_ENNOIA, 10_055 * WAD);

        // ---------- Atlas Core Development March 2025 SKY Payments ----------
        // Forum: https://forum.sky.money/t/atlas-core-development-payment-requests-march-2025/26077
        // Forum: https://forum.sky.money/t/atlas-core-development-payment-requests-february-2025/25921/6

        // BLUE - 330,000 SKY - 0xb6C09680D822F162449cdFB8248a7D3FC26Ec9Bf
        _transferSky(BLUE, 330_000 * WAD);

        // Cloaky - 288,000 SKY - 0x9244F47D70587Fa2329B89B6f503022b63Ad54A5
        _transferSky(CLOAKY_2, 288_000 * WAD);

        // ---------- Top-up of the Integration Boost ----------
        // Forum: https://forum.sky.money/t/utilization-of-the-integration-boost-budget-a-5-2-1-2/25536/8
        // Atlas: https://sky-atlas.powerhouse.io/A.5.2.1.2_Integration_Boost/129f2ff0-8d73-8057-850b-d32304e9c91a%7C8d5a9e88cf49

        // Integration Boost - 3,000,000 USDS - 0xD6891d1DFFDA6B0B1aF3524018a1eE2E608785F7
        _transferUsds(INTEGRATION_BOOST_INITIATIVE, 3_000_000 * WAD);

        // ---------- Trigger Spark Proxy Spell ----------

        // TODO Wait for the content
        // Execute Spark Spell at TBC
    }

    // ---------- Helper Functions ----------

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
        // Note: Calculate the equivalent amount of MKR required
        uint256 mkrWad = wad / MKR_SKY_RATE;
        // Note: if rounding error is expected, add an extra wei of MKR
        if (wad % MKR_SKY_RATE != 0) { mkrWad++; }
        // Note: Approve MKR_SKY for the amount sent to be able to convert it
        MKR.approve(MKR_SKY, mkrWad);
        // Note: Convert the calculated amount to SKY for `PAUSE_PROXY`
        MkrSkyLike(MKR_SKY).mkrToSky(address(this), mkrWad);
        // Note: Transfer originally requested amount, leaving extra on the `PAUSE_PROXY`
        GemAbstract(SKY).transfer(usr, wad);
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) {}
}
