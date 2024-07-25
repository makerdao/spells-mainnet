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
import {DssLitePsmInstance} from "./DssLitePsmInstance.sol";

struct DssLitePsmInitConfig {
    bytes32 psmKey;
    bytes32 pocketKey;
    bytes32 psmMomKey;
    address pip;
    bytes32 ilk;
    address gem;
    address pocket;
}

interface DssLitePsmLike {
    function daiJoin() external view returns (address);
    function file(bytes32, address) external;
    function gem() external view returns (address);
    function ilk() external view returns (bytes32);
    function kiss(address) external;
    function pocket() external view returns (address);
    function rely(address) external;
}

interface DssLitePsmMomLike {
    function setAuthority(address) external;
}

interface PipLike {
    function read() external view returns (bytes32);
}

interface GemLike {
    function allowance(address, address) external view returns (uint256);
    function decimals() external view returns (uint256);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
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

library DssLitePsmInit {
    uint256 internal constant WAD = 10 ** 18;
    uint256 internal constant RAY = 10 ** 27;

    // @dev New `IlkRegistry` class
    uint256 internal constant REG_CLASS_JOINLESS = 6;

    /**
     * @dev Initializes a DssLitePsm instance.
     * @param dss The DSS instance.
     * @param inst The DssLitePsm instance.
     * @param cfg The init config.
     */
    function init(DssInstance memory dss, DssLitePsmInstance memory inst, DssLitePsmInitConfig memory cfg) internal {
        // Sanity checks
        require(cfg.psmKey != cfg.pocketKey, "DssLitePsmInit/dst-psm-same-key-pocket");
        require(DssLitePsmLike(inst.litePsm).ilk() == cfg.ilk, "DssLitePsmInit/ilk-mismatch");
        require(DssLitePsmLike(inst.litePsm).gem() == cfg.gem, "DssLitePsmInit/gem-mismatch");
        require(DssLitePsmLike(inst.litePsm).pocket() == cfg.pocket, "DssLitePsmInit/pocket-mismatch");
        require(DssLitePsmLike(inst.litePsm).daiJoin() == address(dss.daiJoin), "DssLitePsmInit/dai-join-mismatch");
        // Ensure `litePsm` can spend `gem` on behalf of `pocket`.
        require(
            GemLike(cfg.gem).allowance(cfg.pocket, inst.litePsm) == type(uint256).max,
            "DssLitePsmInit/invalid-pocket-allowance"
        );
        require(uint256(PipLike(cfg.pip).read()) == 1 * WAD, "DssLitePsmInit/invalid-pip-val");

        // 1. Initialize the new ilk
        dss.vat.init(cfg.ilk);
        dss.jug.init(cfg.ilk);
        dss.spotter.file(cfg.ilk, "mat", 1 * RAY);
        dss.spotter.file(cfg.ilk, "pip", cfg.pip);
        dss.spotter.poke(cfg.ilk);

        // 2. Initial `litePsm` setup
        // Set `ink` to the largest value that will not cause an overflow for `ink * spot`.
        // Notice: `litePsm` assumes that:
        //   a. `spotter.par == RAY`
        //   b. `vat.ilks[ilk].spot == RAY`
        int256 vink = int256(type(uint256).max / RAY);
        dss.vat.slip(cfg.ilk, inst.litePsm, vink);
        dss.vat.grab(cfg.ilk, inst.litePsm, inst.litePsm, address(0), vink, 0);

        // 3. Set `litePsm` config params.
        // Notice: `buf`, `tin` and `tout` need to be set in the higher level migration scripts.
        DssLitePsmLike(inst.litePsm).file("vow", dss.chainlog.getAddress("MCD_VOW"));

        // 4. Allow `MCD_PAUSE_PROXY` to swap with no fees on `litePsm`.
        DssLitePsmLike(inst.litePsm).kiss(address(this));

        // 5. Configure `mom`
        // 5.1 Rely `mom` on `litePsm`
        DssLitePsmLike(inst.litePsm).rely(inst.mom);
        // 5.2. Set the chief as authority for `mom`.
        DssLitePsmMomLike(inst.mom).setAuthority(dss.chainlog.getAddress("MCD_ADM"));

        // 6. Add `litePsm` to `IlkRegistry`
        IlkRegistryLike reg = IlkRegistryLike(dss.chainlog.getAddress("ILK_REGISTRY"));
        reg.put(
            cfg.ilk,
            address(0), // No `gemJoin` for `litePsm`
            cfg.gem,
            GemLike(cfg.gem).decimals(),
            REG_CLASS_JOINLESS,
            cfg.pip,
            address(0), // No `clip` for `litePsm`
            GemLike(cfg.gem).name(),
            GemLike(cfg.gem).symbol()
        );

        // 7. Add `litePsm`, `mom` and `pocket` to the chainlog.
        dss.chainlog.setAddress(cfg.psmKey, inst.litePsm);
        dss.chainlog.setAddress(cfg.psmMomKey, inst.mom);
        dss.chainlog.setAddress(cfg.pocketKey, cfg.pocket);
    }
}
