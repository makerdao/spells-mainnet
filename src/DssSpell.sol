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

import {Fileable, ChainlogLike} from "dss-exec-lib/DssExecLib.sol";
import "dss-exec-lib/DssExec.sol";
import "dss-exec-lib/DssAction.sol";
import "dss-interfaces/dss/IlkRegistryAbstract.sol";
import "dss-interfaces/dss/VowAbstract.sol";
import "dss-interfaces/dss/DogAbstract.sol";
import "dss-interfaces/dss/ClipAbstract.sol";
import "dss-interfaces/dss/ClipperMomAbstract.sol";
import "dss-interfaces/dss/EndAbstract.sol";
import "dss-interfaces/dss/ESMAbstract.sol";

interface LerpFabLike {
    function newLerp(bytes32, address, bytes32, uint256, uint256, uint256, uint256) external returns (address);
}

contract DssSpellAction is DssAction {

    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community//governance/votes/Executive%20vote%20-%20April%2023%2C%202021.md -q -O - 2>/dev/null)"
    string public constant description =
        "2021-04-23 MakerDAO Executive Spell | Hash: ";

    // New addresses
    address constant MCD_CLIP_YFI_A      = 0x9daCc11dcD0aa13386D295eAeeBBd38130897E6f;
    address constant MCD_CLIP_CALC_YFI_A = 0x1f206d7916Fd3B1b5B0Ce53d5Cab11FCebc124DA;
    address constant LERP_FAB            = 0x00B416da876fe42dd02813da435Cc030F0d72434;

    // Units used
    uint256 constant MILLION    = 10**6;
    uint256 constant WAD        = 10**18;
    uint256 constant RAY        = 10**27;
    uint256 constant RAD        = 10**45;

    // Many of the settings that change weekly rely on the rate accumulator
    // described at https://docs.makerdao.com/smart-contract-modules/rates-module
    // To check this yourself, use the following rate calculation (example 8%):
    //
    // $ bc -l <<< 'scale=27; e( l(1.08)/(60 * 60 * 24 * 365) )'
    //
    // A table of rates can be found at
    //    https://ipfs.io/ipfs/QmefQMseb3AiTapiAKKexdKHig8wroKuZbmLtPLv4u2YwW
    //
    uint256 constant ZERO_PCT           = 1000000000000000000000000000;
    uint256 constant ONE_PCT            = 1000000000315522921573372069;
    uint256 constant TWO_PCT            = 1000000000627937192491029810;
    uint256 constant THREE_PCT          = 1000000000937303470807876289;
    uint256 constant THREE_PT_FIVE_PCT  = 1000000001090862085746321732;
    uint256 constant FOUR_PCT           = 1000000001243680656318820312;
    uint256 constant FOUR_PT_FIVE_PCT   = 1000000001395766281313196627;
    uint256 constant FIVE_PCT           = 1000000001547125957863212448;
    uint256 constant TEN_PCT            = 1000000003022265980097387650;

    function actions() public override {
        // ------------- Get all the needed address from Chainlog -------------

        address MCD_VAT        = DssExecLib.vat();
        address MCD_CAT        = DssExecLib.cat();
        address MCD_DOG        = DssExecLib.getChangelogAddress("MCD_DOG");
        address MCD_VOW        = DssExecLib.vow();
        address MCD_SPOT       = DssExecLib.spotter();
        address MCD_END        = DssExecLib.end();
        address MCD_ESM        = DssExecLib.getChangelogAddress("MCD_ESM");
        address CLIPPER_MOM    = DssExecLib.getChangelogAddress("CLIPPER_MOM");
        address ILK_REGISTRY   = DssExecLib.getChangelogAddress("ILK_REGISTRY");
        address PIP_YFI        = DssExecLib.getChangelogAddress("PIP_YFI");
        address MCD_FLIP_YFI_A = DssExecLib.getChangelogAddress("MCD_FLIP_YFI_A");
        address CHANGELOG      = DssExecLib.getChangelogAddress("CHANGELOG");

        // ------------- Increase the System Surplus Buffer And Add Burn Percentage -------------

        // TODO: Review values
        address lerp = LerpFabLike(LERP_FAB).newLerp("20210423_VOW_HUMP1", MCD_VOW, "hump", 1619841600, 30 * MILLION, 60 * MILLION, 105 days);
        VowAbstract(MCD_VOW).rely(lerp);
        DssExecLib.setChangelogAddress("LERP_FAB", LERP_FAB);

        // ------------- Add YFI-A to Liquidations 2.0 Framework -------------

        // Check constructor values of Clipper
        require(ClipAbstract(MCD_CLIP_YFI_A).vat() == MCD_VAT, "DssSpell/clip-wrong-vat");
        require(ClipAbstract(MCD_CLIP_YFI_A).spotter() == MCD_SPOT, "DssSpell/clip-wrong-spotter");
        require(ClipAbstract(MCD_CLIP_YFI_A).dog() == MCD_DOG, "DssSpell/clip-wrong-dog");
        require(ClipAbstract(MCD_CLIP_YFI_A).ilk() == "YFI-A", "DssSpell/clip-wrong-ilk");

        // Set CLIP for YFI-A in the DOG
        DssExecLib.setContract(MCD_DOG, "YFI-A", "clip", MCD_CLIP_YFI_A);

        // Set VOW in the YFI-A CLIP
        DssExecLib.setContract(MCD_CLIP_YFI_A, "vow", MCD_VOW);

        // Set CALC in the YFI-A CLIP
        DssExecLib.setContract(MCD_CLIP_YFI_A, "calc", MCD_CLIP_CALC_YFI_A);

        // Authorize CLIP can access to VAT
        DssExecLib.authorize(MCD_VAT, MCD_CLIP_YFI_A);

        // Authorize CLIP can access to DOG
        DssExecLib.authorize(MCD_DOG, MCD_CLIP_YFI_A);

        // Authorize DOG can kick auctions on CLIP
        DssExecLib.authorize(MCD_CLIP_YFI_A, MCD_DOG);

        // Authorize the new END to access the YFI CLIP
        DssExecLib.authorize(MCD_CLIP_YFI_A, MCD_END);

        // Authorize CLIPPERMOM can set the stopped flag in CLIP
        DssExecLib.authorize(MCD_CLIP_YFI_A, CLIPPER_MOM);

        // Authorize new ESM to execute in YFI-A Clipper
        DssExecLib.authorize(MCD_CLIP_YFI_A, MCD_ESM);

        // Whitelist CLIP in the YFI osm
        DssExecLib.addReaderToOSMWhitelist(PIP_YFI, MCD_CLIP_YFI_A);

        // Whitelist CLIPPER_MOM in the YFI osm
        DssExecLib.addReaderToOSMWhitelist(PIP_YFI, CLIPPER_MOM);

        // No more auctions kicked via the CAT:
        DssExecLib.deauthorize(MCD_FLIP_YFI_A, MCD_CAT);

        // No more circuit breaker for the FLIP in YFI-A:
        DssExecLib.deauthorize(MCD_FLIP_YFI_A, DssExecLib.flipperMom());

        Fileable(MCD_DOG).file("YFI-A", "hole", 5 * MILLION * RAD);
        Fileable(MCD_DOG).file("YFI-A", "chop", 113 * WAD / 100);
        Fileable(MCD_CLIP_YFI_A).file("buf", 130 * RAY / 100);
        Fileable(MCD_CLIP_YFI_A).file("tail", 140 minutes);
        Fileable(MCD_CLIP_YFI_A).file("cusp", 40 * RAY / 100);
        Fileable(MCD_CLIP_YFI_A).file("chip", 1 * WAD / 1000);
        Fileable(MCD_CLIP_YFI_A).file("tip", 0);
        Fileable(MCD_CLIP_CALC_YFI_A).file("cut", 99 * RAY / 100); // 1% cut
        Fileable(MCD_CLIP_CALC_YFI_A).file("step", 90 seconds);

        //  Tolerance currently set to 50%.
        //   n.b. 600000000000000000000000000 == 40% acceptable drop
        ClipperMomAbstract(CLIPPER_MOM).setPriceTolerance(MCD_CLIP_YFI_A, 50 * RAY / 100);

        ClipAbstract(MCD_CLIP_YFI_A).upchost();

        // Replace flip to clip in the ilk registry
        DssExecLib.setContract(ILK_REGISTRY, "YFI-A", "xlip", MCD_CLIP_YFI_A);
        Fileable(ILK_REGISTRY).file("YFI-A", "class", 1);

        DssExecLib.setChangelogAddress("MCD_CLIP_YFI_A", MCD_CLIP_YFI_A);
        DssExecLib.setChangelogAddress("MCD_CLIP_CALC_YFI_A", MCD_CLIP_CALC_YFI_A);
        ChainlogLike(CHANGELOG).removeAddress("MCD_FLIP_YFI_A");

        // ------------- Stability fees -------------
        DssExecLib.setIlkStabilityFee("LINK-A", FIVE_PCT, true);
        DssExecLib.setIlkStabilityFee("ETH-A", TEN_PCT, true);
        DssExecLib.setIlkStabilityFee("ZRX-A", FOUR_PCT, true);
        DssExecLib.setIlkStabilityFee("LRC-A", FOUR_PCT, true);
        DssExecLib.setIlkStabilityFee("UNIV2DAIETH-A", THREE_PT_FIVE_PCT, true);
        DssExecLib.setIlkStabilityFee("UNIV2USDCETH-A", FOUR_PT_FIVE_PCT, true);
        DssExecLib.setIlkStabilityFee("AAVE-A", THREE_PCT, true);
        DssExecLib.setIlkStabilityFee("BAT-A", FIVE_PCT, true);
        DssExecLib.setIlkStabilityFee("MANA-A", THREE_PCT, true);
        DssExecLib.setIlkStabilityFee("BAL-A", TWO_PCT, true);
        DssExecLib.setIlkStabilityFee("UNIV2DAIUSDC-A", ONE_PCT, true);
        DssExecLib.setIlkStabilityFee("UNIV2LINKETH-A", FOUR_PCT, true);
        DssExecLib.setIlkStabilityFee("UNIV2WBTCDAI-A", ZERO_PCT, true);
        DssExecLib.setIlkStabilityFee("UNIV2AAVEETH-A", FOUR_PCT, true);
        DssExecLib.setIlkStabilityFee("UNIV2DAIUSDT-A", THREE_PCT, true);

        // ------------- Regular debt ceilings -------------

        DssExecLib.decreaseIlkDebtCeiling("USDT-A", 25 * MILLION / 10, true);

        // ------------- Auto line max ceiling changes -------------

        DssExecLib.setIlkAutoLineDebtCeiling("YFI-A", 90 * MILLION);
        // DssExecLib.setIlkAutoLineDebtCeiling("AAVE-A", 50 * MILLION);
        DssExecLib.setIlkAutoLineDebtCeiling("BAT-A", 7 * MILLION);
        // DssExecLib.setIlkAutoLineDebtCeiling("RENBTC-A", 10 * MILLION);
        // DssExecLib.setIlkAutoLineDebtCeiling("MANA-A", 5 * MILLION);
        // DssExecLib.setIlkAutoLineDebtCeiling("BAL-A", 30 * MILLION);
        DssExecLib.setIlkAutoLineDebtCeiling("UNIV2DAIETH-A", 50 * MILLION);
        // DssExecLib.setIlkAutoLineDebtCeiling("LRC-A", 5 * MILLION);

        // ------------- Auto line gap changes -------------

        DssExecLib.setIlkAutoLineParameters("AAVE-A", 50 * MILLION, 5 * MILLION, 12 hours);
        DssExecLib.setIlkAutoLineParameters("RENBTC-A", 10 * MILLION, 1 * MILLION, 12 hours);
        DssExecLib.setIlkAutoLineParameters("MANA-A", 5 * MILLION, 1 * MILLION, 12 hours);
        DssExecLib.setIlkAutoLineParameters("BAL-A", 30 * MILLION, 3 * MILLION, 12 hours);
        DssExecLib.setIlkAutoLineParameters("LRC-A", 5 * MILLION, 1 * MILLION, 12 hours);

        // ------------- Auto line new ilks -------------

        DssExecLib.setIlkAutoLineParameters("UNIV2WBTCETH-A", 20 * MILLION, 3 * MILLION, 12 hours);
        DssExecLib.setIlkAutoLineParameters("UNIV2UNIETH-A", 20 * MILLION, 3 * MILLION, 12 hours);
        DssExecLib.setIlkAutoLineParameters("UNIV2LINKETH-A", 20 * MILLION, 2 * MILLION, 12 hours);
        DssExecLib.setIlkAutoLineParameters("UNIV2AAVEETH-A", 20 * MILLION, 2 * MILLION, 12 hours);
        DssExecLib.setIlkAutoLineParameters("UNIV2ETHUSDT-A", 10 * MILLION, 2 * MILLION, 12 hours);
        DssExecLib.setIlkAutoLineParameters("UNIV2DAIUSDT-A", 10 * MILLION, 2 * MILLION, 12 hours);
        DssExecLib.setIlkAutoLineParameters("UNIV2WBTCDAI-A", 20 * MILLION, 3 * MILLION, 12 hours);

        // ------------- Chainlog version -------------

        DssExecLib.setChangelogVersion("1.4.0");
    }
}

contract DssSpell is DssExec {
    DssSpellAction internal action_ = new DssSpellAction();
    constructor() DssExec(action_.description(), block.timestamp + 30 days, address(action_)) public {}
}
