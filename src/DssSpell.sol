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

import "dss-interfaces/dapp/DSTokenAbstract.sol";

contract DssSpellAction is DssAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: cast keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/3ccd2e061217ef336e1cf1d71b9cfcce36548f74/governance/votes/Executive%20vote%20-%20March%208%2C%202023.md -q -O - 2>/dev/null)"
    string public constant override description =
        "2023-03-08 MakerDAO Executive Spell | Hash: 0x1a2df7f087facb40bb6bf6b60f9853045793df1f2e664d29c2a660cb3e9c2a0c";

    // Turn office hours on
    function officeHours() public pure override returns (bool) {
        return true;
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

    uint256 constant ZERO_SEVENTY_FIVE_PCT_RATE = 1000000000236936036262880196;
    uint256 constant ONE_PCT_RATE               = 1000000000315522921573372069;
    uint256 constant ONE_FIVE_PCT_RATE          = 1000000000472114805215157978;

    uint256 constant MILLION = 10 ** 6;
    uint256 constant RAY     = 10 ** 27;

    address constant GRO_WALLET         = 0x7800C137A645c07132886539217ce192b9F0528e;
    address constant TECH_WALLET        = 0x2dC0420A736D1F40893B9481D8968E4D7424bC0B;
    address constant DECO_WALLET        = 0xF482D1031E5b172D42B2DAA1b6e5Cbf6519596f7;
    address constant RISK_WALLET_VEST   = 0x5d67d5B1fC7EF4bfF31967bE2D2d7b9323c1521c;

    address constant COLDIRON           = 0x6634e3555DBF4B149c5AEC99D579A2469015AEca;
    address constant FLIPFLOPFLAP       = 0x688d508f3a6B0a377e266405A1583B3316f9A2B3;
    address constant GFXLABS            = 0xa6e8772af29b29B9202a073f8E36f447689BEef6;
    address constant MHONKASALOTEEMULAU = 0x97Fb39171ACd7C82c439b6158EA2F71D26ba383d;
    address constant PENNBLOCKCHAIN     = 0x2165D41aF0d8d5034b9c266597c1A415FA0253bd;
    address constant FEEDBLACKLOOPS     = 0x80882f2A36d49fC46C3c654F7f9cB9a2Bf0423e1;
    address constant FLIPSIDE           = 0x1ef753934C40a72a60EaB12A68B6f8854439AA78;
    address constant JUSTINCASE         = 0xE070c2dCfcf6C6409202A8a210f71D51dbAe9473;
    address constant STABLELAB          = 0x3B91eBDfBC4B78d778f62632a4004804AC5d2DB0;
    address constant FRONTIERRESEARCH   = 0xA2d55b89654079987CF3985aEff5A7Bd44DA15A8;
    address constant CHRISBLEC          = 0xa3f0AbB4Ba74512b5a736C5759446e9B50FDA170;
    address constant CODEKNIGHT         = 0xf6006d4cF95d6CB2CD1E24AC215D5BF3bca81e7D;
    address constant ONESTONE           = 0x4eFb12d515801eCfa3Be456B5F348D3CD68f9E8a;
    address constant HKUSTEPI           = 0x2dA0d746938Efa28C7DC093b1da286b3D8bAC34a;

    address immutable MCD_SPOT = DssExecLib.spotter();
    address immutable MCD_GOV  = DssExecLib.mkr();

    function actions() public override {
        // CRVV1ETHSTETH-A Liquidation Parameter Changes
        // https://forum.makerdao.com/t/crvv1ethsteth-a-liquidation-parameters-adjustment/20020
        DssExecLib.setIlkMaxLiquidationAmount("CRVV1ETHSTETH-A", 5 * MILLION);
        DssExecLib.setStartingPriceMultiplicativeFactor("CRVV1ETHSTETH-A", 110_00);
        DssExecLib.setAuctionTimeBeforeReset("CRVV1ETHSTETH-A", 7200);
        DssExecLib.setAuctionPermittedDrop("CRVV1ETHSTETH-A", 45_00);

        // Stablecoin vault offboarding
        // https://vote.makerdao.com/polling/QmemXoCi#poll-detail
        DssExecLib.setValue(MCD_SPOT, "USDC-A",   "mat", 15 * RAY); // 1500% collateralization ratio
        DssExecLib.setValue(MCD_SPOT, "PAXUSD-A", "mat", 15 * RAY);
        DssExecLib.setValue(MCD_SPOT, "GUSD-A",   "mat", 15 * RAY);
        DssExecLib.updateCollateralPrice("USDC-A");
        DssExecLib.updateCollateralPrice("PAXUSD-A");
        DssExecLib.updateCollateralPrice("GUSD-A");

        // MOMC Parameter Changes
        // https://vote.makerdao.com/polling/QmXGgakY#poll-detail
        DssExecLib.setIlkStabilityFee("ETH-C", ZERO_SEVENTY_FIVE_PCT_RATE, true);
        DssExecLib.setIlkStabilityFee("WSTETH-B", ZERO_SEVENTY_FIVE_PCT_RATE, true);
        DssExecLib.setIlkStabilityFee("WBTC-C", ONE_PCT_RATE, true);
        DssExecLib.setIlkStabilityFee("YFI-A", ONE_FIVE_PCT_RATE, true);
        DssExecLib.setIlkAutoLineDebtCeiling("RETH-A", 20 * MILLION);
        DssExecLib.setIlkAutoLineDebtCeiling("YFI-A", 4 * MILLION);
        DssExecLib.setIlkAutoLineDebtCeiling("DIRECT-COMPV2-DAI", 70 * MILLION);

        // DAI Budget Transfer
        // https://mips.makerdao.com/mips/details/MIP40c3SP70
        DssExecLib.sendPaymentFromSurplusBuffer(GRO_WALLET, 648_134);

        // MKR Vesting Transfers
        // https://mips.makerdao.com/mips/details/MIP40c3SP54
        DSTokenAbstract(MCD_GOV).transfer(TECH_WALLET, 67.9579 ether);
        // https://mips.makerdao.com/mips/details/MIP40c3SP36
        DSTokenAbstract(MCD_GOV).transfer(DECO_WALLET, 125 ether);
        // https://mips.makerdao.com/mips/details/MIP40c3SP25
        DSTokenAbstract(MCD_GOV).transfer(RISK_WALLET_VEST, 175 ether);

        // Delegate Compensation for February
        // https://forum.makerdao.com/t/recognized-delegate-compensation-february-2023/20033
        DssExecLib.sendPaymentFromSurplusBuffer(COLDIRON,           12_000);
        DssExecLib.sendPaymentFromSurplusBuffer(FLIPFLOPFLAP,       12_000);
        DssExecLib.sendPaymentFromSurplusBuffer(GFXLABS,            12_000);
        DssExecLib.sendPaymentFromSurplusBuffer(MHONKASALOTEEMULAU, 11_447);
        DssExecLib.sendPaymentFromSurplusBuffer(PENNBLOCKCHAIN,     11_178);
        DssExecLib.sendPaymentFromSurplusBuffer(FEEDBLACKLOOPS,     10_802);
        DssExecLib.sendPaymentFromSurplusBuffer(FLIPSIDE,           10_347);
        DssExecLib.sendPaymentFromSurplusBuffer(JUSTINCASE,          8_680);
        DssExecLib.sendPaymentFromSurplusBuffer(STABLELAB,           3_961);
        DssExecLib.sendPaymentFromSurplusBuffer(FRONTIERRESEARCH,    2_455);
        DssExecLib.sendPaymentFromSurplusBuffer(CHRISBLEC,             951);
        DssExecLib.sendPaymentFromSurplusBuffer(CODEKNIGHT,            939);
        DssExecLib.sendPaymentFromSurplusBuffer(ONESTONE,              360);
        DssExecLib.sendPaymentFromSurplusBuffer(HKUSTEPI,              348);
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) {}
}
