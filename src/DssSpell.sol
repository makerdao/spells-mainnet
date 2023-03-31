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
}

interface PauseLike {
    function setDelay(uint256) external;
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
        DssExecLib.sendPaymentFromSurplusBuffer(LBSBLOCKCHAIN,       3_045);
        DssExecLib.sendPaymentFromSurplusBuffer(HKUSTEPI,            2_607);
        DssExecLib.sendPaymentFromSurplusBuffer(JUSTINCASE,          2_488);
        DssExecLib.sendPaymentFromSurplusBuffer(FRONTIERRESEARCH,    2_421);
        DssExecLib.sendPaymentFromSurplusBuffer(CODEKNIGHT,            630);
        DssExecLib.sendPaymentFromSurplusBuffer(FLIPSIDE,              541);
        DssExecLib.sendPaymentFromSurplusBuffer(ONESTONE,              314);
        DssExecLib.sendPaymentFromSurplusBuffer(CONSENSYS,             154);
        DssExecLib.sendPaymentFromSurplusBuffer(ACREINVEST,             33);
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) {}
}
