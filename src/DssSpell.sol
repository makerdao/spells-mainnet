// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2021 Maker Ecosystem Growth Holdings, INC.
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

pragma solidity 0.6.12;

import "dss-exec-lib/DssExec.sol";
import "dss-exec-lib/DssAction.sol";
import "lib/dss-interfaces/src/dss/GemJoinAbstract.sol";
import "lib/dss-interfaces/src/dapp/DSTokenAbstract.sol";

interface Initializable {
    function init(bytes32) external;
}

interface Hopeable {
    function hope(address) external;
}

interface Kissable {
    function kiss(address) external;
}

interface RwaLiquidationLike {
    function ilks(bytes32) external returns (string memory,address,uint48,uint48);
    function init(bytes32, uint256, string calldata, uint48) external;
}

contract DssSpellAction is DssAction {

    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/2a7a8c915695b7298fe725ee3dc6c613fa9d9bbe/governance/votes/Executive%20vote%20-%20April%2012%2C%202021.md -q -O - 2>/dev/null)"
    string public constant description =
        "";

    // Many of the settings that change weekly rely on the rate accumulator
    // described at https://docs.makerdao.com/smart-contract-modules/rates-module
    // To check this yourself, use the following rate calculation (example 8%):
    //
    // $ bc -l <<< 'scale=27; e( l(1.08)/(60 * 60 * 24 * 365) )'
    //
    // A table of rates can be found at
    //    https://ipfs.io/ipfs/QmefQMseb3AiTapiAKKexdKHig8wroKuZbmLtPLv4u2YwW
    //
    uint256 constant SIX_PCT            = 1000000001847694957439350562;
    uint256 constant SEVEN_PCT          = 1000000002145441671308778766;
    uint256 constant FOUR_PT_FIVE_PCT   = 1000000001395766281313196627;
    uint256 constant TWO_PCT            = 1000000000627937192491029810;

    // Math
    uint256 constant MILLION = 10**6;
    uint256 constant WAD     = 10**18;
    uint256 constant RAD     = 10**45;

    // Addresses
    address constant RWA003_OPERATOR         = 0xaf1f5F5a203Aaf08237013A7280B03F35147b9D2;
    address constant RWA003_GEM              = address(0);
    address constant MCD_JOIN_RWA003_A       = address(0);
    address constant RWA003_A_URN            = address(0);
    address constant RWA003_A_INPUT_CONDUIT  = 0xaf1f5F5a203Aaf08237013A7280B03F35147b9D2;
    address constant RWA003_A_OUTPUT_CONDUIT = 0xaf1f5F5a203Aaf08237013A7280B03F35147b9D2;

    address constant RWA004_OPERATOR         = 0x5Ad81Ed0b281fDB732d30E496Ac1ba3A7D760c1E;
    address constant RWA004_GEM              = address(0);
    address constant MCD_JOIN_RWA004_A       = address(0);
    address constant RWA004_A_URN            = address(0);
    address constant RWA004_A_INPUT_CONDUIT  = 0x5Ad81Ed0b281fDB732d30E496Ac1ba3A7D760c1E;
    address constant RWA004_A_OUTPUT_CONDUIT = 0x5Ad81Ed0b281fDB732d30E496Ac1ba3A7D760c1E;

    address constant RWA005_OPERATOR         = 0xaC7F683F048120Aa35a18F687E5eE7446380A3bE;
    address constant RWA005_GEM              = address(0);
    address constant MCD_JOIN_RWA005_A       = address(0);
    address constant RWA005_A_URN            = address(0);
    address constant RWA005_A_INPUT_CONDUIT  = 0xaC7F683F048120Aa35a18F687E5eE7446380A3bE;
    address constant RWA005_A_OUTPUT_CONDUIT = 0xaC7F683F048120Aa35a18F687E5eE7446380A3bE;

    address constant RWA006_OPERATOR         = address(0);
    address constant RWA006_GEM              = address(0);
    address constant MCD_JOIN_RWA006_A       = address(0);
    address constant RWA006_A_URN            = address(0);
    address constant RWA006_A_INPUT_CONDUIT  = address(0);
    address constant RWA006_A_OUTPUT_CONDUIT = address(0);

    function actions() public override {
        address MIP21_LIQUIDATION_ORACLE =
            DssExecLib.getChangelogAddress("MIP21_LIQUIDATION_ORACLE");

        address vat = DssExecLib.vat();

        // -------------------------------- RWA003 --------------------------------
        bytes32 RWA003_ilk   = "RWA003-A";
        uint256 RWA003_CEIL  = 2 * MILLION;
        uint256 RWA003_PRICE = 2_247_200 * WAD;
        uint256 RWA003_MAT   = 10_500;
        uint48 RWA003_TAU    = 0;

        // https://ipfs.io/ipfs/
        string memory RWA003_DOC = "";

        // Sanity checks
        require(GemJoinAbstract(MCD_JOIN_RWA003_A).vat() == vat, "join-vat-not-match");
        require(GemJoinAbstract(MCD_JOIN_RWA003_A).ilk() == RWA003_ilk, "join-ilk-not-match");
        require(GemJoinAbstract(MCD_JOIN_RWA003_A).gem() == RWA003_GEM, "join-gem-not-match");
        require(GemJoinAbstract(MCD_JOIN_RWA003_A).dec() == DSTokenAbstract(RWA003_GEM).decimals(), "join-dec-not-match");

        RwaLiquidationLike(MIP21_LIQUIDATION_ORACLE).init(
            RWA003_ilk, RWA003_PRICE, RWA003_DOC, RWA003_TAU
        );
        (,address RWA003_pip,,) = RwaLiquidationLike(MIP21_LIQUIDATION_ORACLE).ilks(RWA003_ilk);

        // Set price feed for RWA003
        DssExecLib.setContract(DssExecLib.spotter(), RWA003_ilk, "pip", RWA003_pip);

        // Init RWA-003 in Vat
        Initializable(vat).init(RWA003_ilk);
        // Init RWA-003 in Jug
        Initializable(DssExecLib.jug()).init(RWA003_ilk);

        // Allow RWA-003 Join to modify Vat registry
        DssExecLib.authorize(vat, MCD_JOIN_RWA003_A);

        // Allow RwaLiquidationOracle to modify Vat registry
        // DssExecLib.authorize(vat, MIP21_LIQUIDATION_ORACLE);

        // Increase the global debt ceiling by the ilk ceiling
        DssExecLib.increaseGlobalDebtCeiling(RWA003_CEIL);
        // Set the ilk debt ceiling
        DssExecLib.setIlkDebtCeiling(RWA003_ilk, RWA003_CEIL);

        // No dust
        // DssExecLib.setIlkMinVaultAmount(RWA003_ilk, 0);

        // stability fee
        DssExecLib.setIlkStabilityFee(RWA003_ilk, THREE_PT_FIVE_PCT, false);

        // collateralization ratio
        DssExecLib.setIlkLiquidationRatio(RWA003_ilk, RWA003_MAT);

        // poke the spotter to pull in a price
        DssExecLib.updateCollateralPrice(RWA003_ilk);

        // give the urn permissions on the join adapter
        // DssExecLib.authorize(MCD_JOIN_RWA003_A, RWA003_A_URN);

        // set up the urn
        Hopeable(RWA003_A_URN).hope(RWA003_OPERATOR);

        // set up output conduit
        // Hopeable(RWA003_A_OUTPUT_CONDUIT).hope(RWA003_OPERATOR);

        // Authorize the SC Domain team deployer address on the output conduit
        // during introductory phase. This allows the SC team to assist in the
        // testing of a complete circuit. Once a broker dealer arrangement is
        // established the deployer address should be `deny`ed on the conduit.
        // Kissable(RWA003_A_OUTPUT_CONDUIT).kiss(SC_DOMAIN_DEPLOYER_07);

        // add RWA-003 contract to the changelog
        DssExecLib.setChangelogAddress("RWA003", RWA003_GEM);
        DssExecLib.setChangelogAddress("PIP_RWA003", pip);
        DssExecLib.setChangelogAddress("MCD_JOIN_RWA003_A", MCD_JOIN_RWA003_A);
        DssExecLib.setChangelogAddress("RWA003_A_URN", RWA003_A_URN);
        DssExecLib.setChangelogAddress(
            "RWA003_A_INPUT_CONDUIT", RWA003_A_INPUT_CONDUIT
        );
        DssExecLib.setChangelogAddress(
            "RWA003_A_OUTPUT_CONDUIT", RWA003_A_OUTPUT_CONDUIT
        );

        // -------------------------------- RWA004 --------------------------------
        bytes32 RWA004_ilk   = "RWA004-A";
        uint256 RWA004_CEIL  = 7 * MILLION;
        uint256 RWA004_PRICE = 8_014_300 * WAD;
        uint256 RWA004_MAT   = 11_000;
        uint48 RWA004_TAU    = 0;


        // -------------------------------- RWA005 --------------------------------
        bytes32 RWA005_ilk   = "RWA005-A";
        uint256 RWA005_CEIL  = 15 * MILLION;
        uint256 RWA005_PRICE = 16_380_375 * WAD;
        uint256 RWA005_MAT   = 10_500;
        uint48 RWA005_TAU    = 0;


        // -------------------------------- RWA006 --------------------------------
        bytes32 RWA006_ilk   = "RWA006-A";
        uint256 RWA006_CEIL  = 20 * MILLION;
        uint256 RWA006_PRICE = 20_808_000 * WAD;
        uint256 RWA006_MAT   = 10_000;
        uint48 RWA006_TAU    = 0;

        // bump changelog version
        DssExecLib.setChangelogVersion("");
    }
}

contract DssSpell is DssExec {
    DssSpellAction internal action_ = new DssSpellAction();
    constructor() DssExec(action_.description(), block.timestamp + 30 days, address(action_)) public {}
}