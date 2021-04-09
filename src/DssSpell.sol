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
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/c9dd499d90ec08ec55fa242456045bb712932006/governance/votes/Executive%20vote%20-%20April%209%2C%202021.md -q -O - 2>/dev/null)"
    string public constant description =
        "2021-04-09 MakerDAO Executive Spell | Hash: 0x6362b56cd687d047ecaa6b4de28d84703e488a2dc71f45557a589dbac95736f2";

    // Many of the settings that change weekly rely on the rate accumulator
    // described at https://docs.makerdao.com/smart-contract-modules/rates-module
    // To check this yourself, use the following rate calculation (example 8%):
    //
    // $ bc -l <<< 'scale=27; e( l(1.08)/(60 * 60 * 24 * 365) )'
    //
    // A table of rates can be found at
    //    https://ipfs.io/ipfs/QmefQMseb3AiTapiAKKexdKHig8wroKuZbmLtPLv4u2YwW
    //
    uint256 constant THREE_PT_FIVE_PCT  = 1000000001090862085746321732;

    // Math
    uint256 constant MILLION = 10**6;
    uint256 constant WAD     = 10**18;
    uint256 constant RAD     = 10**45;

    // Addresses
    address constant RWA002_OPERATOR         = 0x2474F297214E5d96Ba4C81986A9F0e5C260f445D;
    address constant RWA002_GEM              = 0xAAA760c2027817169D7C8DB0DC61A2fb4c19AC23;
    address constant MCD_JOIN_RWA002_A       = 0xe72C7e90bc26c11d45dBeE736F0acf57fC5B7152;
    address constant RWA002_A_URN            = 0x225B3da5BE762Ee52B182157E67BeA0b31968163;
    address constant RWA002_A_INPUT_CONDUIT  = 0x2474F297214E5d96Ba4C81986A9F0e5C260f445D;
    address constant RWA002_A_OUTPUT_CONDUIT = 0x2474F297214E5d96Ba4C81986A9F0e5C260f445D;

    function actions() public override {
        bytes32 ilk   = "RWA002-A";
        uint256 CEIL  = 5 * MILLION;
        uint256 PRICE = 5_634_804 * WAD;
        uint256 MAT   = 10_500;
        uint48 TAU    = 0;

        // https://ipfs.io/ipfs/QmdfuQSLmNFHoxvMjXvv8qbJ2NWprrsvp5L3rGr3JHw18E
        string memory DOC = "QmdfuQSLmNFHoxvMjXvv8qbJ2NWprrsvp5L3rGr3JHw18E";

        address MIP21_LIQUIDATION_ORACLE =
            DssExecLib.getChangelogAddress("MIP21_LIQUIDATION_ORACLE");

        address vat = DssExecLib.vat();

        // Sanity checks
        require(GemJoinAbstract(MCD_JOIN_RWA002_A).vat() == vat, "join-vat-not-match");
        require(GemJoinAbstract(MCD_JOIN_RWA002_A).ilk() == ilk, "join-ilk-not-match");
        require(GemJoinAbstract(MCD_JOIN_RWA002_A).gem() == RWA002_GEM, "join-gem-not-match");
        require(GemJoinAbstract(MCD_JOIN_RWA002_A).dec() == DSTokenAbstract(RWA002_GEM).decimals(), "join-dec-not-match");

        RwaLiquidationLike(MIP21_LIQUIDATION_ORACLE).init(
            ilk, PRICE, DOC, TAU
        );
        (,address pip,,) = RwaLiquidationLike(MIP21_LIQUIDATION_ORACLE).ilks(ilk);

        // Set price feed for RWA002
        DssExecLib.setContract(DssExecLib.spotter(), ilk, "pip", pip);

        // Init RWA-002 in Vat
        Initializable(vat).init(ilk);
        // Init RWA-002 in Jug
        Initializable(DssExecLib.jug()).init(ilk);

        // Allow RWA-002 Join to modify Vat registry
        DssExecLib.authorize(vat, MCD_JOIN_RWA002_A);

        // Allow RwaLiquidationOracle to modify Vat registry
        // DssExecLib.authorize(vat, MIP21_LIQUIDATION_ORACLE);

        // Increase the global debt ceiling by the ilk ceiling
        DssExecLib.increaseGlobalDebtCeiling(CEIL);
        // Set the ilk debt ceiling
        DssExecLib.setIlkDebtCeiling(ilk, CEIL);

        // No dust
        // DssExecLib.setIlkMinVaultAmount(ilk, 0);

        // stability fee
        DssExecLib.setIlkStabilityFee(ilk, THREE_PT_FIVE_PCT, false);

        // collateralization ratio
        DssExecLib.setIlkLiquidationRatio(ilk, MAT);

        // poke the spotter to pull in a price
        DssExecLib.updateCollateralPrice(ilk);

        // give the urn permissions on the join adapter
        DssExecLib.authorize(MCD_JOIN_RWA002_A, RWA002_A_URN);

        // set up the urn
        Hopeable(RWA002_A_URN).hope(RWA002_OPERATOR);

        // set up output conduit
        // Hopeable(RWA002_A_OUTPUT_CONDUIT).hope(RWA002_OPERATOR);

        // Authorize the SC Domain team deployer address on the output conduit
        // during introductory phase. This allows the SC team to assist in the
        // testing of a complete circuit. Once a broker dealer arrangement is
        // established the deployer address should be `deny`ed on the conduit.
        // Kissable(RWA002_A_OUTPUT_CONDUIT).kiss(SC_DOMAIN_DEPLOYER_07);

        // add RWA-002 contract to the changelog
        DssExecLib.setChangelogAddress("RWA002", RWA002_GEM);
        DssExecLib.setChangelogAddress("PIP_RWA002", pip);
        DssExecLib.setChangelogAddress("MCD_JOIN_RWA002_A", MCD_JOIN_RWA002_A);
        DssExecLib.setChangelogAddress("RWA002_A_URN", RWA002_A_URN);
        DssExecLib.setChangelogAddress(
            "RWA002_A_INPUT_CONDUIT", RWA002_A_INPUT_CONDUIT
        );
        DssExecLib.setChangelogAddress(
            "RWA002_A_OUTPUT_CONDUIT", RWA002_A_OUTPUT_CONDUIT
        );

        // bump changelog version
        DssExecLib.setChangelogVersion("1.2.11");
    }
}

contract DssSpell is DssExec {
    DssSpellAction internal action_ = new DssSpellAction();
    constructor() DssExec(action_.description(), block.timestamp + 30 days, address(action_)) public {}
}
