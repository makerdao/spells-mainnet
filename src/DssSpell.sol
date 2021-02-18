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
import "lib/dss-interfaces/src/dss/VatAbstract.sol";
import "lib/dss-interfaces/src/dss/DaiJoinAbstract.sol";
import "lib/dss-interfaces/src/dss/DaiAbstract.sol";

interface ChainlogAbstract {
    function removeAddress(bytes32) external;
}

interface LPOracle {
    function orb0() external view returns (address);
    function orb1() external view returns (address);
}

interface GnosisAllowanceModule {
    function executeAllowanceTransfer(address safe, address token, address to, uint96 amount, address paymentToken, uint96 payment, address delegate, bytes memory signature) external;
}

contract DssSpellAction is DssAction {

    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/9b7eba966a6f43e95935276313cac2490ec44e71/governance/votes/Executive%20vote%20-%20February%2012%2C%202021.md -q -O - 2>/dev/null)"
    string public constant description =
        "2021-02-19 MakerDAO Executive Spell | Hash: TODO";


    // Many of the settings that change weekly rely on the rate accumulator
    // described at https://docs.makerdao.com/smart-contract-modules/rates-module
    // To check this yourself, use the following rate calculation (example 8%):
    //
    // $ bc -l <<< 'scale=27; e( l(1.08)/(60 * 60 * 24 * 365) )'
    //
    // A table of rates can be found at
    //    https://ipfs.io/ipfs/QmefQMseb3AiTapiAKKexdKHig8wroKuZbmLtPLv4u2YwW
    //
    uint256 constant ONE_HUNDREDTH_PCT = 1000000000003170820659990704;

    /**
        @dev constructor (required)
        @param officeHours true if officehours enabled
    */
    constructor(bool officeHours) public DssAction(officeHours) {}

    uint256 constant WAD        = 10**18;
    uint256 constant RAD        = 10**45;
    uint256 constant MILLION    = 10**6;

    bytes32 constant ETH_A_ILK          = "ETH-A";
    bytes32 constant LRC_A_ILK          = "LRC-A";
    bytes32 constant BAT_A_ILK          = "BAT-A";
    bytes32 constant BAL_A_ILK          = "BAL-A";
    bytes32 constant MANA_A_ILK         = "MANA-A";
    bytes32 constant ZRX_A_ILK          = "ZRX-A";
    bytes32 constant KNC_A_ILK          = "KNC-A";
    bytes32 constant RENBTC_A_ILK       = "RENBTC-A";
    bytes32 constant PSM_USDC_A_ILK     = "PSM-USDC-A";
    bytes32 constant UNIV2DAIUSDC_A_ILK = "PSM-USDC-A";

    function actions() public override {
        // Increase ETH-A Maximum Debt Ceiling
        setIlkAutoLineDebtCeiling(ETH_A_ILK, 2_500 * MILLION);

        // Set Debt Ceiling Instant Access Module Parameters For Multiple Vault Types
        setIlkAutoLineParameters(LRC_A_ILK, 10 * MILLION, 2 * MILLION, 12 hours);
        setIlkAutoLineParameters(BAT_A_ILK, 3 * MILLION, 1 * MILLION, 12 hours);
        setIlkAutoLineParameters(BAL_A_ILK, 5 * MILLION, 1 * MILLION, 12 hours);
        setIlkAutoLineParameters(MANA_A_ILK, 2 * MILLION, 500_000, 12 hours);
        setIlkAutoLineParameters(ZRX_A_ILK, 5 * MILLION, 1 * MILLION, 12 hours);
        setIlkAutoLineParameters(KNC_A_ILK, 5 * MILLION, 1 * MILLION, 12 hours);
        setIlkAutoLineParameters(RENBTC_A_ILK, 2 * MILLION, 500_000, 12 hours);

        // Increase System Surplus Buffer
        setSurplusBuffer(30 * MILLION);

        // TODO: Onboard UNIV2WBTCDAI-A

        // TODO: Onboard UNIV2AAVEETH-A

        // Dai Savings Rate Adjustment
        setDSR(ONE_HUNDREDTH_PCT);

        // Remove Permissions for Liquidations Circuit Breaker
        address flipperMom = flipperMom();
        deauthorize(flip(PSM_USDC_A_ILK), flipperMom);
        deauthorize(flip(UNIV2DAIUSDC_A_ILK), flipperMom);
    }
}

contract DssSpell is DssExec {
    DssSpellAction public spell = new DssSpellAction(true);
    constructor() DssExec(spell.description(), now + 30 days, address(spell)) public {}
}
