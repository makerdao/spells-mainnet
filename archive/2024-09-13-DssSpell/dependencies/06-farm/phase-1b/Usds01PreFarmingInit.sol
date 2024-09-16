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

struct Usds01PreFarmingInitParams {
    address usds;
    address rewards;
    bytes32 rewardsKey; // Chainlog key
}

library Usds01PreFarmingInit {
    ChainlogLike internal constant chainlog = ChainlogLike(0xdA0Ab1e0017DEbCd72Be8599041a2aa3bA7e740F);

    function init(Usds01PreFarmingInitParams memory p) internal {
        require(
            StakingRewardsLike(p.rewards).stakingToken() == p.usds,
            "Usds01PreFarmingInit/rewards-staking-token-mismatch"
        );
        require(
            StakingRewardsLike(p.rewards).rewardsToken() == address(0),
            "Usds01PreFarmingInit/invalid-rewards-token"
        );
        require(StakingRewardsLike(p.rewards).rewardRate() == 0, "Usds01PreFarmingInit/reward-rate-not-zero");
        require(
            StakingRewardsLike(p.rewards).rewardsDistribution() == address(0),
            "Usds01PreFarmingInit/rewards-distribution-already-set"
        );
        require(
            StakingRewardsLike(p.rewards).owner() == chainlog.getAddress("MCD_PAUSE_PROXY"),
            "Usds01PreFarmingInit/invalid-owner"
        );

        chainlog.setAddress(p.rewardsKey, p.rewards);
    }
}

interface StakingRewardsLike {
    function owner() external view returns (address);

    function rewardRate() external view returns (uint256);

    function rewardsDistribution() external view returns (address);

    function rewardsToken() external view returns (address);

    function stakingToken() external view returns (address);
}

interface ChainlogLike {
    function getAddress(bytes32 key) external view returns (address);

    function setAddress(bytes32 key, address addr) external;
}
