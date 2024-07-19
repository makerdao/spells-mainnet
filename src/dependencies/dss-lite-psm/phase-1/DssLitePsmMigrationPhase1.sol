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
import {DssLitePsmInstance} from "../DssLitePsmInstance.sol";
import {DssLitePsmInit, DssLitePsmInitConfig} from "../DssLitePsmInit.sol";
import {DssLitePsmMigration, MigrationConfig, MigrationResult} from "../DssLitePsmMigration.sol";

struct DssLitePsmMigrationConfigPhase1 {
    bytes32 psmMomKey;
    bytes32 dstPsmKey;
    bytes32 dstPocketKey;
    address dstPip;
    bytes32 dstIlk;
    address dstGem;
    address dstPocket;
    uint256 dstBuf; // [wad]
    uint256 dstMaxLine; // [rad]
    uint256 dstGap; // [rad]
    uint256 dstTtl; // [seconds]
    uint256 dstWant; // [wad]
    bytes32 srcPsmKey;
    uint256 srcMaxLine; // [rad]
    uint256 srcGap; // [rad]
    uint256 srcTtl; // [seconds]
    uint256 srcKeep; // [wad]
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

library DssLitePsmMigrationPhase1 {
    /**
     * @dev Initializes a LitePsm instance and performs the initial migration of funds.
     * @param dss The MCD instance.
     * @param inst The LitePsm instance.
     * @param cfg The migration config params.
     */
    function initAndMigrate(
        DssInstance memory dss,
        DssLitePsmInstance memory inst,
        DssLitePsmMigrationConfigPhase1 memory cfg
    ) internal {
        // 1. Initialize the new PSM.
        DssLitePsmInit.init(
            dss,
            inst,
            DssLitePsmInitConfig({
                psmMomKey: cfg.psmMomKey,
                psmKey: cfg.dstPsmKey,
                pocketKey: cfg.dstPocketKey,
                pip: cfg.dstPip,
                ilk: cfg.dstIlk,
                gem: cfg.dstGem,
                pocket: cfg.dstPocket
            })
        );

        // 2. Migrate some funds to the new PSM.
        MigrationResult memory res = DssLitePsmMigration.migrate(
            dss,
            MigrationConfig({
                srcPsmKey: cfg.srcPsmKey,
                dstPsmKey: cfg.dstPsmKey,
                srcKeep: cfg.srcKeep,
                dstWant: cfg.dstWant
            })
        );

        // 3. Update auto-line.
        AutoLineLike autoLine = AutoLineLike(dss.chainlog.getAddress("MCD_IAM_AUTO_LINE"));

        // 3.1. Update auto-line for `srcIlk`
        autoLine.setIlk(res.srcIlk, cfg.srcMaxLine, cfg.srcGap, cfg.srcTtl);
        autoLine.exec(res.srcIlk);

        // 3.2. Update auto-line for `dstIlk`
        // Notice: Setting auto-line parameters automatically resets time intervals.
        // Effectively, it allows `litePsm` `line` to increase faster than expected.
        autoLine.setIlk(res.dstIlk, cfg.dstMaxLine, cfg.dstGap, cfg.dstTtl);
        autoLine.exec(res.dstIlk);

        // 4. Set the final params for `dstPsm`.
        DssLitePsmLike(res.dstPsm).file("buf", cfg.dstBuf);

        // 5. Fill `dstPsm` so there is liquidity available immediately.
        // Notice: `dstPsm.fill` must be called last because it is constrained by both `cfg.buf` and `cfg.maxLine`.
        if (DssLitePsmLike(res.dstPsm).rush() > 0) {
            DssLitePsmLike(res.dstPsm).fill();
        }
    }
}
