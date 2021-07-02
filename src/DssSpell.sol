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

contract DssSpellAction is DssAction {

    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/713afa54a66e928426cfda0fb482b03ecf291d25/governance/votes/Executive%20vote%20-%20July%202%2C%202021.md -q -O - 2> /dev/null)"
    string public constant description =
        "2021-07-02 MakerDAO Executive Spell | Hash: 0x601096005a6c4241eac0272a7bab57f4fd966d0fb94ec72a6cb17e4123e3bd86";

    // Turn off office hours
    function officeHours() public override returns (bool) {
        return false;
    }

    uint256 constant WAD = 10**18;
    uint256 constant RAY = 10**27;
    uint256 constant RAD = 10**45;

    bytes32 constant ILK_PSM_USDC_A     = "PSM-USDC-A";

    // Growth Core Unit
    address constant GRO_MULTISIG        = 0x7800C137A645c07132886539217ce192b9F0528e;
    // Content Production Core Unit
    address constant MKT_MULTISIG        = 0xDCAF2C84e1154c8DdD3203880e5db965bfF09B60;
    // GovAlpha Core Unit
    address constant GOV_MULTISIG        = 0x01D26f8c5cC009868A4BF66E268c17B057fF7A73;
    // Real-World Finance Core Unit
    address constant RWF_MULTISIG        = 0x9e1585d9CA64243CE43D42f7dD7333190F66Ca09;
    // Risk Core Unit
    address constant RISK_CU_EOA         = 0xd98ef20520048a35EdA9A202137847A62120d2d9;
    // Protocol Engineering Multisig
    address constant PE_MULTISIG         = 0xe2c16c308b843eD02B09156388Cb240cEd58C01c;
    // Oracles Core Unit (Operating)
    address constant ORA_MULTISIG        = 0x2d09B7b95f3F312ba6dDfB77bA6971786c5b50Cf;
    // Oracles Core Unit (Emergency Fund)
    address constant ORA_ER_MULTISIG     = 0x53CCAA8E3beF14254041500aCC3f1D4edb5B6D24;

    // Many of the settings that change weekly rely on the rate accumulator
    // described at https://docs.makerdao.com/smart-contract-modules/rates-module
    // To check this yourself, use the following rate calculation (example 8%):
    //
    // $ bc -l <<< 'scale=27; e( l(1.08)/(60 * 60 * 24 * 365) )'
    //
    // A table of rates can be found at
    //    https://ipfs.io/ipfs/QmefQMseb3AiTapiAKKexdKHig8wroKuZbmLtPLv4u2YwW
    //
    uint256 constant ZERO_PCT =            1000000000000000000000000000;
    uint256 constant ZERO_POINT_FIVE_PCT = 1000000000158153903837946257;
    uint256 constant ONE_PCT =             1000000000315522921573372069;
    uint256 constant ONE_POINT_FIVE_PCT =  1000000000472114805215157978;
    uint256 constant TWO_PCT =             1000000000627937192491029810;
    uint256 constant SIX_PCT =             1000000001847694957439350562;

    function actions() public override {

        // ----------- Auto-Line updates -----------
        // https://vote.makerdao.com/polling/QmZz4ssm?network=mainnet#poll-detail
        DssExecLib.setIlkAutoLineParameters(ILK_PSM_USDC_A, 10_000_000_000, 1_000_000_000, 24 hours);

        // ----------- Stability Fee updates -----------
        // https://vote.makerdao.com/polling/QmfZWY87?network=mainnet#poll-detail
        DssExecLib.setIlkStabilityFee("ETH-A", TWO_PCT, true);
        DssExecLib.setIlkStabilityFee("ETH-B", SIX_PCT, true);
        DssExecLib.setIlkStabilityFee("ETH-C", ZERO_POINT_FIVE_PCT, true);
        DssExecLib.setIlkStabilityFee("WBTC-A", TWO_PCT, true);
        DssExecLib.setIlkStabilityFee("LINK-A", ONE_PCT, true);
        DssExecLib.setIlkStabilityFee("YFI-A", ONE_PCT, true);
        DssExecLib.setIlkStabilityFee("UNI-A", ONE_PCT, true);
        DssExecLib.setIlkStabilityFee("AAVE-A", ONE_PCT, true);
        DssExecLib.setIlkStabilityFee("RENBTC-A", TWO_PCT, true);
        DssExecLib.setIlkStabilityFee("COMP-A", ONE_PCT, true);
        DssExecLib.setIlkStabilityFee("BAL-A", ONE_PCT, true);
        DssExecLib.setIlkStabilityFee("UNIV2DAIETH-A", ONE_POINT_FIVE_PCT, true);
        DssExecLib.setIlkStabilityFee("UNIV2USDCETH-A", TWO_PCT, true);
        DssExecLib.setIlkStabilityFee("UNIV2DAIUSDC-A", ZERO_PCT, true);
        DssExecLib.setIlkStabilityFee("UNIV2WBTCETH-A", TWO_PCT, true);
        DssExecLib.setIlkStabilityFee("UNIV2UNIETH-A", TWO_PCT, true);
        DssExecLib.setIlkStabilityFee("UNIV2ETHUSDT-A", TWO_PCT, true);

        // Core Unit Budget Distributions - July
        DssExecLib.sendPaymentFromSurplusBuffer(GRO_MULTISIG,    126_117);
        DssExecLib.sendPaymentFromSurplusBuffer(MKT_MULTISIG,     44_375);
        DssExecLib.sendPaymentFromSurplusBuffer(GOV_MULTISIG,    273_334);
        DssExecLib.sendPaymentFromSurplusBuffer(RWF_MULTISIG,    155_000);
        DssExecLib.sendPaymentFromSurplusBuffer(RISK_CU_EOA,     182_000);
        DssExecLib.sendPaymentFromSurplusBuffer(PE_MULTISIG,     510_000);
        DssExecLib.sendPaymentFromSurplusBuffer(ORA_MULTISIG,    419_677);
        DssExecLib.sendPaymentFromSurplusBuffer(ORA_ER_MULTISIG, 800_000);
        //                                                     _________
        //                                         TOTAL DAI:  2,510,503
    }
}

contract DssSpell is DssExec {
    DssSpellAction internal action_ = new DssSpellAction();
    constructor() DssExec(action_.description(), block.timestamp + 30 days, address(action_)) public {}
}
