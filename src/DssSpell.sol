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
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/f33870a7938c1842e8467226f8007a2d47f9ddeb/governance/votes/Executive%20vote%20-%20October%208%2C%202021.md -q -O - 2>/dev/null)"
    string public constant override description =
        "2021-10-08 MakerDAO Executive Spell | Hash: 0xe1126241f8df6e094363eac12a5c4620f0dbf54c4d7da7fa94f5b8dd499e30d2";

    uint256 constant WAD     = 10 ** 18;
    uint256 constant RAY     = 10 ** 27;

    address constant CES_WALLET  = 0x25307aB59Cd5d8b4E2C01218262Ddf6a89Ff86da;
    address constant RISK_WALLET = 0x5d67d5B1fC7EF4bfF31967bE2D2d7b9323c1521c;

    address constant MCD_VEST_MKR_TREASURY = 0x6D635c8d08a1eA2F1687a5E46b666949c977B7dd;
    address constant OPTIMISM_DAI_BRIDGE   = 0x10E6593CDda8c58a1d0f14C5164B376352a55f2F;
    address constant OPTIMISM_ESCROW       = 0x467194771dAe2967Aef3ECbEDD3Bf9a310C76C65;
    address constant OPTIMISM_GOV_RELAY    = 0x09B354CDA89203BB7B3131CC728dFa06ab09Ae2F;
    address constant ARBITRUM_DAI_BRIDGE   = 0xD3B5b60020504bc3489D6949d545893982BA3011;
    address constant ARBITRUM_ESCROW       = 0xA10c7CE4b876998858b1a9E12b10092229539400;
    address constant ARBITRUM_GOV_RELAY    = 0x9ba25c289e351779E0D481Ba37489317c34A899d;

    uint256 constant APR_01_2021 = 1617235200;

    uint256 constant CURRENT_BAT_MAT          = 150 * RAY / 100;
    uint256 constant CURRENT_LRC_MAT          = 175 * RAY / 100;
    uint256 constant CURRENT_ZRX_MAT          = 175 * RAY / 100;
    uint256 constant CURRENT_UNIV2AAVEETH_MAT = 165 * RAY / 100;
    uint256 constant CURRENT_UNIV2LINKETH_MAT = 165 * RAY / 100;

    uint256 constant TARGET_BAT_MAT          = 800 * RAY / 100;
    uint256 constant TARGET_LRC_MAT          = 2600 * RAY / 100;
    uint256 constant TARGET_ZRX_MAT          = 900 * RAY / 100;
    uint256 constant TARGET_UNIV2AAVEETH_MAT = 400 * RAY / 100;
    uint256 constant TARGET_UNIV2LINKETH_MAT = 300 * RAY / 100;

    function _add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }
    function _sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
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

        // Set system-wide cap on maximum vesting speed
        DssVestLike(MCD_VEST_MKR_TREASURY).file("cap", 1100 * WAD / 365 days);

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
        totalLineReduction = _add(totalLineReduction, line);
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
        totalLineReduction = _add(totalLineReduction, line);
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
        totalLineReduction = _add(totalLineReduction, line);
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
        totalLineReduction = _add(totalLineReduction, line);
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
        totalLineReduction = _add(totalLineReduction, line);
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
        vat.file("Line", _sub(vat.Line(), totalLineReduction));

        //
        // Update Changelog
        //

        DssExecLib.setChangelogAddress("MCD_VEST_MKR_TREASURY", MCD_VEST_MKR_TREASURY);
        DssExecLib.setChangelogAddress("OPTIMISM_DAI_BRIDGE", OPTIMISM_DAI_BRIDGE);
        DssExecLib.setChangelogAddress("OPTIMISM_ESCROW", OPTIMISM_ESCROW);
        DssExecLib.setChangelogAddress("OPTIMISM_GOV_RELAY", OPTIMISM_GOV_RELAY);
        DssExecLib.setChangelogAddress("ARBITRUM_DAI_BRIDGE", ARBITRUM_DAI_BRIDGE);
        DssExecLib.setChangelogAddress("ARBITRUM_ESCROW", ARBITRUM_ESCROW);
        DssExecLib.setChangelogAddress("ARBITRUM_GOV_RELAY", ARBITRUM_GOV_RELAY);
        DssExecLib.setChangelogVersion("1.9.7");
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) public {}
}
