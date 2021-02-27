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

interface ChainlogAbstract {
    function removeAddress(bytes32) external;
}

interface LPOracle {
    function orb0() external view returns (address);
    function orb1() external view returns (address);
}

interface Fileable {
    function file(bytes32,uint256) external;
}

contract DssSpellAction is DssAction {

    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/46cbe46a16b7836d6b219201e3a07d40b01a7db4/governance/votes/Community%20Executive%20vote%20-%20February%2026%2C%202021.md -q -O - 2>/dev/null)"
    string public constant description =
        "2021-02-26 MakerDAO Executive Spell | Hash: 0x4c91fafa587264790d3ad6498caf9c0070a810237c46bb7f3b2556e043ba7b23";


    // Many of the settings that change weekly rely on the rate accumulator
    // described at https://docs.makerdao.com/smart-contract-modules/rates-module
    // To check this yourself, use the following rate calculation (example 8%):
    //
    // $ bc -l <<< 'scale=27; e( l(1.08)/(60 * 60 * 24 * 365) )'
    //
    // A table of rates can be found at
    //    https://ipfs.io/ipfs/QmefQMseb3AiTapiAKKexdKHig8wroKuZbmLtPLv4u2YwW
    //
    uint256 constant FOUR_PCT           = 1000000001243680656318820312;
    uint256 constant FIVE_PT_FIVE_PCT   = 1000000001697766583380253701;
    uint256 constant NINE_PCT           = 1000000002732676825177582095;

    uint256 constant WAD        = 10**18;
    uint256 constant RAD        = 10**45;
    uint256 constant MILLION    = 10**6;

    address constant UNIV2DAIUSDT_GEM   = 0xB20bd5D04BE54f870D5C0d3cA85d82b34B836405;
    address constant UNIV2DAIUSDT_JOIN  = 0xAf034D882169328CAf43b823a4083dABC7EEE0F4;
    address constant UNIV2DAIUSDT_FLIP  = 0xD32f8B8aDbE331eC0CfADa9cfDbc537619622cFe;
    address constant UNIV2DAIUSDT_PIP   = 0x69562A7812830E6854Ffc50b992c2AA861D5C2d3;

    function actions() public override {
        // Rates Proposal - February 22, 2021
        DssExecLib.setIlkStabilityFee("ETH-A", FIVE_PT_FIVE_PCT, true);
        DssExecLib.setIlkStabilityFee("ETH-B", NINE_PCT, true);

        // Onboard UNIV2DAIUSDT-A
        DssExecLib.addReaderToMedianWhitelist(
            LPOracle(UNIV2DAIUSDT_PIP).orb1(),
            UNIV2DAIUSDT_PIP
        );
        CollateralOpts memory UNIV2DAIUSDT_A = CollateralOpts({
            ilk: "UNIV2DAIUSDT-A",
            gem: UNIV2DAIUSDT_GEM,
            join: UNIV2DAIUSDT_JOIN,
            flip: UNIV2DAIUSDT_FLIP,
            pip: UNIV2DAIUSDT_PIP,
            isLiquidatable: true,
            isOSM: true,
            whitelistOSM: false,
            ilkDebtCeiling: 3 * MILLION,
            minVaultAmount: 2000,
            maxLiquidationAmount: 50000,
            liquidationPenalty: 1300,
            ilkStabilityFee: FOUR_PCT,
            bidIncrease: 300,
            bidDuration: 6 hours,
            auctionDuration: 6 hours,
            liquidationRatio: 12500
        });
        addNewCollateral(UNIV2DAIUSDT_A);
        DssExecLib.setChangelogAddress("UNIV2DAIUSDT",             UNIV2DAIUSDT_GEM);
        DssExecLib.setChangelogAddress("MCD_JOIN_UNIV2DAIUSDT_A",  UNIV2DAIUSDT_JOIN);
        DssExecLib.setChangelogAddress("MCD_FLIP_UNIV2DAIUSDT_A",  UNIV2DAIUSDT_FLIP);
        DssExecLib.setChangelogAddress("PIP_UNIV2DAIUSDT",         UNIV2DAIUSDT_PIP);

        // Lower PSM-USDC-A Toll Out
        Fileable(DssExecLib.getChangelogAddress("MCD_PSM_USDC_A")).file("tout", 4 * WAD / 10000);

        // bump Changelog version
        DssExecLib.setChangelogVersion("1.2.8");
    }
}

contract DssSpell is DssExec {
    DssSpellAction internal action_ = new DssSpellAction();
    constructor() DssExec(action_.description(), block.timestamp + 30 days, address(action_)) public {}
}
