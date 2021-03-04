// SPDX-License-Identifier: GPL-3.0-or-later
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
pragma solidity 0.6.11;

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

interface RwaLiquidationLike {
    function ilks(bytes32) external returns (bytes32,address,uint48,uint48);
    function init(bytes32, uint256, string calldata, uint48) external;
}

contract DssSpellAction is DssAction {

    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community//governance/votes/Community%20Executive%20vote%20-%20March%205%2C%202021.md -q -O - 2>/dev/null)"
    string public constant description =
        "2021-03-05 MakerDAO Executive Spell | Hash: ";


    // Many of the settings that change weekly rely on the rate accumulator
    // described at https://docs.makerdao.com/smart-contract-modules/rates-module
    // To check this yourself, use the following rate calculation (example 8%):
    //
    // $ bc -l <<< 'scale=27; e( l(1.08)/(60 * 60 * 24 * 365) )'
    //
    // A table of rates can be found at
    //    https://ipfs.io/ipfs/QmefQMseb3AiTapiAKKexdKHig8wroKuZbmLtPLv4u2YwW
    //
    uint256 constant THREE_PCT_RATE  = 1000000000937303470807876289;

    uint256 constant WAD        = 10**18;
    uint256 constant RAD        = 10**45;

    address constant RWA001_OPERATOR           = 0x7709f0840097170E5cB1F8c890AcB8601d73b35f;
    address constant RWA001_GEM                = 0x10b2aA5D77Aa6484886d8e244f0686aB319a270d;
    address constant MCD_JOIN_RWA001_A         = 0x476b81c12Dc71EDfad1F64B9E07CaA60F4b156E2;
    address constant RWA001_A_URN              = 0xa3342059BcDcFA57a13b12a35eD4BBE59B873005;
    address constant RWA001_A_INPUT_CONDUIT    = 0x8000458b54a0050c0b256aCBAf6Aa192adf5b952;
    address constant RWA001_A_OUTPUT_CONDUIT   = 0xb3eFb912e1cbC0B26FC17388Dd433Cecd2206C3d;
    address constant MIP21_LIQUIDATION_ORACLE  = 0x88f88Bb9E66241B73B84f3A6E197FbBa487b1E30;

    uint256 constant RWA001_A_INITIAL_PRICE = 1060 * WAD;


    // MIP13c3-SP4 Declaration of Intent & Commercial Points -
    //   Off-Chain Asset Backed Lender to onboard Real World Assets
    //   as Collateral for a DAI loan
    //
    // https://ipfs.io/ipfs/QmdmAUTU3sd9VkdfTZNQM6krc9jsKgF2pz7W1qvvfJo1xk
    string constant DOC = "QmdmAUTU3sd9VkdfTZNQM6krc9jsKgF2pz7W1qvvfJo1xk";

    function actions() public override {

        // RWA001-A collateral deploy

        // Set ilk bytes32 variable
        bytes32 ilk = "RWA001-A";

        address vat = DssExecLib.vat();

        // Sanity checks
        require(GemJoinAbstract(MCD_JOIN_RWA001_A).vat() == vat, "join-vat-not-match");
        require(GemJoinAbstract(MCD_JOIN_RWA001_A).ilk() == ilk, "join-ilk-not-match");
        require(GemJoinAbstract(MCD_JOIN_RWA001_A).gem() == RWA001_GEM, "join-gem-not-match");
        require(GemJoinAbstract(MCD_JOIN_RWA001_A).dec() == DSTokenAbstract(RWA001_GEM).decimals(), "join-dec-not-match");

        // init the RwaLiquidationOracle
        // doc: "doc"
        // tau: 5 minutes
        RwaLiquidationLike(MIP21_LIQUIDATION_ORACLE).init(
            ilk, RWA001_A_INITIAL_PRICE, DOC, 300
        );
        (,address pip,,) = RwaLiquidationLike(MIP21_LIQUIDATION_ORACLE).ilks(ilk);

        // Set price feed for RWA001
        DssExecLib.setContract(DssExecLib.spotter(), ilk, "pip", pip);

        // Init RWA-001 in Vat
        Initializable(vat).init(ilk);
        // Init RWA-001 in Jug
        Initializable(DssExecLib.jug()).init(ilk);

        // Allow RWA-001 Join to modify Vat registry
        DssExecLib.authorize(vat, MCD_JOIN_RWA001_A);

        // Allow RwaLiquidationOracle to modify Vat registry
        DssExecLib.authorize(vat, MIP21_LIQUIDATION_ORACLE);

        // Increase the global debt ceiling by the ilk ceiling
        DssExecLib.increaseGlobalDebtCeiling(1_000);
        // Set the ilk debt ceiling
        DssExecLib.setIlkDebtCeiling(ilk, 1_000);

        // No dust
        // DssExecLib.setIlkMinVaultAmount(ilk, 0);

        // 3% stability fee
        DssExecLib.setIlkStabilityFee(ilk, THREE_PCT_RATE, true);

        // collateralization ratio 100%
        DssExecLib.setIlkLiquidationRatio(ilk, 10_000);

        // poke the spotter to pull in a price
        DssExecLib.updateCollateralPrice(ilk);

        // give the urn permissions on the join adapter
        DssExecLib.authorize(MCD_JOIN_RWA001_A, RWA001_A_URN);

        // set up the urn
        Hopeable(RWA001_A_URN).hope(RWA001_OPERATOR);

        // set up output conduit
        Hopeable(RWA001_A_OUTPUT_CONDUIT).hope(RWA001_OPERATOR);
        // could potentially kiss some BD addresses if they are available

        // add RWA-001 contract to the changelog
        DssExecLib.setChangelogAddress("RWA001", RWA001_GEM);
        DssExecLib.setChangelogAddress("PIP_RWA001", pip);
        DssExecLib.setChangelogAddress("MCD_JOIN_RWA001_A", MCD_JOIN_RWA001_A);
        DssExecLib.setChangelogAddress("MIP21_LIQUIDATION_ORACLE", MIP21_LIQUIDATION_ORACLE);
        DssExecLib.setChangelogAddress("RWA001_A_URN", RWA001_A_URN);
        DssExecLib.setChangelogAddress("RWA001_A_INPUT_CONDUIT", RWA001_A_INPUT_CONDUIT);
        DssExecLib.setChangelogAddress("RWA001_A_OUTPUT_CONDUIT", RWA001_A_OUTPUT_CONDUIT);

        // bump changelog version
        DssExecLib.setChangelogVersion("1.2.9");
    }
}

contract DssSpell is DssExec {
    DssSpellAction internal action_ = new DssSpellAction();
    constructor() DssExec(action_.description(), block.timestamp + 30 days, address(action_)) public {}
}
