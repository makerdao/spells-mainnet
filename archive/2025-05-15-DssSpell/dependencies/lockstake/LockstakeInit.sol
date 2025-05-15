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

pragma solidity >=0.8.0;

import { DssInstance } from "dss-test/MCD.sol";
import { LockstakeInstance } from "./LockstakeInstance.sol";

interface LockstakeSkyLike {
    function rely(address) external;
}

interface LockstakeEngineLike {
    function voteDelegateFactory() external view returns (address);
    function vat() external view returns (address);
    function usdsJoin() external view returns (address);
    function usds() external view returns (address);
    function ilk() external view returns (bytes32);
    function sky() external view returns (address);
    function lssky() external view returns (address);
    function fee() external view returns (uint256);
    function rely(address) external;
    function file(bytes32, address) external;
    function addFarm(address) external;
}

interface LockstakeClipperLike {
    function vat() external view returns (address);
    function dog() external view returns (address);
    function spotter() external view returns (address);
    function engine() external view returns (address);
    function ilk() external view returns (bytes32);
    function rely(address) external;
    function file(bytes32, address) external;
    function file(bytes32, uint256) external;
    function upchost() external;
}

interface LockstakeMigratorLike {
    function oldEngine() external view returns (address);
    function newEngine() external view returns (address);
    function mkrSky() external view returns (address);
    function flash() external view returns (address);
}

interface PipLike {
    function kiss(address) external;
    function rely(address) external;
}

interface CalcLike {
    function file(bytes32, uint256) external;
}

interface AutoLineLike {
    function ilks(bytes32) external returns (uint256, uint256, uint48, uint48, uint48);
    function remIlk(bytes32) external;
}

interface OsmMomLike {
    function setOsm(bytes32, address) external;
}

interface LineMomLike {
    function addIlk(bytes32) external;
}

interface ClipperMomLike {
    function setPriceTolerance(address, uint256) external;
}

interface StakingRewardsLike {
    function stakingToken() external view returns (address);
}

interface IlkRegistryLike {
    function put(
        bytes32 _ilk,
        address _join,
        address _gem,
        uint256 _dec,
        uint256 _class,
        address _pip,
        address _xlip,
        string memory _name,
        string memory _symbol
    ) external;
}

struct LockstakeConfig {
    bytes32   ilk;
    address[] farms;
    uint256   fee;
    uint256   dust;
    uint256   duty;
    uint256   mat;
    uint256   buf;
    uint256   tail;
    uint256   cusp;
    uint256   chip;
    uint256   tip;
    uint256   stopped;
    uint256   chop;
    uint256   hole;
    uint256   tau;
    uint256   cut;
    uint256   step;
    bool      lineMom;
    uint256   tolerance;
    string    name;
    string    symbol;
}

struct StackExtension {
    LockstakeSkyLike lssky;
    LockstakeEngineLike engine;
    LockstakeClipperLike clipper;
    CalcLike calc;
    LockstakeMigratorLike migrator;
    LockstakeEngineLike oldEngine;
    AutoLineLike autoLine;
    address sky;
}

library LockstakeInit {
    uint256 constant internal RATES_ONE_HUNDRED_PCT = 1000000021979553151239153027;
    uint256 constant internal WAD = 10**18;
    uint256 constant internal RAY = 10**27;
    uint256 constant internal RAD = 10**45;

    function initLockstake(
        DssInstance        memory dss,
        LockstakeInstance  memory lockstakeInstance,
        LockstakeConfig    memory cfg
    ) internal {
        StackExtension memory se = StackExtension ({
            lssky:     LockstakeSkyLike(lockstakeInstance.lssky),
            engine:    LockstakeEngineLike(lockstakeInstance.engine),
            clipper:   LockstakeClipperLike(lockstakeInstance.clipper),
            calc:      CalcLike(lockstakeInstance.clipperCalc),
            migrator:  LockstakeMigratorLike(lockstakeInstance.migrator),
            oldEngine: LockstakeEngineLike(dss.chainlog.getAddress("LOCKSTAKE_ENGINE")),
            autoLine:  AutoLineLike(dss.chainlog.getAddress("MCD_IAM_AUTO_LINE")),
            sky:       dss.chainlog.getAddress("SKY")
        });

        bytes32 oldEngineIlk = se.oldEngine.ilk();

        // Sanity checks
        require(oldEngineIlk                    != cfg.ilk);
        require(se.engine.voteDelegateFactory() == dss.chainlog.getAddress("VOTE_DELEGATE_FACTORY"));
        require(se.engine.vat()                 == address(dss.vat));
        require(se.engine.usdsJoin()            == dss.chainlog.getAddress("USDS_JOIN"));
        require(se.engine.usds()                == dss.chainlog.getAddress("USDS"));
        require(se.engine.ilk()                 == cfg.ilk);
        require(se.engine.sky()                 == se.sky);
        require(se.engine.lssky()               == address(se.lssky));
        require(se.engine.fee()                 == cfg.fee);
        require(se.clipper.ilk()                == cfg.ilk);
        require(se.clipper.vat()                == address(dss.vat));
        require(se.clipper.engine()             == address(se.engine));
        require(se.clipper.dog()                == address(dss.dog));
        require(se.clipper.spotter()            == address(dss.spotter));
        require(se.migrator.oldEngine()         == address(se.oldEngine));
        require(se.migrator.newEngine()         == address(se.engine));
        require(se.migrator.mkrSky()            == dss.chainlog.getAddress("MKR_SKY"));
        require(se.migrator.flash()             == dss.chainlog.getAddress("MCD_FLASH"));
        (,,, uint256 line,) = dss.vat.ilks(cfg.ilk);
        require(line                            == 0);
        (line,,,,) = se.autoLine.ilks(cfg.ilk);
        require(line                            == 0);

        require(cfg.dust <= cfg.hole);
        require(cfg.duty >= RAY && cfg.duty <= RATES_ONE_HUNDRED_PCT);
        require(cfg.mat >= RAY && cfg.mat < 10 * RAY);
        require(cfg.buf >= RAY && cfg.buf < 10 * RAY);
        require(cfg.cusp < RAY);
        require(cfg.chip < WAD);
        require(cfg.tip <= 1_000 * RAD);
        require(cfg.chop >= WAD && cfg.chop < 2 * WAD);
        require(cfg.tolerance < RAY);

        se.oldEngine.rely(address(se.migrator));

        dss.vat.file(oldEngineIlk, "line", 0); // Clean only ilk line, as there will probably be existing debt. Line can be adjusted in a later stage.
        se.autoLine.remIlk(oldEngineIlk);

        dss.vat.init(cfg.ilk);
        dss.vat.file(cfg.ilk, "dust", cfg.dust);
        dss.vat.rely(address(se.engine));
        dss.vat.rely(address(se.clipper));
        dss.vat.rely(address(se.migrator));

        dss.jug.init(cfg.ilk);
        dss.jug.file(cfg.ilk, "duty", cfg.duty);

        address pip = dss.chainlog.getAddress("PIP_SKY");
        address clipperMom = dss.chainlog.getAddress("CLIPPER_MOM");
        PipLike(pip).kiss(address(dss.spotter));
        PipLike(pip).kiss(address(se.clipper));
        PipLike(pip).kiss(clipperMom);
        PipLike(pip).kiss(address(dss.end));
        // This assumes pip is a standard Osm sourced by a Median
        {
        address osmMom = dss.chainlog.getAddress("OSM_MOM");
        PipLike(pip).rely(osmMom);
        OsmMomLike(osmMom).setOsm(cfg.ilk, pip);
        }

        dss.spotter.file(cfg.ilk, "mat", cfg.mat);
        dss.spotter.file(cfg.ilk, "pip", pip);
        dss.spotter.poke(cfg.ilk);

        dss.dog.file(cfg.ilk, "clip", address(se.clipper));
        dss.dog.file(cfg.ilk, "chop", cfg.chop);
        dss.dog.file(cfg.ilk, "hole", cfg.hole);
        dss.dog.rely(address(se.clipper));

        se.lssky.rely(address(se.engine));

        se.engine.file("jug", address(dss.jug));
        for (uint256 i = 0; i < cfg.farms.length; i++) {
            require(StakingRewardsLike(cfg.farms[i]).stakingToken() == lockstakeInstance.lssky);
            se.engine.addFarm(cfg.farms[i]);
        }
        se.engine.rely(address(se.clipper));

        se.clipper.file("buf",     cfg.buf);
        se.clipper.file("tail",    cfg.tail);
        se.clipper.file("cusp",    cfg.cusp);
        se.clipper.file("chip",    cfg.chip);
        se.clipper.file("tip",     cfg.tip);
        se.clipper.file("stopped", cfg.stopped);
        se.clipper.file("vow",     address(dss.vow));
        se.clipper.file("calc",    address(se.calc));
        se.clipper.upchost();
        se.clipper.rely(address(dss.dog));
        se.clipper.rely(address(dss.end));
        se.clipper.rely(clipperMom);

        if (cfg.tau  > 0) se.calc.file("tau",  cfg.tau);
        if (cfg.cut  > 0) se.calc.file("cut",  cfg.cut);
        if (cfg.step > 0) se.calc.file("step", cfg.step);

        if (cfg.lineMom) {
            LineMomLike(dss.chainlog.getAddress("LINE_MOM")).addIlk(cfg.ilk);
        }

        if (cfg.tolerance > 0) {
            ClipperMomLike(clipperMom).setPriceTolerance(address(se.clipper), cfg.tolerance);
        }

        IlkRegistryLike(dss.chainlog.getAddress("ILK_REGISTRY")).put(
            cfg.ilk,
            address(0),
            se.sky,
            18,
            7, // New class
            pip,
            address(se.clipper),
            cfg.name,
            cfg.symbol
        );

        dss.chainlog.setAddress("LOCKSTAKE_MKR_OLD_V1",       dss.chainlog.getAddress("LOCKSTAKE_MKR"));
        dss.chainlog.setAddress("LOCKSTAKE_ENGINE_OLD_V1",    address(se.oldEngine));
        dss.chainlog.setAddress("LOCKSTAKE_CLIP_OLD_V1",      dss.chainlog.getAddress("LOCKSTAKE_CLIP"));
        dss.chainlog.setAddress("LOCKSTAKE_CLIP_CALC_OLD_V1", dss.chainlog.getAddress("LOCKSTAKE_CLIP_CALC"));
        dss.chainlog.removeAddress("LOCKSTAKE_MKR");

        dss.chainlog.setAddress("LOCKSTAKE_SKY",       address(se.lssky));
        dss.chainlog.setAddress("LOCKSTAKE_ENGINE",    address(se.engine));
        dss.chainlog.setAddress("LOCKSTAKE_CLIP",      address(se.clipper));
        dss.chainlog.setAddress("LOCKSTAKE_CLIP_CALC", address(se.calc));
        dss.chainlog.setAddress("LOCKSTAKE_MIGRATOR",  address(se.migrator));
    }
}
