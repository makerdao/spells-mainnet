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

interface VestLike {
    function restrict(uint256 _id) external;
    function create(address _usr, uint256 _tot, uint256 _bgn, uint256 _tau, uint256 _eta, address _mgr) external returns (uint256 id);
    function yank(uint256 _id) external;
}
interface NetworkPaymentAdapterLike {
    function bufferMax() external view returns (uint256);
    function minimumPayment() external view returns (uint256);
    function file(bytes32 what, uint256 data) external;
    function file(bytes32 what, address data) external;
}

interface DssCronSequencerLike {
    function windows(bytes32) external view returns (uint256 start, uint256 length);
}

contract DssSpellAction is DssAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: cast keccak -- "$(wget 'https://raw.githubusercontent.com/makerdao/community/TODO' -q -O - 2>/dev/null)"
    string public constant override description =
        "2023-05-24 MakerDAO Executive Spell | Hash: TODO";

    // Set office hours according to the summary
    function officeHours() public pure override returns (bool) {
        return true;
    }

    uint256 internal constant WAD                       = 10 ** 18;

    // 24 May 2023 12:00:00 AM UTC
    uint256 internal constant MAY_24_2023               = 1684886400;
    // 23 May 2023 11:59:59 PM UTC
    uint256 internal constant MAY_23_2024               = 1716508799;
    // 23 May 2026 11:59:59 PM UTC
    uint256 internal constant MAY_23_2026               = 1779580799;

    // Keeper Network
    address internal constant GELATO_PAYMENT_ADAPTER    = 0x0B5a34D084b6A5ae4361de033d1e6255623b41eD;
    address internal constant GELATO_TREASURY           = 0xbfDC6b9944B7EFdb1e2Bc9D55ae9424a2a55b206;
    address internal constant KEEP3R_PAYMENT_ADAPTER    = 0xaeFed819b6657B3960A8515863abe0529Dfc444A;
    address internal constant KEEP3R_TREASURY           = 0x4DfC6DA2089b0dfCF04788b341197146Ea97f743;
    address internal constant CHAINLINK_PAYMENT_ADAPTER = 0xfB5e1D841BDA584Af789bDFABe3c6419140EC065;
    address internal constant TECHOPS_VEST_STREAMING    = 0x5A6007d17302238D63aB21407FF600a67765f982;
    
    address internal constant DSS_CRON_SEQUENCER        = 0x238b4E35dAed6100C6162fAE4510261f88996EC9;
    address internal immutable MCD_VEST_DAI             = DssExecLib.getChangelogAddress("MCD_VEST_DAI");

    function actions() public override {

        // --------- Keeper Network Amendments ---------
        // Poll: https://vote.makerdao.com/polling/QmZZJcCj#poll-detail

        // Yank DAI stream ID 16 to Chainlink Automation - being replaced by new stream
        VestLike(MCD_VEST_DAI).yank(16);


        // GELATO    | 1,500 DAI/day | 1_644_000 DAI | 3 years | Vest Target: 0x0B5a34D084b6A5ae4361de033d1e6255623b41eD | Treasury: 0xbfDC6b9944B7EFdb1e2Bc9D55ae9424a2a55b206
        (,uint256 windowLengthGelato) = DssCronSequencerLike(DSS_CRON_SEQUENCER).windows(bytes32("GELATO"));
        require(windowLengthGelato == 13, "Gelato/incrorrect-window-length");
        require(NetworkPaymentAdapterLike(GELATO_PAYMENT_ADAPTER).bufferMax() == 20_000 * WAD, "Gelato-Payment-Adapter/incorrect-buffer-max");
        require(NetworkPaymentAdapterLike(GELATO_PAYMENT_ADAPTER).minimumPayment() == 4_000 * WAD, "Gelato-Payment-Adapter/incorrect-minimum-payment");
        uint256 gelatoVestId = VestLike(MCD_VEST_DAI).create(
                GELATO_PAYMENT_ADAPTER,    // usr
                1_644_000 * WAD,           // tot
                MAY_24_2023,               // bgn
                MAY_23_2026 - MAY_24_2023, // tau
                0,                         // eta
                address(0)                 // mgr
        );
        VestLike(MCD_VEST_DAI).restrict(gelatoVestId);
        NetworkPaymentAdapterLike(GELATO_PAYMENT_ADAPTER).file("vestId", gelatoVestId);
        NetworkPaymentAdapterLike(GELATO_PAYMENT_ADAPTER).file("treasury", GELATO_TREASURY);

        // KEEP3R    | 1,500 DAI/day | 1_644_000 DAI | 3 years | Vest Target: 0xaeFed819b6657B3960A8515863abe0529Dfc444A | Treasury: 0x4DfC6DA2089b0dfCF04788b341197146Ea97f743
        (,uint256 windowLengthKeeper) = DssCronSequencerLike(DSS_CRON_SEQUENCER).windows(bytes32("KEEP3R"));
        require(windowLengthKeeper == 13, "Keep3r/incrorrect-window-length");
        require(NetworkPaymentAdapterLike(KEEP3R_PAYMENT_ADAPTER).bufferMax() == 20_000 * WAD, "Keep3r-Payment-Adapter/incorrect-buffer-max");
        require(NetworkPaymentAdapterLike(KEEP3R_PAYMENT_ADAPTER).minimumPayment() == 4_000 * WAD, "Keep3r-Payment-Adapter/incorrect-minimum-payment");
        uint256 kepperVestId = VestLike(MCD_VEST_DAI).create(
                KEEP3R_PAYMENT_ADAPTER,    // usr
                1_644_000 * WAD,           // tot
                MAY_24_2023,               // bgn
                MAY_23_2026 - MAY_24_2023, // tau
                0,                         // eta
                address(0)                 // mgr
        );
        VestLike(MCD_VEST_DAI).restrict(kepperVestId);
        NetworkPaymentAdapterLike(KEEP3R_PAYMENT_ADAPTER).file("vestId", kepperVestId);
        NetworkPaymentAdapterLike(KEEP3R_PAYMENT_ADAPTER).file("treasury", KEEP3R_TREASURY);

        // CHAINLINK | 1,500 DAI/day | 1_644_000 DAI | 3 years | Vest Target: 0xfB5e1D841BDA584Af789bDFABe3c6419140EC065
        (,uint256 windowLengthChainlink) = DssCronSequencerLike(DSS_CRON_SEQUENCER).windows(bytes32("CHAINLINK"));
        require(windowLengthChainlink == 13, "Chainling/incrorrect-window-length");
        require(NetworkPaymentAdapterLike(CHAINLINK_PAYMENT_ADAPTER).bufferMax() == 20_000 * WAD, "Chainlink-Payment-Adapter/incorrect-buffer-max");
        require(NetworkPaymentAdapterLike(CHAINLINK_PAYMENT_ADAPTER).minimumPayment() == 4_000 * WAD, "Chainlink-Payment-Adapter/incorrect-minimum-payment");
        uint256 chainlinkVestId = VestLike(MCD_VEST_DAI).create(
                CHAINLINK_PAYMENT_ADAPTER, // usr
                1_644_000 * WAD,           // tot
                MAY_24_2023,               // bgn
                MAY_23_2026 - MAY_24_2023, // tau
                0,                         // eta
                address(0)                 // mgr
        );
        VestLike(MCD_VEST_DAI).restrict(chainlinkVestId);
        NetworkPaymentAdapterLike(CHAINLINK_PAYMENT_ADAPTER).file("vestId", chainlinkVestId);

        // TECHOPS   | 1,000 DAI/day | 366_000 DAI   | 1 years | Vest Target: 0x5A6007d17302238D63aB21407FF600a67765f982
        VestLike(MCD_VEST_DAI).restrict(
            VestLike(MCD_VEST_DAI).create(
                TECHOPS_VEST_STREAMING,    // usr
                366_000 * WAD,             // tot
                MAY_24_2023,               // bgn
                MAY_23_2024 - MAY_24_2023, // tau
                0,                         // eta
                address(0)                 // mgr
            )
        );


        // --------- CAIS Bootstrap Funding ---------
        // Poll: https://vote.makerdao.com/polling/Qmc6Wqrc#poll-detail
        // DssExecLib.sendPaymentFromSurplusBuffer(CAIS_WALLET, XXX_XXX);

        // Bump the chainlog
        DssExecLib.setChangelogVersion("1.14.12");
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) {}
}
