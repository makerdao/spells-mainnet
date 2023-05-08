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

interface StarknetLike {
    function setCeiling(uint256 _ceiling) external;
}

interface GemLike {
    function transfer(address, uint256) external returns (bool);
    function allowance(address, address) external view returns (uint256);
    function approve(address, uint256) external returns (bool);
}

interface VestLike {
    function file(bytes32, uint256) external;
    function restrict(uint256) external;
    function create(address, uint256, uint256, uint256, uint256, address) external returns (uint256);
    function yank(uint256) external;
}

contract DssSpellAction is DssAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: cast keccak -- "$(wget 'https://raw.githubusercontent.com/makerdao/community/3e28783bb8e5dc0ad2ea2597cf5ae825b6ee7ee8/governance/votes/Executive%20vote%20-%20May%2010%2C%202023.md' -q -O - 2>/dev/null)"
    string public constant override description =
        "2023-05-10 MakerDAO Executive Spell | Hash: 0x194493aa72c265dd0e40716e4d56a3e9f5c54343cc42ef9cb4ca5439ccd0d51c";

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

    uint256 internal constant ZERO_PT_SEVEN_FIVE_PCT_RATE    = 1000000000236936036262880196;
    uint256 internal constant ONE_PCT_RATE                   = 1000000000315522921573372069;
    uint256 internal constant ONE_PT_SEVEN_FIVE_PCT_RATE     = 1000000000550121712943459312;
    uint256 internal constant THREE_PT_TWO_FIVE_PCT_RATE     = 1000000001014175731521720677;

    uint256 internal constant MILLION                        = 10 ** 6;
    uint256 internal constant WAD                            = 10 ** 18;
    uint256 internal constant RAD                            = 10 ** 45;

    // 01 May 2023 12:00:00 AM UTC
    uint256 public constant MAY_01_2023                      = 1682899200;
    // 01 May 2024 11:59:59 PM UTC
    uint256 public constant MAY_01_2024                      = 1714607999;
    // 01 May 2025 11:59:59 PM UTC
    uint256 public constant MAY_01_2025                      = 1746143999;

    // ECOSYSTEM ACTORS
    address internal constant PHOENIX_LABS_2                 = 0x115F76A98C2268DaE6c1421eb6B08e4e1dF525dA;
    address internal constant PULL_UP                        = 0x42aD911c75d25E21727E45eCa2A9d999D5A7f94c;
    
    address internal constant PULL_UP_VEST_MGR               = 0x9B6213D350A4AFbda2361b6572A07C90c22002F1;

    address internal immutable MCD_VEST_MKR_TREASURY         = DssExecLib.getChangelogAddress("MCD_VEST_MKR_TREASURY");
    address internal immutable MCD_VEST_DAI                  = DssExecLib.getChangelogAddress("MCD_VEST_DAI");
    GemLike internal immutable MKR                           = GemLike(DssExecLib.mkr());

    address internal immutable STARKNET_DAI_BRIDGE           = DssExecLib.getChangelogAddress("STARKNET_DAI_BRIDGE");

    function actions() public override {

        // ---------- Starknet ----------
        // Increase L1 Starknet Bridge Limit from 1,000,000 DAI to 5,000,000 DAI
        // Forum: https://forum.makerdao.com/t/april-26th-2023-spell-starknet-bridge-limit/20589
        StarknetLike(STARKNET_DAI_BRIDGE).setCeiling(5 * MILLION * WAD);

        // ---------- Risk Parameters Changes (Stability Fee & DC-IAM) ----------
        // Poll: https://vote.makerdao.com/polling/QmYFfRuR#poll-detail
        // Forum: https://forum.makerdao.com/t/out-of-scope-proposed-risk-parameters-changes-stability-fee-dc-iam/20564

        // Increase ETH-A Stability Fee by 0.25% from 1.5% to 1.75%.
        DssExecLib.setIlkStabilityFee("ETH-A", ONE_PT_SEVEN_FIVE_PCT_RATE, true);

        // Increase ETH-B Stability Fee by 0.25% from 3% to 3.25%.
        DssExecLib.setIlkStabilityFee("ETH-B", THREE_PT_TWO_FIVE_PCT_RATE, true);

        // Increase ETH-C Stability Fee by 0.25% from 0.75% to 1%.
        DssExecLib.setIlkStabilityFee("ETH-C", ONE_PCT_RATE, true);

        // Increase WSTETH-A Stability Fee by 0.25% from 1.5% to 1.75%.
        DssExecLib.setIlkStabilityFee("WSTETH-A", ONE_PT_SEVEN_FIVE_PCT_RATE, true);

        // Increase WSTETH-B Stability Fee by 0.25% from 0.75% to 1%.
        DssExecLib.setIlkStabilityFee("WSTETH-B", ONE_PCT_RATE, true);

        // Increase RETH-A Stability Fee by 0.25% from 0.5% to 0.75%.
        DssExecLib.setIlkStabilityFee("RETH-A", ZERO_PT_SEVEN_FIVE_PCT_RATE, true);

        // Increase CRVV1ETHSTETH-A Stability Fee by 0.25% from 1.5% to 1.75%.
        DssExecLib.setIlkStabilityFee("CRVV1ETHSTETH-A", ONE_PT_SEVEN_FIVE_PCT_RATE, true);


        // Increase the WSTETH-A gap by 15 million DAI from 15 million DAI to 30 million DAI.
        // Increase the WSTETH-A ttl by 21,600 seconds from 21,600 seconds to 43,200 seconds
        DssExecLib.setIlkAutoLineParameters("WSTETH-A", 500 * MILLION, 30 * MILLION, 12 hours);

        // Increase the WSTETH-B gap by 15 million DAI from 15 million DAI to 30 million DAI.
        // Increase the WSTETH-B ttl by 28,800 seconds from 28,800 seconds to 57,600 seconds.
        DssExecLib.setIlkAutoLineParameters("WSTETH-B", 500 * MILLION, 30 * MILLION, 16 hours);

        // Reduce the WBTC-A gap by 10 million DAI from 20 million DAI to 10 million DAI.
        DssExecLib.setIlkAutoLineParameters("WBTC-A", 500 * MILLION, 10 * MILLION, 24 hours);

        // Reduce the WBTC-B gap by 5 million DAI from 10 million DAI to 5 million DAI.
        DssExecLib.setIlkAutoLineParameters("WBTC-B", 250 * MILLION, 5 * MILLION, 24 hours);

        // Reduce the WBTC-C gap by 10 million DAI from 20 million DAI to 10 million DAI.
        DssExecLib.setIlkAutoLineParameters("WBTC-C", 500 * MILLION, 10 * MILLION, 24 hours);


        // ----- Stream Yanks -----
        // FORUM: https://mips.makerdao.com/mips/details/MIP106#6-6-2-1a-

        // Yank DAI Stream ID 22 to Phoenix Labs as being replaced with new stream
        VestLike(MCD_VEST_DAI).yank(22);

        // Yank MKR Stream ID 37 to Phoenix Labs as being replaced with new stream
        VestLike(MCD_VEST_MKR_TREASURY).yank(37);

        // ----- Ecosystem Actor Dai Streams -----
        // Forum: https://mips.makerdao.com/mips/details/MIP106#6-6-2-1a-

        // Vote:
        // Phoenix Labs | 2023-05-01 to 2024-05-01 | 1,534,000 DAI
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
        // PullUp | 2023-05-01 to 2024-05-01 | 3,300,000 DAI
        VestLike(MCD_VEST_DAI).restrict(
            VestLike(MCD_VEST_DAI).create(
                PULL_UP,                   // usr
                3_300_000 * WAD,           // tot
                MAY_01_2023,               // bgn
                MAY_01_2024 - MAY_01_2023, // tau
                0,                         // eta
                PULL_UP_VEST_MGR           // mgr
            )
        );


        // ----- Ecosystem Actor MKR Streams -----
        // FORUM: https://mips.makerdao.com/mips/details/MIP106#6-6-2-1a-
        // VOTE: VOTE: https://vote.makerdao.com/polling/QmTYdpaU#poll-detail

        // Set system-wide cap on maximum vesting speed
        VestLike(MCD_VEST_MKR_TREASURY).file("cap", 2_200 * WAD / 365 days);

        // Increase allowance by new vesting delta
        uint256 newVesting = 4_000 * WAD; // PULLUP
               newVesting += 986.25 ether; // Phoenix Labs
        MKR.approve(address(MCD_VEST_MKR_TREASURY), MKR.allowance(address(this), address(MCD_VEST_MKR_TREASURY)) + newVesting);

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
        VestLike(MCD_VEST_MKR_TREASURY).restrict(
            VestLike(MCD_VEST_MKR_TREASURY).create(
                PULL_UP,                   // usr
                4_000 * WAD,               // tot
                MAY_01_2023,               // bgn
                MAY_01_2025 - MAY_01_2023, // tau
                0,                         // eta
                PULL_UP_VEST_MGR           // mgr
            )
        );

        // ----- Ecosystem Actor Dai Transfers -----
        // FORUM: https://mips.makerdao.com/mips/details/MIP106#6-6-2-1a-
        // VOTE:  https://vote.makerdao.com/polling/QmTYdpaU#poll-detail

        // Phoenix Labs - 318,000 DAI - 0x115F76A98C2268DaE6c1421eb6B08e4e1dF525dA
        DssExecLib.sendPaymentFromSurplusBuffer(PHOENIX_LABS_2, 318_000);
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) {}
}
