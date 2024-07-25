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

struct MigrationConfig {
    bytes32 srcPsmKey; // Chainlog key
    bytes32 dstPsmKey; // Chainlog key
    uint256 srcKeep; // [wad] Min amount of gems to keep
    uint256 dstWant; // [wad] Max amount of gems to move
}

struct MigrationResult {
    address srcPsm;
    bytes32 srcIlk;
    address dstPsm;
    bytes32 dstIlk;
    uint256 sap; // [wad] Amount of gems migrated
}

struct SrcPsm {
    address psm;
    bytes32 ilk;
    address gemJoin;
    address gem;
    uint256 rate; // [ray]
    uint256 ink; // [wad]
    uint256 art; // [wad]
}

struct DstPsm {
    address psm;
    bytes32 ilk;
    address gem;
    uint256 buf; // [wad]
    uint256 rate; // [ray]
    uint256 line; // [rad]
}

interface DssPsmLike {
    function gemJoin() external view returns (address);
    function ilk() external view returns (bytes32);
}

interface DssLitePsmLike {
    function buf() external view returns (uint256);
    function file(bytes32, uint256) external;
    function fill() external returns (uint256);
    function gem() external view returns (address);
    function ilk() external view returns (bytes32);
    function rush() external view returns (uint256);
    function sellGemNoFee(address, uint256) external returns (uint256);
    function to18ConversionFactor() external view returns (uint256);
}

interface GemJoinLike {
    function gem() external view returns (address);
    function exit(address, uint256) external;
}

interface GemLike {
    function approve(address, uint256) external;
}

library DssLitePsmMigration {
    /// @dev Workaround to explicitly revert with an arithmetic error.
    string internal constant ARITHMETIC_ERROR = string(abi.encodeWithSignature("Panic(uint256)", 0x11));

    uint256 internal constant RAY = 10 ** 27;

    /// @dev Safely converts `uint256` to `int256`. Reverts if it overflows.
    function _int256(uint256 x) internal pure returns (int256 y) {
        require((y = int256(x)) >= 0, ARITHMETIC_ERROR);
    }

    function _min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    /// @dev Returns the difference between `x` and `y` or zero if `x` is lower than `y`.
    function _subcap(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? 0 : x - y;
    }

    /**
     * @dev Migrates funds from `src` to `dst`.
     * @param dss The DSS instance.
     * @param cfg The migration config.
     * @return res The state of both PSMs after migration.
     */
    function migrate(DssInstance memory dss, MigrationConfig memory cfg)
        internal
        returns (MigrationResult memory res)
    {
        SrcPsm memory src;
        src.psm = dss.chainlog.getAddress(cfg.srcPsmKey);
        src.ilk = DssPsmLike(src.psm).ilk();
        src.gemJoin = DssPsmLike(src.psm).gemJoin();
        src.gem = GemJoinLike(src.gemJoin).gem();
        (, src.rate,,,) = dss.vat.ilks(src.ilk);
        (src.ink, src.art) = dss.vat.urns(src.ilk, src.psm);

        DstPsm memory dst;
        dst.psm = dss.chainlog.getAddress(cfg.dstPsmKey);
        dst.ilk = DssLitePsmLike(dst.psm).ilk();
        dst.gem = DssLitePsmLike(dst.psm).gem();
        dst.buf = DssLitePsmLike(dst.psm).buf();
        (, dst.rate,, dst.line,) = dss.vat.ilks(dst.ilk);

        // Store current params to reset them at the end.
        uint256 currentGlobalLine = dss.vat.Line();

        // --- Sanity checks ---

        require(cfg.srcPsmKey != cfg.dstPsmKey, "DssLitePsmMigration/src-psm-same-key-dst-psm");
        uint256 to18ConversionFactor = DssLitePsmLike(dst.psm).to18ConversionFactor();
        require(
            cfg.dstWant == type(uint256).max || cfg.dstWant % to18ConversionFactor == 0,
            "DssLitePsmMigration/dst-want-rounding-issue"
        );
        require(cfg.srcKeep % to18ConversionFactor == 0, "DssLitePsmMigration/src-keep-rounding-issue");

        require(src.ink >= src.art, "DssLitePsmMigration/src-ink-lower-than-art");
        require(dst.ilk != src.ilk, "DssLitePsmMigration/invalid-ilk-reuse");
        require(dst.gem == src.gem, "DssLitePsmMigration/dst-src-gem-mismatch");
        // We assume stability fees should be set to zero for both PSMs.
        require(src.rate == RAY, "DssLitePsmMigration/invalid-src-ilk-rate");
        require(dst.rate == RAY, "DssLitePsmMigration/invalid-dst-ilk-rate");

        // --- Funds migration ---

        // 0. Define the base parameters for the migration.
        // The actual amount to move is constrained by both `dstWant` and `srcKeep`.
        uint256 mink = _min(cfg.dstWant, _subcap(src.ink, cfg.srcKeep));
        // Ensure it does not try to erase more than the existing debt.
        uint256 mart = _min(src.art, mink);

        // 1. Grab the collateral from `src.psm` into the executing contract.
        dss.vat.grab(src.ilk, src.psm, address(this), address(this), -_int256(mink), -_int256(mart));

        // 2. Transfer the grabbed collateral to the executing contract.
        uint256 srcGemAmt = mink / to18ConversionFactor;
        GemJoinLike(src.gemJoin).exit(address(this), srcGemAmt);

        // 3. Set interim params to accommodate the migration.
        dss.vat.file("Line", type(uint256).max);
        dss.vat.file(dst.ilk, "line", type(uint256).max);

        // 4. Pre-mint enough Dai liquidity to move funds from `src.psm`.
        DssLitePsmLike(dst.psm).file("buf", mink);
        if (DssLitePsmLike(dst.psm).rush() > 0) {
            DssLitePsmLike(dst.psm).fill();
        }

        // 5. Sell the grabbed collateral gems to `dst.psm`.
        GemLike(dst.gem).approve(dst.psm, srcGemAmt);
        uint256 daiOutWad = DssLitePsmLike(dst.psm).sellGemNoFee(address(this), srcGemAmt);
        require(daiOutWad == mink, "DssLitePsmMigration/invalid-dai-amount");

        // 6. Convert ERC20 Dai into Vat Dai.
        dss.dai.approve(address(dss.daiJoin), daiOutWad);
        dss.daiJoin.join(address(this), daiOutWad);

        // 7. Erase the bad debt generated by `vat.grab()`.
        dss.vat.heal(mart * RAY);

        // 8. Reset the previous params.
        dss.vat.file("Line", currentGlobalLine);
        dss.vat.file(dst.ilk, "line", dst.line);
        DssLitePsmLike(dst.psm).file("buf", dst.buf);

        // 9. Return the result params
        res.srcPsm = src.psm;
        res.srcIlk = src.ilk;
        res.dstPsm = dst.psm;
        res.dstIlk = dst.ilk;
        res.sap = mink;
    }
}
