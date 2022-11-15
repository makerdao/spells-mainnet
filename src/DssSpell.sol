// SPDX-FileCopyrightText: © 2020 Dai Foundation <www.daifoundation.org>
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

pragma solidity 0.6.12;
// Enable ABIEncoderV2 when onboarding collateral through `DssExecLib.addNewCollateral()`
// pragma experimental ABIEncoderV2;

import "dss-exec-lib/DssExec.sol";
import "dss-exec-lib/DssAction.sol";

interface RwaLiquidationLike {
    function ilks(bytes32) external view returns (string memory, address, uint48, uint48);
    function init(bytes32, uint256, string calldata, uint48) external;
    function bump(bytes32 ilk, uint256 val) external;
}

interface ChainlogLike {
    function removeAddress(bytes32) external;
}

contract DssSpellAction is DssAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: cast keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/d8c711404e9e17db24b611aa03d45507c1993148/governance/votes/Executive%20vote%20-%20November%2016%2C%202022.md -q -O - 2>/dev/null)"

    string public constant override description =
        "2022-11-16 MakerDAO Executive Spell | Hash: 0xf3023b0a9b3c423edf28bf4cdbd61d287ab29265d462a5fae0378227c153ea7b";


    // Turn office hours off
    function officeHours() public override returns (bool) {
        return false;
    }

    // Many of the settings that change weekly rely on the rate accumulator
    // described at https://docs.makerdao.com/smart-contract-modules/rates-module
    // To check this yourself, use the following rate calculation (example 8%):
    //
    // $ bc -l <<< 'scale=27; e( l(1.08)/(60 * 60 * 24 * 365) )'
    //
    // A table of rates can be found at
    //    https://ipfs.io/ipfs/QmVp4mhhbwWGTfbh2BzwQB9eiBrQBKiqcPRZCaAxNUaar6
    //

    // --- Rates ---
    // uint256 internal constant SEVEN_PT_FIVE_PERCENT_RATE = 1000000002293273137447730714;

    // --- Math ---
    uint256 constant WAD            = 10 ** 18;
    uint256 constant MILLION        = 10 ** 6;

    address immutable MIP21_LIQUIDATION_ORACLE = DssExecLib.getChangelogAddress("MIP21_LIQUIDATION_ORACLE");

    function _updateDoc(bytes32 ilk, string memory doc) internal {
        ( , address pip, uint48 tau, ) = RwaLiquidationLike(MIP21_LIQUIDATION_ORACLE).ilks(ilk);
        require(pip != address(0), "DssSpell/unexisting-rwa-ilk");

        // Init the RwaLiquidationOracle to reset the doc
        RwaLiquidationLike(MIP21_LIQUIDATION_ORACLE).init(
            ilk, // ilk to update
            0,   // price ignored if init() has already been called
            doc, // new legal document
            tau  // old tau value
        );
    }

    function actions() public override {
        // -------------------- Update RWA007, RWA008, RWA009 Legal Documents ---------------------
        // https://forum.makerdao.com/t/nov-16-2022-executive-contents/18747
        //
        // Monetalis (RWA007-A) legal update doc
        _updateDoc("RWA007-A", "QmejL1CKKN5vCwp9QD1gebnnAM2MJSt9XbF64uy4ptkJtR");
        // SG Forge OFH (RWA008-A) legal update doc
        _updateDoc("RWA008-A", "QmZ4heYjptvj3ovafADJpXYMFXMyY3yQjkTXpvjFPnAKcy");
        // HVB (RWA009-A) legal update doc
        _updateDoc("RWA009-A", "QmeRrbDF8MVPQfNe83gWf2qV48jApVigm1WyjEtDXCZ5rT");

        // RWA007-A autoline changes:
        // - bump oralce price to 500m
        // - increase DC to 500m
        // - increase autoline `gap` to 100m
        //
        // https://vote.makerdao.com/polling/QmSfMtTM#poll-detail
        DssExecLib.setIlkAutoLineParameters(
            "RWA007-A",
            500 * MILLION,
            100 * MILLION,
            1 weeks
        );
        RwaLiquidationLike(MIP21_LIQUIDATION_ORACLE).bump(
            "RWA007-A",
             500 * MILLION * WAD
        );
        DssExecLib.updateCollateralPrice("RWA007-A");

        // RETH-A autoline changes:
        // - line 5m
        // - gap 3m
        // - ttl 8h
        //
        //  https://vote.makerdao.com/polling/QmfMswF2#poll-detail
        DssExecLib.setIlkAutoLineParameters(
            "RETH-A",
            5 * MILLION,
            3 * MILLION,
            8 hours
        );

        // -------------------- Changelog Update & housekeeping ---------------------

        // - Change "RWA007_A_INPUT_CONDUIT_URN" to "RWA007_A_INPUT_CONDUIT"
        // - Change "RWA007_A_INPUT_CONDUIT_JAR" to "RWA007_A_JAR_INPUT_CONDUIT"
        //
        DssExecLib.setChangelogAddress("RWA007_A_INPUT_CONDUIT", DssExecLib.getChangelogAddress("RWA007_A_INPUT_CONDUIT_URN"));
        DssExecLib.setChangelogAddress("RWA007_A_JAR_INPUT_CONDUIT", DssExecLib.getChangelogAddress("RWA007_A_INPUT_CONDUIT_JAR"));
        ChainlogLike(DssExecLib.LOG).removeAddress("RWA007_A_INPUT_CONDUIT_URN");
        ChainlogLike(DssExecLib.LOG).removeAddress("RWA007_A_INPUT_CONDUIT_JAR");

        // Bump version
        DssExecLib.setChangelogVersion("1.14.5");
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) public {}
}
