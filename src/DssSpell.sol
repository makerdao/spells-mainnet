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

contract DssSpellAction is DssAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: cast keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/TODO/governance/votes/TODO.md -q -O - 2>/dev/null)"
    string public constant override description =
        "2023-02-02 MakerDAO Executive Spell | Hash: 0x0";

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

    address internal constant TECH_WALLET = 0x2dC0420A736D1F40893B9481D8968E4D7424bC0B;
    address internal constant COM_WALLET  = 0x1eE3ECa7aEF17D1e74eD7C447CcBA61aC76aDbA9;
    address internal constant SF01_WALLET = 0x4Af6f22d454581bF31B2473Ebe25F5C6F55E028D;

    function actions() public override {
        // Tech-Ops DAI Transfer
        // https://vote.makerdao.com/polling/QmUMnuGb
        DssExecLib.sendPaymentFromSurplusBuffer(TECH_WALLET, 138_894);

        // GovComms offboarding
        // https://vote.makerdao.com/polling/QmV9iktK 
        // https://forum.makerdao.com/t/mip39c3-sp7-core-unit-offboarding-com-001/19068/65
        DssExecLib.sendPaymentFromSurplusBuffer(COM_WALLET, 131_200);
        DssExecLib.sendPaymentFromSurplusBuffer(0x50D2f29206a76aE8a9C2339922fcBCC4DfbdD7ea, 1_336);
        DssExecLib.sendPaymentFromSurplusBuffer(0xeD27986bf84Fa8E343aA9Ff90307291dAeF234d3, 1_983);
        DssExecLib.sendPaymentFromSurplusBuffer(0x3dfE26bEDA4282ECCEdCaF2a0f146712712e81EA, 715);
        DssExecLib.sendPaymentFromSurplusBuffer(0x74520D1690348ba882Af348223A30D760BCbD72a, 1_376);
        DssExecLib.sendPaymentFromSurplusBuffer(0x471C5806cadAFB297D9b95B914B65f626fDCD1a7, 583);
        DssExecLib.sendPaymentFromSurplusBuffer(0x051cCee0CfBF1Fe9BD891117E85bEbDFa42aFaA9, 1_026);
        DssExecLib.sendPaymentFromSurplusBuffer(0x1c138352C779af714b6cE328C9d962E5c82EBA07, 631);
        DssExecLib.sendPaymentFromSurplusBuffer(0x55f2E8728cFCCf260040cfcc24E14A6047fF4d31, 255);
        DssExecLib.sendPaymentFromSurplusBuffer(0xE004DAabEfe0322Ac1ab46A3CF382a2A0bA81Ab4, 1_758);
        DssExecLib.sendPaymentFromSurplusBuffer(0xC2bE81CeB685eea53c77975b5F9c5f82641deBC8, 3_013);
        DssExecLib.sendPaymentFromSurplusBuffer(0xdB7c1777b5d4502b3d1228c2449F1816EB507748, 2_683);

        // SPF Funding: Expanded SF-001 Domain Work
        // https://vote.makerdao.com/polling/QmTjgcHY
        DssExecLib.sendPaymentFromSurplusBuffer(SF01_WALLET, 209_000);
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) {}
}
