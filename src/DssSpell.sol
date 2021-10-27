// SPDX-License-Identifier: AGPL-3.0-or-later
//
// Copyright (C) 2021 Dai Foundation
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
pragma experimental ABIEncoderV2;

import "dss-exec-lib/DssExec.sol";
import "dss-exec-lib/DssAction.sol";

interface MomLike {
    function setAuthority(address authority_) external;
}

interface DssVestLike {
    function create(address, uint256, uint256, uint256, uint256, address) external returns (uint256);
    function restrict(uint256) external;
}

contract DssSpellAction is DssAction {

    uint256 constant MILLION  = 10**6;
    uint256 constant RAY      = 10**27;

    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/TODO/governance/votes/TODO.md -q -O - 2>/dev/null)"
    string public constant override description =
        "2021-10-29 MakerDAO Executive Spell | Hash: TODO";

    // Many of the settings that change weekly rely on the rate accumulator
    // described at https://docs.makerdao.com/smart-contract-modules/rates-module
    // To check this yourself, use the following rate calculation (example 8%):
    //
    // $ bc -l <<< 'scale=27; e( l(1.08)/(60 * 60 * 24 * 365) )'
    //
    // A table of rates can be found at
    //    https://ipfs.io/ipfs/QmefQMseb3AiTapiAKKexdKHig8wroKuZbmLtPLv4u2YwW
    //
    uint256 constant ZERO_PCT_RATE = 1000000000000000000000000000;

    address constant ADAI                            = 0x028171bCA77440897B824Ca71D1c56caC55b68A3;
    address constant PIP_ADAI                        = 0x6A858592fC4cBdf432Fc9A1Bc8A0422B99330bdF;
    address constant MCD_JOIN_DIRECT_AAVEV2_DAI      = 0xa13C0c8eB109F5A13c6c90FC26AFb23bEB3Fb04a;
    address constant MCD_CLIP_DIRECT_AAVEV2_DAI      = 0xa93b98e57dDe14A3E301f20933d59DC19BF8212E;
    address constant MCD_CLIP_CALC_DIRECT_AAVEV2_DAI = 0x786DC9b69abeA503fd101a2A9fa95bcE82C20d0A;
    address constant DIRECT_MOM                      = 0x99A219f3dD2DeEC02c6324df5009aaa60bA36d38;

    address constant JOIN_FAB     = 0xf1738d22140783707Ca71CB3746e0dc7Bf2b0264;
    address constant LERP_FAB     = 0x9175561733D138326FDeA86CdFdF53e92b588276;

    address constant MCD_VEST_DAI = 0x2Cc583c0AaCDaC9e23CB601fDA8F1A0c56Cdcb71;

    address constant DIN_WALLET   = 0x7327Aed0Ddf75391098e8753512D8aEc8D740a1F;
    address constant GRO_WALLET   = 0x7800C137A645c07132886539217ce192b9F0528e;

    uint256 constant NOV_01_2021 = 1635724800;
    uint256 constant MAY_01_2022 = 1651363200;
    uint256 constant JUL_01_2022 = 1656633600;

    function actions() public override {

        // Add Aave V2 D3M
        DssExecLib.setStairstepExponentialDecrease(MCD_CLIP_CALC_DIRECT_AAVEV2_DAI, 120 seconds, 9990);
        DssExecLib.setValue(MCD_JOIN_DIRECT_AAVEV2_DAI, "bar", 4 * RAY / 100);      // 4%
        DssExecLib.setValue(MCD_JOIN_DIRECT_AAVEV2_DAI, "tau", 7 days);
        DssExecLib.setContract(MCD_JOIN_DIRECT_AAVEV2_DAI, "king", address(this));

        // Set the D3M Mom authority to be the chief
        MomLike(DIRECT_MOM).setAuthority(DssExecLib.getChangelogAddress("MCD_ADM"));

        // Authorize ESM to shut down during governance attack
        DssExecLib.authorize(MCD_JOIN_DIRECT_AAVEV2_DAI, DssExecLib.esm());

        // Authorize D3M Mom to allow no wait delay
        DssExecLib.authorize(MCD_JOIN_DIRECT_AAVEV2_DAI, DIRECT_MOM);

        CollateralOpts memory DIRECT_AAVEV2_DAI = CollateralOpts({
            ilk:                   "DIRECT-AAVEV2-DAI",
            gem:                   ADAI,
            join:                  MCD_JOIN_DIRECT_AAVEV2_DAI,
            clip:                  MCD_CLIP_DIRECT_AAVEV2_DAI,
            calc:                  MCD_CLIP_CALC_DIRECT_AAVEV2_DAI,
            pip:                   PIP_ADAI,
            isLiquidatable:        false,
            isOSM:                 false,
            whitelistOSM:          false,
            ilkDebtCeiling:        10 * MILLION,
            minVaultAmount:        0,
            maxLiquidationAmount:  0,
            liquidationPenalty:    1300,
            ilkStabilityFee:       ZERO_PCT_RATE,
            startingPriceFactor:   10500,
            breakerTolerance:      9500, // Allows for a 5% hourly price drop before disabling liquidations
            auctionDuration:       220 minutes,
            permittedDrop:         9000,
            liquidationRatio:      10000,
            kprFlatReward:         300,
            kprPctReward:          10 // 0.1%
        });
        DssExecLib.addNewCollateral(DIRECT_AAVEV2_DAI);

        DssExecLib.setChangelogAddress("ADAI", ADAI);
        DssExecLib.setChangelogAddress("MCD_JOIN_DIRECT_AAVEV2_DAI", MCD_JOIN_DIRECT_AAVEV2_DAI);
        DssExecLib.setChangelogAddress("MCD_CLIP_DIRECT_AAVEV2_DAI", MCD_CLIP_DIRECT_AAVEV2_DAI);
        DssExecLib.setChangelogAddress("MCD_CLIP_CALC_DIRECT_AAVEV2_DAI", MCD_CLIP_CALC_DIRECT_AAVEV2_DAI);
        DssExecLib.setChangelogAddress("PIP_ADAI", PIP_ADAI);

        // Data Insights Core Unit Budget
        DssExecLib.sendPaymentFromSurplusBuffer(DIN_WALLET, 107_500);
        DssVestLike(MCD_VEST_DAI).restrict(
            DssVestLike(MCD_VEST_DAI).create(DIN_WALLET, 357_000.00 * 10**18, NOV_01_2021, MAY_01_2022 - NOV_01_2021, 0, address(0))
        );

        // Growth Core Unit Budget
        DssExecLib.sendPaymentFromSurplusBuffer(GRO_WALLET, 791_138);
        DssVestLike(MCD_VEST_DAI).restrict(
            DssVestLike(MCD_VEST_DAI).create(GRO_WALLET, 942_663.00 * 10**18, NOV_01_2021, JUL_01_2022 - NOV_01_2021, 0, address(0))
        );

        // Add Join factory to ChainLog
        DssExecLib.setChangelogAddress("JOIN_FAB", JOIN_FAB);

        // Update Lerp factory in ChainLog
        DssExecLib.setChangelogAddress("LERP_FAB", LERP_FAB);

        // bump changelog version
        DssExecLib.setChangelogVersion("1.9.9");
    }
}


contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) public {}
}
