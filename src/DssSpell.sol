// SPDX-License-Identifier: AGPL-3.0-or-later
// 
// Copyright (C) 2021 Dai Foundation
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


pragma solidity 0.6.12;

import "dss-exec-lib/DssExec.sol";
import "dss-exec-lib/DssAction.sol";

interface DssVestLike {
    function create(address, uint256, uint256, uint256, uint256, address) external returns (uint256);
    function file(bytes32, uint256) external;
    function restrict(uint256) external;
}

contract DssSpellAction is DssAction {

    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/989a2ee92df41ef7aee75a1ccdbedbe6071e28a7/governance/votes/Executive%20vote%20-%20October%201%2C%202021.md -q -O - 2>/dev/null)"
    string public constant override description =
        "2021-10-01 MakerDAO Executive Spell | Hash: 0x240a8946c4c5f2463a1fcd6c7036409087af1c2407d502330e27c9149bfa7ed7";

    // GovAlpha Core Unit
    address constant GOV_ALPHA_WALLET = 0x01D26f8c5cC009868A4BF66E268c17B057fF7A73;

    uint256 constant OCT_01_2021 = 1633046400;
    uint256 constant MAR_03_2022 = 1648684800;

    // Math
    uint256 constant MILLION = 10 ** 6;
    uint256 constant WAD     = 10 ** 18;

    // Turn on office hours
    function officeHours() public override returns (bool) {
        return true;
    }

    function actions() public override {
        address MCD_CLIP_USDT_A = DssExecLib.getChangelogAddress("MCD_CLIP_USDT_A");
        address MCD_VEST_DAI    = DssExecLib.getChangelogAddress("MCD_VEST_DAI");

        // Offboard USDT-A
        // https://vote.makerdao.com/polling/QmRNwrTy?network=mainnet#vote-breakdown

        // 15 thousand DAI maximum liquidation amount
        DssExecLib.setIlkMaxLiquidationAmount("USDT-A", 15_000);

        // flip breaker to enable liquidations
        DssExecLib.setValue(MCD_CLIP_USDT_A, "stopped", 0);

        // authorize breaker
        DssExecLib.authorize(MCD_CLIP_USDT_A, DssExecLib.clipperMom());

        // set liquidation ratio to 300%
        DssExecLib.setIlkLiquidationRatio("USDT-A", 30000);

        // remove liquidation penalty
        DssExecLib.setIlkLiquidationPenalty("USDT-A", 0);


        // DssVestLike(VEST).restrict( Only recipient can request funds
        //     DssVestLike(VEST).create(
        //         Recipient of vest,
        //         Total token amount of vest over period,
        //         Start timestamp of vest,
        //         Duration of the vesting period (in seconds),
        //         Length of cliff period (in seconds),
        //         Manager address
        //     )
        // );

        // GOV-001 | 2021-10-01 to 2022-03-31 | 538,400 DAI | 0x01D26f8c5cC009868A4BF66E268c17B057fF7A73
        // https://vote.makerdao.com/polling/QmVtkcqW?network=mainnet#poll-detail
        DssVestLike(MCD_VEST_DAI).restrict(
            DssVestLike(MCD_VEST_DAI).create(
                GOV_ALPHA_WALLET,
                538_400 * WAD,
                OCT_01_2021,
                MAR_03_2022 - OCT_01_2021,
                0,
                address(0)
            )
        );

        // SNE-001 | 2021-10-01 to 2021-12-31 | 135,375 DAI | 0x6D348f18c88D45243705D4fdEeB6538c6a9191F1
        // https://vote.makerdao.com/polling/QmesWgnC?network=mainnet

        // SH-001 | 2021-10-01 to 2021-12-31 | 58,000 DAI | 0x955993Df48b0458A01cfB5fd7DF5F5DCa6443550
        // https://vote.makerdao.com/polling/Qme27ywB?network=mainnet#vote-breakdown
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) public {}
}
