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

import {DssAutoLineAbstract} from "dss-interfaces/dss/DssAutoLineAbstract.sol";
import {GemAbstract} from "dss-interfaces/ERC/GemAbstract.sol";

interface ProxyLike {
    function exec(address target, bytes calldata args) external payable returns (bytes memory out);
}

interface PauseLike {
    function setDelay(uint256) external;
}

interface DaiUsdsLike {
    function daiToUsds(address usr, uint256 wad) external;
}

interface MkrSkyLike {
    function mkrToSky(address usr, uint256 wad) external;
    function rate() external view returns (uint256);
}

interface SUsdsLike {
    function file(bytes32, uint256) external;
    function drip() external returns (uint256);
}

interface LineMomLike {
    function addIlk(bytes32 ilk) external;
}

contract DssSpellAction is DssAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: cast keccak -- "$(wget 'https://raw.githubusercontent.com/makerdao/community/cab5eee66ed682ef2ab13848164ae2bfc6819fa8/governance/votes/Executive%20vote%20-%20November%2028%2C%202024.md' -q -O - 2>/dev/null)"
    string public constant override description = "2024-11-28 MakerDAO Executive Spell | Hash: 0xe09c4973bac96805d70c88a1ccb74038b30b438fba50e7f3a35b5f87968a7275";

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
    uint256 internal constant EIGHT_PT_FIVE_PCT_RATE        = 1000000002586884420913935572;
    uint256 internal constant NINE_PCT_RATE                 = 1000000002732676825177582095;
    uint256 internal constant NINE_PT_TWO_FIVE_PCT_RATE     = 1000000002805322428706865331;
    uint256 internal constant NINE_PT_THREE_ONE_PCT_RATE    = 1000000002822732637090604696;
    uint256 internal constant NINE_PT_FIVE_PCT_RATE         = 1000000002877801985002875644;
    uint256 internal constant NINE_PT_SEVEN_FIVE_PCT_RATE   = 1000000002950116251408586949;
    uint256 internal constant TEN_PCT_RATE                  = 1000000003022265980097387650;
    uint256 internal constant TEN_PT_TWO_FIVE_PCT_RATE      = 1000000003094251918120023627;
    uint256 internal constant TWELVE_PCT_RATE               = 1000000003593629043335673582;
    uint256 internal constant TWELVE_PT_TWO_FIVE_PCT_RATE   = 1000000003664330950215446102;
    uint256 internal constant TWELVE_PT_SEVEN_FIVE_PCT_RATE = 1000000003805263591546724039;

    // ---------- Math ----------
    uint256 internal constant THOUSAND = 10 ** 3;
    uint256 internal constant MILLION  = 10 ** 6;
    uint256 internal constant WAD      = 10 ** 18;

    // ---------- MCD Addresses ----------
    GemAbstract internal immutable MKR                 = GemAbstract(DssExecLib.mkr());
    GemAbstract internal immutable DAI                 = GemAbstract(DssExecLib.dai());
    address internal immutable AUTO_LINE               = DssExecLib.autoLine();
    address internal immutable DAI_USDS                = DssExecLib.getChangelogAddress("DAI_USDS");
    address internal immutable LINE_MOM                = DssExecLib.getChangelogAddress("LINE_MOM");
    address internal immutable MCD_ESM                 = DssExecLib.getChangelogAddress("MCD_ESM");
    address internal immutable MCD_PAUSE               = DssExecLib.getChangelogAddress("MCD_PAUSE");
    address internal immutable MKR_SKY                 = DssExecLib.getChangelogAddress("MKR_SKY");
    uint256 internal immutable MKR_SKY_RATE            = MkrSkyLike(DssExecLib.getChangelogAddress("MKR_SKY")).rate();
    address internal immutable SUSDS                   = DssExecLib.getChangelogAddress("SUSDS");
    address internal constant EMSP_CLIP_BREAKER_FAB    = 0xd7321d0919573a33f9147fD2579a48F60237564A;
    address internal constant EMSP_DDM_DISABLE_FAB     = 0x8BA0f6C4009Ea915706e1bCfB1d879E34587dC69;
    address internal constant EMSP_LINE_WIPE_FAB       = 0xA649730fA92695096b7C49DBae682995F8906684;
    address internal constant EMSP_OSM_STOP_FAB        = 0x83211c74131bA2B3de7538f588f1c2f309e81eF0;
    address internal constant EMSP_GLOBAL_CLIP_BREAKER = 0x828824dBC62Fba126C76E0Abe79AE28E5393C2cb;
    address internal constant EMSP_GLOBAL_LINE_WIPE    = 0x4B5f856B59448304585C2AA009802A16946DDb0f;
    address internal constant EMSP_GLOBAL_OSM_STOP     = 0x3021dEdB0bC677F43A23Fcd1dE91A07e5195BaE8;

    // ---------- Wallets ----------
    address internal constant BLUE                         = 0xb6C09680D822F162449cdFB8248a7D3FC26Ec9Bf;
    address internal constant BONAPUBLICA                  = 0x167c1a762B08D7e78dbF8f24e5C3f1Ab415021D3;
    address internal constant BYTERON                      = 0xc2982e72D060cab2387Dba96b846acb8c96EfF66;
    address internal constant CLOAKY                       = 0x869b6d5d8FA7f4FFdaCA4D23FFE0735c5eD1F818;
    address internal constant CLOAKY_ENNOIA                = 0xA7364a1738D0bB7D1911318Ca3FB3779A8A58D7b;
    address internal constant CLOAKY_KOHLA_2               = 0x73dFC091Ad77c03F2809204fCF03C0b9dccf8c7a;
    address internal constant INTEGRATION_BOOST_INITIATIVE = 0xD6891d1DFFDA6B0B1aF3524018a1eE2E608785F7;
    address internal constant JULIACHANG                   = 0x252abAEe2F4f4b8D39E5F12b163eDFb7fac7AED7;
    address internal constant LAUNCH_PROJECT_FUNDING       = 0x3C5142F28567E6a0F172fd0BaaF1f2847f49D02F;
    address internal constant LIQUIDITY_BOOTSTRAPPING      = 0xD8507ef0A59f37d15B5D7b630FA6EEa40CE4AFdD;
    address internal constant VIGILANT                     = 0x2474937cB55500601BCCE9f4cb0A0A72Dc226F61;

    // ---------- Spark Proxy Spell ----------
    // Spark Proxy: https://github.com/marsfoundation/sparklend-deployments/blob/bba4c57d54deb6a14490b897c12a949aa035a99b/script/output/1/primary-sce-latest.json#L2
    address internal constant SPARK_PROXY = 0x3300f198988e4C9C63F75dF86De36421f06af8c4;
    address internal constant SPARK_SPELL = 0x6c87D984689CeD0bB367A58722aC74013F82267d;

    function actions() public override {
        // ---------- DIRECT-SPK-AAVE-LIDO-USDS DDM line increase ----------
        // Forum: https://forum.sky.money/t/28-nov-2024-proposed-changes-to-spark-for-upcoming-spell/25543
        // Poll: https://vote.makerdao.com/polling/QmabCDcn

        // Increase DIRECT-SPK-AAVE-LIDO-USDS DDM line by 100 million, USDS from 100 million USDS to 200 million USDS
        DssExecLib.setIlkAutoLineDebtCeiling("DIRECT-SPK-AAVE-LIDO-USDS", 200 * MILLION);

        // ---------- ALLOCATOR-SPARK-A DC-IAM changes ----------
        // Forum: https://forum.sky.money/t/28-nov-2024-proposed-changes-to-spark-for-upcoming-spell-amendments/25575
        // Poll: https://vote.makerdao.com/polling/QmcNd4mH#poll-detail

        // Increase DC-IAM gap by 90 million USDS, from 10 million USDS to 100 million USDS
        // Increase DC-IAM line by 90 million USDS, from 10 million USDS to 100 million USDS
        // ttl: 86,400 seconds (unchanged)
        DssExecLib.setIlkAutoLineParameters("ALLOCATOR-SPARK-A", /* amount = */ 100 * MILLION, /* gap = */ 100 * MILLION, /* ttl = */ 24 hours);

        // ---------- Surplus Buffer Upper Limit increase ----------
        // Forum: https://forum.sky.money/t/weekly-atlas-edit-proposal-week-of-2024-11-18-0/25552
        // Poll: https://vote.makerdao.com/polling/QmZfYrR7

        // Increase the Surplus Buffer Upper Limit by 60 million DAI, from 60 million DAI to 120 million DAI
        DssExecLib.setSurplusBuffer(120 * MILLION);

        // ---------- Stability Fees Changes ----------
        // Forum: https://forum.sky.money/t/stability-scope-parameter-changes-18-sfs-dsr-ssr-spark-effective-dai-borrow-rate-spark-liquidity-layer/25593

        // Increase ETH-A Stability Fee by 1 percentage point from 8.25% to 9.25%
        DssExecLib.setIlkStabilityFee("ETH-A", NINE_PT_TWO_FIVE_PCT_RATE, /* doDrip = */ true);

        // Increase ETH-B Stability Fee by 1 percentage point from 8.75% to 9.75%
        DssExecLib.setIlkStabilityFee("ETH-B", NINE_PT_SEVEN_FIVE_PCT_RATE, /* doDrip = */ true);

        // Increase ETH-C Stability Fee by 1 percentage point from 8.00% to 9.00%
        DssExecLib.setIlkStabilityFee("ETH-C", NINE_PCT_RATE, /* doDrip = */ true);

        // Increase WSTETH-A Stability Fee by 1 percentage point from 9.25% to 10.25%
        DssExecLib.setIlkStabilityFee("WSTETH-A", TEN_PT_TWO_FIVE_PCT_RATE, /* doDrip = */ true);

        // Increase WSTETH-B Stability Fee by 1 percentage point from 9.00% to 10.00%
        DssExecLib.setIlkStabilityFee("WSTETH-B", TEN_PCT_RATE, /* doDrip = */ true);

        // Increase WBTC-A Stability Fee by 1 percentage point from 11.25% to 12.25%
        DssExecLib.setIlkStabilityFee("WBTC-A", TWELVE_PT_TWO_FIVE_PCT_RATE, /* doDrip = */ true);

        // Increase WBTC-B Stability Fee by 1 percentage point from 11.75% to 12.75%
        DssExecLib.setIlkStabilityFee("WBTC-B", TWELVE_PT_SEVEN_FIVE_PCT_RATE, /* doDrip = */ true);

        // Increase WBTC-C Stability Fee by 1 percentage point from 11.00% to 12.00%
        DssExecLib.setIlkStabilityFee("WBTC-C", TWELVE_PCT_RATE, /* doDrip = */ true);

        // Increase ALLOCATOR-SPARK-A Stability Fee by 4.11 percentage points from 5.2% to 9.31%
        DssExecLib.setIlkStabilityFee("ALLOCATOR-SPARK-A", NINE_PT_THREE_ONE_PCT_RATE, /* doDrip = */ true);

        // ---------- Savings Rate Changes ----------
        // Forum: https://forum.sky.money/t/stability-scope-parameter-changes-18-sfs-dsr-ssr-spark-effective-dai-borrow-rate-spark-liquidity-layer/25593

        // Increase DSR by 1 percentage point from 7.50% to 8.50%
        DssExecLib.setDSR(EIGHT_PT_FIVE_PCT_RATE, /* doDrip = */ true);

        // Increase SSR by 1 percentage point from 8.50% to 9.50%
        SUsdsLike(SUSDS).drip();
        SUsdsLike(SUSDS).file("ssr", NINE_PT_FIVE_PCT_RATE);

        // ---------- GSM Delay increase ----------
        // Forum: https://forum.sky.money/t/november-28th-spell-parameter-proposal-esm-threshold-gsm-delay-increase/25579

        // Increase GSM Delay by 14 hours, from 16 hours to 30 hours
        PauseLike(MCD_PAUSE).setDelay(30 hours);

        // ---------- Add ilks to the LineMom ----------
        // Forum: https://forum.sky.money/t/standby-spells-for-sky-emergency-response/25594/2

        // Add ALLOCATOR-SPARK-A to the LineMom
        LineMomLike(LINE_MOM).addIlk("ALLOCATOR-SPARK-A");

        // Add RWA001-A to the LineMom
        LineMomLike(LINE_MOM).addIlk("RWA001-A");

        // Add RWA002-A to the LineMom
        LineMomLike(LINE_MOM).addIlk("RWA002-A");

        // Add RWA009-A to the LineMom
        LineMomLike(LINE_MOM).addIlk("RWA009-A");

        // Add RWA012-A to the LineMom
        LineMomLike(LINE_MOM).addIlk("RWA012-A");

        // Add RWA013-A to the LineMom
        LineMomLike(LINE_MOM).addIlk("RWA013-A");

        // Add RWA015-A to the LineMom
        LineMomLike(LINE_MOM).addIlk("RWA015-A");

        // ---------- Add emergency spells to the chainlog ----------
        // Forum: https://forum.sky.money/t/standby-spells-for-sky-emergency-response/25594
        // Poll: https://vote.makerdao.com/polling/QmRfTQ5t

        // Contract: SingleClipBreakerFactory - Key: EMSP_CLIP_BREAKER_FAB - Value: 0xd7321d0919573a33f9147fD2579a48F60237564A
        DssExecLib.setChangelogAddress("EMSP_CLIP_BREAKER_FAB", EMSP_CLIP_BREAKER_FAB);

        // Contract: SingleDdmDisableFactory - Key: EMSP_DDM_DISABLE_FAB - Value: 0x8BA0f6C4009Ea915706e1bCfB1d879E34587dC69
        DssExecLib.setChangelogAddress("EMSP_DDM_DISABLE_FAB", EMSP_DDM_DISABLE_FAB);

        // Contract: SingleLineWipeFactory - Key: EMSP_LINE_WIPE_FAB - Value: 0xA649730fA92695096b7C49DBae682995F8906684
        DssExecLib.setChangelogAddress("EMSP_LINE_WIPE_FAB", EMSP_LINE_WIPE_FAB);

        // Contract: SingleOsmStopFactory - Key: EMSP_OSM_STOP_FAB - Value: 0x83211c74131bA2B3de7538f588f1c2f309e81eF0
        DssExecLib.setChangelogAddress("EMSP_OSM_STOP_FAB", EMSP_OSM_STOP_FAB);

        // Contract: MultiClipBreakerSpell - Key: EMSP_GLOBAL_CLIP_BREAKER - Value: 0x828824dBC62Fba126C76E0Abe79AE28E5393C2cb
        DssExecLib.setChangelogAddress("EMSP_GLOBAL_CLIP_BREAKER", EMSP_GLOBAL_CLIP_BREAKER);

        // Contract: MultiLineWipeSpell - Key: EMSP_GLOBAL_LINE_WIPE - Value: 0x4B5f856B59448304585C2AA009802A16946DDb0f
        DssExecLib.setChangelogAddress("EMSP_GLOBAL_LINE_WIPE", EMSP_GLOBAL_LINE_WIPE);

        // Contract: MultiOsmStopSpell - Key: EMSP_GLOBAL_OSM_STOP - Value: 0x3021dEdB0bC677F43A23Fcd1dE91A07e5195BaE8
        DssExecLib.setChangelogAddress("EMSP_GLOBAL_OSM_STOP", EMSP_GLOBAL_OSM_STOP);

        // Note: Bump chainlog patch version as new keys are being added
        DssExecLib.setChangelogVersion("1.19.4");

        // ---------- Launch Project Funding ----------
        // Forum: https://forum.sky.money/t/utilization-of-the-launch-project-under-the-accessibility-scope/21468/26
        // Atlas: https://sky-atlas.powerhouse.io/A.5.6_Launch_Project/1f433d9d-7cdb-406f-b7e8-f9bc4855eb77%7C8d5a

        // Transfer 10,000,000 USDS to 0x3C5142F28567E6a0F172fd0BaaF1f2847f49D02F
        _transferUsds(LAUNCH_PROJECT_FUNDING, 10 * MILLION * WAD);

        // Transfer 24,000,000 SKY to 0x3C5142F28567E6a0F172fd0BaaF1f2847f49D02F
        _transferSky(LAUNCH_PROJECT_FUNDING, 24 * MILLION * WAD);

        // ---------- Sky Ecosystem Liquidity Bootstrapping Funding ----------
        // Forum: https://forum.sky.money/t/utilization-of-the-sky-ecosystem-liquidity-bootstrapping-budget-a-5-6-1-9/25537/2
        // Poll: https://vote.makerdao.com/polling/QmYHUDVA

        // Transfer 6,000,000 USDS to 0xD8507ef0A59f37d15B5D7b630FA6EEa40CE4AFdD
        _transferUsds(LIQUIDITY_BOOTSTRAPPING, 6 * MILLION * WAD);

        // ---------- Integration Boost Funding ----------
        // Forum: https://forum.sky.money/t/utilization-of-the-integration-boost-budget-a-5-2-1-2/25536/2
        // Poll: https://vote.makerdao.com/polling/QmYHUDVA

        // Transfer 3,000,000 USDS to 0xD6891d1DFFDA6B0B1aF3524018a1eE2E608785F7
        _transferUsds(INTEGRATION_BOOST_INITIATIVE, 3 * MILLION * WAD);

        // ---------- ESM Minimum Threshold increase ----------
        // Forum: https://forum.sky.money/t/november-28th-spell-parameter-proposal-esm-threshold-gsm-delay-increase/25579

        // Increase ESM Minimum Threshold by 200,000 MKR, from 300,000 MKR to 500,000 MKR
        DssExecLib.setValue(MCD_ESM, "min", 500 * THOUSAND * WAD);

        // ---------- October 2024 AD Compensation ----------
        // Forum: https://forum.sky.money/t/october-2024-aligned-delegate-compensation/25581
        // Atlas: https://sky-atlas.powerhouse.io/A.1.5.8_Budget_For_Prime_Delegate_Slots/e3e420fc-9b1f-4fdc-9983-fcebc45dd3aa%7C0db3af4ece0c

        // BLUE - 2,968 USDS - 0xb6C09680D822F162449cdFB8248a7D3FC26Ec9Bf
        _transferUsds(BLUE,        2_968 * WAD);

        // Bonapublica - 4,000 USDS  - 0x167c1a762B08D7e78dbF8f24e5C3f1Ab415021D3
        _transferUsds(BONAPUBLICA, 4_000 * WAD);

        // Byteron - 1,733 USDS  - 0xc2982e72D060cab2387Dba96b846acb8c96EfF66
        _transferUsds(BYTERON,     1_733 * WAD);

        // Cloaky - 4,000 USDS  - 0x869b6d5d8FA7f4FFdaCA4D23FFE0735c5eD1F818
        _transferUsds(CLOAKY,      4_000 * WAD);

        // JuliaChang - 4,000 USDS  - 0x252abAEe2F4f4b8D39E5F12b163eDFb7fac7AED7
        _transferUsds(JULIACHANG,  4_000 * WAD);

        // vigilant - 4,000 USDS  - 0x2474937cB55500601BCCE9f4cb0A0A72Dc226F61
        _transferUsds(VIGILANT,    4_000 * WAD);

        // ---------- Atlas Core Development Payments ----------
        // Forum: https://forum.sky.money/t/atlas-core-development-payment-requests-november-2024/25580
        // Atlas: https://forum.sky.money/t/atlas-core-development-payment-requests-november-2024/25580/8

        // Kohla (Cloaky) - 20,000 USDS - 0x73dFC091Ad77c03F2809204fCF03C0b9dccf8c7a
        _transferUsds(CLOAKY_KOHLA_2,  20_000 * WAD);

        // Ennoia (Cloaky) - 20,110 USDS - 0xA7364a1738D0bB7D1911318Ca3FB3779A8A58D7b
        _transferUsds(CLOAKY_ENNOIA,   20_110 * WAD);

        // BLUE - 50,167 USDS - 0xb6C09680D822F162449cdFB8248a7D3FC26Ec9Bf
        _transferUsds(BLUE,            50_167 * WAD);

        // BLUE - 330,000 SKY - 0xb6C09680D822F162449cdFB8248a7D3FC26Ec9Bf
        _transferSky( BLUE,           330_000 * WAD);

        // ---------- Spark Proxy Spell ----------
        // Forum: https://forum.sky.money/t/stability-scope-parameter-changes-18-sfs-dsr-ssr-spark-effective-dai-borrow-rate-spark-liquidity-layer/25593
        // Forum: https://forum.sky.money/t/28-nov-2024-proposed-changes-to-spark-for-upcoming-spell/25543
        // Poll: https://vote.makerdao.com/polling/QmSxJJ6Z
        // Poll: https://vote.makerdao.com/polling/QmaxFZfF
        // Poll: https://vote.makerdao.com/polling/QmWUkstV
        // Poll: https://vote.makerdao.com/polling/QmQ2Umfm
        // Poll: https://vote.makerdao.com/polling/QmcNd4mH

        // Note: The spark spell below expects the new auto-line settings to be effective.
        DssAutoLineAbstract(AUTO_LINE).exec("ALLOCATOR-SPARK-A");

        // Execute Spark Proxy Spell at 0x6c87D984689CeD0bB367A58722aC74013F82267d
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
