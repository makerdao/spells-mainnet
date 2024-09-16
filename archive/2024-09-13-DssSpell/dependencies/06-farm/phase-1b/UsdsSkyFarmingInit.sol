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

pragma solidity ^0.8.16;

import {StakingRewardsInit, StakingRewardsInitParams} from "../StakingRewardsInit.sol";
import {VestedRewardsDistributionInit, VestedRewardsDistributionInitParams} from "../VestedRewardsDistributionInit.sol";
import {VestInit, VestCreateParams} from "../VestInit.sol";

struct UsdsSkyFarmingInitParams {
    address usds;
    address sky;
    address rewards;
    bytes32 rewardsKey; // Chainlog key
    address dist;
    bytes32 distKey; // Chainlog key
    address vest;
    uint256 vestTot;
    uint256 vestBgn;
    uint256 vestTau;
}

struct UsdsSkyFarmingInitResult {
    uint256 vestId;
}

library UsdsSkyFarmingInit {
    ChainlogLike internal constant chainlog = ChainlogLike(0xdA0Ab1e0017DEbCd72Be8599041a2aa3bA7e740F);

    function init(UsdsSkyFarmingInitParams memory p) internal returns (UsdsSkyFarmingInitResult memory r) {
        require(DssVestWithGemLike(p.vest).gem() == p.sky, "UsdsSkyFarmingInit/vest-gem-mismatch");

        require(
            StakingRewardsLike(p.rewards).stakingToken() == p.usds,
            "UsdsSkyFarmingInit/rewards-staking-token-mismatch"
        );
        require(
            StakingRewardsLike(p.rewards).rewardsToken() == p.sky,
            "UsdsSkyFarmingInit/rewards-rewards-token-mismatch"
        );
        require(StakingRewardsLike(p.rewards).rewardRate() == 0, "UsdsSkyFarmingInit/reward-rate-not-zero");
        require(
            StakingRewardsLike(p.rewards).rewardsDistribution() == address(0),
            "UsdsSkyFarmingInit/rewards-distribution-already-set"
        );
        require(
            StakingRewardsLike(p.rewards).owner() == chainlog.getAddress("MCD_PAUSE_PROXY"),
            "UsdsSkyFarmingInit/invalid-owner"
        );

        require(VestedRewardsDistributionLike(p.dist).gem() == p.sky, "UsdsSkyFarmingInit/dist-gem-mismatch");
        require(VestedRewardsDistributionLike(p.dist).dssVest() == p.vest, "UsdsSkyFarmingInit/dist-dss-vest-mismatch");
        require(
            VestedRewardsDistributionLike(p.dist).stakingRewards() == p.rewards,
            "UsdsSkyFarmingInit/dist-staking-rewards-mismatch"
        );

        // `vest` is expected to be an instance of `DssVestMintable`.
        // Check if minting rights on `sky` were granted to `vest`.
        require(WardsLike(p.sky).wards(p.vest) == 1, "UsdsSkyFarmingInit/missing-sky-rely-vest");
        // Set `dist` with  `rewardsDistribution` role in `rewards`.
        StakingRewardsInit.init(p.rewards, StakingRewardsInitParams({dist: p.dist}));

        // Create the proper vesting stream for rewards distribution.
        uint256 vestId = VestInit.create(
            p.vest,
            VestCreateParams({usr: p.dist, tot: p.vestTot, bgn: p.vestBgn, tau: p.vestTau, eta: 0})
        );

        // Set the `vestId` in `dist`
        VestedRewardsDistributionInit.init(p.dist, VestedRewardsDistributionInitParams({vestId: vestId}));

        r.vestId = vestId;

        chainlog.setAddress(p.rewardsKey, p.rewards);
        chainlog.setAddress(p.distKey, p.dist);
    }
}

interface WardsLike {
    function wards(address who) external view returns (uint256);
}

interface DssVestWithGemLike {
    function gem() external view returns (address);
}

interface StakingRewardsLike {
    function owner() external view returns (address);

    function rewardRate() external view returns (uint256);

    function rewardsDistribution() external view returns (address);

    function rewardsToken() external view returns (address);

    function stakingToken() external view returns (address);
}

interface VestedRewardsDistributionLike {
    function dssVest() external view returns (address);

    function gem() external view returns (address);

    function stakingRewards() external view returns (address);
}

interface ChainlogLike {
    function getAddress(bytes32 key) external view returns (address);

    function setAddress(bytes32 key, address addr) external;
}
