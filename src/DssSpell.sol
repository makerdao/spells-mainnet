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

interface TokenLike {
    function approve(address, uint256) external returns (bool);
}

interface DssVestLike {
    function yank(uint256) external;
    function restrict(uint256) external;
    function create(
        address _usr,
        uint256 _tot,
        uint256 _bgn,
        uint256 _tau,
        uint256 _eta,
        address _mgr
  ) external returns (uint256);
}

contract DssSpellAction is DssAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/TODO/governance/votes/Executive%20vote%20-%20December%2010%2C%202021.md -q -O - 2>/dev/null)"
    string public constant override description =
        "2021-12-10 MakerDAO Executive Spell | Hash: TODO";

    // --- Wallet addresses ---
    address constant GRO_WALLET = 0x7800C137A645c07132886539217ce192b9F0528e;
    address constant ORA_WALLET = 0x2d09B7b95f3F312ba6dDfB77bA6971786c5b50Cf;
    address constant PE_WALLET  = 0xe2c16c308b843eD02B09156388Cb240cEd58C01c;

    // --- Dates ---
    uint256 constant MAY_01_2021 = 1619827200;
    uint256 constant JUN_21_2021 = 1624233600;
    uint256 constant JUL_01_2021 = 1625097600;
    uint256 constant SEP_13_2021 = 1631491200;
    uint256 constant SEP_20_2021 = 1632096000;

    function officeHours() public override returns (bool) {
        return false;
    }

    function actions() public override {

        // ------------- Transfer vesting streams from MCD_VEST_MKR to MCD_VEST_MKR_TREASURY -------------
        // https://vote.makerdao.com/polling/QmYdDTsn

        address MCD_VEST_MKR          = DssExecLib.getChangelogAddress("MCD_VEST_MKR");
        address MCD_VEST_MKR_TREASURY = DssExecLib.getChangelogAddress("MCD_VEST_MKR_TREASURY");

        TokenLike(DssExecLib.getChangelogAddress("MCD_GOV")).approve(MCD_VEST_MKR_TREASURY, 16_484.43 * 10**18);

        // Growth MKR whole team vesting
        DssVestLike(MCD_VEST_MKR).yank(1);
        DssVestLike(MCD_VEST_MKR_TREASURY).restrict(
            DssVestLike(MCD_VEST_MKR_TREASURY).create({
                _usr: GRO_WALLET,
                _tot: 803.18 * 10**18,
                _bgn: JUL_01_2021,
                _tau: 365 days,
                _eta: 365 days,
                _mgr: address(0)
            })
        );

        // Oracles MKR whole team vesting
        DssVestLike(MCD_VEST_MKR).yank(2);
        DssVestLike(MCD_VEST_MKR_TREASURY).restrict(
            DssVestLike(MCD_VEST_MKR_TREASURY).create({
                _usr: ORA_WALLET,
                _tot: 1_051.25 * 10**18,
                _bgn: JUL_01_2021,
                _tau: 365 days,
                _eta: 365 days,
                _mgr: address(0)
            })
        );

        // PE MKR vestings (per individual)
        DssVestLike(MCD_VEST_MKR).yank(3);
        (
            DssVestLike(MCD_VEST_MKR_TREASURY).create({
                _usr: 0xfDB9F5e045D7326C1da87d0e199a05CDE5378EdD,
                _tot: 995.00 * 10**18,
                _bgn: MAY_01_2021,
                _tau: 4 * 365 days,
                _eta: 365 days,
                _mgr: PE_WALLET
            })
        );

        DssVestLike(MCD_VEST_MKR).yank(4);
        DssVestLike(MCD_VEST_MKR_TREASURY).restrict(
            DssVestLike(MCD_VEST_MKR_TREASURY).create({
                _usr: 0xBe4De3E151D52668c2C0610C985b4297833239C8,
                _tot: 995.00 * 10**18,
                _bgn: MAY_01_2021,
                _tau: 4 * 365 days,
                _eta: 365 days,
                _mgr: PE_WALLET
            })
        );

        DssVestLike(MCD_VEST_MKR).yank(5);
        DssVestLike(MCD_VEST_MKR_TREASURY).restrict(
            DssVestLike(MCD_VEST_MKR_TREASURY).create({
                _usr: 0x58EA3C96a8b81abC01EB78B98deCe2AD1e5fd7fc,
                _tot: 995.00 * 10**18,
                _bgn: MAY_01_2021,
                _tau: 4 * 365 days,
                _eta: 365 days,
                _mgr: PE_WALLET
            })
        );

        DssVestLike(MCD_VEST_MKR).yank(6);
        DssVestLike(MCD_VEST_MKR_TREASURY).restrict(
            DssVestLike(MCD_VEST_MKR_TREASURY).create({
                _usr: 0xBAB4Cd1cB31Cd28f842335973712a6015eB0EcD5,
                _tot: 995.00 * 10**18,
                _bgn: MAY_01_2021,
                _tau: 4 * 365 days,
                _eta: 365 days,
                _mgr: PE_WALLET
            })
        );

        DssVestLike(MCD_VEST_MKR).yank(7);
        (
            DssVestLike(MCD_VEST_MKR_TREASURY).create({
                _usr: 0xB5c86aff90944CFB3184902482799bD5fA3B18dD,
                _tot: 995.00 * 10**18,
                _bgn: MAY_01_2021,
                _tau: 4 * 365 days,
                _eta: 365 days,
                _mgr: PE_WALLET
            })
        );

        DssVestLike(MCD_VEST_MKR).yank(8);
        DssVestLike(MCD_VEST_MKR_TREASURY).restrict(
            DssVestLike(MCD_VEST_MKR_TREASURY).create({
                _usr: 0x780f478856ebE01e46d9A432e8776bAAB5A81b5b,
                _tot: 995.00 * 10**18,
                _bgn: MAY_01_2021,
                _tau: 4 * 365 days,
                _eta: 365 days,
                _mgr: PE_WALLET
            })
        );

        DssVestLike(MCD_VEST_MKR).yank(9);
        DssVestLike(MCD_VEST_MKR_TREASURY).restrict(
            DssVestLike(MCD_VEST_MKR_TREASURY).create({
                _usr: 0x34364E234b3DD02FF5c8A2ad9ba86bbD3D3D3284,
                _tot: 995.00 * 10**18,
                _bgn: MAY_01_2021,
                _tau: 4 * 365 days,
                _eta: 365 days,
                _mgr: PE_WALLET
            })
        );

        DssVestLike(MCD_VEST_MKR).yank(10);
        DssVestLike(MCD_VEST_MKR_TREASURY).restrict(
            DssVestLike(MCD_VEST_MKR_TREASURY).create({
                _usr: 0x46E5DBad3966453Af57e90Ec2f3548a0e98ec979,
                _tot: 995.00 * 10**18,
                _bgn: MAY_01_2021,
                _tau: 4 * 365 days,
                _eta: 365 days,
                _mgr: PE_WALLET
            })
        );

        DssVestLike(MCD_VEST_MKR).yank(11);
        DssVestLike(MCD_VEST_MKR_TREASURY).restrict(
            DssVestLike(MCD_VEST_MKR_TREASURY).create({
                _usr: 0x18CaE82909C31b60Fe0A9656D76406345C9cb9FB,
                _tot: 995.00 * 10**18,
                _bgn: MAY_01_2021,
                _tau: 4 * 365 days,
                _eta: 365 days,
                _mgr: PE_WALLET
            })
        );

        DssVestLike(MCD_VEST_MKR).yank(12);
        (
            DssVestLike(MCD_VEST_MKR_TREASURY).create({
                _usr: 0x301dD8eB831ddb93F128C33b9d9DC333210d9B25,
                _tot: 995.00 * 10**18,
                _bgn: MAY_01_2021,
                _tau: 4 * 365 days,
                _eta: 365 days,
                _mgr: PE_WALLET
            })
        );

        DssVestLike(MCD_VEST_MKR).yank(13);
        (
            DssVestLike(MCD_VEST_MKR_TREASURY).create({
                _usr: 0xBFC47D0D7452a25b7d3AA4d7379c69A891bD5d43,
                _tot: 995.00 * 10**18,
                _bgn: MAY_01_2021,
                _tau: 4 * 365 days,
                _eta: 365 days,
                _mgr: PE_WALLET
            })
        );

        DssVestLike(MCD_VEST_MKR).yank(14);
        (
            DssVestLike(MCD_VEST_MKR_TREASURY).create({
                _usr: 0xcD16aa978A89Aa26b3121Fc8dd32228d7D0fcF4a,
                _tot: 995.00 * 10**18,
                _bgn: SEP_13_2021,
                _tau: 4 * 365 days,
                _eta: 365 days,
                _mgr: PE_WALLET
            })
        );

        DssVestLike(MCD_VEST_MKR).yank(15);
        DssVestLike(MCD_VEST_MKR_TREASURY).restrict(
            DssVestLike(MCD_VEST_MKR_TREASURY).create({
                _usr: 0x3189cfe40CF011AAb13aDD8aE7284deD4CD30602,
                _tot: 995.00 * 10**18,
                _bgn: JUN_21_2021,
                _tau: 4 * 365 days,
                _eta: 365 days,
                _mgr: PE_WALLET
            })
        );

        DssVestLike(MCD_VEST_MKR).yank(16);
        DssVestLike(MCD_VEST_MKR_TREASURY).restrict(
            DssVestLike(MCD_VEST_MKR_TREASURY).create({
                _usr: 0x29b37159C09a65af6a7CFb062998B169879442B6,
                _tot: 995.00 * 10**18,
                _bgn: SEP_20_2021,
                _tau: 4 * 365 days,
                _eta: 365 days,
                _mgr: PE_WALLET
            })
        );
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) public {}
}
