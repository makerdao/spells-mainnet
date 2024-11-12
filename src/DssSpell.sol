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
import { VestAbstract } from "dss-interfaces/dss/VestAbstract.sol";
import { GemAbstract } from "dss-interfaces/ERC/GemAbstract.sol";
import { JugAbstract } from "dss-interfaces/dss/JugAbstract.sol";

interface RwaLiquidationOracleLike {
    function cull(bytes32 ilk, address urn) external;
}

interface ProxyLike {
    function exec(address target, bytes calldata args) external payable returns (bytes memory out);
}

interface SUsdsLike {
    function file(bytes32, uint256) external;
    function drip() external returns (uint256);
}

contract DssSpellAction is DssAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: cast keccak -- "$(wget 'TODO' -q -O - 2>/dev/null)"
    string public constant override description =
        "2024-11-14 MakerDAO Executive Spell | Hash: TODO";

    // Set office hours according to the summary
    function officeHours() public pure override returns (bool) {
        return true;
    }

    // Note: by the previous convention it should be a comma-separated list of DAO resolutions IPFS hashes
    string public constant dao_resolutions = "QmX4DdVBiDBjLXYT4J4jC1XMdTn2Q7Ao8L66pKB8N3yETA";

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
    uint256 internal constant SEVEN_PT_FIVE_PCT_RATE        = 1000000002293273137447730714;
    uint256 internal constant EIGHT_PCT_RATE                = 1000000002440418608258400030;
    uint256 internal constant EIGHT_PT_TWO_FIVE_PCT_RATE    = 1000000002513736079215619839;
    uint256 internal constant EIGHT_PT_FIVE_PCT_RATE        = 1000000002586884420913935572;
    uint256 internal constant EIGHT_PT_SEVEN_FIVE_PCT_RATE  = 1000000002659864411854984565;
    uint256 internal constant NINE_PCT_RATE                 = 1000000002732676825177582095;
    uint256 internal constant NINE_PT_TWO_FIVE_PCT_RATE     = 1000000002805322428706865331;
    uint256 internal constant ELEVEN_PCT_RATE               = 1000000003309234382829738808;
    uint256 internal constant ELEVEN_PT_TWO_FIVE_PCT_RATE   = 1000000003380572527855758393;
    uint256 internal constant ELEVEN_PT_SEVEN_FIVE_PCT_RATE = 1000000003522769143241571114;


    // ---------- Math ----------
    uint256 internal constant MILLION = 10 ** 6;
    uint256 internal constant WAD     = 10 ** 18;

    // ---------- Contracts ----------
    GemAbstract internal immutable MKR                  = GemAbstract(DssExecLib.mkr());
    address internal immutable MCD_JUG                  = DssExecLib.jug();
    address internal immutable MIP21_LIQUIDATION_ORACLE = DssExecLib.getChangelogAddress("MIP21_LIQUIDATION_ORACLE");
    address internal immutable RWA003_A_URN             = DssExecLib.getChangelogAddress("RWA003_A_URN");
    address internal immutable MCD_VEST_DAI             = DssExecLib.getChangelogAddress("MCD_VEST_DAI");
    address internal immutable MCD_VEST_MKR_TREASURY    = DssExecLib.getChangelogAddress("MCD_VEST_MKR_TREASURY");
    address internal immutable DIRECT_SPARK_DAI_PLAN    = DssExecLib.getChangelogAddress("DIRECT_SPARK_DAI_PLAN");
    address internal immutable SUSDS                    = DssExecLib.getChangelogAddress("SUSDS");
    address internal constant GELATO_PAYMENT_ADAPTER    = 0x0B5a34D084b6A5ae4361de033d1e6255623b41eD;
    address internal constant GELATO_TREASURY_NEW       = 0x5041c60C75633F29DEb2AED79cB0A9ed79202415;

    // ---------- Wallets ----------
    address internal constant JANSKY                = 0xf3F868534FAD48EF5a228Fe78669cf242745a755;
    address internal constant VOTEWIZARD            = 0x9E72629dF4fcaA2c2F5813FbbDc55064345431b1;
    address internal constant ECOSYSTEM_FACILITATOR = 0xFCa6e196c2ad557E64D9397e283C2AFe57344b75;
    address internal constant JULIACHANG            = 0x252abAEe2F4f4b8D39E5F12b163eDFb7fac7AED7;
    address internal constant CLOAKY                = 0x869b6d5d8FA7f4FFdaCA4D23FFE0735c5eD1F818;
    address internal constant BLUE                  = 0xb6C09680D822F162449cdFB8248a7D3FC26Ec9Bf;
    address internal constant BYTERON               = 0xc2982e72D060cab2387Dba96b846acb8c96EfF66;
    address internal constant VIGILANT              = 0x2474937cB55500601BCCE9f4cb0A0A72Dc226F61;
    address internal constant CLOAKY_KOHLA_2        = 0x73dFC091Ad77c03F2809204fCF03C0b9dccf8c7a;
    address internal constant CLOAKY_ENNOIA         = 0xA7364a1738D0bB7D1911318Ca3FB3779A8A58D7b;
    address internal constant BONAPUBLICA           = 0x167c1a762B08D7e78dbF8f24e5C3f1Ab415021D3;
    address internal constant ROCKY                 = 0xC31637BDA32a0811E39456A59022D2C386cb2C85;

    // ---------- Timestamps ----------
    // 2024-10-01 00:00:00 UTC
    uint256 internal constant OCT_01_2024 = 1727740800;
    // 2024-12-01 00:00:00 UTC
    uint256 internal constant DEC_01_2024 = 1733011200;
    // 2025-01-31 23:59:59 UTC
    uint256 internal constant JAN_31_2025 = 1738367999;

    // ---------- Spark Proxy Spell ----------
    // Spark Proxy: https://github.com/marsfoundation/sparklend-deployments/blob/bba4c57d54deb6a14490b897c12a949aa035a99b/script/output/1/primary-sce-latest.json#L2
    address internal constant SPARK_PROXY = 0x3300f198988e4C9C63F75dF86De36421f06af8c4;
    address internal constant SPARK_SPELL = 0x8a3aaeAC45Cf3D76Cf82b0e4C63cCfa8c72BDCa7;

    function actions() public override {
        // ---------- Stability Fee Changes ----------
        // Forum: https://forum.sky.money/t/stability-scope-parameter-changes-17-sfs-dsr-ssr-spark-effective-dai-borrow-rate/25522/3
        // Forum: https://forum.sky.money/t/stability-scope-parameter-changes-17-sfs-dsr-ssr-spark-effective-dai-borrow-rate/25522/4

        // Increase ETH-A Stability Fee by 2 percentage point from 6.25% to 8.25%
        DssExecLib.setIlkStabilityFee("ETH-A", EIGHT_PT_TWO_FIVE_PCT_RATE, /* doDrip = */ true);

        // Increase ETH-B Stability Fee by 2 percentage point from 6.75% to 8.75%
        DssExecLib.setIlkStabilityFee("ETH-B", EIGHT_PT_SEVEN_FIVE_PCT_RATE, /* doDrip = */ true);

        // Increase ETH-C Stability Fee by 2 percentage point from 6.00% to 8.00%
        DssExecLib.setIlkStabilityFee("ETH-C", EIGHT_PCT_RATE, /* doDrip = */ true);

        // Increase WSTETH-A Stability Fee by 2 percentage point from 7.25% to 9.25%
        DssExecLib.setIlkStabilityFee("WSTETH-A", NINE_PT_TWO_FIVE_PCT_RATE, /* doDrip = */ true);

        // Increase WSTETH-B Stability Fee by 2 percentage point from 7.00% to 9.00%
        DssExecLib.setIlkStabilityFee("WSTETH-B", NINE_PCT_RATE, /* doDrip = */ true);

        // Increase WBTC-A Stability Fee by 2 percentage point from 9.25% to 11.25%
        DssExecLib.setIlkStabilityFee("WBTC-A", ELEVEN_PT_TWO_FIVE_PCT_RATE, /* doDrip = */ true);

        // Increase WBTC-B Stability Fee by 2 percentage point from 9.75% to 11.75%
        DssExecLib.setIlkStabilityFee("WBTC-B", ELEVEN_PT_SEVEN_FIVE_PCT_RATE, /* doDrip = */ true);

        // Increase WBTC-C Stability Fee by 2 percentage point from 9.00% to 11.00%
        DssExecLib.setIlkStabilityFee("WBTC-C", ELEVEN_PCT_RATE, /* doDrip = */ true);

        // ---------- Savings Rate Changes ----------
        // Forum: https://forum.sky.money/t/stability-scope-parameter-changes-17-sfs-dsr-ssr-spark-effective-dai-borrow-rate/25522/3
        // Forum: https://forum.sky.money/t/stability-scope-parameter-changes-17-sfs-dsr-ssr-spark-effective-dai-borrow-rate/25522/4

        // Increase DSR by 2 percentage point from 5.50% to 7.50%
        DssExecLib.setDSR(SEVEN_PT_FIVE_PCT_RATE, /* doDrip = */ true);

        // Increase SSR by 2 percentage point from 6.50% to 8.50%
        SUsdsLike(SUSDS).drip();
        SUsdsLike(SUSDS).file("ssr", EIGHT_PT_FIVE_PCT_RATE);

        // ---------- Increase SparkLend D3M Buffer Parameter ----------
        // Forum: https://forum.sky.money/t/14-nov-2024-proposed-changes-to-spark-for-upcoming-spell/25466
        // Poll: https://vote.makerdao.com/polling/QmNTKFqG#poll-detail

        // Increase the DIRECT-SPARK-DAI buffer parameter by 50 million DAI from 50 million DAI to 100 million DAI.
        DssExecLib.setValue(DIRECT_SPARK_DAI_PLAN, "buffer", 100 * MILLION * WAD);

        // ---------- Update Gelato Keeper Treasury Address ----------
        // Forum: https://forum.sky.money/t/gelato-keeper-update/25456

        // Update DssExecLib.setContract: GELATO_PAYMENT_ADAPTER - "treasury" to 0x5041c60C75633F29DEb2AED79cB0A9ed79202415
        DssExecLib.setContract(GELATO_PAYMENT_ADAPTER, "treasury", GELATO_TREASURY_NEW);

        // ---------- ConsolFreight Debt Write-Off and DAO Resolution ----------
        // Forum: https://forum.sky.money/t/consolfreight-rwa-003-cf4-drop-default/21745/21
        // Forum: https://forum.sky.money/t/consolfreight-rwa-003-cf4-drop-default/21745/22

        // Account for the accumulated stability fee by calling jug.drip("RWA003-A")
        JugAbstract(MCD_JUG).drip("RWA003-A");

        // Write-off the debt of RWA003-A by calling rwaLiqOrcl.cull("RWA003-A", RWA003_A_URN)
        RwaLiquidationOracleLike(MIP21_LIQUIDATION_ORACLE).cull("RWA003-A", RWA003_A_URN);

        // Approve ConsolFreight Dao Resolution with IPFS hash QmX4DdVBiDBjLXYT4J4jC1XMdTn2Q7Ao8L66pKB8N3yETA
        // Note: see `dao_resolutions` public variable declared above

        // ---------- Set Facilitator DAI Payment Streams ----------
        // Atlas: https://sky-atlas.powerhouse.io/A.1.6.2.4.1_List_of_Facilitator_Budgets/c511460d-53df-47e9-a4a5-2e48a533315b%7C0db3343515519c4a

        // JanSky | 2024-10-01 00:00:00 to 2025-01-31 23:59:59 | Cliff: 2024-10-01 00:00:00 | 168,000 DAI | 0xf3F868534FAD48EF5a228Fe78669cf242745a755 | Restricted: Yes
        VestAbstract(MCD_VEST_DAI).restrict(
            VestAbstract(MCD_VEST_DAI).create(
                JANSKY,                    // usr
                168_000 * WAD,             // tot
                OCT_01_2024,               // bgn
                JAN_31_2025 - OCT_01_2024, // tau
                0,                         // eta
                address(0)                 // mgr
            )
        );

        // Endgame Edge | 2024-10-01 00:00:00 to 2025-01-31 23:59:59 | Cliff: 2024-10-01 00:00:00 | 168,000 DAI | 0x9E72629dF4fcaA2c2F5813FbbDc55064345431b1 | Restricted: Yes
        VestAbstract(MCD_VEST_DAI).restrict(
            VestAbstract(MCD_VEST_DAI).create(
                VOTEWIZARD,                // usr
                168_000 * WAD,             // tot
                OCT_01_2024,               // bgn
                JAN_31_2025 - OCT_01_2024, // tau
                0,                         // eta
                address(0)                 // mgr
            )
        );

        // Ecosystem | 2024-12-01 00:00:00 to 2025-01-31 23:59:59 | Cliff: 2024-12-01 00:00:00 | 84,000 DAI | 0xFCa6e196c2ad557E64D9397e283C2AFe57344b75 | Restricted: Yes
        VestAbstract(MCD_VEST_DAI).restrict(
            VestAbstract(MCD_VEST_DAI).create(
                ECOSYSTEM_FACILITATOR,     // usr
                84_000 * WAD,              // tot
                DEC_01_2024,               // bgn
                JAN_31_2025 - DEC_01_2024, // tau
                0,                         // eta
                address(0)                 // mgr
            )
        );

        // ---------- Set Facilitator MKR Payment Streams ----------
        // Atlas: https://sky-atlas.powerhouse.io/A.1.6.2.4.1_List_of_Facilitator_Budgets/c511460d-53df-47e9-a4a5-2e48a533315b%7C0db3343515519c4a

        // Note: For the MKR stream we need to increase allowance by new vesting delta
        MKR.approve(address(MCD_VEST_MKR_TREASURY), MKR.allowance(address(this), address(MCD_VEST_MKR_TREASURY)) + 180 * WAD);

        // JanSky | 2024-10-01 00:00:00 to 2025-01-31 23:59:59 | Cliff: 2024-10-01 00:00:00 | 72.00 MKR | 0xf3F868534FAD48EF5a228Fe78669cf242745a755 | Restricted: Yes
        VestAbstract(MCD_VEST_MKR_TREASURY).restrict(
            VestAbstract(MCD_VEST_MKR_TREASURY).create(
                JANSKY,                    // usr
                72 * WAD,                  // tot
                OCT_01_2024,               // bgn
                JAN_31_2025 - OCT_01_2024, // tau
                0,                         // eta
                address(0)                 // mgr
            )
        );

        // Endgame Edge | 2024-10-01 00:00:00 to 2025-01-31 23:59:59 | Cliff: 2024-10-01 00:00:00 | 72.00 MKR | 0x9E72629dF4fcaA2c2F5813FbbDc55064345431b1 | Restricted: Yes
        VestAbstract(MCD_VEST_MKR_TREASURY).restrict(
            VestAbstract(MCD_VEST_MKR_TREASURY).create(
                VOTEWIZARD,                // usr
                72 * WAD,                  // tot
                OCT_01_2024,               // bgn
                JAN_31_2025 - OCT_01_2024, // tau
                0,                         // eta
                address(0)                 // mgr
            )
        );

        // Ecosystem | 2024-12-01 00:00:00 to 2025-01-31 23:59:59 | Cliff: 2024-12-01 00:00:00 | 36.00 MKR | 0xFCa6e196c2ad557E64D9397e283C2AFe57344b75 | Restricted: Yes
        VestAbstract(MCD_VEST_MKR_TREASURY).restrict(
            VestAbstract(MCD_VEST_MKR_TREASURY).create(
                ECOSYSTEM_FACILITATOR,     // usr
                36 * WAD,                  // tot
                DEC_01_2024,               // bgn
                JAN_31_2025 - DEC_01_2024, // tau
                0,                         // eta
                address(0)                 // mgr
            )
        );

        // ---------- Aligned Delegate DAI Compensation ----------
        // Forum: https://forum.sky.money/t/september-2024-aligned-delegate-compensation/25489
        // Atlas: https://sky-atlas.powerhouse.io/A.1.5.8_Budget_For_Prime_Delegate_Slots/e3e420fc-9b1f-4fdc-9983-fcebc45dd3aa%7C0db3af4ece0c

        // JuliaChang - 109168 DAI - 0x252abAEe2F4f4b8D39E5F12b163eDFb7fac7AED7
        DssExecLib.sendPaymentFromSurplusBuffer(JULIACHANG, 109_168);

        // Cloaky - 58412 DAI - 0x869b6d5d8FA7f4FFdaCA4D23FFE0735c5eD1F818
        DssExecLib.sendPaymentFromSurplusBuffer(CLOAKY, 58_412);

        // BLUE - 54167 DAI - 0xb6C09680D822F162449cdFB8248a7D3FC26Ec9Bf
        DssExecLib.sendPaymentFromSurplusBuffer(BLUE, 54_167);

        // Byteron - 34517 DAI - 0xc2982e72D060cab2387Dba96b846acb8c96EfF66
        DssExecLib.sendPaymentFromSurplusBuffer(BYTERON, 34_517);

        // vigilant - 16155 DAI - 0x2474937cB55500601BCCE9f4cb0A0A72Dc226F61
        DssExecLib.sendPaymentFromSurplusBuffer(VIGILANT, 16_155);

        // Kohla (Cloaky) - 10000 DAI - 0x73dFC091Ad77c03F2809204fCF03C0b9dccf8c7a
        DssExecLib.sendPaymentFromSurplusBuffer(CLOAKY_KOHLA_2, 10_000);

        // Ennoia (Cloaky) - 10000 DAI - 0xA7364a1738D0bB7D1911318Ca3FB3779A8A58D7b
        DssExecLib.sendPaymentFromSurplusBuffer(CLOAKY_ENNOIA, 10_000);

        // Bonapublica - 8333 DAI - 0x167c1a762B08D7e78dbF8f24e5C3f1Ab415021D3
        DssExecLib.sendPaymentFromSurplusBuffer(BONAPUBLICA, 8_333);

        // Rocky - 7796 DAI - 0xC31637BDA32a0811E39456A59022D2C386cb2C85
        DssExecLib.sendPaymentFromSurplusBuffer(ROCKY, 7_796);

        // ---------- Aligned Delegate MKR Compensation ----------
        // Forum: https://forum.sky.money/t/september-2024-aligned-delegate-compensation/25489
        // Atlas: https://sky-atlas.powerhouse.io/A.1.5.8_Budget_For_Prime_Delegate_Slots/e3e420fc-9b1f-4fdc-9983-fcebc45dd3aa%7C0db3af4ece0c

        // BLUE - 13.75 MKR - 0xb6C09680D822F162449cdFB8248a7D3FC26Ec9Bf
        MKR.transfer(BLUE, 13.75 ether); // Note: 'ether' is a keyword helper, only MKR is transferred here

        // Cloaky - 29.25 MKR - 0x869b6d5d8FA7f4FFdaCA4D23FFE0735c5eD1F818
        MKR.transfer(CLOAKY, 29.25 ether); // Note: 'ether' is a keyword helper, only MKR is transferred here

        // JuliaChang - 28.75 MKR - 0x252abAEe2F4f4b8D39E5F12b163eDFb7fac7AED7
        MKR.transfer(JULIACHANG, 28.75 ether); // Note: 'ether' is a keyword helper, only MKR is transferred here

        // Byteron - 9.68 MKR - 0xc2982e72D060cab2387Dba96b846acb8c96EfF66
        MKR.transfer(BYTERON, 9.68 ether); // Note: 'ether' is a keyword helper, only MKR is transferred here

        // vigilant - 2.43 MKR - 0x2474937cB55500601BCCE9f4cb0A0A72Dc226F61
        MKR.transfer(VIGILANT, 2.43 ether); // Note: 'ether' is a keyword helper, only MKR is transferred here

        // Bonapublica - 2.06 MKR - 0x167c1a762B08D7e78dbF8f24e5C3f1Ab415021D3
        MKR.transfer(BONAPUBLICA, 2.06 ether); // Note: 'ether' is a keyword helper, only MKR is transferred here

        // Rocky - 1.17 MKR - 0xC31637BDA32a0811E39456A59022D2C386cb2C85
        MKR.transfer(ROCKY, 1.17 ether); // Note: 'ether' is a keyword helper, only MKR is transferred here

        // ---------- Spark Proxy Spell ----------
        // Forum: https://forum.sky.money/t/14-nov-2024-proposed-changes-to-spark-for-upcoming-spell/25466
        // Poll: https://vote.makerdao.com/polling/QmQizL1F
        // Poll: https://vote.makerdao.com/polling/Qmbohkr5
        // Poll: https://vote.makerdao.com/polling/QmYqM8Yf
        // Poll: https://vote.makerdao.com/polling/QmXsXzot
        // Poll: https://vote.makerdao.com/polling/Qmf955yA

        // Execute Spark Proxy Spell at 0x8a3aaeAC45Cf3D76Cf82b0e4C63cCfa8c72BDCa7
        ProxyLike(SPARK_PROXY).exec(SPARK_SPELL, abi.encodeWithSignature("execute()"));
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) {}
}
