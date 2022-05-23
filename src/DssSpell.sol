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

import "dss-interfaces/dss/EndAbstract.sol";
import "dss-interfaces/dss/IlkRegistryAbstract.sol";
import "dss-interfaces/dss/FlashAbstract.sol";
import "dss-interfaces/dapp/DSTokenAbstract.sol";

contract DssSpellAction is DssAction, DssSpellCollateralOnboardingAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: cast keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/45d2525f0b3f57a3e102fbd7034d1d912dea921a/governance/votes/Executive%20vote%20-%20May%2025%2C%202022.md -q -O - 2>/dev/null)"

    string public constant override description =
        "2022-05-25 MakerDAO Executive Spell | Hash: 0x308785a5c5d12cf03a48ce076a72b12ac887590da1b84ef68e4272a2d026ed9c";

    // Math
    uint256 constant WAD = 10 ** 18;
    uint256 constant RAD = 10 ** 45;

    // Many of the settings that change weekly rely on the rate accumulator
    // described at https://docs.makerdao.com/smart-contract-modules/rates-module
    // To check this yourself, use the following rate calculation (example 8%):
    //
    // $ bc -l <<< 'scale=27; e( l(1.08)/(60 * 60 * 24 * 365) )'
    //
    // A table of rates can be found at
    //    https://ipfs.io/ipfs/QmPgPVrVxDCGyNR5rGp9JC5AUxppLzUAqvncRJDcxQnX1u
    //

    // Turn office hours off
    function officeHours() public override returns (bool) {
        return false;
    }

    address immutable MCD_FLAP = DssExecLib.flap();
    address immutable MCD_ESM  = DssExecLib.esm();
    address immutable MCD_GOV  = DssExecLib.mkr();

    address immutable SIDESTREAM_WALLET = 0xb1f950a51516a697E103aaa69E152d839182f6Fe;
    address immutable DUX_WALLET =        0x5A994D8428CCEbCC153863CCdA9D2Be6352f89ad;

    function actions() public override {
        // ---------------------------------------------------------------------
        // Includes changes from the DssSpellCollateralOnboardingAction
        // onboardNewCollaterals();

        // ---------------------------- Lid for Flap ---------------------------
        DssExecLib.setValue(MCD_FLAP, "lid", 30_000 * RAD);

        // ------------------------------ ESM Min ------------------------------
        DssExecLib.setValue(MCD_ESM, "min", 150_000 * WAD);

        // ---------------------------- Transfer MKR ---------------------------
        DSTokenAbstract(MCD_GOV).transfer(SIDESTREAM_WALLET, 243.7953 ether);
        DSTokenAbstract(MCD_GOV).transfer(DUX_WALLET,        355.86   ether);

    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) public {}
}
