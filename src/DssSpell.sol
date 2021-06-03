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
import "dss-interfaces/dss/ClipAbstract.sol";
import "dss-interfaces/dss/ClipperMomAbstract.sol";

struct Collateral {
    bytes32 ilk;
    address vat;
    address vow;
    address spotter;
    address cat;
    address dog;
    address end;
    address esm;
    address flipperMom;
    address clipperMom;
    address ilkRegistry;
    address pip;
    address clipper;
    address flipper;
    address calc;
    uint256 hole;
    uint256 chop;
    uint256 buf;
    uint256 tail;
    uint256 cusp;
    uint256 chip;
    uint256 tip;
    uint256 cut;
    uint256 step;
    uint256 tolerance;
    bytes32 clipKey;
    bytes32 calcKey;
    bytes32 flipKey;
}

contract DssSpellAction is DssAction {

    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/1159b773b56c125c9f955b8012316fc752b287ce/governance/votes/Executive%20vote%20-%20June%204%2C%202021.md -q -O - 2> /dev/null)"
    string public constant description =
        "2021-06-04 MakerDAO Executive Spell | Hash: ";

    // Turn off office hours
    function officeHours() public override returns (bool) {
        return false;
    }

    uint256 constant WAD = 10**18;
    uint256 constant RAY = 10**27;
    uint256 constant RAD = 10**45;

    address constant MCD_CLIP_USDC_A              = 0x046b1A5718da6A226D912cFd306BA19980772908;
    address constant MCD_CLIP_CALC_USDC_A         = 0x0FCa4ba0B80123b5d22dD3C8BF595F3E561d594D;
    address constant MCD_CLIP_USDC_B              = 0x5590F23358Fe17361d7E4E4f91219145D8cCfCb3;
    address constant MCD_CLIP_CALC_USDC_B         = 0xD6FE411284b92d309F79e502Dd905D7A3b02F561;
    address constant MCD_CLIP_TUSD_A              = 0x0F6f88f8A4b918584E3539182793a0C276097f44;
    address constant MCD_CLIP_CALC_TUSD_A         = 0x059acdf311E38aAF77139638228d393Ff27639bF;
    address constant MCD_CLIP_USDT_A              = 0xFC9D6Dd08BEE324A5A8B557d2854B9c36c2AeC5d;
    address constant MCD_CLIP_CALC_USDT_A         = 0x1Cf3DE6D570291CDB88229E70037d1705d5be748;
    address constant MCD_CLIP_PAXUSD_A            = 0xBCb396Cd139D1116BD89562B49b9D1d6c25378B0;
    address constant MCD_CLIP_CALC_PAXUSD_A       = 0xAB98De83840b8367046383D2Adef9959E130923e;
    address constant MCD_CLIP_GUSD_A              = 0xa47D68b9dB0A0361284fA04BA40623fcBd1a263E;
    address constant MCD_CLIP_CALC_GUSD_A         = 0xF7e80359Cb9C4E6D178E6689eD8A6A6f91060747;
    address constant MCD_CLIP_PSM_USDC_A          = 0x66609b4799fd7cE12BA799AD01094aBD13d5014D;
    address constant MCD_CLIP_CALC_PSM_USDC_A     = 0xbEF2ab2aA5CC780A03bccf22AD3320c8CF35af6A;
    address constant MCD_CLIP_UNIV2DAIUSDC_A      = 0x9B3310708af333f6F379FA42a5d09CBAA10ab309;
    address constant MCD_CLIP_CALC_UNIV2DAIUSDC_A = 0xbeE028b5Fa9eb0aDAC5eeF7E5B13383172b91A4E;

    address constant RWF_001_MULSTISIG  = 0x9e1585d9CA64243CE43D42f7dD7333190F66Ca09;
    uint256 constant RWF_001_EXPENSE    = 40_000;
    address constant RISK_001_MULSTISIG = 0xd98ef20520048a35EdA9A202137847A62120d2d9;
    uint256 constant RISK_001_EXPENSE   = 100_500;
    address constant GOV_001_MULSTISIG  = 0x01D26f8c5cC009868A4BF66E268c17B057fF7A73;
    uint256 constant GOV_001_EXPENSE    = 80_000;
    address constant PE_001_MULSTISIG   = 0xe2c16c308b843eD02B09156388Cb240cEd58C01c;
    uint256 constant PE_001_EXPENSE     = 510_000;
    address constant GRO_001_MULSTISIG  = 0x7800C137A645c07132886539217ce192b9F0528e;
    uint256 constant GRO_001_EXPENSE    = 126_117;
    address constant MKT_001_MULSTISIG  = 0xDCAF2C84e1154c8DdD3203880e5db965bfF09B60;
    uint256 constant MKT_001_EXPENSE    = 44_375;
    address constant SES_001_MULSTISIG  = 0x87AcDD9208f73bFc9207e1f6F0fDE906bcA95cc6;
    uint256 constant SES_001_EXPENSE    = 642_135;

    function flipperToClipper(Collateral memory col) internal {
        // Check constructor values of Clipper
        require(ClipAbstract(col.clipper).vat() == col.vat, "DssSpell/clip-wrong-vat");
        require(ClipAbstract(col.clipper).spotter() == col.spotter, "DssSpell/clip-wrong-spotter");
        require(ClipAbstract(col.clipper).dog() == col.dog, "DssSpell/clip-wrong-dog");
        require(ClipAbstract(col.clipper).ilk() == col.ilk, "DssSpell/clip-wrong-ilk");
        // Set CLIP for the ilk in the DOG
        DssExecLib.setContract(col.dog, col.ilk, "clip", col.clipper);
        // Set VOW in the CLIP
        DssExecLib.setContract(col.clipper, "vow", col.vow);
        // Set CALC in the CLIP
        DssExecLib.setContract(col.clipper, "calc", col.calc);
        // Authorize CLIP can access to VAT
        DssExecLib.authorize(col.vat, col.clipper);
        // Authorize CLIP can access to DOG
        DssExecLib.authorize(col.dog, col.clipper);
        // Authorize DOG can kick auctions on CLIP
        DssExecLib.authorize(col.clipper, col.dog);
        // Authorize the END to access the CLIP
        DssExecLib.authorize(col.clipper, col.end);
        // Authorize CLIPPERMOM can set the stopped flag in CLIP
        // DssExecLib.authorize(col.clipper, col.clipperMom);
        ClipAbstract(col.clipper).file("stopped", 3);
        // Authorize ESM to execute in Clipper
        DssExecLib.authorize(col.clipper, col.esm);
        if (col.pip != address(0)) {
            // We are passing address(0) to those ilks that use a DSValue
            // instead of an Osm or LPOracle. Meaning there is nothing to
            // whilelist on them, the call would revert otherwise.

            // Whitelist CLIP in the osm
            DssExecLib.addReaderToOSMWhitelist(col.pip, col.clipper);
            // Whitelist clipperMom in the osm
            DssExecLib.addReaderToOSMWhitelist(col.pip, col.clipperMom);
        }
        // No more auctions kicked via the CAT:
        DssExecLib.deauthorize(col.flipper, col.cat);
        // No more circuit breaker for the FLIP:
        DssExecLib.deauthorize(col.flipper, col.flipperMom);
        // Set values
        Fileable(col.dog).file(col.ilk, "hole", col.hole);
        Fileable(col.dog).file(col.ilk, "chop", col.chop);
        Fileable(col.clipper).file("buf", col.buf);
        Fileable(col.clipper).file("tail", col.tail);
        Fileable(col.clipper).file("cusp", col.cusp);
        Fileable(col.clipper).file("chip", col.chip);
        Fileable(col.clipper).file("tip", col.tip);
        Fileable(col.calc).file("cut", col.cut);
        Fileable(col.calc).file("step", col.step);
        ClipperMomAbstract(col.clipperMom).setPriceTolerance(col.clipper, col.tolerance);
        // Update chost
        ClipAbstract(col.clipper).upchost();
        // Replace flip to clip in the ilk registry
        DssExecLib.setContract(col.ilkRegistry, col.ilk, "xlip", col.clipper);
        Fileable(col.ilkRegistry).file(col.ilk, "class", 1);
        // Update Chainlog
        DssExecLib.setChangelogAddress(col.clipKey, col.clipper);
        DssExecLib.setChangelogAddress(col.calcKey, col.calc);
        ChainlogLike(DssExecLib.LOG).removeAddress(col.flipKey);
    }

    function actions() public override {
        address MCD_VAT         = DssExecLib.vat();
        address MCD_CAT         = DssExecLib.cat();
        address MCD_DOG         = DssExecLib.getChangelogAddress("MCD_DOG");
        address MCD_VOW         = DssExecLib.vow();
        address MCD_SPOT        = DssExecLib.spotter();
        address MCD_END         = DssExecLib.end();
        address MCD_ESM         = DssExecLib.getChangelogAddress("MCD_ESM");
        address FLIPPER_MOM     = DssExecLib.getChangelogAddress("FLIPPER_MOM");
        address CLIPPER_MOM     = DssExecLib.getChangelogAddress("CLIPPER_MOM");
        address ILK_REGISTRY    = DssExecLib.getChangelogAddress("ILK_REGISTRY");

        // ----------------------------- Global Debt Ceiling ----------------------------
        DssExecLib.increaseGlobalDebtCeiling(500_000_000);

        // --------------------------------- PSM Fee Out --------------------------------
        Fileable(DssExecLib.getChangelogAddress("MCD_PSM_USDC_A")).file("tout", 0);

        // ----------------------------- Core Units Payments ----------------------------
        DssExecLib.sendPaymentFromSurplusBuffer(RWF_001_MULSTISIG,  RWF_001_EXPENSE);
        DssExecLib.sendPaymentFromSurplusBuffer(RISK_001_MULSTISIG, RISK_001_EXPENSE);
        DssExecLib.sendPaymentFromSurplusBuffer(GOV_001_MULSTISIG,  GOV_001_EXPENSE);
        DssExecLib.sendPaymentFromSurplusBuffer(PE_001_MULSTISIG,   PE_001_EXPENSE);
        DssExecLib.sendPaymentFromSurplusBuffer(GRO_001_MULSTISIG,  GRO_001_EXPENSE);
        DssExecLib.sendPaymentFromSurplusBuffer(MKT_001_MULSTISIG,  MKT_001_EXPENSE);
        DssExecLib.sendPaymentFromSurplusBuffer(SES_001_MULSTISIG,  SES_001_EXPENSE);

        // ----------------------------------- USDC-A -----------------------------------
        flipperToClipper(Collateral({
            ilk: "USDC-A",
            vat: MCD_VAT,
            vow: MCD_VOW,
            spotter: MCD_SPOT,
            cat: MCD_CAT,
            dog: MCD_DOG,
            end: MCD_END,
            esm: MCD_ESM,
            flipperMom: FLIPPER_MOM,
            clipperMom: CLIPPER_MOM,
            ilkRegistry: ILK_REGISTRY,
            pip: address(0), // DsValue (nothing to whitelist)
            clipper: MCD_CLIP_USDC_A,
            flipper: DssExecLib.getChangelogAddress("MCD_FLIP_USDC_A"),
            calc: MCD_CLIP_CALC_USDC_A,
            hole: 0,
            chop: 113 * WAD / 100,
            buf: 105 * RAY / 100,
            tail: 220 minutes,
            cusp: 90 * RAY / 100,
            chip: 1 * WAD / 1000,
            tip: 300 * RAD,
            cut: 999 * RAY / 1000,
            step: 120 seconds,
            tolerance: 95 * RAY / 100,
            clipKey: "MCD_CLIP_USDC_A",
            calcKey: "MCD_CLIP_CALC_USDC_A",
            flipKey: "MCD_FLIP_USDC_A"
        }));

        // ----------------------------------- USDC-B -----------------------------------
        flipperToClipper(Collateral({
            ilk: "USDC-B",
            vat: MCD_VAT,
            vow: MCD_VOW,
            spotter: MCD_SPOT,
            cat: MCD_CAT,
            dog: MCD_DOG,
            end: MCD_END,
            esm: MCD_ESM,
            flipperMom: FLIPPER_MOM,
            clipperMom: CLIPPER_MOM,
            ilkRegistry: ILK_REGISTRY,
            pip: address(0), // DsValue (nothing to whitelist)
            clipper: MCD_CLIP_USDC_B,
            flipper: DssExecLib.getChangelogAddress("MCD_FLIP_USDC_B"),
            calc: MCD_CLIP_CALC_USDC_B,
            hole: 0,
            chop: 113 * WAD / 100,
            buf: 105 * RAY / 100,
            tail: 220 minutes,
            cusp: 90 * RAY / 100,
            chip: 1 * WAD / 1000,
            tip: 300 * RAD,
            cut: 999 * RAY / 1000,
            step: 120 seconds,
            tolerance: 95 * RAY / 100,
            clipKey: "MCD_CLIP_USDC_B",
            calcKey: "MCD_CLIP_CALC_USDC_B",
            flipKey: "MCD_FLIP_USDC_B"
        }));

        // ----------------------------------- TUSD-A -----------------------------------
        flipperToClipper(Collateral({
            ilk: "TUSD-A",
            vat: MCD_VAT,
            vow: MCD_VOW,
            spotter: MCD_SPOT,
            cat: MCD_CAT,
            dog: MCD_DOG,
            end: MCD_END,
            esm: MCD_ESM,
            flipperMom: FLIPPER_MOM,
            clipperMom: CLIPPER_MOM,
            ilkRegistry: ILK_REGISTRY,
            pip: address(0), // DsValue (nothing to whitelist)
            clipper: MCD_CLIP_TUSD_A,
            flipper: DssExecLib.getChangelogAddress("MCD_FLIP_TUSD_A"),
            calc: MCD_CLIP_CALC_TUSD_A,
            hole: 0,
            chop: 113 * WAD / 100,
            buf: 105 * RAY / 100,
            tail: 220 minutes,
            cusp: 90 * RAY / 100,
            chip: 1 * WAD / 1000,
            tip: 300 * RAD,
            cut: 999 * RAY / 1000,
            step: 120 seconds,
            tolerance: 95 * RAY / 100,
            clipKey: "MCD_CLIP_TUSD_A",
            calcKey: "MCD_CLIP_CALC_TUSD_A",
            flipKey: "MCD_FLIP_TUSD_A"
        }));

        // ----------------------------------- USDT-A -----------------------------------
        flipperToClipper(Collateral({
            ilk: "USDT-A",
            vat: MCD_VAT,
            vow: MCD_VOW,
            spotter: MCD_SPOT,
            cat: MCD_CAT,
            dog: MCD_DOG,
            end: MCD_END,
            esm: MCD_ESM,
            flipperMom: FLIPPER_MOM,
            clipperMom: CLIPPER_MOM,
            ilkRegistry: ILK_REGISTRY,
            pip: DssExecLib.getChangelogAddress("PIP_USDT"),
            clipper: MCD_CLIP_USDT_A,
            flipper: DssExecLib.getChangelogAddress("MCD_FLIP_USDT_A"),
            calc: MCD_CLIP_CALC_USDT_A,
            hole: 0,
            chop: 113 * WAD / 100,
            buf: 105 * RAY / 100,
            tail: 220 minutes,
            cusp: 90 * RAY / 100,
            chip: 1 * WAD / 1000,
            tip: 300 * RAD,
            cut: 999 * RAY / 1000,
            step: 120 seconds,
            tolerance: 95 * RAY / 100,
            clipKey: "MCD_CLIP_USDT_A",
            calcKey: "MCD_CLIP_CALC_USDT_A",
            flipKey: "MCD_FLIP_USDT_A"
        }));

        // ---------------------------------- PAXUSD-A ---------------------------------
        flipperToClipper(Collateral({
            ilk: "PAXUSD-A",
            vat: MCD_VAT,
            vow: MCD_VOW,
            spotter: MCD_SPOT,
            cat: MCD_CAT,
            dog: MCD_DOG,
            end: MCD_END,
            esm: MCD_ESM,
            flipperMom: FLIPPER_MOM,
            clipperMom: CLIPPER_MOM,
            ilkRegistry: ILK_REGISTRY,
            pip: address(0), // DsValue (nothing to whitelist)
            clipper: MCD_CLIP_PAXUSD_A,
            flipper: DssExecLib.getChangelogAddress("MCD_FLIP_PAXUSD_A"),
            calc: MCD_CLIP_CALC_PAXUSD_A,
            hole: 0,
            chop: 113 * WAD / 100,
            buf: 105 * RAY / 100,
            tail: 220 minutes,
            cusp: 90 * RAY / 100,
            chip: 1 * WAD / 1000,
            tip: 300 * RAD,
            cut: 999 * RAY / 1000,
            step: 120 seconds,
            tolerance: 95 * RAY / 100,
            clipKey: "MCD_CLIP_PAXUSD_A",
            calcKey: "MCD_CLIP_CALC_PAXUSD_A",
            flipKey: "MCD_FLIP_PAXUSD_A"
        }));

        // ----------------------------------- GUSD-A -----------------------------------
        flipperToClipper(Collateral({
            ilk: "GUSD-A",
            vat: MCD_VAT,
            vow: MCD_VOW,
            spotter: MCD_SPOT,
            cat: MCD_CAT,
            dog: MCD_DOG,
            end: MCD_END,
            esm: MCD_ESM,
            flipperMom: FLIPPER_MOM,
            clipperMom: CLIPPER_MOM,
            ilkRegistry: ILK_REGISTRY,
            pip: address(0), // DsValue (nothing to whitelist)
            clipper: MCD_CLIP_GUSD_A,
            flipper: DssExecLib.getChangelogAddress("MCD_FLIP_GUSD_A"),
            calc: MCD_CLIP_CALC_GUSD_A,
            hole: 0,
            chop: 113 * WAD / 100,
            buf: 105 * RAY / 100,
            tail: 220 minutes,
            cusp: 90 * RAY / 100,
            chip: 1 * WAD / 1000,
            tip: 300 * RAD,
            cut: 999 * RAY / 1000,
            step: 120 seconds,
            tolerance: 95 * RAY / 100,
            clipKey: "MCD_CLIP_GUSD_A",
            calcKey: "MCD_CLIP_CALC_GUSD_A",
            flipKey: "MCD_FLIP_GUSD_A"
        }));

        // ----------------------------------- PSM-USDC-A -----------------------------------
        flipperToClipper(Collateral({
            ilk: "PSM-USDC-A",
            vat: MCD_VAT,
            vow: MCD_VOW,
            spotter: MCD_SPOT,
            cat: MCD_CAT,
            dog: MCD_DOG,
            end: MCD_END,
            esm: MCD_ESM,
            flipperMom: FLIPPER_MOM,
            clipperMom: CLIPPER_MOM,
            ilkRegistry: ILK_REGISTRY,
            pip: address(0), // DsValue (nothing to whitelist)
            clipper: MCD_CLIP_PSM_USDC_A,
            flipper: DssExecLib.getChangelogAddress("MCD_FLIP_PSM_USDC_A"),
            calc: MCD_CLIP_CALC_PSM_USDC_A,
            hole: 0,
            chop: 113 * WAD / 100,
            buf: 105 * RAY / 100,
            tail: 220 minutes,
            cusp: 90 * RAY / 100,
            chip: 1 * WAD / 1000,
            tip: 300 * RAD,
            cut: 999 * RAY / 1000,
            step: 120 seconds,
            tolerance: 95 * RAY / 100,
            clipKey: "MCD_CLIP_PSM_USDC_A",
            calcKey: "MCD_CLIP_CALC_PSM_USDC_A",
            flipKey: "MCD_FLIP_PSM_USDC_A"
        }));

        // ----------------------------------- UNIV2DAIUSDC-A -----------------------------------
        flipperToClipper(Collateral({
            ilk: "UNIV2DAIUSDC-A",
            vat: MCD_VAT,
            vow: MCD_VOW,
            spotter: MCD_SPOT,
            cat: MCD_CAT,
            dog: MCD_DOG,
            end: MCD_END,
            esm: MCD_ESM,
            flipperMom: FLIPPER_MOM,
            clipperMom: CLIPPER_MOM,
            ilkRegistry: ILK_REGISTRY,
            pip: DssExecLib.getChangelogAddress("PIP_UNIV2DAIUSDC"),
            clipper: MCD_CLIP_UNIV2DAIUSDC_A,
            flipper: DssExecLib.getChangelogAddress("MCD_FLIP_UNIV2DAIUSDC_A"),
            calc: MCD_CLIP_CALC_UNIV2DAIUSDC_A,
            hole: 0,
            chop: 113 * WAD / 100,
            buf: 105 * RAY / 100,
            tail: 220 minutes,
            cusp: 90 * RAY / 100,
            chip: 1 * WAD / 1000,
            tip: 300 * RAD,
            cut: 999 * RAY / 1000,
            step: 120 seconds,
            tolerance: 95 * RAY / 100,
            clipKey: "MCD_CLIP_UNIV2DAIUSDC_A",
            calcKey: "MCD_CLIP_CALC_UNIV2DAIUSDC_A",
            flipKey: "MCD_FLIP_UNIV2DAIUSDC_A"
        }));

        // ------------------------- Update Chainlog -------------------------

        DssExecLib.setChangelogVersion("1.9.0");
    }
}

contract DssSpell is DssExec {
    DssSpellAction internal action_ = new DssSpellAction();
    constructor() DssExec(action_.description(), block.timestamp + 30 days, address(action_)) public {}
}
