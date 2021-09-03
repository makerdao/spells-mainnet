// SPDX-License-Identifier: AGPL-3.0-or-later
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

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "dss-exec-lib/DssExec.sol";
import "dss-exec-lib/DssAction.sol";

interface ChainlogLike {
    function removeAddress(bytes32) external;
}

interface DssVestLike {
    function create(address, uint256, uint256, uint256, uint256, address) external returns (uint256);
    function file(bytes32, uint256) external;
    function restrict(uint256) external;
}

contract DssSpellAction is DssAction {

    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/40b362fc70793e9980a8d53c47b1937e05d0c6d3/governance/votes/Executive%20vote%20-%20August%2020%2C%202021.md -q -O - 2>/dev/null)"
    string public constant override description =
        "2021-09-03 MakerDAO Executive Spell | Hash: ";

    address constant MCD_VEST_DAI = 0x2Cc583c0AaCDaC9e23CB601fDA8F1A0c56Cdcb71;
    address constant MCD_VEST_MKR = 0x0fC8D4f2151453ca0cA56f07359049c8f07997Bd;

    // Com Core Unit
    address constant COM_WALLET     = 0x1eE3ECa7aEF17D1e74eD7C447CcBA61aC76aDbA9;
    // Dai Foundation Core Unit
    address constant DAIF_WALLET    = 0x34D8d61050Ef9D2B48Ab00e6dc8A8CA6581c5d63;
    // Dai Foundation Core Unit (Emergency Fund)
    address constant DAIF_EF_WALLET = 0x5F5c328732c9E52DfCb81067b8bA56459b33921f;
    // GovAlpha Core Unit
    address constant GOV_WALLET     = 0x01D26f8c5cC009868A4BF66E268c17B057fF7A73;
    // Growth Core Unit
    address constant GRO_WALLET     = 0x7800C137A645c07132886539217ce192b9F0528e;
    // Marketing Content Production Core Unit
    address constant MKT_WALLET     = 0xDCAF2C84e1154c8DdD3203880e5db965bfF09B60;
    // Oracles Core Unit
    address constant ORA_WALLET     = 0x2d09B7b95f3F312ba6dDfB77bA6971786c5b50Cf;
    // Protocol Engineering
    address constant PE_WALLET      = 0xe2c16c308b843eD02B09156388Cb240cEd58C01c;
    // Risk Core Unit
    address constant RISK_WALLET    = 0xd98ef20520048a35EdA9A202137847A62120d2d9;
    // Real-World Finance Core Unit
    address constant RWF_WALLET     = 0x9e1585d9CA64243CE43D42f7dD7333190F66Ca09;
    // Ses Core Unit
    address constant SES_WALLET     = 0x87AcDD9208f73bFc9207e1f6F0fDE906bcA95cc6;

    uint256 constant MAY_01_2021 = 1619827200;
    uint256 constant JUN_21_2021 = 1624233600;
    uint256 constant JUL_01_2021 = 1625097600;
    uint256 constant SEP_01_2021 = 1630454400;
    uint256 constant SEP_13_2021 = 1631491200;
    uint256 constant SEP_20_2021 = 1632096000;
    uint256 constant OCT_01_2021 = 1633046400;
    uint256 constant NOV_01_2021 = 1635724800;
    uint256 constant JAN_01_2022 = 1640995200;
    uint256 constant MAY_01_2022 = 1651363200;
    uint256 constant JUL_01_2022 = 1656633600;
    uint256 constant SEP_01_2022 = 1661990400;

    uint256 constant MILLION = 10 ** 6;
    uint256 constant WAD     = 10 ** 18;

    // Turn off office hours
    function officeHours() public override returns (bool) {
        return false;
    }

    function actions() public override {
        // Fix PAX keys
        DssExecLib.setChangelogAddress("PAX", DssExecLib.getChangelogAddress("PAXUSD"));
        DssExecLib.setChangelogAddress("PIP_PAX", DssExecLib.getChangelogAddress("PIP_PAXUSD"));
        ChainlogLike(DssExecLib.LOG).removeAddress("PIP_PSM_PAX");

        // Set unique payments
        DssExecLib.sendPaymentFromSurplusBuffer(DAIF_WALLET,    2_000_000);
        DssExecLib.sendPaymentFromSurplusBuffer(DAIF_EF_WALLET,   138_591);
        DssExecLib.sendPaymentFromSurplusBuffer(SES_WALLET,       155_237);

        // Setup both DssVest modules
        DssExecLib.authorize(DssExecLib.vat(), MCD_VEST_DAI);
        DssExecLib.authorize(DssExecLib.getChangelogAddress("GOV_GUARD"), MCD_VEST_MKR);
        DssVestLike(MCD_VEST_DAI).file("cap", 1 * MILLION * WAD / 30 days);
        DssVestLike(MCD_VEST_MKR).file("cap", 1_100 * WAD / 365 days);
        DssExecLib.setChangelogAddress("MCD_VEST_DAI", MCD_VEST_DAI);
        DssExecLib.setChangelogAddress("MCD_VEST_MKR", MCD_VEST_MKR);

        // Set DAI stream payments
        DssVestLike(MCD_VEST_DAI).restrict(
            DssVestLike(MCD_VEST_DAI).create(                                COM_WALLET,   122_700.00 * 10**18, SEP_01_2021, JAN_01_2022 - 1 - SEP_01_2021,        0, address(0))
        );
        DssVestLike(MCD_VEST_DAI).restrict(
            DssVestLike(MCD_VEST_DAI).create(                               DAIF_WALLET,   492_971.00 * 10**18, OCT_01_2021, SEP_01_2022 - 1 - OCT_01_2021,        0, address(0))
        );
        DssVestLike(MCD_VEST_DAI).restrict(
            DssVestLike(MCD_VEST_DAI).create(                                GOV_WALLET,   123_333.00 * 10**18, SEP_01_2021, OCT_01_2021 - 1 - SEP_01_2021,        0, address(0))
        );
        DssVestLike(MCD_VEST_DAI).restrict(
            DssVestLike(MCD_VEST_DAI).create(                                GRO_WALLET,   300_050.00 * 10**18, SEP_01_2021, NOV_01_2021 - 1 - SEP_01_2021,        0, address(0))
        );
        DssVestLike(MCD_VEST_DAI).restrict(
            DssVestLike(MCD_VEST_DAI).create(                                MKT_WALLET,   103_134.00 * 10**18, SEP_01_2021, NOV_01_2021 - 1 - SEP_01_2021,        0, address(0))
        );
        DssVestLike(MCD_VEST_DAI).restrict(
            DssVestLike(MCD_VEST_DAI).create(                                ORA_WALLET,   196_771.00 * 10**18, SEP_01_2021, JUL_01_2022 - 1 - SEP_01_2021,        0, address(0))
        );
        DssVestLike(MCD_VEST_DAI).restrict(
            DssVestLike(MCD_VEST_DAI).create(                                 PE_WALLET, 4_080_000.00 * 10**18, SEP_01_2021, MAY_01_2022 - 1 - SEP_01_2021,        0, address(0))
        );
        DssVestLike(MCD_VEST_DAI).restrict(
            DssVestLike(MCD_VEST_DAI).create(                               RISK_WALLET,   184_000.00 * 10**18, SEP_01_2021, SEP_01_2022 - 1 - SEP_01_2021,        0, address(0))
        );
        DssVestLike(MCD_VEST_DAI).restrict(
            DssVestLike(MCD_VEST_DAI).create(                                RWF_WALLET,   620_000.00 * 10**18, SEP_01_2021, JAN_01_2022 - 1 - SEP_01_2021,        0, address(0))
        );

        // Growth MKR whole team vesting
        DssVestLike(MCD_VEST_MKR).restrict(
            DssVestLike(MCD_VEST_MKR).create(GRO_WALLET,                                       803.18 * 10**18, JUL_01_2021,                      365 days, 365 days, address(0))
        );

        // Oracles MKR whole team vesting
        DssVestLike(MCD_VEST_MKR).restrict(
            DssVestLike(MCD_VEST_MKR).create(ORA_WALLET,                                     1_051.25 * 10**18, JUL_01_2021,                      365 days, 365 days, address(0))
        );

        // PE MKR vestings (per individual)
        (
            DssVestLike(MCD_VEST_MKR).create(0xfDB9F5e045D7326C1da87d0e199a05CDE5378EdD,       995.00 * 10**18, MAY_01_2021,                  4 * 365 days, 365 days,  PE_WALLET)
        );
        DssVestLike(MCD_VEST_MKR).restrict(
            DssVestLike(MCD_VEST_MKR).create(0xBe4De3E151D52668c2C0610C985b4297833239C8,       995.00 * 10**18, MAY_01_2021,                  4 * 365 days, 365 days,  PE_WALLET)
        );
        DssVestLike(MCD_VEST_MKR).restrict(
            DssVestLike(MCD_VEST_MKR).create(0x58EA3C96a8b81abC01EB78B98deCe2AD1e5fd7fc,       995.00 * 10**18, MAY_01_2021,                  4 * 365 days, 365 days,  PE_WALLET)
        );
        DssVestLike(MCD_VEST_MKR).restrict(
            DssVestLike(MCD_VEST_MKR).create(0xBAB4Cd1cB31Cd28f842335973712a6015eB0EcD5,       995.00 * 10**18, MAY_01_2021,                  4 * 365 days, 365 days,  PE_WALLET)
        );
        (
            DssVestLike(MCD_VEST_MKR).create(0xB5c86aff90944CFB3184902482799bD5fA3B18dD,       995.00 * 10**18, MAY_01_2021,                  4 * 365 days, 365 days,  PE_WALLET)
        );
        DssVestLike(MCD_VEST_MKR).restrict(
            DssVestLike(MCD_VEST_MKR).create(0x780f478856ebE01e46d9A432e8776bAAB5A81b5b,       995.00 * 10**18, MAY_01_2021,                  4 * 365 days, 365 days,  PE_WALLET)
        );
        (
            DssVestLike(MCD_VEST_MKR).create(0x34364E234b3DD02FF5c8A2ad9ba86bbD3D3D3284,       995.00 * 10**18, MAY_01_2021,                  4 * 365 days, 365 days,  PE_WALLET)
        );
        DssVestLike(MCD_VEST_MKR).restrict(
            DssVestLike(MCD_VEST_MKR).create(0x46E5DBad3966453Af57e90Ec2f3548a0e98ec979,       995.00 * 10**18, MAY_01_2021,                  4 * 365 days, 365 days,  PE_WALLET)
        );
        DssVestLike(MCD_VEST_MKR).restrict(
            DssVestLike(MCD_VEST_MKR).create(0x18CaE82909C31b60Fe0A9656D76406345C9cb9FB,       995.00 * 10**18, MAY_01_2021,                  4 * 365 days, 365 days,  PE_WALLET)
        );
        (
            DssVestLike(MCD_VEST_MKR).create(0x301dD8eB831ddb93F128C33b9d9DC333210d9B25,       995.00 * 10**18, MAY_01_2021,                  4 * 365 days, 365 days,  PE_WALLET)
        );
        (
            DssVestLike(MCD_VEST_MKR).create(0xBFC47D0D7452a25b7d3AA4d7379c69A891bD5d43,       995.00 * 10**18, MAY_01_2021,                  4 * 365 days, 365 days,  PE_WALLET)
        );
        (
            DssVestLike(MCD_VEST_MKR).create(0xcD16aa978A89Aa26b3121Fc8dd32228d7D0fcF4a,       995.00 * 10**18, SEP_13_2021,                  4 * 365 days, 365 days,  PE_WALLET)
        );
        DssVestLike(MCD_VEST_MKR).restrict(
            DssVestLike(MCD_VEST_MKR).create(0x3189cfe40CF011AAb13aDD8aE7284deD4CD30602,       995.00 * 10**18, JUN_21_2021,                  4 * 365 days, 365 days,  PE_WALLET)
        );
        DssVestLike(MCD_VEST_MKR).restrict(
            DssVestLike(MCD_VEST_MKR).create(0x29b37159C09a65af6a7CFb062998B169879442B6,       995.00 * 10**18, SEP_20_2021,                  4 * 365 days, 365 days,  PE_WALLET)
        );

        // Increase PAX-PSM-A DC from 50 million DAI to 500 million DAI
        DssExecLib.setIlkDebtCeiling("PSM-PAX-A", 500 * MILLION);

        // Decrease Flash Mint Fee (toll) from 0.05% to 0%
        DssExecLib.setValue(DssExecLib.getChangelogAddress("MCD_FLASH"), "toll", WAD);

        // Bump changelog version
        DssExecLib.setChangelogVersion("1.9.5");
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) public {}
}
