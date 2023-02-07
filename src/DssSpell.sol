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

contract DssSpellAction is DssAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: cast keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/TODO -q -O - 2>/dev/null)"
    string public constant override description =
        "2023-02-08 MakerDAO Executive Spell | Hash: 0x";

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
    uint256 internal constant WAD     = 10 ** 18;

    address immutable public MCD_VEST_DAI = DssExecLib.getChangelogAddress("MCD_VEST_DAI");

    // Wed 01 Feb 2023 12:00:00 AM UTC
    uint256 constant public FEB_01_2023 = 1675209600;
    // Mon 31 Jul 2023 11:59:59 PM UTC
    uint256 constant public AUG_01_2023 = 1690847999;

    address constant public CHAINLINK_AUTOMATION = 0x5E9dfc5fe95A0754084fB235D58752274314924b;

    address constant public COLDIRON = 0x6634e3555DBF4B149c5AEC99D579A2469015AEca;
    address constant public FLIPFLOPFLAP = 0x688d508f3a6B0a377e266405A1583B3316f9A2B3;
    address constant public GFXLABS = 0xa6e8772af29b29B9202a073f8E36f447689BEef6;
    address constant public FLIPSIDE = 0x1ef753934C40a72a60EaB12A68B6f8854439AA78;
    address constant public MHONKASALOTEEMULAU = 0x97Fb39171ACd7C82c439b6158EA2F71D26ba383d;
    address constant public FEEDBLACKLOOPS = 0x80882f2A36d49fC46C3c654F7f9cB9a2Bf0423e1;
    address constant public PENNBLOCKCHAIN = 0x2165D41aF0d8d5034b9c266597c1A415FA0253bd;
    address constant public JUSTINCASE = 0xE070c2dCfcf6C6409202A8a210f71D51dbAe9473;
    address constant public STABLENODE = 0x3B91eBDfBC4B78d778f62632a4004804AC5d2DB0;
    address constant public LBSBLOCKCHAIN = 0xB83b3e9C8E3393889Afb272D354A7a3Bd1Fbcf5C;
    address constant public FRONTIERRESEARCH = 0xA2d55b89654079987CF3985aEff5A7Bd44DA15A8;
    address constant public BLOCKCHAINCOLUMBIA = 0xdC1F98682F4F8a5c6d54F345F448437b83f5E432;
    address constant public CHRISBLEC = 0xa3f0AbB4Ba74512b5a736C5759446e9B50FDA170;
    address constant public CODEKNIGHT = 0x46dFcBc2aFD5DD8789Ef0737fEdb03489D33c428;
    address constant public ONESTONE = 0x4eFb12d515801eCfa3Be456B5F348D3CD68f9E8a;
    address constant public CONSENSYS = 0xE78658A8acfE982Fde841abb008e57e6545e38b3;
    address constant public PVL = 0x6ebB1A9031177208A4CA50164206BF2Fa5ff7416;


    function actions() public override {
        // Dust Parameter Changes
        // https://vote.makerdao.com/polling/QmRfegL4#vote-breakdown

        // Reduce dust for ETH-A, WBTC-A, and WSTETH-A to 7,500 DAI.
        DssExecLib.setIlkMinVaultAmount("ETH-A", 7_500);
        DssExecLib.setIlkMinVaultAmount("WBTC-A", 7_500);
        DssExecLib.setIlkMinVaultAmount("WSTETH-A", 7_500);

        // Reduce dust for ETH-C, WBTC-C, and WSTETH-B to 3,500 DAI.
        DssExecLib.setIlkMinVaultAmount("ETH-C", 3_500);
        DssExecLib.setIlkMinVaultAmount("WBTC-C", 3_500);
        DssExecLib.setIlkMinVaultAmount("WSTETH-B", 3_500);

        // Reduce dust for ETH-B and WBTC-B to 25,000 DAI.
        DssExecLib.setIlkMinVaultAmount("ETH-B", 25_000);
        DssExecLib.setIlkMinVaultAmount("WBTC-B", 25_000);


        // Chainlink Automation Keeper Network Stream Setup
        // https://vote.makerdao.com/polling/QmXeWcrX
        // Note: unrestricted stream
        VestLike(MCD_VEST_DAI).create(
            CHAINLINK_AUTOMATION,                                    // usr
            181_000 * WAD,                                           // tot
            FEB_01_2023,                                             // bgn
            AUG_01_2023 - FEB_01_2023,                               // tau
            0,                                                       // eta
            address(0)                                               // mgr
        );


        // Recognized Delegate Compensation
        // https://mips.makerdao.com/mips/details/MIP61
        DssExecLib.sendPaymentFromSurplusBuffer(COLDIRON,            12_000);
        DssExecLib.sendPaymentFromSurplusBuffer(FLIPFLOPFLAP,        12_000);
        DssExecLib.sendPaymentFromSurplusBuffer(GFXLABS,             11_653);
        DssExecLib.sendPaymentFromSurplusBuffer(FLIPSIDE,            11_407);
        DssExecLib.sendPaymentFromSurplusBuffer(MHONKASALOTEEMULAU,  11_064);
        DssExecLib.sendPaymentFromSurplusBuffer(FEEDBLACKLOOPS,      10_807);
        DssExecLib.sendPaymentFromSurplusBuffer(PENNBLOCKCHAIN,      10_738);
        DssExecLib.sendPaymentFromSurplusBuffer(JUSTINCASE,           9_588);
        DssExecLib.sendPaymentFromSurplusBuffer(STABLENODE,           9_496);
        DssExecLib.sendPaymentFromSurplusBuffer(LBSBLOCKCHAIN,        3_797);
        DssExecLib.sendPaymentFromSurplusBuffer(FRONTIERRESEARCH,     2_419);
        DssExecLib.sendPaymentFromSurplusBuffer(BLOCKCHAINCOLUMBIA,   1_656);
        DssExecLib.sendPaymentFromSurplusBuffer(CHRISBLEC,            1_001);
        DssExecLib.sendPaymentFromSurplusBuffer(CODEKNIGHT,             939);
        DssExecLib.sendPaymentFromSurplusBuffer(ONESTONE,               352);
        DssExecLib.sendPaymentFromSurplusBuffer(CONSENSYS,               96);
        DssExecLib.sendPaymentFromSurplusBuffer(PVL,                     35);
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) {}
}
