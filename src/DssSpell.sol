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

pragma solidity 0.6.12;
// Enable ABIEncoderV2 when onboarding collateral through `DssExecLib.addNewCollateral()`
// pragma experimental ABIEncoderV2;

import "dss-exec-lib/DssExec.sol";
import "dss-exec-lib/DssAction.sol";

// import { DssSpellCollateralAction } from "./DssSpellCollateral.sol";

interface VestMKRLike {
    function vest(uint256) external;
}

interface RwaLiquidationLike {
    function ilks(bytes32) external returns (string memory, address, uint48, uint48);
    function init(bytes32, uint256, string calldata, uint48) external;
}

contract DssSpellAction is DssAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: cast keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/7e054d5ba9b9cc7566cf93ba7e19309fb9f59ab5/governance/votes/Executive%20vote%20-%20September%207%2C%202022.md -q -O - 2>/dev/null)"

    string public constant override description =
        "2022-09-14 MakerDAO Executive Spell | Hash: 0x0";

    // Many of the settings that change weekly rely on the rate accumulator
    // described at https://docs.makerdao.com/smart-contract-modules/rates-module
    // To check this yourself, use the following rate calculation (example 8%):
    //
    // $ bc -l <<< 'scale=27; e( l(1.08)/(60 * 60 * 24 * 365) )'
    //
    // A table of rates can be found at
    //    https://ipfs.io/ipfs/QmVp4mhhbwWGTfbh2BzwQB9eiBrQBKiqcPRZCaAxNUaar6
    //
    // --- Rates ---

    // HVB (RWA009-A) legal update doc
    string constant DOC = "QmPH6gMsoqrGFN8ECGGbuaaR5KSD4mtnuiuNkHzHgryp48";

    // wallet addresses
    address internal constant WTF1_WALLET = 0x173d85CD1754daD73cfc673944D9C8BF11A01D3F;
    address internal constant WTF2_WALLET = 0x29408abeCe474C85a12ce15B05efBB6A1e8587fe;

    uint256 internal constant WAD = 10**18;

    // Turn office hours off
    function officeHours() public override returns (bool) {
        return false;
    }

    function actions() public override {
        // ---------------------------------------------------------------------
        // Includes changes from the DssSpellCollateralAction
        // onboardNewCollaterals();
        // offboardCollaterals();

        // ---------------------- CU DAI Vesting Streams -----------------------
        // TODO

        // ---------------------- SPF Funding Transfers ------------------------
        // https://forum.makerdao.com/t/mip55c3-sp6-legal-domain-work-on-greenlit-collateral-bibta-special-purpose-fund/17166
        // https://vote.makerdao.com/polling/QmdaG8mo#vote-breakdown
        DssExecLib.sendPaymentFromSurplusBuffer(WTF1_WALLET, 50_000);
        DssExecLib.sendPaymentFromSurplusBuffer(WTF2_WALLET, 30_000);

        // ------------------- GRO-001 MKR Stream Clean-up ---------------------
        // https://forum.makerdao.com/t/executive-inclusion-gro-001-mkr-vesting-stream-clean-up/17820
        VestMKRLike vest = VestMKRLike(
            DssExecLib.getChangelogAddress("MCD_VEST_MKR_TREASURY")
        );
        vest.vest(2);

        // -------------------- Update HVB Legal Documents ---------------------
        // https://forum.makerdao.com/t/poll-inclusion-request-hvbank-legal-update/17547
        // https://vote.makerdao.com/polling/QmX81EhP#vote-breakdown
        bytes32 ilk                      = "RWA009-A";
        address MIP21_LIQUIDATION_ORACLE = DssExecLib.getChangelogAddress(
            "MIP21_LIQUIDATION_ORACLE"
        );

        ( , address pip, uint48 tau, ) = RwaLiquidationLike(
            MIP21_LIQUIDATION_ORACLE
        ).ilks(ilk);

        require(pip != address(0), "Abort spell execution: pip must be set");

        // Init the RwaLiquidationOracle to reset the doc
        RwaLiquidationLike(MIP21_LIQUIDATION_ORACLE).init(
            ilk,       // ilk to update
            0,         // price ignored if init() has already been called
            DOC,       // new legal document
            tau        // old tau value
        );
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) public {}
}
