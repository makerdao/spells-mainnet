// SPDX-FileCopyrightText: © 2021 Dai Foundation <www.daifoundation.org>
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

contract Actions {

    struct Stream {
        uint256 streamId;
        bytes32 wallet;       // name of the wallet
        uint256 rewardAmount; // units
        uint256 start;
        uint256 cliff;
        uint256 end;
        uint256 durationDays;
        address manager;
        uint256 isRestricted;
        uint256 claimedAmount;
    }

    struct Payee {
        bytes32 wallet;       // name of the payee
        uint256 amount;       // units
    }

    struct Yank {
        uint256 streamId;
        bytes32 wallet;
        uint256 finPlanned;   // the planned fin of the stream (via variable defined below)
    }

    Stream[] public daiStreams;
    Stream[] public mkrStreams;
    Payee[] public daiPayees;
    Payee[] public mkrPayees;
    Yank[] public daiYanks;
    Yank[] public mkrYanks;


    // Expected global actions
    uint256 immutable DAI_STREAMS_COUNT;
    uint256 immutable DAI_PAYEES_COUNT;
    uint256 immutable DAI_YANKS_COUNT;

    uint256 immutable MKR_STREAMS_COUNT;
    uint256 immutable MKR_PAYEES_COUNT;
    uint256 immutable MKR_YANKS_COUNT;

    uint256 immutable DAI_SUM_PAYMENTS;
    uint256 immutable MKR_SUM_PAYMENTS;

    // Provide human-readable names for timestamps
    uint256 DEC_01_2023 = 1701385200;
    uint256 MARCH_31_2024 = 1711929599;
    uint256 NOV_30_2024 = 1733007599;

    constructor() {
        // Initialize the amount of streams and payees for MKR and DAI
        DAI_STREAMS_COUNT = 1;
        DAI_PAYEES_COUNT = 1;
        DAI_YANKS_COUNT = 2;

        MKR_STREAMS_COUNT = 1;
        MKR_PAYEES_COUNT = 0;
        MKR_YANKS_COUNT = 0;

        // Fill the number with the value from exec doc.
        DAI_SUM_PAYMENTS = 201_738;
        MKR_SUM_PAYMENTS = 0;

        // For each new stream, provide Stream object
        daiStreams.push(Stream({
            streamId:      38,
            wallet:        "ECOSYSTEM_FACILITATOR",
            rewardAmount:  504_000,
            start:         DEC_01_2023,
            cliff:         DEC_01_2023,
            end:           NOV_30_2024,
            durationDays:  366 days,
            manager:       address(0),
            isRestricted:  1,
            claimedAmount: 0
        }));

        mkrStreams.push(Stream({
            streamId:      44,
            wallet:        "ECOSYSTEM_FACILITATOR",
            rewardAmount:  216,
            start:         DEC_01_2023,
            cliff:         DEC_01_2023,
            end:           NOV_30_2024,
            durationDays:  366 days,
            manager:       address(0),
            isRestricted:  1,
            claimedAmount: 0
        }));

        // For each new payee, provide Payee object
        daiPayees.push(Payee({
            wallet: "BLOCKTOWER_WALLET_2",
            amount: 201_738
        }));

        // For each new yank, provide Yank object
        daiYanks.push(Yank({
            streamId: 18,
            wallet: "TECH",
            finPlanned: MARCH_31_2024
        }));

        daiYanks.push(Yank({
            streamId: 19,
            wallet: "STEAKHOUSE",
            finPlanned: MARCH_31_2024
        }));
    }

}
