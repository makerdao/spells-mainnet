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

interface VatLike {
    function ilks(bytes32) external view returns (uint256, uint256, uint256, uint256, uint256);
    function Line() external view returns (uint256);
    function file(bytes32, uint256) external;
}

interface TokenLike {
    function approve(address, uint256) external returns (bool);
}

interface DssVestLike {
    function file(bytes32, uint256) external;
    function create(address, uint256, uint256, uint256, uint256, address) external returns (uint256);
    function restrict(uint256) external;
}

contract DssSpellAction is DssAction {

    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/989a2ee92df41ef7aee75a1ccdbedbe6071e28a7/governance/votes/Executive%20vote%20-%20October%201%2C%202021.md -q -O - 2>/dev/null)"
    string public constant override description =
        "2021-10-08 MakerDAO Executive Spell | Hash: 0x240a8946c4c5f2463a1fcd6c7036409087af1c2407d502330e27c9149bfa7ed7";

    uint256 constant MILLION = 10 ** 6;
    uint256 constant WAD     = 10 ** 18;
    uint256 constant RAY     = 10 ** 27;

    address constant CES_WALLET  = 0x25307aB59Cd5d8b4E2C01218262Ddf6a89Ff86da;
    address constant RISK_WALLET = 0x5d67d5B1fC7EF4bfF31967bE2D2d7b9323c1521c;

    address constant MCD_VEST_MKR_TREASURY = 0x6D635c8d08a1eA2F1687a5E46b666949c977B7dd;

    uint256 constant APR_01_2021 = 1617235200;

    uint256 constant CURRENT_BAT_MAT          = 150 * RAY / 100;
    uint256 constant CURRENT_LRC_MAT          = 175 * RAY / 100;
    uint256 constant CURRENT_ZRX_MAT          = 175 * RAY / 100;
    uint256 constant CURRENT_UNIV2AAVEETH_MAT = 165 * RAY / 100;
    uint256 constant CURRENT_UNIV2LINKETH_MAT = 165 * RAY / 100;

    // The end parameter of dss-lerp is calculated as Math.round(CRmax / 100 * 1.5) * RAY where CRmax is the maximum collateral ratio for the ilk
    uint256 constant TARGET_BAT_MAT          = 3800 * RAY / 100;
    uint256 constant TARGET_LRC_MAT          = 2700 * RAY / 100;
    uint256 constant TARGET_ZRX_MAT          = 2600 * RAY / 100;
    uint256 constant TARGET_UNIV2AAVEETH_MAT = 400 * RAY / 100;
    uint256 constant TARGET_UNIV2LINKETH_MAT = 700 * RAY / 100;

    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }
    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }

    // Turn on office hours
    function officeHours() public override returns (bool) {
        return true;
    }

    function actions() public override {
       
        //
        // Direct payment
        //
        
        // CES-001 - 1_223_552 DAI - 0x25307aB59Cd5d8b4E2C01218262Ddf6a89Ff86da
        // https://vote.makerdao.com/polling/QmbM8u7Q?network=mainnet#vote-breakdown
        DssExecLib.sendPaymentFromSurplusBuffer(CES_WALLET, 1_223_552);

        //
        // MKR vesting
        //

        TokenLike(DssExecLib.getChangelogAddress("MCD_GOV")).approve(MCD_VEST_MKR_TREASURY, 700 * WAD);
        DssVestLike(MCD_VEST_MKR_TREASURY).file("cap", 700 * WAD / 365 days);

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

        // RISK-001 - 700 MKR - 0x5d67d5B1fC7EF4bfF31967bE2D2d7b9323c1521c
        // https://vote.makerdao.com/polling/QmUAXKm4?network=mainnet#vote-breakdown

        DssVestLike(MCD_VEST_MKR_TREASURY).restrict(
            DssVestLike(MCD_VEST_MKR_TREASURY).create(
                RISK_WALLET,
                700 * WAD,
                APR_01_2021,
                365 days,
                365 days,
                address(0)
            )
        );

        //
        // Collateral offboarding
        //

        uint256 totalLineReduction;
        uint256 line;
        VatLike vat = VatLike(DssExecLib.vat());

        // Offboard BAT-A
        // https://vote.makerdao.com/polling/QmWJfX8U?network=mainnet#vote-breakdown

        (,,,line,) = vat.ilks("BAT-A");
        totalLineReduction = add(totalLineReduction, line);
        DssExecLib.setIlkLiquidationPenalty("BAT-A", 0);
        DssExecLib.removeIlkFromAutoLine("BAT-A");
        DssExecLib.setIlkDebtCeiling("BAT-A", 0);
        DssExecLib.linearInterpolation({
            _name:      "BAT Offboarding",
            _target:    DssExecLib.spotter(),
            _ilk:       "BAT-A",
            _what:      "mat",
            _startTime: block.timestamp,
            _start:     CURRENT_BAT_MAT,
            _end:       TARGET_BAT_MAT,
            _duration:  60 days
        });

        // Offboard LRC-A 
        // https://vote.makerdao.com/polling/QmUx9LVs?network=mainnet#vote-breakdown

        (,,,line,) = vat.ilks("LRC-A");
        totalLineReduction = add(totalLineReduction, line);
        DssExecLib.setIlkLiquidationPenalty("LRC-A", 0);
        DssExecLib.removeIlkFromAutoLine("LRC-A");
        DssExecLib.setIlkDebtCeiling("LRC-A", 0);
        DssExecLib.linearInterpolation({
            _name:      "LRC Offboarding",
            _target:    DssExecLib.spotter(),
            _ilk:       "LRC-A",
            _what:      "mat",
            _startTime: block.timestamp,
            _start:     CURRENT_LRC_MAT,
            _end:       TARGET_LRC_MAT,
            _duration:  60 days
        });

        // Offboard ZRX-A 
        // https://vote.makerdao.com/polling/QmPfuF2W?network=mainnet#vote-breakdown

        (,,,line,) = vat.ilks("ZRX-A");
        totalLineReduction = add(totalLineReduction, line);
        DssExecLib.setIlkLiquidationPenalty("ZRX-A", 0);
        DssExecLib.removeIlkFromAutoLine("ZRX-A");
        DssExecLib.setIlkDebtCeiling("ZRX-A", 0);
        DssExecLib.linearInterpolation({
            _name:      "ZRX Offboarding",
            _target:    DssExecLib.spotter(),
            _ilk:       "ZRX-A",
            _what:      "mat",
            _startTime: block.timestamp,
            _start:     CURRENT_ZRX_MAT,
            _end:       TARGET_ZRX_MAT,
            _duration:  60 days
        });

        // Offboard UNIV2AAVEETH-A
        // https://vote.makerdao.com/polling/QmcuJHkq?network=mainnet#vote-breakdown

        (,,,line,) = vat.ilks("UNIV2AAVEETH-A");
        totalLineReduction = add(totalLineReduction, line);
        DssExecLib.setIlkLiquidationPenalty("UNIV2AAVEETH-A", 0);
        DssExecLib.removeIlkFromAutoLine("UNIV2AAVEETH-A");
        DssExecLib.setIlkDebtCeiling("UNIV2AAVEETH-A", 0);
        DssExecLib.linearInterpolation({
            _name:      "UNIV2AAVEETH Offboarding",
            _target:    DssExecLib.spotter(),
            _ilk:       "UNIV2AAVEETH-A",
            _what:      "mat",
            _startTime: block.timestamp,
            _start:     CURRENT_UNIV2AAVEETH_MAT,
            _end:       TARGET_UNIV2AAVEETH_MAT,
            _duration:  60 days
        });

        // Offboard UNIV2LINKETH-A
        // https://vote.makerdao.com/polling/Qmd7DPye?network=mainnet#vote-breakdown

        (,,,line,) = vat.ilks("UNIV2LINKETH-A");
        totalLineReduction = add(totalLineReduction, line);
        DssExecLib.setIlkLiquidationPenalty("UNIV2LINKETH-A", 0);
        DssExecLib.removeIlkFromAutoLine("UNIV2LINKETH-A");
        DssExecLib.setIlkDebtCeiling("UNIV2LINKETH-A", 0);
        DssExecLib.linearInterpolation({
            _name:      "UNIV2LINKETH Offboarding",
            _target:    DssExecLib.spotter(),
            _ilk:       "UNIV2LINKETH-A",
            _what:      "mat",
            _startTime: block.timestamp,
            _start:     CURRENT_UNIV2LINKETH_MAT,
            _end:       TARGET_UNIV2LINKETH_MAT,
            _duration:  60 days
        });

        // Decrease global debt ceiling in accordance with offboarded ilks
        vat.file("Line", sub(vat.Line(), totalLineReduction));

        //
        // Update Changelog
        //

        DssExecLib.setChangelogAddress("MCD_VEST_MKR_TREASURY", MCD_VEST_MKR_TREASURY);
        DssExecLib.setChangelogVersion("1.9.7");
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) public {}
}
