// SPDX-FileCopyrightText: 2025 Dai Foundation <www.daifoundation.org>
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

pragma solidity ^0.8.0;

import {DssInstance} from "dss-test/MCD.sol";
import {SPBEAMInstance} from "./SPBEAMInstance.sol";

interface RelyLike {
    function rely(address usr) external;
}

interface SPBEAMLike is RelyLike {
    function file(bytes32 what, uint256 data) external;
    function file(bytes32 ilk, bytes32 what, uint256 data) external;
    function kiss(address usr) external;
}

interface SPBEAMMomLike {
    function setAuthority(address usr) external;
}

/// @title Configuration parameters for a rate in SPBEAM
/// @dev Used to configure rate parameters for a specific rate
struct SPBEAMRateConfig {
    /// @dev Rate identifier
    bytes32 id;
    /// @dev Minimum rate in basis points
    uint16 min;
    /// @dev Maximum rate in basis points
    uint16 max;
    /// @dev Maximum step size in basis points
    uint16 step;
}
/// @dev Step size in basis points [0-65535]

/// @title Global configuration parameters for SPBEAM
/// @dev Used to configure global parameters and collateral-specific settings
struct SPBEAMConfig {
    /// @dev Time delay between rate updates
    uint256 tau;
    /// @dev Collateral-specific settings
    SPBEAMRateConfig[] ilks;
    /// @dev Bud to be authed within setup
    address bud;
}
/// @dev Array of collateral configurations

/// @title Dynamic Stability Parameter Controller Initialization
/// @notice Handles initialization and configuration of the SPBEAM contract
/// @dev Sets up permissions and configures parameters for the SPBEAM system
library SPBEAMInit {
    /// @notice Initializes a SPBEAM instance with the specified configuration
    /// @dev Sets up permissions between SPBEAM and core contracts, and configures parameters
    /// @param dss The DSS (MakerDAO) instance containing core contract references
    /// @param inst The SPBEAM instance containing contract addresses
    /// @param cfg The configuration parameters for SPBEAM
    function init(DssInstance memory dss, SPBEAMInstance memory inst, SPBEAMConfig memory cfg) internal {
        // Set up permissions

        // Authorize SPBEAMMom in SPBEAM
        RelyLike(inst.spbeam).rely(inst.mom);

        // Set SPBEAMMom authority to MCD_ADM
        SPBEAMMomLike(inst.mom).setAuthority(dss.chainlog.getAddress("MCD_ADM"));

        // Authorize SPBEAM in core contracts
        dss.jug.rely(inst.spbeam);
        dss.pot.rely(inst.spbeam);
        RelyLike(dss.chainlog.getAddress("SUSDS")).rely(inst.spbeam);

        // Configure global parameters
        SPBEAMLike(inst.spbeam).file("tau", cfg.tau);

        // Configure ilks
        for (uint256 i = 0; i < cfg.ilks.length; i++) {
            SPBEAMRateConfig memory ilk = cfg.ilks[i];
            SPBEAMLike(inst.spbeam).file(ilk.id, "max", uint256(ilk.max));
            SPBEAMLike(inst.spbeam).file(ilk.id, "min", uint256(ilk.min));
            SPBEAMLike(inst.spbeam).file(ilk.id, "step", uint256(ilk.step));
        }

        // Authorize bud
        SPBEAMLike(inst.spbeam).kiss(cfg.bud);
    }
}
