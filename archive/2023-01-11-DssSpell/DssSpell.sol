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

interface VestLike {
    function restrict(uint256) external;
    function create(address, uint256, uint256, uint256, uint256, address) external returns (uint256);
}

interface GemLike {
    function allowance(address, address) external view returns (uint256);
    function approve(address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
}

contract DssSpellAction is DssAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: cast keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/f20339d4956d043c53968d3bdef474959f1021c7/governance/votes/Executive%20vote%20-%20January%2011%2C%202023.md -q -O - 2>/dev/null)"
    string public constant override description =
        "2023-01-11 MakerDAO Executive Spell | Hash: 0xeb7cc87f7514362c910303c532230161b435e5b2626027a3f065cec7ce8f52cb";

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

    // uint256 internal constant MILLION = 10 ** 6;
    // uint256 internal constant RAY     = 10 ** 27;
    uint256 internal constant WAD                = 10 ** 18;

    GemLike  internal immutable MKR              = GemLike(DssExecLib.mkr());
    VestLike internal immutable MCD_VEST_MKR     = VestLike(DssExecLib.getChangelogAddress("MCD_VEST_MKR_TREASURY"));
    VestLike internal immutable MCD_VEST_DAI     = VestLike(DssExecLib.getChangelogAddress("MCD_VEST_DAI"));

    // Start Dates - Start of Day
    uint256 internal constant AUG_01_2022        = 1659312000;
    uint256 internal constant FEB_01_2023        = 1675209600;
    uint256 internal constant APR_30_2025        = 1745971200; // This aligns with other fin values of April 30 2025 00:00:00
    // End Dates - End of Day
    uint256 internal constant JUL_31_2023        = 1690847999;
    uint256 internal constant JAN_31_2024        = 1706745599;

    address internal constant DUX_WALLET         = 0x5A994D8428CCEbCC153863CCdA9D2Be6352f89ad;
    address internal constant SES_WALLET         = 0x87AcDD9208f73bFc9207e1f6F0fDE906bcA95cc6;

    address internal constant DECO_WALLET        = 0xF482D1031E5b172D42B2DAA1b6e5Cbf6519596f7;
    address internal constant RISK_WALLET        = 0x5d67d5B1fC7EF4bfF31967bE2D2d7b9323c1521c;
    address internal constant ORA_WALLET         = 0x2d09B7b95f3F312ba6dDfB77bA6971786c5b50Cf;

    address internal constant STABLENODE         = 0x3B91eBDfBC4B78d778f62632a4004804AC5d2DB0;
    address internal constant ULTRASCHUPPI       = 0xCCffDBc38B1463847509dCD95e0D9AAf54D1c167;
    address internal constant FLIPFLOPFLAP       = 0x688d508f3a6B0a377e266405A1583B3316f9A2B3;
    address internal constant FLIPSIDE           = 0x1ef753934C40a72a60EaB12A68B6f8854439AA78;
    address internal constant FEEDBLACKLOOPS     = 0x80882f2A36d49fC46C3c654F7f9cB9a2Bf0423e1;
    address internal constant PENNBLOCKCHAIN     = 0x2165D41aF0d8d5034b9c266597c1A415FA0253bd;
    address internal constant MHONKASALOTEEMULAU = 0x97Fb39171ACd7C82c439b6158EA2F71D26ba383d;
    address internal constant GFXLABS            = 0xa6e8772af29b29B9202a073f8E36f447689BEef6;
    address internal constant JUSTINCASE         = 0xE070c2dCfcf6C6409202A8a210f71D51dbAe9473;
    address internal constant LBSBLOCKCHAIN      = 0xB83b3e9C8E3393889Afb272D354A7a3Bd1Fbcf5C;
    address internal constant CALBLOCKCHAIN      = 0x7AE109A63ff4DC852e063a673b40BED85D22E585;
    address internal constant BLOCKCHAINCOLUMBIA = 0xdC1F98682F4F8a5c6d54F345F448437b83f5E432;
    address internal constant FRONTIERRESEARCH   = 0xA2d55b89654079987CF3985aEff5A7Bd44DA15A8;
    address internal constant CHRISBLEC          = 0xa3f0AbB4Ba74512b5a736C5759446e9B50FDA170;
    address internal constant CODEKNIGHT         = 0x46dFcBc2aFD5DD8789Ef0737fEdb03489D33c428;
    address internal constant ONESTONE           = 0x4eFb12d515801eCfa3Be456B5F348D3CD68f9E8a;
    address internal constant PVL                = 0x6ebB1A9031177208A4CA50164206BF2Fa5ff7416;
    address internal constant CONSENSYS          = 0xE78658A8acfE982Fde841abb008e57e6545e38b3;

    function actions() public override {

        // ----- Core Unit DAI Budget Streams -----

        // VEST.restrict( Only recipient can request funds
        //     VEST.create(
        //         Recipient of vest,
        //         Total token amount of vest over period,
        //         Start timestamp of vest,
        //         Duration of the vesting period (in seconds),
        //         Length of cliff period (in seconds),
        //         Manager address
        //     )
        // );

        // DUX-001 | 2023-02-01 to 2024-01-31 | 1,611,420 DAI | 0x5A994D8428CCEbCC153863CCdA9D2Be6352f89ad
        // https://vote.makerdao.com/polling/QmdhJVvN#vote-breakdown
        MCD_VEST_DAI.restrict(
            MCD_VEST_DAI.create(
                DUX_WALLET,
                1_611_420 * WAD,
                FEB_01_2023,
                JAN_31_2024 - FEB_01_2023,
                0,
                address(0)
            )
        );

        // SES-001 | 2023-02-01 to 2024-01-31 | 3,199,200 DAI | 0x87AcDD9208f73bFc9207e1f6F0fDE906bcA95cc6
        // https://vote.makerdao.com/polling/QmegsRNC#vote-breakdown
        MCD_VEST_DAI.restrict(
            MCD_VEST_DAI.create(
                SES_WALLET,
                3_199_200 * WAD,
                FEB_01_2023,
                JAN_31_2024 - FEB_01_2023,
                0,
                address(0)
            )
        );

        // ------ Core Unit MKR Transfers -----
        // DECO-001 - 125.0 MKR - 0xF482D1031E5b172D42B2DAA1b6e5Cbf6519596f7
        // https://mips.makerdao.com/mips/details/MIP40c3SP36
        MKR.transfer(DECO_WALLET, 125 * WAD);

        // RISK-001 - 175.00 MKR - 0x5d67d5B1fC7EF4bfF31967bE2D2d7b9323c1521c
        // https://mips.makerdao.com/mips/details/MIP40c3SP25
        MKR.transfer(RISK_WALLET, 175 * WAD);

        // ORA-001 - 843.69 MKR - 0x2d09B7b95f3F312ba6dDfB77bA6971786c5b50Cf
        // https://forum.makerdao.com/t/psa-oracle-core-unit-mkr-distribution/19030
        MKR.transfer(ORA_WALLET, 843.69 * 100 * WAD / 100);

        // ----- MKR Vesting Stream ------
        // Increase allowance by new vesting delta
        MKR.approve(address(MCD_VEST_MKR), MKR.allowance(address(this), address(MCD_VEST_MKR)) + 675 ether);
// Vest for PE member
        MCD_VEST_MKR.restrict(
            MCD_VEST_MKR.create(
                0xa91c40621D63599b00476eC3e528E06940B03B9D, // usr
                675 ether,                                  // tot
                AUG_01_2022,                                // bgn
                APR_30_2025 - AUG_01_2022,                  // tau
                365 days,                                   // eta
                0xe2c16c308b843eD02B09156388Cb240cEd58C01c  // mgr
            )
        );

        // ----- Delegate Compensation for December 2022 -----
        // Link: https://forum.makerdao.com/t/recognized-delegate-compensation-december-2022/19313
        // StableNode - 12000 DAI - 0x3B91eBDfBC4B78d778f62632a4004804AC5d2DB0
        DssExecLib.sendPaymentFromSurplusBuffer(STABLENODE,          12_000);
        // schuppi - 12000 DAI - 0xCCffDBc38B1463847509dCD95e0D9AAf54D1c167
        DssExecLib.sendPaymentFromSurplusBuffer(ULTRASCHUPPI,        12_000);
        // Flip Flop Flap Delegate LLC - 12000 DAI - 0x688d508f3a6B0a377e266405A1583B3316f9A2B3
        DssExecLib.sendPaymentFromSurplusBuffer(FLIPFLOPFLAP,        12_000);
        // Flipside Crypto - 11400 DAI - 0x1ef753934C40a72a60EaB12A68B6f8854439AA78
        DssExecLib.sendPaymentFromSurplusBuffer(FLIPSIDE,            11_400);
        // Feedblack Loops LLC - 10808 DAI - 0x80882f2A36d49fC46C3c654F7f9cB9a2Bf0423e1
        DssExecLib.sendPaymentFromSurplusBuffer(FEEDBLACKLOOPS,      10_808);
        // Penn Blockchain - 10385 DAI - 0x2165d41af0d8d5034b9c266597c1a415fa0253bd
        DssExecLib.sendPaymentFromSurplusBuffer(PENNBLOCKCHAIN,      10_385);
        // mhonkasalo & teemulau - 9484 DAI - 0x97Fb39171ACd7C82c439b6158EA2F71D26ba383d
        DssExecLib.sendPaymentFromSurplusBuffer(MHONKASALOTEEMULAU,   9_484);
        // GFX Labs - 8903 DAI - 0xa6e8772af29b29B9202a073f8E36f447689BEef6
        DssExecLib.sendPaymentFromSurplusBuffer(GFXLABS,              8_903);
        // JustinCase - 7235 DAI - 0xE070c2dCfcf6C6409202A8a210f71D51dbAe9473
        DssExecLib.sendPaymentFromSurplusBuffer(JUSTINCASE,           7_235);
        // London Business School Blockchain - 3798 DAI - 0xB83b3e9C8E3393889Afb272D354A7a3Bd1Fbcf5C
        DssExecLib.sendPaymentFromSurplusBuffer(LBSBLOCKCHAIN,        3_798);
        // CalBlockchain - 3421 DAI - 0x7AE109A63ff4DC852e063a673b40BED85D22E585
        DssExecLib.sendPaymentFromSurplusBuffer(CALBLOCKCHAIN,        3_421);
        // Blockchain@Columbia - 2851 DAI - 0xdC1F98682F4F8a5c6d54F345F448437b83f5E432
        DssExecLib.sendPaymentFromSurplusBuffer(BLOCKCHAINCOLUMBIA,   2_851);
        // Frontier Research LLC - 2285 DAI - 0xA2d55b89654079987CF3985aEff5A7Bd44DA15A8
        DssExecLib.sendPaymentFromSurplusBuffer(FRONTIERRESEARCH,     2_285);
        // Chris Blec - 1334 DAI - 0xa3f0AbB4Ba74512b5a736C5759446e9B50FDA170
        DssExecLib.sendPaymentFromSurplusBuffer(CHRISBLEC,            1_334);
        // CodeKnight - 355 DAI - 0x46dFcBc2aFD5DD8789Ef0737fEdb03489D33c428
        DssExecLib.sendPaymentFromSurplusBuffer(CODEKNIGHT,             355);
        // ONESTONE - 342 DAI - 0x4eFb12d515801eCfa3Be456B5F348D3CD68f9E8a
        DssExecLib.sendPaymentFromSurplusBuffer(ONESTONE,               342);
        // pvl - 56 DAI - 0x6ebB1A9031177208A4CA50164206BF2Fa5ff7416
        DssExecLib.sendPaymentFromSurplusBuffer(PVL,                     56);
        // ConsenSys - 33 DAI - 0xE78658A8acfE982Fde841abb008e57e6545e38b3
        DssExecLib.sendPaymentFromSurplusBuffer(CONSENSYS,               33);

    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) {}
}
