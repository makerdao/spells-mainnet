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
pragma solidity ^0.8.16;

import {DssInstance} from "dss-test/MCD.sol";
import {DssLitePsmMigration, MigrationConfig, MigrationResult} from "../DssLitePsmMigration.sol";

struct DssLitePsmMigrationConfigPhase2 {
    bytes32 dstPsmKey;
    uint256 dstBuf; // [wad]
    uint256 dstMaxLine; // [rad]
    uint256 dstGap; // [rad]
    uint256 dstTtl; // [seconds]
    bytes32 srcPsmKey;
    uint256 srcTin; // [wad] - 10**18 = 100%
    uint256 srcTout; // [wad] - 10**18 = 100%
    uint256 srcMaxLine; // [rad]
    uint256 srcGap; // [rad]
    uint256 srcTtl; // [seconds]
    uint256 srcKeep; // [wad]
}

interface DssPsmLike {
    function file(bytes32, uint256) external;
}

interface DssLitePsmLike {
    function file(bytes32, uint256) external;
    function fill() external returns (uint256);
    function rush() external view returns (uint256);
}

interface AutoLineLike {
    function exec(bytes32) external returns (uint256);
    function setIlk(bytes32, uint256, uint256, uint256) external;
}

library DssLitePsmMigrationPhase2 {
    /**
     * @dev Performs the major migration of funds.
     * @param dss The MCD instance.
     * @param cfg The migration config params.
     */
    function migrate(DssInstance memory dss, DssLitePsmMigrationConfigPhase2 memory cfg) internal {
        /**
         * Notice:
         * There is a potential Flash Loan™ scenario where an attacker could:
         *
         *   1. Flash loan Dai.
         *   2. Sell Dai into `srcPsm` to leave only `srcKeep` there.
         *   3. Cast the spell - effectively nothing will be migrated because of the `srcKeep` constraint.
         *   4. Sell the gems obtained in step 2 back into `srcPsm`.
         *
         * As a result, nothing would be migrated. To prevent that, we enforce that `srcTin > 0`, so there is a fee to
         * be paid in step 4 above, which would disincentivize the attack.
         */
        require(cfg.srcTin > 0, "DssLitePsmMigrationConfigPhase2/src-tin-is-zero");

        /**
         * Notice:
         * There is a second potential Flash Loan™ scenario where anyone could:
         *
         *   1. Flash loan Dai.
         *   2. Sell Dai into `srcPsm` to leave it empty.
         *   3. Sell the gems obtained in step 2 into `dstPsm`.
         *
         * The outcome of this would be that anyone could force a full migration right after phase 2.
         *
         * To prevent that, we enforce that `srcTout > 0`, so there is a fee to be paid in step 3 above, which would
         * disincentivize the attack.
         */
        require(cfg.srcTout > 0, "DssLitePsmMigrationConfigPhase2/src-tout-is-zero");

        // 1. Migrate funds to the new PSM.
        MigrationResult memory res = DssLitePsmMigration.migrate(
            dss,
            MigrationConfig({
                srcPsmKey: cfg.srcPsmKey,
                dstPsmKey: cfg.dstPsmKey,
                srcKeep: cfg.srcKeep,
                dstWant: type(uint256).max
            })
        );

        /**
         * Notice:
         * There is another potential Flash Loan™ scenario which could prevent the desired amount of collateral
         * (`cfg.srcKeep`) to remain in `srcPsm`.
         *
         * For any amount `ink` that exists in `srcPsm`, the attacker could:
         *   1. Flash loan `ink` Dai.
         *   2. Sell Dai into `srcPsm` to leave it empty.
         *   3. Cast the spell - effectively nothing will be migrated, since the remaining `ink` is zero.
         *   4. Sell the gems obtained in step 2 into `dstPsm`.
         *
         * While it is possible to carry out that scenario at any point in time, if the user tries to do it before the
         * spell is cast, they will most likely be constrained by the low `line` set for `dstPsm`. If they try to do it
         * afterwards, there will be swap fees on `srcPsm`, which would make the costs high enough to disincentivize it.
         *
         * To prevent the issue described above, we are making an exception to the rule that spells should not revert
         * and actually checking if the desired amount of collateral remains in `srcPsm`.
         *
         * Even if the spell reverts because `srcInk` naturally became too low by the time of casting, the Maker
         * community could replenish `srcPsm` and try to cast the spell again right away so it does not fail.
         */
        (uint256 srcInk,) = dss.vat.urns(res.srcIlk, res.srcPsm);
        require(srcInk >= cfg.srcKeep, "DssLitePsmMigrationPhase2/remaining-ink-too-low");

        // 2. Update auto-line.
        AutoLineLike autoLine = AutoLineLike(dss.chainlog.getAddress("MCD_IAM_AUTO_LINE"));

        // 2.1. Update auto-line for `srcIlk`
        autoLine.setIlk(res.srcIlk, cfg.srcMaxLine, cfg.srcGap, cfg.srcTtl);
        autoLine.exec(res.srcIlk);

        // 2.2. Update auto-line for `dstIlk`
        // Notice: Setting auto-line parameters automatically resets time intervals.
        // Effectively, it allows `litePsm` `line` to increase faster than expected.
        autoLine.setIlk(res.dstIlk, cfg.dstMaxLine, cfg.dstGap, cfg.dstTtl);
        autoLine.exec(res.dstIlk);

        // 3. Set the final params for both PSMs.
        DssPsmLike(res.srcPsm).file("tin", cfg.srcTin);
        DssPsmLike(res.srcPsm).file("tout", cfg.srcTout);

        DssLitePsmLike(res.dstPsm).file("buf", cfg.dstBuf);

        // 4. Fill `dstPsm` so there is liquidity available immediately.
        // Notice: `dstPsm.fill` must be called last because it is constrained by both `cfg.buf` and `cfg.maxLine`.
        if (DssLitePsmLike(res.dstPsm).rush() > 0) {
            DssLitePsmLike(res.dstPsm).fill();
        }
    }
}
