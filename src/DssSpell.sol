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

interface GemLike {
    function transfer(address, uint256) external returns (bool);
    function allowance(address, address) external view returns (uint256);
    function approve(address, uint256) external returns (bool);
}

interface PauseLike {
    function setDelay(uint256) external;
}

interface VestLike {
    function restrict(uint256) external;
    function create(address, uint256, uint256, uint256, uint256, address) external returns (uint256);
    function yank(uint256) external;
}

contract DssSpellAction is DssAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: cast keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/TODO/governance/votes/TODO.md -q -O - 2>/dev/null)"
    string public constant override description =
        "2023-04-05 MakerDAO Executive Spell | Hash: TODO";

    // Turn office hours off
    function officeHours() public pure override returns (bool) {
        return false;
    }

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

    uint256 internal constant MILLION = 10 ** 6;
    uint256 internal constant WAD     = 10 ** 18;

    address internal immutable MCD_PAUSE = DssExecLib.getChangelogAddress("MCD_PAUSE");

    address constant COLDIRON           = 0x6634e3555DBF4B149c5AEC99D579A2469015AEca;
    address constant FLIPFLOPFLAP       = 0x688d508f3a6B0a377e266405A1583B3316f9A2B3;
    address constant GFXLABS            = 0xa6e8772af29b29B9202a073f8E36f447689BEef6;
    address constant MHONKASALOTEEMULAU = 0x97Fb39171ACd7C82c439b6158EA2F71D26ba383d;
    address constant PENNBLOCKCHAIN     = 0x2165D41aF0d8d5034b9c266597c1A415FA0253bd;
    address constant FEEDBLACKLOOPS     = 0x80882f2A36d49fC46C3c654F7f9cB9a2Bf0423e1;
    address constant STABLELAB          = 0x3B91eBDfBC4B78d778f62632a4004804AC5d2DB0;
    address constant LBSBLOCKCHAIN      = 0xB83b3e9C8E3393889Afb272D354A7a3Bd1Fbcf5C;
    address constant HKUSTEPI           = 0x2dA0d746938Efa28C7DC093b1da286b3D8bAC34a;
    address constant JUSTINCASE         = 0xE070c2dCfcf6C6409202A8a210f71D51dbAe9473;
    address constant FRONTIERRESEARCH   = 0xA2d55b89654079987CF3985aEff5A7Bd44DA15A8;
    address constant CODEKNIGHT         = 0xf6006d4cF95d6CB2CD1E24AC215D5BF3bca81e7D;
    address constant FLIPSIDE           = 0x1ef753934C40a72a60EaB12A68B6f8854439AA78;
    address constant ONESTONE           = 0x4eFb12d515801eCfa3Be456B5F348D3CD68f9E8a;
    address constant CONSENSYS          = 0xE78658A8acfE982Fde841abb008e57e6545e38b3;
    address constant ACREINVEST         = 0x5b9C98e8A3D9Db6cd4B4B4C1F92D0A551D06F00D;

    address internal immutable MCD_VEST_DAI          = DssExecLib.getChangelogAddress("MCD_VEST_DAI");
    GemLike internal immutable MKR                   = GemLike(DssExecLib.mkr());
    address internal immutable MCD_VEST_MKR_TREASURY = DssExecLib.getChangelogAddress("MCD_VEST_MKR_TREASURY");
    address immutable internal ESM                   = DssExecLib.getChangelogAddress("MCD_ESM");
    address immutable internal RWA_LIQ_ORACLE        = DssExecLib.getChangelogAddress("MIP21_LIQUIDATION_ORACLE");


    // 01 Mar 2023 12:00:00 AM UTC
    uint256 constant public MAR_01_2023 = 1677628800;
    // 01 Apr 2023 12:00:00 AM UTC
    uint256 constant public APR_01_2023 = 1680307200;
    // 29 Feb 2024 11:59:59 PM UTC
    uint256 constant public FEB_29_2024 = 1709251199;
    // 31 Mar 2024 11:59:59 PM UTC
    uint256 constant public MAR_31_2024 = 1711929599;
    // 01 Apr 2024 11:59:59 PM UTC
    uint256 constant public APR_01_2024 = 1712015999;

    // RESPONSIBLE FACILITATORS
    address constant GOV_ALPHA  = 0x01D26f8c5cC009868A4BF66E268c17B057fF7A73;
    address constant TECH       = 0x2dC0420A736D1F40893B9481D8968E4D7424bC0B; // TECH_WALLET
    address constant STEAKHOUSE = 0xf737C76D2B358619f7ef696cf3F94548fEcec379; // SF_WALLET
    address constant BA_LABS    = 0xDfe08A40054685E205Ed527014899d1EDe49B892;

    // ECOSYSTEM ACTORS
    address constant PHOENIX_LABS_STREAM = 0x115F76A98C2268DaE6c1421eb6B08e4e1dF525dA;
    address constant VIRIDIAN_STREAM     = 0xbB8AA212267477C3dbfF6643E497919ec2E3dEC9;
    address constant VIRIDIAN_TRANSFER   = 0xA1E62c6321eEd0ECFcF2f382c8c82FD940D83c07;
    address constant DEWIZ               = 0xD8665628742cf54BBBB3b00B15d7E7a838a1b53a;
    address constant SIDESTREAM          = 0x87EcaaACEd3A02A37e7075dc45D3fEb49867d135;

    function actions() public override {

        // ----- GSM Pause Delay Reset to 48 Hours -----
        PauseLike(MCD_PAUSE).setDelay(48 hours);

        // ----- FINAL DELEGATE COMPENSATION -----
        // FORUM: https://forum.makerdao.com/t/final-recognized-delegate-compensation-payments/20341
        DssExecLib.sendPaymentFromSurplusBuffer(COLDIRON,           10_452);
        DssExecLib.sendPaymentFromSurplusBuffer(FLIPFLOPFLAP,       10_452);
        DssExecLib.sendPaymentFromSurplusBuffer(GFXLABS,            10_452);
        DssExecLib.sendPaymentFromSurplusBuffer(MHONKASALOTEEMULAU,  9_929);
        DssExecLib.sendPaymentFromSurplusBuffer(PENNBLOCKCHAIN,      9_568);
        DssExecLib.sendPaymentFromSurplusBuffer(FEEDBLACKLOOPS,      9_408);
        DssExecLib.sendPaymentFromSurplusBuffer(STABLELAB,           3_282);
        DssExecLib.sendPaymentFromSurplusBuffer(LBSBLOCKCHAIN,       3_045);
        DssExecLib.sendPaymentFromSurplusBuffer(HKUSTEPI,            2_607);
        DssExecLib.sendPaymentFromSurplusBuffer(JUSTINCASE,          2_488);
        DssExecLib.sendPaymentFromSurplusBuffer(FRONTIERRESEARCH,    2_421);
        DssExecLib.sendPaymentFromSurplusBuffer(CODEKNIGHT,            630);
        DssExecLib.sendPaymentFromSurplusBuffer(FLIPSIDE,              541);
        DssExecLib.sendPaymentFromSurplusBuffer(ONESTONE,              314);
        DssExecLib.sendPaymentFromSurplusBuffer(CONSENSYS,             154);
        DssExecLib.sendPaymentFromSurplusBuffer(ACREINVEST,             33);

        // ----- RESPONSIBLE FACILITATOR DAI STREAMS
        // VOTE: https://vote.makerdao.com/polling/Qmbndmkr#vote-breakdown
        // FORUM: https://mips.makerdao.com/mips/details/MIP113
        // GovAlpha | 2023-04-01 to 2024-03-31 | 900,000 DAI | 0x01D26f8c5cC009868A4BF66E268c17B057fF7A73
        VestLike(MCD_VEST_DAI).restrict(
            VestLike(MCD_VEST_DAI).create(
                GOV_ALPHA,                 // usr
                900_000 * WAD,             // tot
                APR_01_2023,               // bgn
                MAR_31_2024 - APR_01_2023, // tau
                0,                         // eta
                address(0)                 // mgr
            )
        );
        // TECH | 2023-04-01 to 2024-03-31 | 1,380,000 DAI | 0x2dC0420A736D1F40893B9481D8968E4D7424bC0B
        VestLike(MCD_VEST_DAI).restrict(
            VestLike(MCD_VEST_DAI).create(
                TECH,                      // usr
                1_380_000 * WAD,           // tot
                APR_01_2023,               // bgn
                MAR_31_2024 - APR_01_2023, // tau
                0,                         // eta
                address(0)                 // mgr
            )
        );
        // Steakhouse Financial | 2023-04-01 to 2024-03-31 | 2,220,000 DAI | 0xf737C76D2B358619f7ef696cf3F94548fEcec379
        VestLike(MCD_VEST_DAI).restrict(
            VestLike(MCD_VEST_DAI).create(
                STEAKHOUSE,                // usr
                2_220_000 * WAD,           // tot
                APR_01_2023,               // bgn
                MAR_31_2024 - APR_01_2023, // tau
                0,                         // eta
                address(0)                 // mgr
            )
        );
        // FORUM: https://mips.makerdao.com/mips/details/MIP104
        // BA Labs | 2023-03-01 to 2024-02-29 | 2,484,000 DAI | 0xDfe08A40054685E205Ed527014899d1EDe49B892
        VestLike(MCD_VEST_DAI).restrict(
            VestLike(MCD_VEST_DAI).create(
                BA_LABS,                   // usr
                2_484_000 * WAD,           // tot
                MAR_01_2023,               // bgn
                FEB_29_2024 - MAR_01_2023, // tau
                0,                         // eta
                address(0)                 // mgr
            )
        );
        // BA Labs - Data Insights | 2023-04-01 to 2024-03-31 | 876,000 DAI | 0xDfe08A40054685E205Ed527014899d1EDe49B892
        VestLike(MCD_VEST_DAI).restrict(
            VestLike(MCD_VEST_DAI).create(
                BA_LABS,                   // usr
                876_000 * WAD,             // tot
                APR_01_2023,               // bgn
                MAR_31_2024 - APR_01_2023, // tau
                0,                         // eta
                address(0)                 // mgr
            )
        );

        // ----- RESPONSIBLE FACILITATOR MKR STREAMS
        // VOTE: https://vote.makerdao.com/polling/Qmbndmkr#vote-breakdown
        // Increase allowance by new vesting delta
        uint256 newVesting = 690 * WAD; // STEAKHOUSE
               newVesting += 432 * WAD; // TECH
               newVesting += 340 * WAD; // GovAlpha
               newVesting += 180 * WAD; // BA Labs
               newVesting += 252 * WAD; // Dewiz
               newVesting += 120 * WAD; // Phoenix Labs
        MKR.approve(address(MCD_VEST_MKR_TREASURY), MKR.allowance(address(this), address(MCD_VEST_MKR_TREASURY)) + newVesting);

        // FORUM: https://mips.makerdao.com/mips/details/MIP113
        // Steakhouse Financial | 2023-04-01 to 2024-03-31 | Cliff Date 2023-04-01 | 690 MKR
        VestLike(MCD_VEST_MKR_TREASURY).restrict(
            VestLike(MCD_VEST_MKR_TREASURY).create(
                STEAKHOUSE,                // usr
                690 * WAD,                 // tot
                APR_01_2023,               // bgn
                MAR_31_2024 - APR_01_2023, // tau
                0,                         // eta
                address(0)                 // mgr
            )
        );
        // TECH | 2023-04-01 to 2024-03-31 | Cliff Date 2023-04-01 | 432 MKR
        VestLike(MCD_VEST_MKR_TREASURY).restrict(
            VestLike(MCD_VEST_MKR_TREASURY).create(
                TECH,                      // usr
                432 * WAD,                 // tot
                APR_01_2023,               // bgn
                MAR_31_2024 - APR_01_2023, // tau
                0,                         // eta
                address(0)                 // mgr
            )
        );
        // GovAlpha | 2023-04-01 to 2024-03-31 | Cliff Date 2023-04-01 | 340 MKR
        VestLike(MCD_VEST_MKR_TREASURY).restrict(
            VestLike(MCD_VEST_MKR_TREASURY).create(
                GOV_ALPHA,                 // usr
                340 * WAD,                 // tot
                APR_01_2023,               // bgn
                MAR_31_2024 - APR_01_2023, // tau
                0,                         // eta
                address(0)                 // mgr
            )
        );
        // FORUM: https://mips.makerdao.com/mips/details/MIP104
        // BA Labs - Data Insights | 2023-04-01 to 2024-03-31 | Cliff Date 2023-04-01 | 180 MKR
        VestLike(MCD_VEST_MKR_TREASURY).restrict(
            VestLike(MCD_VEST_MKR_TREASURY).create(
                BA_LABS,                   // usr
                180 * WAD,                 // tot
                APR_01_2023,               // bgn
                MAR_31_2024 - APR_01_2023, // tau
                0,                         // eta
                address(0)                 // mgr
            )
        );

        // ----- Yank old SF-001 MKR Vesting Streams - being replaced with single stream to SF Wallet -----
        // VOTE: N/A
        // FORUM: https://mips.makerdao.com/mips/details/MIP113
        VestLike(MCD_VEST_MKR_TREASURY).yank(18);
        VestLike(MCD_VEST_MKR_TREASURY).yank(19);
        VestLike(MCD_VEST_MKR_TREASURY).yank(30);
        VestLike(MCD_VEST_MKR_TREASURY).yank(31);

        // ----- Responsible Facilitator MKR Transfers
        // VOTE: https://vote.makerdao.com/polling/Qmbndmkr#vote-breakdown
        // GovAlpha - 226.64 MKR - 0x01D26f8c5cC009868A4BF66E268c17B057fF7A73
        MKR.transfer(GOV_ALPHA, 226.64 ether);  // NOTE: 'ether' is a keyword helper, only MKR is transferred here


        // ----- Ecosystem Actor Dai Streams -----
        // Forum: https://mips.makerdao.com/mips/details/MIP106

        // Vote: https://vote.makerdao.com/polling/QmRxNdG7
        // Phoenix Labs | 2023-04-01 to 2024-04-01 | 204,000 DAI | 0x115F76A98C2268DaE6c1421eb6B08e4e1dF525dA
        VestLike(MCD_VEST_DAI).restrict(
            VestLike(MCD_VEST_DAI).create(
                PHOENIX_LABS_STREAM,       // usr
                204_000 * WAD,             // tot
                APR_01_2023,               // bgn
                APR_01_2024 - APR_01_2023, // tau
                0,                         // eta
                address(0)                 // mgr
            )
        );

        // Vote: https://vote.makerdao.com/polling/QmV9MR8B
        // Viridian Protector Advisory Company | 2023-04-01 to 2024-04-01 | 1,029,000 DAI | 0xbB8AA212267477C3dbfF6643E497919ec2E3dEC9
        VestLike(MCD_VEST_DAI).restrict(
            VestLike(MCD_VEST_DAI).create(
                VIRIDIAN_STREAM,           // usr
                1_029_000 * WAD,           // tot
                APR_01_2023,               // bgn
                APR_01_2024 - APR_01_2023, // tau
                0,                         // eta
                address(0)                 // mgr
            )
        );

        // Vote: https://vote.makerdao.com/polling/QmVo7VXV
        // dewiz | 2023-04-01 to 2024-04-01 | 1,800,000 DAI | 0xD8665628742cf54BBBB3b00B15d7E7a838a1b53a
        VestLike(MCD_VEST_DAI).restrict(
            VestLike(MCD_VEST_DAI).create(
                DEWIZ,                     // usr
                1_800_000 * WAD,           // tot
                APR_01_2023,               // bgn
                APR_01_2024 - APR_01_2023, // tau
                0,                         // eta
                address(0)                 // mgr
            )
        );

        // Vote: https://vote.makerdao.com/polling/Qmd5R3Jz
        // Sidestream | 2023-04-01 to 2024-04-01 | 850,950 DAI | 0x87EcaaACEd3A02A37e7075dc45D3fEb49867d135
        VestLike(MCD_VEST_DAI).restrict(
            VestLike(MCD_VEST_DAI).create(
                SIDESTREAM,                // usr
                850_950 * WAD,             // tot
                APR_01_2023,               // bgn
                APR_01_2024 - APR_01_2023, // tau
                0,                         // eta
                address(0)                 // mgr
            )
        );

        // ----- Ecosystem Actor MKR Streams -----
        // VOTE: https://vote.makerdao.com/polling/Qmbndmkr#vote-breakdown

        // VOTE: https://vote.makerdao.com/polling/QmVo7VXV
        // dewiz | 2023-04-01 to 2024-04-01 | 252 MKR | 0xD8665628742cf54BBBB3b00B15d7E7a838a1b53a
        VestLike(MCD_VEST_MKR_TREASURY).restrict(
            VestLike(MCD_VEST_MKR_TREASURY).create(
                DEWIZ,                     // usr
                252 * WAD,                 // tot
                APR_01_2023,               // bgn
                APR_01_2024 - APR_01_2023, // tau
                0,                         // eta
                address(0)                 // mgr
            )
        );

        // VOTE: https://vote.makerdao.com/polling/QmRxNdG7
        // Phoenix Labs | 2023-04-01 to 2024-04-01 | 120 MKR | 0x115F76A98C2268DaE6c1421eb6B08e4e1dF525dA
        VestLike(MCD_VEST_MKR_TREASURY).restrict(
            VestLike(MCD_VEST_MKR_TREASURY).create(
                PHOENIX_LABS_STREAM,       // usr
                120 * WAD,                 // tot
                APR_01_2023,               // bgn
                APR_01_2024 - APR_01_2023, // tau
                0,                         // eta
                address(0)                 // mgr
            )
        );

        // ----- Ecosystem Actor Dai Transfers -----
        // VOTE: https://vote.makerdao.com/polling/Qmbndmkr#vote-breakdown

        // VOTE: https://vote.makerdao.com/polling/QmRxNdG7
        DssExecLib.sendPaymentFromSurplusBuffer(PHOENIX_LABS_STREAM, 347_100);

        // VOTE: https://vote.makerdao.com/polling/QmV9MR8B
        DssExecLib.sendPaymentFromSurplusBuffer(VIRIDIAN_TRANSFER,   257_250);

        // ----- Additional ESM authorization fix -----
        DssExecLib.authorize(RWA_LIQ_ORACLE, ESM);
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) {}
}
