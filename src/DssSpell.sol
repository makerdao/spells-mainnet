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
    function ilks(bytes32) external returns (bytes32,address,uint48,uint48);
    function init(bytes32, uint256, string calldata, uint48) external;
}

contract DssSpellAction is DssAction {

    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/5925c52da6f8d485447228ca5acd435997522de6/governance/votes/Executive%20vote%20-%20March%205%2C%202021.md -q -O - 2>/dev/null)"
    string public constant description =
        "2021-03-12 MakerDAO Executive Spell | Hash: TODO";


    // Many of the settings that change weekly rely on the rate accumulator
    // described at https://docs.makerdao.com/smart-contract-modules/rates-module
    // To check this yourself, use the following rate calculation (example 8%):
    //
    // $ bc -l <<< 'scale=27; e( l(1.08)/(60 * 60 * 24 * 365) )'
    //
    // A table of rates can be found at
    //    https://ipfs.io/ipfs/QmefQMseb3AiTapiAKKexdKHig8wroKuZbmLtPLv4u2YwW
    //
    uint256 constant TWO_PCT            = 1000000000627937192491029810;
    uint256 constant THREE_PCT          = 1000000000937303470807876289;
    uint256 constant THREE_PT_FIVE_PCT  = 1000000001090862085746321732;
    uint256 constant FOUR_PCT           = 1000000001243680656318820312;
    uint256 constant FOUR_PT_FIVE_PCT   = 1000000001395766281313196627;
    uint256 constant FIVE_PCT           = 1000000001547125957863212448;

    uint256 constant MILLION    = 10**6;
    uint256 constant WAD        = 10**18;
    uint256 constant RAD        = 10**45;

    // ETH-C
    address constant MCD_JOIN_ETH_C = 0xF04a5cC80B1E94C69B48f5ee68a08CD2F09A7c3E;
    address constant MCD_FLIP_ETH_C = 0x7A67901A68243241EBf66beEB0e7b5395582BF17;

    function actions() public override {
        // Rates Proposal
        DssExecLib.setIlkStabilityFee("UNIV2DAIETH-A", THREE_PCT, true);
        DssExecLib.setIlkStabilityFee("UNIV2USDCETH-A", THREE_PT_FIVE_PCT, true);
        DssExecLib.setIlkStabilityFee("UNIV2WBTCETH-A", FOUR_PT_FIVE_PCT, true);
        DssExecLib.setIlkStabilityFee("UNIV2ETHUSDT-A", FIVE_PCT, true);
        DssExecLib.setIlkStabilityFee("UNIV2LINKETH-A", FIVE_PCT, true);
        DssExecLib.setIlkStabilityFee("UNIV2UNIETH-A", FIVE_PCT, true);
        DssExecLib.setIlkStabilityFee("UNIV2AAVEETH-A", FIVE_PCT, true);
        DssExecLib.setIlkStabilityFee("MANA-A", FOUR_PCT, true);
        DssExecLib.setIlkStabilityFee("UNIV2WBTCDAI-A", TWO_PCT, true);
        DssExecLib.setIlkStabilityFee("RENBTC-A", FIVE_PCT, true);

        // Onboarding ETH-C
        CollateralOpts memory ETH_C = CollateralOpts({
            ilk: "ETH-C",
            gem: DssExecLib.getChangelogAddress("ETH"),
            join: MCD_JOIN_ETH_C,
            flip: MCD_FLIP_ETH_C,
            pip: DssExecLib.getChangelogAddress("PIP_ETH"),
            isLiquidatable: true,
            isOSM: true,
            whitelistOSM: false,
            ilkDebtCeiling: 100 * MILLION,
            minVaultAmount: 2000,
            maxLiquidationAmount: 50000,
            liquidationPenalty: 1300,
            ilkStabilityFee: THREE_PT_FIVE_PCT,
            bidIncrease: 300,
            bidDuration: 4 hours,
            auctionDuration: 4 hours,
            liquidationRatio: 17500
        });
        addNewCollateral(ETH_C);
        DssExecLib.setIlkAutoLineParameters("ETH-C", 2000 * MILLION, 100 * MILLION, 12 hours);

        DssExecLib.setChangelogAddress("MCD_JOIN_ETH_C", MCD_JOIN_ETH_C);
        DssExecLib.setChangelogAddress("MCD_FLIP_ETH_C", MCD_FLIP_ETH_C);

        // bump changelog version
        DssExecLib.setChangelogVersion("1.2.10");
    }
}

contract DssSpell is DssExec {
    DssSpellAction internal action_ = new DssSpellAction();
    constructor() DssExec(action_.description(), block.timestamp + 30 days, address(action_)) public {}
}
