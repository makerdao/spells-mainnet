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

interface GemLike {
    function transfer(address, uint256) external returns (bool);
}

interface StarknetLike {
    function setMaxDeposit(uint256) external;
}

contract DssSpellAction is DssAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: cast keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/0344515b4f9ef9de6e589b5b873f5bafcf274b38/governance/votes/Executive%20Vote%20-%20September%2028%2C%202022.md -q -O - 2>/dev/null)"

    string public constant override description =
        "2022-09-28 MakerDAO Executive Spell | Hash: 0x2ec09ea8a5fad89c49737c249313db441abebdefb9786c9503c4df5f74b3e983";

    // Many of the settings that change weekly rely on the rate accumulator
    // described at https://docs.makerdao.com/smart-contract-modules/rates-module
    // To check this yourself, use the following rate calculation (example 8%):
    //
    // $ bc -l <<< 'scale=27; e( l(1.08)/(60 * 60 * 24 * 365) )'
    //
    // A table of rates can be found at
    //    https://ipfs.io/ipfs/QmVp4mhhbwWGTfbh2BzwQB9eiBrQBKiqcPRZCaAxNUaar6
    //

    // --- Wallets ---
    address internal constant GOV_WALLET1       = 0xbfDD0E744723192f7880493b66501253C34e1241;
    address internal constant GOV_WALLET2       = 0xbb147E995c9f159b93Da683dCa7893d6157199B9;
    address internal constant GOV_WALLET3       = 0x01D26f8c5cC009868A4BF66E268c17B057fF7A73;
    address internal constant AMBASSADOR_WALLET = 0xF411d823a48D18B32e608274Df16a9957fE33E45;
    address internal constant STARKNET_WALLET   = 0x6D348f18c88D45243705D4fdEeB6538c6a9191F1;
    address internal constant SES_WALLET        = 0x87AcDD9208f73bFc9207e1f6F0fDE906bcA95cc6;

    function actions() public override {
        // ---------------------------------------------------------------------
        // Includes changes from the DssSpellCollateralAction
        // onboardNewCollaterals();
        // offboardCollaterals();

        // MIP65 Deployment - 1 million Pilot Transaction (RWA-007-A)
        // https://vote.makerdao.com/polling/QmXHM6us


        // --- MKR Vests ---
        

        // --- MKR Transfers ---
        GemLike mkr = GemLike(DssExecLib.mkr());
        mkr.transfer(STARKNET_WALLET, 270.00 ether);
        mkr.transfer(SES_WALLET, 227.64 ether);

        // --- DAI Transfers ---
        DssExecLib.sendPaymentFromSurplusBuffer(AMBASSADOR_WALLET, 81_000);
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) public {}
}
