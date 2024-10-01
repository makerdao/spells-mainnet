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

struct DssLitePsmMigrationConfigPhase3 {
    bytes32 dstPsmKey;
    uint256 dstBuf; // [wad]
    uint256 dstMaxLine; // [rad]
    uint256 dstGap; // [rad]
    uint256 dstTtl; // seconds
    bytes32 srcPsmKey;
}

interface DssPsmLike {
    function file(bytes32, uint256) external;
    function ilk() external view returns (bytes32);
}

interface DssLitePsmLike {
    function file(bytes32, uint256) external;
    function fill() external returns (uint256);
    function rush() external view returns (uint256);
}

interface AutoLineLike {
    function exec(bytes32) external returns (uint256);
    function remIlk(bytes32) external;
    function setIlk(bytes32, uint256, uint256, uint256) external;
}

library DssLitePsmMigrationPhase3 {
    /**
     * @dev Performs the final migration of funds.
     * @param dss The MCD instance.
     * @param cfg The migration config params.
     */
    function migrate(DssInstance memory dss, DssLitePsmMigrationConfigPhase3 memory cfg) internal {
        // 1. Migrate all funds to the new PSM.
        MigrationResult memory res = DssLitePsmMigration.migrate(
            dss,
            MigrationConfig({srcPsmKey: cfg.srcPsmKey, dstPsmKey: cfg.dstPsmKey, srcKeep: 0, dstWant: type(uint256).max})
        );

        // 2. Update auto-line.
        AutoLineLike autoLine = AutoLineLike(dss.chainlog.getAddress("MCD_IAM_AUTO_LINE"));

        // 2.1. Remove `srcPsm` from AutoLine.
        autoLine.remIlk(res.srcIlk);

        // 2.2. Adjust global line accordingly.
        (,,, uint256 srcLine,) = dss.vat.ilks(res.srcIlk);
        dss.vat.file(res.srcIlk, "line", 0);
        dss.vat.file("Line", dss.vat.Line() - srcLine);

        // 2.3. Update auto-line for `dstPsm`
        // Notice: Setting auto-line parameters automatically resets time intervals.
        // Effectively, it allows `litePsm` `line` to increase faster than expected.
        autoLine.setIlk(res.dstIlk, cfg.dstMaxLine, cfg.dstGap, cfg.dstTtl);
        autoLine.exec(res.dstIlk);

        // 3. Set the final params for both PSMs.
        DssPsmLike(res.srcPsm).file("tin", 0);
        DssPsmLike(res.srcPsm).file("tout", 0);

        DssLitePsmLike(res.dstPsm).file("buf", cfg.dstBuf);

        // 4. Fill `dstPsm` so there is liquidity available immediately.
        // Notice: `dstPsm.fill` must be called last because it is constrained by both `cfg.buf` and `cfg.maxLine`.
        if (DssLitePsmLike(res.dstPsm).rush() > 0) {
            DssLitePsmLike(res.dstPsm).fill();
        }
    }
}
