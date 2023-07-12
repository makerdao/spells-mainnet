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
import { MCD, DssInstance } from "dss-test/MCD.sol";
import { FlapperInit, FlapperInstance, FlapperUniV2Config } from "src/dependencies/dss-flappers/FlapperInit.sol";

interface DssCronSequencerLike {
    function addJob(address) external;
}

interface RwaOutputConduitLike {
    function deny(address usr) external;
    function hope(address usr) external;
    function nope(address usr) external;
    function mate(address usr) external;
    function hate(address usr) external;
    function kiss(address who) external;
    function diss(address who) external;
    function file(bytes32 what, address data) external;
    function clap(address _psm) external;
}

interface RwaUrnLike {
    function file(bytes32 what, address data) external;
}

interface ChainlogLike {
    function removeAddress(bytes32 _key) external;
}

interface VestLike {
    function file(bytes32 what, uint256 data) external;
    function create(address, uint256, uint256, uint256, uint256, address) external returns (uint256);
    function restrict(uint256) external;
    function yank(uint256) external;
}

interface GemLike {
    function transfer(address, uint256) external returns (bool);
    function approve(address, uint256) external returns (bool);
    function allowance(address, address) external view returns (uint256);
}

interface ProxyLike {
    function exec(address target, bytes calldata args) external payable returns (bytes memory out);
}

contract DssSpellAction is DssAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
        // Hash: cast keccak -- "$(wget 'https://raw.githubusercontent.com/makerdao/community/cb7a1b7e3c5d60f2189d6900c010f2cdb46803c0/governance/votes/Executive%20vote%20-%20July%2012%2C%202023.md' -q -O - 2>/dev/null)"
    string public constant override description =
        "2023-07-12 MakerDAO Executive Spell | Hash: 0x783c40f81b310f4511604064995ea1b279178c10a0e72aff010e6861efc961a3";

    // Set office hours according to the summary
    function officeHours() public pure override returns (bool) {
        return true;
    }

    uint256 internal constant THOUSAND                      = 10 **  3;
    uint256 internal constant MILLION                       = 10 **  6;
    uint256 internal constant WAD                           = 10 ** 18;
    uint256 internal constant RAD                           = 10 ** 45;

    // New RWA015 output conduit
    address internal constant RWA015_A_OPERATOR             = 0x23a10f09Fac6CCDbfb6d9f0215C795F9591D7476;
    address internal constant RWA015_A_CUSTODY              = 0x65729807485F6f7695AF863d97D62140B7d69d83;
    address internal constant RWA015_A_OUTPUT_CONDUIT       = 0x1E86CB085f249772f7e7443631a87c6BDba2aCEb;
    address internal immutable RWA015_A_OUTPUT_CONDUIT_USDC = DssExecLib.getChangelogAddress("RWA015_A_OUTPUT_CONDUIT_LEGACY");
    address internal immutable RWA015_A_URN                 = DssExecLib.getChangelogAddress("RWA015_A_URN");
    address internal immutable RWA015_A_OUTPUT_CONDUIT_PAX  = DssExecLib.getChangelogAddress("RWA015_A_OUTPUT_CONDUIT");
    address internal immutable MCD_PSM_PAX_A                = DssExecLib.getChangelogAddress("MCD_PSM_PAX_A");
    address internal immutable MCD_PSM_GUSD_A               = DssExecLib.getChangelogAddress("MCD_PSM_GUSD_A");
    address internal immutable MCD_PSM_USDC_A               = DssExecLib.getChangelogAddress("MCD_PSM_USDC_A");
    address internal immutable MCD_ESM                      = DssExecLib.esm();

    // Spark
    address internal constant SUBPROXY_SPARK                = 0x3300f198988e4C9C63F75dF86De36421f06af8c4;
    address internal constant SPARK_SPELL                   = 0x843A0539Ca7466Abcb769f1c1d30C8423e13A297;

    // CRON jobs
    address internal constant CRON_SEQUENCER                = 0x238b4E35dAed6100C6162fAE4510261f88996EC9;
    address internal constant CRON_AUTOLINE_JOB             = 0x67AD4000e73579B9725eE3A149F85C4Af0A61361;
    address internal constant CRON_LERP_JOB                 = 0x8F8f2FC1F0380B9Ff4fE5c3142d0811aC89E32fB;
    address internal constant CRON_D3M_JOB                  = 0x1Bb799509b0B039345f910dfFb71eEfAc7022323;
    address internal constant CRON_CLIPPER_MOM_JOB          = 0xc3A76B34CFBdA7A3a5215629a0B937CBDEC7C71a;
    address internal constant CRON_ORACLE_JOB               = 0xe717Ec34b2707fc8c226b34be5eae8482d06ED03;
    address internal constant CRON_FLAP_JOB                 = 0xc32506E9bB590971671b649d9B8e18CB6260559F;

    // New flapper
    address internal constant MCD_FLAP                      = 0x0c10Ae443cCB4604435Ba63DA80CCc63311615Bc;
    address internal constant FLAPPER_MOM                   = 0xee2058A11612587Ef6F5470e7776ceB0E4736078;
    address internal constant PIP_MKR                       = 0xdbBe5e9B1dAa91430cF0772fCEbe53F6c6f137DF;

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

    uint256 internal constant THREE_PT_ONE_NINE_PCT_RATE  = 1000000000995743377573746041;
    uint256 internal constant THREE_PT_FOUR_FOUR_PCT_RATE = 1000000001072474267302354182;
    uint256 internal constant THREE_PT_NINE_FOUR_PCT_RATE = 1000000001225381266358479708;
    uint256 internal constant FIVE_PT_SIX_NINE_PCT_RATE   = 1000000001754822903403114680;
    uint256 internal constant SIX_PT_ONE_NINE_PCT_RATE    = 1000000001904482384730282575;
    uint256 internal constant FIVE_PT_FOUR_FOUR_PCT_RATE  = 1000000001679727448331902751;

    // 2023-06-26 00:00:00 UTC
    uint256 internal constant JUN_26_2023                 = 1687737600;
    // 2023-07-01 00:00:00 UTC
    uint256 internal constant JUL_01_2023                 = 1688169600;
    // 2024-06-30 23:59:59 UTC
    uint256 internal constant JUN_30_2024                 = 1719791999;
    // 2024-12-31 23:59:59 UTC
    uint256 internal constant DEC_31_2024                 = 1735689599;

    // Delegates
    address internal constant DEFENSOR                    = 0x9542b441d65B6BF4dDdd3d4D2a66D8dCB9EE07a9;
    address internal constant BONAPUBLICA                 = 0x167c1a762B08D7e78dbF8f24e5C3f1Ab415021D3;
    address internal constant QGOV                        = 0xB0524D8707F76c681901b782372EbeD2d4bA28a6;
    address internal constant TRUENAME                    = 0x612F7924c367575a0Edf21333D96b15F1B345A5d;
    address internal constant UPMAKER                     = 0xbB819DF169670DC71A16F58F55956FE642cc6BcD;
    address internal constant VIGILANT                    = 0x2474937cB55500601BCCE9f4cb0A0A72Dc226F61;
    address internal constant WBC                         = 0xeBcE83e491947aDB1396Ee7E55d3c81414fB0D47;
    address internal constant PBG                         = 0x8D4df847dB7FfE0B46AF084fE031F7691C6478c2;
    address internal constant BANDHAR                     = 0xE83B6a503A94a5b764CCF00667689B3a522ABc21;
    address internal constant LIBERTAS                    = 0xE1eBfFa01883EF2b4A9f59b587fFf1a5B44dbb2f;
    address internal constant PALC                        = 0x78Deac4F87BD8007b9cb56B8d53889ed5374e83A;
    address internal constant HARMONY                     = 0xF4704Aa4Ad22cAA2A3Dd7A7C529B4C32f7A421F2;
    address internal constant VOTEWIZARD                  = 0x9E72629dF4fcaA2c2F5813FbbDc55064345431b1;
    address internal constant NAVIGATOR                   = 0x11406a9CC2e37425F15f920F494A51133ac93072;

    // Ecosystem actors
    address internal constant DECO_WALLET                 = 0xF482D1031E5b172D42B2DAA1b6e5Cbf6519596f7;
    address internal constant DUX_WALLET                  = 0x5A994D8428CCEbCC153863CCdA9D2Be6352f89ad;
    address internal constant CHRONICLE_LABS              = 0x68D0ca2d5Ac777F6A9b0d1be44332BB3d5981C2f;
    address internal constant JETSTREAM                   = 0xF478A08C41ad06E8D957d5e6B6Bcde7452cEE962;

    GemLike internal immutable MKR                        = GemLike(DssExecLib.mkr());
    VestLike internal immutable MCD_VEST_DAI              = VestLike(DssExecLib.getChangelogAddress("MCD_VEST_DAI"));
    VestLike internal immutable MCD_VEST_MKR_TREASURY     = VestLike(DssExecLib.getChangelogAddress("MCD_VEST_MKR_TREASURY"));

    function actions() public override {
        // ----- Deploy Multiswap Conduit for RWA015-A -----
        // Forum: http://forum.makerdao.com/t/rwa015-project-andromeda-technical-assessment/20974/11

        // OPERATOR permission on RWA015_A_OUTPUT_CONDUIT
        RwaOutputConduitLike(RWA015_A_OUTPUT_CONDUIT).hope(RWA015_A_OPERATOR);
        RwaOutputConduitLike(RWA015_A_OUTPUT_CONDUIT).mate(RWA015_A_OPERATOR);
        // Whitelist custody for output conduit destination address
        RwaOutputConduitLike(RWA015_A_OUTPUT_CONDUIT).kiss(RWA015_A_CUSTODY);
        // Whitelist PSM's
        RwaOutputConduitLike(RWA015_A_OUTPUT_CONDUIT).clap(MCD_PSM_PAX_A);
        RwaOutputConduitLike(RWA015_A_OUTPUT_CONDUIT).clap(MCD_PSM_GUSD_A);
        RwaOutputConduitLike(RWA015_A_OUTPUT_CONDUIT).clap(MCD_PSM_USDC_A);
        // Set "quitTo" address for RWA015_A_OUTPUT_CONDUIT
        RwaOutputConduitLike(RWA015_A_OUTPUT_CONDUIT).file("quitTo", RWA015_A_URN);
        // Route URN to new conduit
        RwaUrnLike(RWA015_A_URN).file("outputConduit", RWA015_A_OUTPUT_CONDUIT);
        // Authorize ESM
        DssExecLib.authorize(RWA015_A_OUTPUT_CONDUIT, MCD_ESM);
        // Update ChainLog address
        DssExecLib.setChangelogAddress("RWA015_A_OUTPUT_CONDUIT", RWA015_A_OUTPUT_CONDUIT);

        // Revoke permissions on the old RWA015_A_OUTPUT_CONDUIT_PAX
        RwaOutputConduitLike(RWA015_A_OUTPUT_CONDUIT_PAX).nope(RWA015_A_OPERATOR);
        RwaOutputConduitLike(RWA015_A_OUTPUT_CONDUIT_PAX).hate(RWA015_A_OPERATOR);
        RwaOutputConduitLike(RWA015_A_OUTPUT_CONDUIT_PAX).diss(RWA015_A_CUSTODY);
        RwaOutputConduitLike(RWA015_A_OUTPUT_CONDUIT_PAX).file("quitTo", address(0));
        RwaOutputConduitLike(RWA015_A_OUTPUT_CONDUIT_PAX).deny(MCD_ESM);
        RwaOutputConduitLike(RWA015_A_OUTPUT_CONDUIT_PAX).deny(address(this));

        // Revoke permissions on the old RWA015_A_OUTPUT_CONDUIT_USDC
        RwaOutputConduitLike(RWA015_A_OUTPUT_CONDUIT_USDC).nope(RWA015_A_OPERATOR);
        RwaOutputConduitLike(RWA015_A_OUTPUT_CONDUIT_USDC).hate(RWA015_A_OPERATOR);
        RwaOutputConduitLike(RWA015_A_OUTPUT_CONDUIT_USDC).diss(RWA015_A_CUSTODY);
        RwaOutputConduitLike(RWA015_A_OUTPUT_CONDUIT_USDC).file("quitTo", address(0));
        RwaOutputConduitLike(RWA015_A_OUTPUT_CONDUIT_USDC).deny(MCD_ESM);
        RwaOutputConduitLike(RWA015_A_OUTPUT_CONDUIT_USDC).deny(address(this));

        // Remove Legacy Conduit From Chainlog
        ChainlogLike(DssExecLib.LOG).removeAddress("RWA015_A_OUTPUT_CONDUIT_LEGACY");

        // ----- Add Cron Jobs to Chainlog -----
        // Forum: https://forum.makerdao.com/t/dsscron-housekeeping-additions/21292

        DssExecLib.setChangelogAddress("CRON_SEQUENCER",       CRON_SEQUENCER);
        DssExecLib.setChangelogAddress("CRON_AUTOLINE_JOB",    CRON_AUTOLINE_JOB);
        DssExecLib.setChangelogAddress("CRON_LERP_JOB",        CRON_LERP_JOB);
        DssExecLib.setChangelogAddress("CRON_D3M_JOB",         CRON_D3M_JOB);
        DssExecLib.setChangelogAddress("CRON_CLIPPER_MOM_JOB", CRON_CLIPPER_MOM_JOB);
        DssExecLib.setChangelogAddress("CRON_ORACLE_JOB",      CRON_ORACLE_JOB);

        // ----- Deploy FlapperUniV2 -----
        // https://vote.makerdao.com/polling/QmQmxEZp#poll-detail
        // Forum: https://forum.makerdao.com/t/introduction-of-smart-burn-engine-and-initial-parameters/21201
        // dss-flappers @ b10f68224c648166cd4f9b09595412bce9824301

        DssInstance memory dss = MCD.loadFromChainlog(DssExecLib.LOG);
        FlapperInstance memory flap = FlapperInstance({
            flapper: MCD_FLAP,
            mom:     FLAPPER_MOM
        });
        FlapperUniV2Config memory cfg = FlapperUniV2Config({
            hop:  1577 seconds,
            want: 98 * WAD / 100,
            pip:  PIP_MKR,
            hump: 50 * MILLION * RAD,
            bump: 5 * THOUSAND * RAD
        });

        FlapperInit.initFlapperUniV2({
            dss: dss,
            flapperInstance: flap,
            cfg: cfg
        });

        FlapperInit.initDirectOracle({
            flapper : MCD_FLAP
        });

        DssExecLib.setChangelogAddress("PIP_MKR", PIP_MKR);

        DssCronSequencerLike(CRON_SEQUENCER).addJob(CRON_FLAP_JOB);
        DssExecLib.setChangelogAddress("CRON_FLAP_JOB", CRON_FLAP_JOB);

        // ----- Scope Defined Parameter Changes -----
        // Forum: https://forum.makerdao.com/t/stability-scope-parameter-changes-3/21238/6

        // Reduce DSR by 0.30% from 3.49% to 3.19%
        DssExecLib.setDSR(THREE_PT_ONE_NINE_PCT_RATE, /* doDrip = */ true);

        // Reduce WSTETH-A Liquidation Ratio by 10% from 160% to 150%
        DssExecLib.setIlkLiquidationRatio("WSTETH-A", 150_00);

        // Reduce WSTETH-B Liquidation Ratio by 10% from 185% to 175%
        DssExecLib.setIlkLiquidationRatio("WSTETH-B", 175_00);

        // Reduce RETH-A Liquidation Ratio by 20% from 170% to 150%
        DssExecLib.setIlkLiquidationRatio("RETH-A", 150_00);

        // Reduce the ETH-A Stability Fee (SF) by 0.30% from 3.74% to 3.44%
        DssExecLib.setIlkStabilityFee("ETH-A", THREE_PT_FOUR_FOUR_PCT_RATE, /* doDrip = */ true);

        // Reduce the ETH-B Stability Fee (SF) by 0.30% from 4.24% to 3.94%
        DssExecLib.setIlkStabilityFee("ETH-B", THREE_PT_NINE_FOUR_PCT_RATE, /* doDrip = */ true);

        // Reduce the ETH-C Stability Fee (SF) by 0.30% from 3.49% to 3.19%
        DssExecLib.setIlkStabilityFee("ETH-C", THREE_PT_ONE_NINE_PCT_RATE, /* doDrip = */ true);

        // Reduce the WSTETH-A Stability Fee (SF) by 0.30% from 3.74% to 3.44%
        DssExecLib.setIlkStabilityFee("WSTETH-A", THREE_PT_FOUR_FOUR_PCT_RATE, /* doDrip = */ true);

        // Reduce the WSTETH-B Stability Fee (SF) by 0.30% from 3.49% to 3.19%
        DssExecLib.setIlkStabilityFee("WSTETH-B", THREE_PT_ONE_NINE_PCT_RATE, /* doDrip = */ true);

        // Reduce the RETH-A Stability Fee (SF) by 0.30% from 3.74% to 3.44%
        DssExecLib.setIlkStabilityFee("RETH-A", THREE_PT_FOUR_FOUR_PCT_RATE, /* doDrip = */ true);

        // Reduce the WBTC-A Stability Fee (SF) by 0.11% from 5.80% to 5.69%
        DssExecLib.setIlkStabilityFee("WBTC-A", FIVE_PT_SIX_NINE_PCT_RATE, /* doDrip = */ true);

        // Reduce the WBTC-B Stability Fee (SF) by 0.11% from 6.30% to 6.19%
        DssExecLib.setIlkStabilityFee("WBTC-B", SIX_PT_ONE_NINE_PCT_RATE, /* doDrip = */ true);

        // Reduce the WBTC-C Stability Fee (SF) by 0.11% from 5.55% to 5.44%
        DssExecLib.setIlkStabilityFee("WBTC-C", FIVE_PT_FOUR_FOUR_PCT_RATE, /* doDrip = */ true);

        // ----- Delegate Compensation for June 2023 -----
        // Forum: https://forum.makerdao.com/t/june-2023-aligned-delegate-compensation/21310

        // 0xDefensor  - 29.76 MKR - 0x9542b441d65B6BF4dDdd3d4D2a66D8dCB9EE07a9
        MKR.transfer(DEFENSOR,       29.76 ether); // note: ether is a keyword helper, only MKR is transferred here

        // BONAPUBLICA - 29.76 MKR - 0x167c1a762B08D7e78dbF8f24e5C3f1Ab415021D3
        MKR.transfer(BONAPUBLICA,    29.76 ether); // note: ether is a keyword helper, only MKR is transferred here

        // QGov        - 29.76 MKR - 0xB0524D8707F76c681901b782372EbeD2d4bA28a6
        MKR.transfer(QGOV,           29.76 ether); // note: ether is a keyword helper, only MKR is transferred here

        // TRUE NAME   - 29.76 MKR - 0x612f7924c367575a0edf21333d96b15f1b345a5d
        MKR.transfer(TRUENAME,       29.76 ether); // note: ether is a keyword helper, only MKR is transferred here

        // UPMaker     - 29.76 MKR - 0xbb819df169670dc71a16f58f55956fe642cc6bcd
        MKR.transfer(UPMAKER,        29.76 ether); // note: ether is a keyword helper, only MKR is transferred here

        // vigilant    - 29.76 MKR - 0x2474937cB55500601BCCE9f4cb0A0A72Dc226F61
        MKR.transfer(VIGILANT,       29.76 ether); // note: ether is a keyword helper, only MKR is transferred here

        // WBC         - 20.16 MKR - 0xeBcE83e491947aDB1396Ee7E55d3c81414fB0D47
        MKR.transfer(WBC,            20.16 ether); // note: ether is a keyword helper, only MKR is transferred here

        // PBG         -  9.92 MKR - 0x8D4df847dB7FfE0B46AF084fE031F7691C6478c2
        MKR.transfer(PBG,             9.92 ether); // note: ether is a keyword helper, only MKR is transferred here

        // Bandhar     -  7.68 MKR - 0xE83B6a503A94a5b764CCF00667689B3a522ABc21
        MKR.transfer(BANDHAR,         7.68 ether); // note: ether is a keyword helper, only MKR is transferred here

        // Libertas    -  7.04 MKR - 0xE1eBfFa01883EF2b4A9f59b587fFf1a5B44dbb2f
        MKR.transfer(LIBERTAS,        7.04 ether); // note: ether is a keyword helper, only MKR is transferred here

        // PALC        -  2.24 MKR - 0x78Deac4F87BD8007b9cb56B8d53889ed5374e83A
        MKR.transfer(PALC,            2.24 ether); // note: ether is a keyword helper, only MKR is transferred here

        // Harmony     -  1.92 MKR - 0xF4704Aa4Ad22cAA2A3Dd7A7C529B4C32f7A421F2
        MKR.transfer(HARMONY,         1.92 ether); // note: ether is a keyword helper, only MKR is transferred here

        // VoteWizard  -  1.6  MKR - 0x9E72629dF4fcaA2c2F5813FbbDc55064345431b1
        MKR.transfer(VOTEWIZARD,      1.6  ether); // note: ether is a keyword helper, only MKR is transferred here

        // Navigator   -  0.32 MKR - 0x11406a9CC2e37425F15f920F494A51133ac93072
        MKR.transfer(NAVIGATOR,       0.32 ether); // note: ether is a keyword helper, only MKR is transferred here

        // ----- CRVV1ETHSTETH-A 1st Stage Offboarding -----
        // Forum: https://forum.makerdao.com/t/stability-scope-parameter-changes-3/21238/6

        // Set CRVV1ETHSTETH-A Debt Ceiling to 0
        DssExecLib.setIlkDebtCeiling("CRVV1ETHSTETH-A", 0);

        // Remove CRVV1ETHSTETH-A from autoline
        DssExecLib.removeIlkFromAutoLine("CRVV1ETHSTETH-A");

        // ----- Ecosystem Actor Dai Budget Stream -----

        // Chronicle Labs Auditor Wallet | 2023-07-01 00:00:00 to 2024-06-30 23:59:59 | 3,721,800 DAI | 0x68D0ca2d5Ac777F6A9b0d1be44332BB3d5981C2f
        // Poll: https://vote.makerdao.com/polling/QmdnSKPu#poll-detail
        MCD_VEST_DAI.restrict(
            MCD_VEST_DAI.create(
                CHRONICLE_LABS,            // usr
                3_721_800 * WAD,           // tot
                JUL_01_2023,               // bgn
                JUN_30_2024 - JUL_01_2023, // tau
                0,                         // eta
                address(0)                 // mgr
            )
        );

        // Jetstream Auditor Wallet      | 2023-07-01 00:00:00 to 2024-12-31 23:59:59 | 2,964,006 DAI | 0xF478A08C41ad06E8D957d5e6B6Bcde7452cEE962
        // Forum: https://forum.makerdao.com/t/mip39c3-sp9-removing-dux-001/21306
        MCD_VEST_DAI.restrict(
            MCD_VEST_DAI.create(
                JETSTREAM,                 // usr
                2_964_006 * WAD,           // tot
                JUL_01_2023,               // bgn
                DEC_31_2024 - JUL_01_2023, // tau
                0,                         // eta
                address(0)                 // mgr
            )
        );

        // ----- Ecosystem Actor MKR Budget Stream -----

        // Increase allowance by new vesting delta
        uint256 newVesting = 2_216.4  ether; // CHRONICLE_LABS; note: ether is a keyword helper, only MKR is transferred here
               newVesting += 1_619.93 ether; // JETSTREAM; note: ether is a keyword helper, only MKR is transferred here
        MKR.approve(address(MCD_VEST_MKR_TREASURY), MKR.allowance(address(this), (address(MCD_VEST_MKR_TREASURY))) + newVesting);

        // Set system-wide cap on maximum vesting speed
        MCD_VEST_MKR_TREASURY.file("cap", 2_220 * WAD / 365 days);

        // Chronicle Labs Auditor Wallet | 2023-07-01 00:00:00 to 2024-06-30 23:59:59 | 2,216.4  MKR | 0x68D0ca2d5Ac777F6A9b0d1be44332BB3d5981C2f
        // Poll: https://vote.makerdao.com/polling/QmdnSKPu#poll-detail
        MCD_VEST_MKR_TREASURY.restrict(
            MCD_VEST_MKR_TREASURY.create(
                CHRONICLE_LABS,            // usr
                2_216.4 ether,             // tot; note: ether is a keyword helper, only MKR is transferred here
                JUL_01_2023,               // bgn
                JUN_30_2024 - JUL_01_2023, // tau
                0,                         // eta
                address(0)                 // mgr
            )
        );

        // Jetstream Auditor Wallet      | 2023-06-26 00:00:00 to 2024-12-31 23:59:59 | 1,619.93 MKR | 0xF478A08C41ad06E8D957d5e6B6Bcde7452cEE962
        // Forum: https://forum.makerdao.com/t/mip39c3-sp9-removing-dux-001/21306
        MCD_VEST_MKR_TREASURY.restrict(
            MCD_VEST_MKR_TREASURY.create(
                JETSTREAM,                 // usr
                1_619.93 ether,            // tot; note: ether is a keyword helper, only MKR is transferred here
                JUN_26_2023,               // bgn
                DEC_31_2024 - JUN_26_2023, // tau
                0,                         // eta
                address(0)                 // mgr
            )
        );

        // ----- Ecosystem Actor Dai Transfer -----

        // Jetstream - 494,001 DAI - 0xF478A08C41ad06E8D957d5e6B6Bcde7452cEE962
        // Forum: https://forum.makerdao.com/t/mip39c3-sp9-removing-dux-001/21306
        DssExecLib.sendPaymentFromSurplusBuffer(JETSTREAM, 494_001);

        // ----- Core Unit MKR Vesting Transfer -----

        // DECO-001 - 125    MKR - 0xF482D1031E5b172D42B2DAA1b6e5Cbf6519596f7
        // Mip: https://mips.makerdao.com/mips/details/MIP40c3SP36#mkr-vesting
        MKR.transfer(DECO_WALLET,    125    ether); // note: ether is a keyword helper, only MKR is transferred here

        // DUX-001  -  56.48 MKR - 0x5A994D8428CCEbCC153863CCdA9D2Be6352f89ad
        // Forum: https://forum.makerdao.com/t/mip39c3-sp9-removing-dux-001/21306
        MKR.transfer(DUX_WALLET,      56.48 ether); // note: ether is a keyword helper, only MKR is transferred here

        // ----- Core Unit DAI Stream Cancel -----

        // yank DAI stream ID 14 to DUX-001
        // Forum: https://forum.makerdao.com/t/mip39c3-sp9-removing-dux-001/21306
        MCD_VEST_DAI.yank(14);

        // ----- Trigger Spark Proxy Spell -----
        // Forum: https://forum.makerdao.com/t/freeze-the-sdai-market-on-spark/21322

        // Trigger Spark Spell at 0x843A0539Ca7466Abcb769f1c1d30C8423e13A297
        ProxyLike(SUBPROXY_SPARK).exec(SPARK_SPELL, abi.encodeWithSignature("execute()"));

        // ----- Update ChainLog version -----
        // Justification: The MINOR version is updated as core MCD_FLAP contract is being replaced in the spell
        // See https://github.com/makerdao/pe-checklists/blob/492326ab00b4c400173b7d7d43a79df90c0c6c1d/spell/spell-crafter-goerli-workflow.md?plain=1#L80
        DssExecLib.setChangelogVersion("1.15.0");
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) {}
}
