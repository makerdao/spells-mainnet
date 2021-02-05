// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2021 Maker Ecosystem Growth Holdings, INC.
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
pragma solidity 0.6.11;

import "dss-exec-lib/DssExec.sol";
import "dss-exec-lib/DssAction.sol";

contract DssSpellAction is DssAction {

    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: seth keccak -- "$(wget https://<TBD> -q -O - 2>/dev/null)"
    string public constant description =
        "2021-02-05 MakerDAO Executive Spell | Hash: 0x";


    // Many of the settings that change weekly rely on the rate accumulator
    // described at https://docs.makerdao.com/smart-contract-modules/rates-module
    // To check this yourself, use the following rate calculation (example 8%):
    //
    // $ bc -l <<< 'scale=27; e( l(1.08)/(60 * 60 * 24 * 365) )'
    //
    // A table of rates can be found at
    //    https://ipfs.io/ipfs/QmefQMseb3AiTapiAKKexdKHig8wroKuZbmLtPLv4u2YwW
    //

    /**
        @dev constructor (required)
        @param lib         address of the DssExecLib contract
        @param officeHours true if officehours enabled
    */
    constructor(address lib, bool officeHours) public DssAction(lib, officeHours) {}

    uint256 constant MILLION = 10**6;

    function actions() public override {
        // add UNI-V2-DAI-USDC-A collateral type
        CollateralOpts memory UNIV2DAIUSDC_A = CollateralOpts({
            ilk: "UNIV2DAIUSDC-A",
            gem: 0xAE461cA67B15dc8dc81CE7615e0320dA1A9aB8D5,
            join: 0xA81598667AC561986b70ae11bBE2dd5348ed4327,
            flip: 0x4a613f79a250D522DdB53904D87b8f442EA94496,
            pip: 0x25CD858a00146961611b18441353603191f110A0,
            isLiquidatable: false,
            isOSM: true,
            whitelistOSM: false,
            ilkDebtCeiling: 3 * MILLION, // initially 3 million
            minVaultAmount: 2000,
            maxLiquidationAmount: 50000,
            liquidationPenalty: 1300,
            ilkStabilityFee: 1000000000937303470807876289, // 3%
            bidIncrease: 300, // 3%
            bidDuration: 6 hours,
            auctionDuration: 6 hours,
            liquidationRatio: 11000 // 110%
        });
        addNewCollateral(UNIV2DAIUSDC_A);

        addReaderToMedianWhitelist(
            0x64DE91F5A373Cd4c28de3600cB34C7C6cE410C85, // median ETH/USDC
            0x9b015AA3e4787dd0df8B43bF2FE6d90fa543E13B  // pip
        );

        addReaderToMedianWhilelist(
            0x56D4bBF358D7790579b55eA6Af3f605BcA2c0C3A, // median USDT/USD
            0x9b015AA3e4787dd0df8B43bF2FE6d90fa543E13B  // pip
        );

        // add UNI-V2-ETH-USDT-A collateral type
        CollateralOpts memory UNIV2ETHUSDT_A = CollateralOpts({
            ilk: "UNIV2ETHUSDT-A",
            gem: 0x0d4a11d5EEaaC28EC3F61d100daF4d40471f1852,
            join: 0x4aAD139a88D2dd5e7410b408593208523a3a891d,
            flip: 0x118d5051e70F9EaF3B4a6a11F765185A2Ca0802E,
            pip: 0x9b015AA3e4787dd0df8B43bF2FE6d90fa543E13B,
            isLiquidatable: true,
            isOSM: true,
            whitelistOSM: false,
            ilkDebtCeiling: 3 * MILLION, // initially 3 million
            minVaultAmount: 2000,
            maxLiquidationAmount: 50000,
            liquidationPenalty: 1300,
            ilkStabilityFee: 1000000001243680656318820312, // 4% 
            bidIncrease: 300, // 3%
            bidDuration: 6 hours,
            auctionDuration: 6 hours,
            liquidationRatio: 14000 // 140%
        });
        addNewCollateral(UNIV2ETHUSDT_A);

        // risk params
    }
}

contract DssSpell is DssExec {
    address public constant LIB = 0x5b2867E4537DC4e10B2876E91bF693a6E6A768B3; // v0.0.3
    DssSpellAction public spell = new DssSpellAction(LIB, false);
    constructor() DssExec(spell.description(), now + 30 days, address(spell)) public {}
}
