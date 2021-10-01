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
    function restrict(uint256) external;
}

interface GemLike {
    function transfer(address, uint256) external returns (bool);
}

contract DssSpellAction is DssAction {

    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/989a2ee92df41ef7aee75a1ccdbedbe6071e28a7/governance/votes/Executive%20vote%20-%20October%201%2C%202021.md -q -O - 2>/dev/null)"
    string public constant override description =
        "2021-10-01 MakerDAO Executive Spell | Hash: 0x240a8946c4c5f2463a1fcd6c7036409087af1c2407d502330e27c9149bfa7ed7";

    // wallet addresses
    address constant GOV_ALPHA_WALLET = 0x01D26f8c5cC009868A4BF66E268c17B057fF7A73;
    address constant SNE_WALLET       = 0x6D348f18c88D45243705D4fdEeB6538c6a9191F1;
    address constant SH_WALLET        = 0x955993Df48b0458A01cfB5fd7DF5F5DCa6443550;
    address constant SES_WALLET       = 0x87AcDD9208f73bFc9207e1f6F0fDE906bcA95cc6;
    address constant DUX_WALLET       = 0x5A994D8428CCEbCC153863CCdA9D2Be6352f89ad;
    address constant RISK_WALLET      = 0x5d67d5B1fC7EF4bfF31967bE2D2d7b9323c1521c;

    uint256 constant OCT_01_2021 = 1633046400;
    uint256 constant DEC_31_2021 = 1640908800;
    uint256 constant MAR_31_2022 = 1648684800;

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
                MAR_31_2022 - OCT_01_2021,
                0,
                address(0)
            )
        );

        // SNE-001 | 2021-10-01 to 2021-12-31 | 135,375 DAI | 0x6D348f18c88D45243705D4fdEeB6538c6a9191F1
        // https://vote.makerdao.com/polling/QmesWgnC?network=mainnet
        DssVestLike(MCD_VEST_DAI).restrict(
            DssVestLike(MCD_VEST_DAI).create(
                SNE_WALLET,
                135_375 * WAD,
                OCT_01_2021,
                DEC_31_2021 - OCT_01_2021,
                0,
                address(0)
            )
        );

        // SH-001 | 2021-10-01 to 2021-12-31 | 58,000 DAI | 0x955993Df48b0458A01cfB5fd7DF5F5DCa6443550
        // https://vote.makerdao.com/polling/Qme27ywB?network=mainnet#vote-breakdown
        DssVestLike(MCD_VEST_DAI).restrict(
            DssVestLike(MCD_VEST_DAI).create(
                SH_WALLET,
                58_000 * WAD,
                OCT_01_2021,
                DEC_31_2021 - OCT_01_2021,
                0,
                address(0)
            )
        );


        // direct payments

        // SES-001 - 307,631 DAI - 0x87AcDD9208f73bFc9207e1f6F0fDE906bcA95cc6
        // https://vote.makerdao.com/polling/QmSkTmAx?network=mainnet
        DssExecLib.sendPaymentFromSurplusBuffer(SES_WALLET, 307_631);

        // DUX-001 - 483,575 DAI - 0x5A994D8428CCEbCC153863CCdA9D2Be6352f89ad
        // https://vote.makerdao.com/polling/QmSYLL9K?network=mainnet
        DssExecLib.sendPaymentFromSurplusBuffer(DUX_WALLET, 483_575);

        // SNE-001 - 75,000 DAI - 0x6D348f18c88D45243705D4fdEeB6538c6a9191F1
        // https://vote.makerdao.com/polling/QmesWgnC?network=mainnet
        DssExecLib.sendPaymentFromSurplusBuffer(SNE_WALLET, 75_000);

        // SH-001 - 106,500 DAI - 0x955993Df48b0458A01cfB5fd7DF5F5DCa6443550
        // https://vote.makerdao.com/polling/Qme27ywB?network=mainnet
        DssExecLib.sendPaymentFromSurplusBuffer(SH_WALLET, 106_500);


        // direct MKR distribution

        // Send 300 MKR from treasury to Risk
        // RISK-001 - 300 MKR (from treasury) - 0x5d67d5B1fC7EF4bfF31967bE2D2d7b9323c1521c
        // https://vote.makerdao.com/polling/QmUAXKm4?network=mainnet
        GemLike(DssExecLib.getChangelogAddress("MCD_GOV")).transfer(RISK_WALLET, 300 * WAD);

    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) public {}
}
