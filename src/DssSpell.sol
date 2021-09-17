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
pragma experimental ABIEncoderV2;

import "dss-exec-lib/DssExec.sol";
import "dss-exec-lib/DssAction.sol";

contract DssSpellAction is DssAction {

    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/6d18889e1ebcc2f024c377e106682493ce399beb/governance/votes/Executive%20vote%20-%20September%2017%2C%202021.md -q -O - 2>/dev/null)"
    string public constant override description =
        "2021-09-17 MakerDAO Executive Spell | Hash: 0x613a50aee82adca6f6f32a4f7298c70b1c9d061648e786c84b3872ffc5963e3e";

    string public constant in_memory_of = "Jeffrey Blechschmidt";
    
    // Many of the settings that change weekly rely on the rate accumulator
    // described at https://docs.makerdao.com/smart-contract-modules/rates-module
    // To check this yourself, use the following rate calculation (example 8%):
    //
    // $ bc -l <<< 'scale=27; e( l(1.08)/(60 * 60 * 24 * 365) )'
    //
    // A table of rates can be found at
    //    https://ipfs.io/ipfs/QmefQMseb3AiTapiAKKexdKHig8wroKuZbmLtPLv4u2YwW
    //
    uint256 constant ONE_PCT_RATE = 1000000000315522921573372069;

    // Math
    uint256 constant THOUSAND = 10 ** 3;
    uint256 constant MILLION  = 10 ** 6;
    uint256 constant BILLION  = 10 ** 9;
    uint256 constant RAY      = 10 ** 27;

    address constant GUNIV3DAIUSDC1                 = 0xAbDDAfB225e10B90D798bB8A886238Fb835e2053;
    address constant MCD_JOIN_GUNIV3DAIUSDC1_A      = 0xbFD445A97e7459b0eBb34cfbd3245750Dba4d7a4;
    address constant MCD_CLIP_GUNIV3DAIUSDC1_A      = 0x5048c5Cd3102026472f8914557A1FD35c8Dc6c9e;
    address constant MCD_CLIP_CALC_GUNIV3DAIUSDC1_A = 0x25B17065b94e3fDcD97d94A2DA29E7F77105aDd7;
    address constant PIP_GUNIV3DAIUSDC1             = 0xDCbC54439ac0AF5FEa1d8394Fb177E4BFdA426f0;

    // Turn on office hours
    function officeHours() public override returns (bool) {
        return true;
    }

    function actions() public override {

        // Offboard KNC Legacy Token
        // https://vote.makerdao.com/polling/QmQ4Jotm?network=mainnet#poll-detail
        DssExecLib.setIlkLiquidationPenalty("KNC-A", 0);
        DssExecLib.linearInterpolation({
            _name:      "KNC Offboarding",
            _target:    DssExecLib.spotter(),
            _ilk:       "KNC-A",
            _what:      "mat",
            _startTime: block.timestamp,
            _start:       175 * RAY / 100,
            _end:       5_000 * RAY / 100,
            _duration:  60 days
        });

        // Adopt the Debt Ceiling Instant Access Module (DC-IAM) for PSM-PAX-A
        // https://vote.makerdao.com/polling/QmbGPgxo?network=mainnet#poll-detail
        DssExecLib.setIlkAutoLineParameters({
            _ilk:    "PSM-PAX-A",
            _amount: 500 * MILLION,
            _gap:     50 * MILLION,
            _ttl:    24 hours
        });
        DssExecLib.setIlkAutoLineParameters({
            _ilk:    "PSM-USDC-A",
            _amount:  10 * BILLION,
            _gap:    950 * MILLION,
            _ttl:    24 hours
        });

        // G-UNI DAI/USDC
        DssExecLib.setStairstepExponentialDecrease(MCD_CLIP_CALC_GUNIV3DAIUSDC1_A, 120 seconds, 9990);

        CollateralOpts memory GUNIV3DAIUSDC1_A = CollateralOpts({
            ilk:                   "GUNIV3DAIUSDC1-A",
            gem:                   GUNIV3DAIUSDC1,
            join:                  MCD_JOIN_GUNIV3DAIUSDC1_A,
            clip:                  MCD_CLIP_GUNIV3DAIUSDC1_A,
            calc:                  MCD_CLIP_CALC_GUNIV3DAIUSDC1_A,
            pip:                   PIP_GUNIV3DAIUSDC1,
            isLiquidatable:        false,
            isOSM:                 true,
            whitelistOSM:          false,
            ilkDebtCeiling:        10 * MILLION,
            minVaultAmount:        10 * THOUSAND,
            maxLiquidationAmount:  5 * MILLION,
            liquidationPenalty:    1300,
            ilkStabilityFee:       ONE_PCT_RATE,
            startingPriceFactor:   10500,
            breakerTolerance:      9500, // Allows for a 5% hourly price drop before disabling liquidations
            auctionDuration:       220 minutes,
            permittedDrop:         9000,
            liquidationRatio:      10500,
            kprFlatReward:         300,
            kprPctReward:          10 // 0.1%
        });

        DssExecLib.addNewCollateral(GUNIV3DAIUSDC1_A);
        DssExecLib.setIlkAutoLineParameters("GUNIV3DAIUSDC1-A", 10 * MILLION, 10 * MILLION, 8 hours);

        DssExecLib.setChangelogAddress("GUNIV3DAIUSDC1", GUNIV3DAIUSDC1);
        DssExecLib.setChangelogAddress("MCD_JOIN_GUNIV3DAIUSDC1_A", MCD_JOIN_GUNIV3DAIUSDC1_A);
        DssExecLib.setChangelogAddress("MCD_CLIP_GUNIV3DAIUSDC1_A", MCD_CLIP_GUNIV3DAIUSDC1_A);
        DssExecLib.setChangelogAddress("MCD_CLIP_CALC_GUNIV3DAIUSDC1_A", MCD_CLIP_CALC_GUNIV3DAIUSDC1_A);
        DssExecLib.setChangelogAddress("PIP_GUNIV3DAIUSDC1", PIP_GUNIV3DAIUSDC1);
        DssExecLib.setChangelogVersion("1.9.6");
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) public {}
}
