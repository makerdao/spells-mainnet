// SPDX-License-Identifier: AGPL-3.0-or-later
//
// Copyright (C) 2021-2022 Dai Foundation
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

import { DssSpellCollateralOnboardingAction } from "./DssSpellCollateralOnboarding.sol";

interface DssVestLike {
    function create(address, uint256, uint256, uint256, uint256, address) external returns (uint256);
    function restrict(uint256) external;
    function yank(uint256) external;
}

contract DssSpellAction is DssAction, DssSpellCollateralOnboardingAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/<tbd>/2024%2C%202022.md -q -O - 2>/dev/null)"
    string public constant override description =
        "2022-01-28 MakerDAO Executive Spell | Hash: 0x";

    address constant MCD_VEST_DAI          = 0x2Cc583c0AaCDaC9e23CB601fDA8F1A0c56Cdcb71;
    address constant MCD_VEST_MKR_TREASURY = 0x6D635c8d08a1eA2F1687a5E46b666949c977B7dd;


    address constant SNE_001_WALLET        = 0x6D348f18c88D45243705D4fdEeB6538c6a9191F1;
    address constant TECH_001_WALLET       = 0x2dC0420A736D1F40893B9481D8968E4D7424bC0B;
    address constant ORA_001_GAS           = 0x2B6180b413511ce6e3DA967Ec503b2Cc19B78Db6;
    address constant ORA_001_GAS_EMERGENCY = 0x1A5B692029b157df517b7d21a32c8490b8692b0f;
    address constant DUX_001_WALLET        = 0x5A994D8428CCEbCC153863CCdA9D2Be6352f89ad;
    address constant SES_001_WALLET        = 0x87AcDD9208f73bFc9207e1f6F0fDE906bcA95cc6;
    address constant SF_001_WALLET         = 0xf737C76D2B358619f7ef696cf3F94548fEcec379;
    address constant RWF_001_WALLET        = 0x96d7b01Cc25B141520C717fa369844d34FF116ec;
    address constant SF_001_VEST_01        = 0xBC7fd5AA2016C3e2C8F0dBf4e919485C6BBb59e2;
    address constant SF_001_VEST_02        = 0xCC81578d163A04ea8d2EaE6904d0C8E61A84E1Bb;


    uint256 constant APR_01_2021 = 1617235200;
    uint256 constant SEP_01_2021 = 1630454400;
    uint256 constant FEB_01_2022 = 1643673600;
    uint256 constant DEC_31_2022 = 1672444800;
    uint256 constant JAN_31_2023 = 1675123200;
    uint256 constant JUL_31_2023 = 1690761600;


    // Math
    uint256 constant MILLION = 10**6;
    uint256 constant WAD = 10**18;

    // Turn office hours off
    function officeHours() public override returns (bool) {
        return false;
    }

    function actions() public override {

        // Includes changes from the DssSpellCollateralOnboardingAction
        // onboardNewCollaterals();

        // Revoking Content Production Budget (MKT-001)
        // https://mips.makerdao.com/mips/details/MIP40c3SP49
        DssVestLike(MCD_VEST_DAI).yank(20);


        //Core Unit DAI Budget Transfers
        // https://mips.makerdao.com/mips/details/MIP40c3SP47
        DssExecLib.sendPaymentFromSurplusBuffer(SNE_001_WALLET, 229_792);
        // https://mips.makerdao.com/mips/details/MIP40c3SP53
        DssExecLib.sendPaymentFromSurplusBuffer(TECH_001_WALLET, 1_069_250);
        // https://mips.makerdao.com/mips/details/MIP40c3SP45
        DssExecLib.sendPaymentFromSurplusBuffer(ORA_001_GAS, 6_966_070);
        // https://mips.makerdao.com/mips/details/MIP40c3SP45
        DssExecLib.sendPaymentFromSurplusBuffer(ORA_001_GAS_EMERGENCY, 1_805_407);


        // Core Unit DAI Budget Streams
        // https://mips.makerdao.com/mips/details/MIP40c3SP52
        DssVestLike(MCD_VEST_DAI).restrict(
            DssVestLike(MCD_VEST_DAI).create(DUX_001_WALLET,   1_934_300 * WAD, FEB_01_2022, JAN_31_2023 - FEB_01_2022,            0, address(0))
        );
        // https://mips.makerdao.com/mips/details/MIP40c3SP55
        DssVestLike(MCD_VEST_DAI).restrict(
            DssVestLike(MCD_VEST_DAI).create(SES_001_WALLET,   5_844_444 * WAD, FEB_01_2022, JAN_31_2023 - FEB_01_2022,            0, address(0))
        );
        // https://mips.makerdao.com/mips/details/MIP40c3SP47
        DssVestLike(MCD_VEST_DAI).restrict(
            DssVestLike(MCD_VEST_DAI).create(SNE_001_WALLET,     257_500 * WAD, FEB_01_2022, JUL_31_2023 - FEB_01_2022,            0, address(0))
        );
        // https://mips.makerdao.com/mips/details/MIP40c3SP53
        DssVestLike(MCD_VEST_DAI).restrict(
            DssVestLike(MCD_VEST_DAI).create(TECH_001_WALLET,  2_566_200 * WAD, FEB_01_2022, JAN_31_2023 - FEB_01_2022,            0, address(0))
        );
        // https://mips.makerdao.com/mips/details/MIP40c3SP46
        DssVestLike(MCD_VEST_DAI).restrict(
            DssVestLike(MCD_VEST_DAI).create(SF_001_WALLET,      494_502 * WAD, FEB_01_2022, JUL_31_2023 - FEB_01_2022,            0, address(0))
        );
        // - Forum Post TODO
        DssVestLike(MCD_VEST_DAI).yank(15);
        DssVestLike(MCD_VEST_DAI).restrict(
            DssVestLike(MCD_VEST_DAI).create(RWF_001_WALLET,   1_705_000 * WAD, FEB_01_2022, DEC_31_2022 - FEB_01_2022,            0, address(0))
        );


        // Core Unit MKR Vesting Streams (sourced from treasury)
        // https://mips.makerdao.com/mips/details/MIP40c3SP48
        DssVestLike(MCD_VEST_MKR_TREASURY).restrict(
            DssVestLike(MCD_VEST_MKR_TREASURY).create(
                SF_001_VEST_01,  // Participant
                240 * WAD,       // Amount
                SEP_01_2021,     // Begin date
                3 * 365 days,    // Vest duration
                365 days,        // Cliff time
                SF_001_WALLET    // Manager
            )
        );
        // https://mips.makerdao.com/mips/details/MIP40c3SP48
        DssVestLike(MCD_VEST_MKR_TREASURY).restrict(
            DssVestLike(MCD_VEST_MKR_TREASURY).create(
                SF_001_VEST_02,
                240 * WAD,
                APR_01_2021,
                3 * 365 days,
                365 days,
                SF_001_WALLET
            )
        );

    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) public {}
}
