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
// Enable ABIEncoderV2 when onboarding collateral
// pragma experimental ABIEncoderV2;
import "dss-exec-lib/DssExec.sol";
import "dss-exec-lib/DssAction.sol";

import { DssSpellCollateralOnboardingAction } from "./DssSpellCollateralOnboarding.sol";

interface DssVestLike {
    function cap() external view returns (uint256);
    function chainlog() external view returns (address);
    function daiJoin() external view returns (address);
    function ids() external view returns (uint256);
    function vat() external view returns (address);
    function create(address, uint256, uint256, uint256, uint256, address) external returns (uint256);
    function file(bytes32, uint256) external;
    function rely(address) external;
    function restrict(uint256) external;
}

contract DssSpellAction is DssAction, DssSpellCollateralOnboardingAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: cast keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/f76fcca7cb8ca0db328c1241d067a0bb9b30a16e/governance/votes/Executive%20Vote%20-%20April%2029%2C%202022.md -q -O - 2>/dev/null)"
    string public constant override description =
        "2022-04-29 MakerDAO Executive Spell | Hash: 0x707ebde4cd135ef70155726ab88d178c20fbaad79bd5d1faa32313d6247d7bbf";

    address constant MCD_VEST_DAI = 0xa4c22f0e25C6630B2017979AcF1f865e94695C4b;

    address constant COM_WALLET     = 0x1eE3ECa7aEF17D1e74eD7C447CcBA61aC76aDbA9;
    address constant COM_EF_WALLET  = 0x99E1696A680c0D9f426Be20400E468089E7FDB0f;
    address constant EVENTS_WALLET  = 0x3D274fbAc29C92D2F624483495C0113B44dBE7d2;
    address constant DIN_WALLET     = 0x7327Aed0Ddf75391098e8753512D8aEc8D740a1F;
    address constant PE_WALLET      = 0xe2c16c308b843eD02B09156388Cb240cEd58C01c;
    address constant SH_WALLET      = 0x955993Df48b0458A01cfB5fd7DF5F5DCa6443550;

    uint256 constant MAY_01_2022 = 1651363200;
    uint256 constant JUL_01_2022 = 1656633600;
    uint256 constant JAN_01_2023 = 1672531200;
    uint256 constant MAY_01_2023 = 1682899200;

    // Math

    uint256 constant WAD = 10 ** 18;

    // Many of the settings that change weekly rely on the rate accumulator
    // described at https://docs.makerdao.com/smart-contract-modules/rates-module
    // To check this yourself, use the following rate calculation (example 8%):
    //
    // $ bc -l <<< 'scale=27; e( l(1.08)/(60 * 60 * 24 * 365) )'
    //
    // A table of rates can be found at
    //    https://ipfs.io/ipfs/QmPgPVrVxDCGyNR5rGp9JC5AUxppLzUAqvncRJDcxQnX1u
    //

    // --- Rates ---
    //uint256 constant FOUR_FIVE_PCT_RATE      = 1000000001395766281313196627;

    function actions() public override {
        // ---------------------------------------------------------------------
        // Includes changes from the DssSpellCollateralOnboardingAction
        // onboardNewCollaterals();

        // Verify new vesting contract was correctly deployed
        address MCD_VEST_DAI_LEGACY = DssExecLib.getChangelogAddress("MCD_VEST_DAI");
        require(DssVestLike(MCD_VEST_DAI).ids() == 0, "DssSpell/non-empty-vesting-contract");
        require(DssVestLike(MCD_VEST_DAI).chainlog() == DssVestLike(MCD_VEST_DAI_LEGACY).chainlog(), "DssSpell/non-matching-chainlog");
        require(DssVestLike(MCD_VEST_DAI).vat() == DssVestLike(MCD_VEST_DAI_LEGACY).vat(), "DssSpell/non-matching-vat");
        require(DssVestLike(MCD_VEST_DAI).daiJoin() == DssVestLike(MCD_VEST_DAI_LEGACY).daiJoin(), "DssSpell/non-matching-daiJoin");

        // Rely ESM in old vesting contract
        DssVestLike(MCD_VEST_DAI_LEGACY).rely(DssExecLib.getChangelogAddress("MCD_ESM"));

        // Set up new vesting contract
        DssExecLib.authorize(DssExecLib.vat(), MCD_VEST_DAI);
        DssVestLike(MCD_VEST_DAI).file("cap", DssVestLike(MCD_VEST_DAI_LEGACY).cap());

        // Replace vesting in the chainlog and bump version
        DssExecLib.setChangelogAddress("MCD_VEST_DAI", MCD_VEST_DAI);
        DssExecLib.setChangelogAddress("MCD_VEST_DAI_LEGACY", MCD_VEST_DAI_LEGACY);
        DssExecLib.setChangelogVersion("1.12.0");

        // Stream payments
        DssVestLike(MCD_VEST_DAI).restrict(
            DssVestLike(MCD_VEST_DAI).create(PE_WALLET,   7_590_000 * WAD, MAY_01_2022, MAY_01_2023 - MAY_01_2022, 0, address(0))
        );
        DssVestLike(MCD_VEST_DAI).restrict(
            DssVestLike(MCD_VEST_DAI).create(COM_WALLET,    336_672 * WAD, JUL_01_2022, JAN_01_2023 - JUL_01_2022, 0, address(0))
        );
        DssVestLike(MCD_VEST_DAI).restrict(
            DssVestLike(MCD_VEST_DAI).create(DIN_WALLET,  1_083_000 * WAD, MAY_01_2022, MAY_01_2023 - MAY_01_2022, 0, address(0))
        );
        DssVestLike(MCD_VEST_DAI).restrict(
            DssVestLike(MCD_VEST_DAI).create(EVENTS_WALLET, 748_458 * WAD, MAY_01_2022, MAY_01_2023 - MAY_01_2022, 0, address(0))
        );

        // Unique payments
        DssExecLib.sendPaymentFromSurplusBuffer(PE_WALLET, 800_000);
        DssExecLib.sendPaymentFromSurplusBuffer(COM_EF_WALLET, 46_836);
        DssExecLib.sendPaymentFromSurplusBuffer(COM_WALLET, 26_390);
        DssExecLib.sendPaymentFromSurplusBuffer(EVENTS_WALLET, 149_692);
        DssExecLib.sendPaymentFromSurplusBuffer(SH_WALLET, 35_000);
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) public {}
}
