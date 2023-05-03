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

pragma solidity 0.8.16;

import "dss-exec-lib/DssExec.sol";
import "dss-exec-lib/DssAction.sol";

interface GemLike {
    function transfer(address, uint256) external returns (bool);
    function allowance(address, address) external view returns (uint256);
    function approve(address, uint256) external returns (bool);
}

interface VestLike {
    function restrict(uint256) external;
    function create(address, uint256, uint256, uint256, uint256, address) external returns (uint256);
    function yank(uint256) external;
}

contract DssSpellAction is DssAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: cast keccak -- "$(wget 'https://raw.githubusercontent.com/makerdao/community/98e98eae03662eeab0dd2092ccc7edafb2dd75d3/governance/votes/Executive%20vote%20-%20April%2028%2C%202023.md' -q -O - 2>/dev/null)"
    string public constant override description =
        "2023-05-10 MakerDAO Executive Spell | Hash: TODO";

    // Many of the settings that change weekly rely on the rate accumulator
    // described at https://docs.makerdao.com/smart-contract-modules/rates-module
    // To check this yourself, use the following rate calculation (example 8%):
    //
    // $ bc -l <<< 'scale=27; e( l(1.08)/(60 * 60 * 24 * 365) )'
    //
    // A table of rates can be found at
    //    https://ipfs.io/ipfs/QmVp4mhhbwWGTfbh2BzwQB9eiBrQBKiqcPRZCaAxNUaar6
    //
    // uint256 internal constant X_PCT_RATE      = ;

    // Turn office hours on
    function officeHours() public pure override returns (bool) {
        return true;
    }

    uint256 internal constant MILLION = 10 ** 6;
    uint256 internal constant WAD     = 10 ** 18;
    uint256 internal constant RAD     = 10 ** 45;

    // 01 May 2023 12:00:00 AM UTC
    uint256 public constant MAY_01_2023              = 1682899200;
    // 01 May 2024 11:59:59 PM UTC
    uint256 public constant MAY_01_2024              = 1714607999;
    // 01 May 2025 11:59:59 PM UTC
    uint256 public constant MAY_01_2025              = 1746143999;

    // ECOSYSTEM ACTORS
    address internal constant PHOENIX_LABS_2         = 0x115F76A98C2268DaE6c1421eb6B08e4e1dF525dA;
    address internal constant PULL_UP                = address(0);

    address internal immutable MCD_VEST_MKR_TREASURY = DssExecLib.getChangelogAddress("MCD_VEST_MKR_TREASURY");
    address internal immutable MCD_VEST_DAI          = DssExecLib.getChangelogAddress("MCD_VEST_DAI");
    GemLike internal immutable MKR                   = GemLike(DssExecLib.mkr());

    function actions() public override {
        // ----- Stream Yanks -----
        // FORUM: https://mips.makerdao.com/mips/details/MIP106#6-6-2-1a-
        // GovAlpha | 2023-04-01 to 2024-03-31 | 900,000 DAI | 0x01D26f8c5cC009868A4BF66E268c17B057fF7A73

        // Yank DAI Stream ID 22 to Phoenix Labs as being replaced with new stream
        VestLike(MCD_VEST_DAI).yank(22);

        // Yank MKR Stream ID 37 to Phoenix Labs as being replaced with new stream
        VestLike(MCD_VEST_MKR_TREASURY).yank(37);

        // ----- Ecosystem Actor Dai Streams -----
        // Forum: https://mips.makerdao.com/mips/details/MIP106#6-6-2-1a-

        // Vote:
        // Phoenix Labs | 2023-05-01 to 2024-05-01 | 1,534,000 DAI | 0x115F76A98C2268DaE6c1421eb6B08e4e1dF525dA
        VestLike(MCD_VEST_DAI).restrict(
            VestLike(MCD_VEST_DAI).create(
                PHOENIX_LABS_2,            // usr
                1_534_000 * WAD,           // tot
                MAY_01_2023,               // bgn
                MAY_01_2024 - MAY_01_2023, // tau
                0,                         // eta
                address(0)                 // mgr
            )
        );

        // Vote: https://vote.makerdao.com/polling/QmebPdpa#poll-detail
        // PullUp | 2023-05-01 to 2024-05-01 | 3,300,000 DAI | TBD
        // VestLike(MCD_VEST_DAI).restrict(
        //     VestLike(MCD_VEST_DAI).create(
        //         PULL_UP,                   // usr
        //         3_300_000 * WAD,           // tot
        //         APR_01_2023,               // bgn
        //         APR_01_2024 - APR_01_2023, // tau
        //         0,                         // eta
        //         address(0)                 // mgr
        //     )
        // );


        // ----- Ecosystem Actor MKR Streams -----
        // FORUM: https://mips.makerdao.com/mips/details/MIP106#6-6-2-1a-

        // Increase allowance by new vesting delta
        uint256 newVesting = 4_000 * WAD; // PULLUP
               newVesting += 986.25 ether; // Phoenix Labs
        MKR.approve(address(MCD_VEST_MKR_TREASURY), MKR.allowance(address(this), address(MCD_VEST_MKR_TREASURY)) + newVesting);

        // VOTE: 
        // Phoenix Labs | 2023-05-01 to 2024-05-01 | Cliff 2023-05-01 | 986.25 MKR
        VestLike(MCD_VEST_MKR_TREASURY).restrict(
            VestLike(MCD_VEST_MKR_TREASURY).create(
                PHOENIX_LABS_2,            // usr
                986.25 ether,              // tot
                MAY_01_2023,               // bgn
                MAY_01_2024 - MAY_01_2023, // tau
                0,                         // eta
                address(0)                 // mgr
            )
        );

        // VOTE: https://vote.makerdao.com/polling/QmcswbHs#poll-detail, https://vote.makerdao.com/polling/QmebPdpa#poll-detail
        // PullUp | 2023-05-01 to 2025-05-01 | Cliff 2023-05-01 | 4,000 MKR
        // VestLike(MCD_VEST_MKR_TREASURY).restrict(
        //     VestLike(MCD_VEST_MKR_TREASURY).create(
        //         PULL_UP,                   // usr
        //         4_000 * WAD,               // tot
        //         MAY_01_2023,               // bgn
        //         MAY_01_2025 - MAY_01_2023, // tau
        //         0,                         // eta
        //         address(0)                 // mgr
        //     )
        // );


        // Bump the chainlog
        DssExecLib.setChangelogVersion("1.14.12");
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) {}
}
