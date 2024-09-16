// SPDX-FileCopyrightText: © 2023 Dai Foundation <www.daifoundation.org>
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
pragma solidity ^0.8.13;

struct VestedRewardsDistributionJobInitConfig {
    bytes32 jobKey; // Chainlog key
}

struct VestedRewardsDistributionJobDeinitConfig {
    bytes32 jobKey; // Chainlog key
}

struct VestedRewardsDistributionJobSetDistConfig {
    address dist;
    uint256 interval;
}

struct VestedRewardsDistributionJobRemDistConfig {
    address dist;
}

library VestedRewardsDistributionJobInit {
    ChainlogLike internal constant chainlog = ChainlogLike(0xdA0Ab1e0017DEbCd72Be8599041a2aa3bA7e740F);

    function init(address job, VestedRewardsDistributionJobInitConfig memory cfg) internal {
        SequencerLike sequencer = SequencerLike(chainlog.getAddress("CRON_SEQUENCER"));
        require(
            VestedRewardsDistributionJobLike(job).sequencer() == address(sequencer),
            "VestedRewardsDistributionJobInit/invalid-sequencer"
        );
        sequencer.addJob(job);
        chainlog.setAddress(cfg.jobKey, job);
    }

    function deinit(address job, VestedRewardsDistributionJobDeinitConfig memory cfg) internal {
        SequencerLike sequencer = SequencerLike(chainlog.getAddress("CRON_SEQUENCER"));
        require(
            VestedRewardsDistributionJobLike(job).sequencer() == address(sequencer),
            "VestedRewardsDistributionJobInit/invalid-sequencer"
        );
        sequencer.removeJob(job);
        chainlog.removeAddress(cfg.jobKey);
    }

    function setDist(address job, VestedRewardsDistributionJobSetDistConfig memory cfg) internal {
        VestedRewardsDistributionJobLike(job).set(cfg.dist, cfg.interval);
    }

    function remDist(address job, VestedRewardsDistributionJobRemDistConfig memory cfg) internal {
        VestedRewardsDistributionJobLike(job).rem(cfg.dist);
    }
}

interface VestedRewardsDistributionJobLike {
    function sequencer() external view returns (address);
    function set(address dist, uint256 interval) external;
    function rem(address dist) external;
}

interface ChainlogLike {
    function getAddress(bytes32 key) external view returns (address);
    function removeAddress(bytes32 key) external;
    function setAddress(bytes32 key, address val) external;
}

interface SequencerLike {
    function addJob(address job) external;
    function removeJob(address job) external;
}
