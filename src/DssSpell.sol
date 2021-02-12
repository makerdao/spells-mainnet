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

contract DssSpellAction is DssAction {

    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/9b7eba966a6f43e95935276313cac2490ec44e71/governance/votes/Executive%20vote%20-%20February%2012%2C%202021.md -q -O - 2>/dev/null)"
    string public constant description =
        "2021-02-12 MakerDAO Executive Spell | Hash: 0x82215e761ec28f92aa02ac1c3533a9315a9accc2847b9dac99ae2aa65d9a9b27";


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
    uint256 constant TWO_PT_FIVE_PCT    = 1000000000782997609082909351;
    uint256 constant THREE_PCT          = 1000000000937303470807876289;
    uint256 constant THREE_PT_FIVE_PCT  = 1000000001090862085746321732;
    uint256 constant FOUR_PT_FIVE_PCT   = 1000000001395766281313196627;
    uint256 constant FIVE_PT_FIVE_PCT   = 1000000001697766583380253701;
    uint256 constant SIX_PCT            = 1000000001847694957439350562;
    uint256 constant SEVEN_PT_FIVE_PCT  = 1000000002293273137447730714;

    /**
        @dev constructor (required)
        @param officeHours true if officehours enabled
    */
    constructor(bool officeHours) public DssAction(officeHours) {}

    uint256 constant WAD        = 10**18;
    uint256 constant RAD        = 10**45;
    uint256 constant MILLION    = 10**6;

    bytes32 constant ETH_A_ILK          = "ETH-A";
    bytes32 constant ETH_B_ILK          = "ETH-B";
    bytes32 constant UNI_ILK            = "UNI-A";
    bytes32 constant AAVE_ILK           = "AAVE-A";
    bytes32 constant COMP_ILK           = "COMP-A";
    bytes32 constant LINK_ILK           = "LINK-A";
    bytes32 constant WBTC_ILK           = "WBTC-A";
    bytes32 constant YFI_ILK            = "YFI-A";
    bytes32 constant BAL_ILK            = "BAL-A";
    bytes32 constant BAT_ILK            = "BAT-A";
    bytes32 constant UNIV2DAIETH_ILK    = "UNIV2DAIETH-A";
    bytes32 constant UNIV2USDCETH_ILK   = "UNIV2USDCETH-A";
    bytes32 constant UNIV2WBTCETH_ILK   = "UNIV2WBTCETH-A";

    bytes32 constant UNIV2LINKETH_ILK   = "UNIV2LINKETH-A";
    address constant UNIV2LINKETH_GEM   = 0xa2107FA5B38d9bbd2C461D6EDf11B11A50F6b974;
    address constant UNIV2LINKETH_JOIN  = 0xDae88bDe1FB38cF39B6A02b595930A3449e593A6;
    address constant UNIV2LINKETH_FLIP  = 0xb79f818e3c73fca387845f892356224ca75eac4b;
    address constant UNIV2LINKETH_PIP   = 0x628009F5F5029544AE84636Ef676D3Cc5755238b;

    bytes32 constant UNIV2UNIETH_ILK    = "UNIV2UNIETH-A";
    address constant UNIV2UNIETH_GEM    = 0xd3d2E2692501A5c9Ca623199D38826e513033a17;
    address constant UNIV2UNIETH_JOIN   = 0xf11a98339fe1cde648e8d1463310ce3ccc3d7cc1;
    address constant UNIV2UNIETH_FLIP   = 0xe5ed7da0483e291485011d5372f3bf46235eb277;
    address constant UNIV2UNIETH_PIP    = 0x8Ce9E9442F2791FC63CD6394cC12F2dE4fbc1D71;

    function actions() public override {
        // DC-IAM
        setIlkAutoLineParameters(UNI_ILK, 50 * MILLION, 3 * MILLION, 12 hours);
        setIlkAutoLineParameters(AAVE_ILK, 25 * MILLION, 2 * MILLION, 12 hours);
        setIlkAutoLineParameters(COMP_ILK, 10 * MILLION, 2 * MILLION, 12 hours);
        setIlkAutoLineParameters(LINK_ILK, 140 * MILLION, 7 * MILLION, 12 hours);
        setIlkAutoLineParameters(WBTC_ILK, 350 * MILLION, 15 * MILLION, 12 hours);
        setIlkAutoLineParameters(YFI_ILK, 45 * MILLION, 5 * MILLION, 12 hours);

        // add UNI-V2-LINK-ETH-A collateral type
        addReaderToMedianWhitelist(
            LPOracle(UNIV2LINKETH_A).orb0(),
            UNIV2LINKETH_A
        );
        addReaderToMedianWhitelist(
            LPOracle(UNIV2LINKETH_A).orb1(),
            UNIV2LINKETH_A
        );
        CollateralOpts memory UNIV2LINKETH_A = CollateralOpts({
            ilk: UNIV2LINKETH_ILK,
            gem: UNIV2LINKETH_GEM,
            join: UNIV2LINKETH_JOIN,
            flip: UNIV2LINKETH_FLIP,
            pip: UNIV2LINKETH_PIP,
            isLiquidatable: true,
            isOSM: true,
            whitelistOSM: false,
            ilkDebtCeiling: 3 * MILLION, // initially 3 million
            minVaultAmount: 2000,
            maxLiquidationAmount: 50000,
            liquidationPenalty: 1300,
            ilkStabilityFee: FOUR_PCT, // 4%
            bidIncrease: 300, // 3%
            bidDuration: 6 hours,
            auctionDuration: 6 hours,
            liquidationRatio: 16500 // 165%
        });
        addNewCollateral(UNIV2LINKETH_A);

        // add UNI-V2-ETH-USDT-A collateral type
        addReaderToMedianWhitelist(
            LPOracle(UNIV2UNIETH_PIP).orb0(),
            UNIV2UNIETH_PIP
        );
        addReaderToMedianWhitelist(
            LPOracle(UNIV2UNIETH_PIP).orb1(),
            UNIV2UNIETH_PIP
        );
        CollateralOpts memory UNIV2UNIETH_A = CollateralOpts({
            ilk: "UNIV2UNIETH-A",
            gem: UNIV2UNIETH_GEM,
            join: UNIV2UNIETH_JOIN,
            flip: UNIV2UNIETH_FLIP,
            pip: UNIV2UNIETH_PIP,
            isLiquidatable: true,
            isOSM: true,
            whitelistOSM: false,
            ilkDebtCeiling: 3 * MILLION, // initially 3 million
            minVaultAmount: 2000,
            maxLiquidationAmount: 50000,
            liquidationPenalty: 1300,
            ilkStabilityFee: FOUR_PCT, // 4%
            bidIncrease: 300, // 3%
            bidDuration: 6 hours,
            auctionDuration: 6 hours,
            liquidationRatio: 16500 // 165%
        });
        addNewCollateral(UNIV2UNIETH_A);

        // Rates changes
        setIlkStabilityFee(ETH_A_ILK, FOUR_PT_FIVE_PCT, true);
        setIlkStabilityFee(ETH_B_ILK, SEVEN_PT_FIVE_PCT, true);
        setIlkStabilityFee(WBTC_ILK, FOUR_PT_FIVE_PCT, true);
        setIlkStabilityFee(LINK_ILK, THREE_PT_FIVE_PCT, true);
        setIlkStabilityFee(COMP_ILK, THREE_PCT, true);
        setIlkStabilityFee(BAL_ILK, THREE_PT_FIVE_PCT, true);
        setIlkStabilityFee(UNIV2DAIETH_ILK, TWO_PCT, true);
        setIlkStabilityFee(UNIV2USDCETH_ILK, TWO_PT_FIVE_PCT, true);
        setIlkStabilityFee(UNIV2WBTCETH_ILK, THREE_PT_FIVE_PCT, true);
        setIlkStabilityFee(BAT_ILK, SIX_PCT, true);
        setIlkStabilityFee(YFI_ILK, FIVE_PT_FIVE_PCT, true);

        // Interim DAO Budget (Note: we are leaving daiJoin hoped from the Pause Proxy for future payments)
        address MCD_JOIN_DAI = getChangelogAddress("MCD_VAT");
        VatAbstract(vat()).suck(vow(), address(this), 100_000 * RAD);
        VatAbstract(vat()).hope(MCD_JOIN_DAI);
        DaiJoinAbstract(MCD_JOIN_DAI).exit(0x73f09254a81e1F835Ee442d1b3262c1f1d7A13ff, 100_000 * WAD);

        // add UNIV2LINKETH to Changelog
        setChangelogAddress("UNIV2LINKETH",             UNIV2LINKETH_GEM);
        setChangelogAddress("MCD_JOIN_UNIV2LINKETH_A",  UNIV2LINKETH_JOIN);
        setChangelogAddress("MCD_FLIP_UNIV2LINKETH_A",  UNIV2LINKETH_FLIP);
        setChangelogAddress("PIP_UNIV2LINKETH",         UNIV2LINKETH_PIP);

        // add UNIV2UNIETH to Changelog
        setChangelogAddress("UNIV2UNIETH",             UNIV2UNIETH_GEM);
        setChangelogAddress("MCD_JOIN_UNIV2UNIETH_A",  UNIV2UNIETH_JOIN);
        setChangelogAddress("MCD_FLIP_UNIV2UNIETH_A",  UNIV2UNIETH_FLIP);
        setChangelogAddress("PIP_UNIV2UNIETH",         UNIV2UNIETH_PIP);

        // bump Changelog version
        setChangelogVersion("1.2.6");
    }
}

contract DssSpell is DssExec {
    DssSpellAction public spell = new DssSpellAction(true);
    constructor() DssExec(spell.description(), now + 30 days, address(spell)) public {}
}
