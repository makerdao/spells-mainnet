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
import "dss-interfaces/dss/ClipAbstract.sol";
import "dss-interfaces/dss/ClipperMomAbstract.sol";
import "dss-interfaces/dss/EndAbstract.sol";
import "dss-interfaces/dss/ESMAbstract.sol";

contract DssSpellAction is DssAction {

    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community//governance/votes/Executive%20vote%20-%20April%2016%2C%202021.md -q -O - 2>/dev/null)"
    string public constant description =
        "2021-04-16 MakerDAO Executive Spell | Hash: ";

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

    // Addresses
    address constant MCD_DOG              = 0x135954d155898D42C90D2a57824C690e0c7BEf1B;
    address constant MCD_END              = 0xFB4713C20CCD81c53BC55e12923d37a4f0DB3E93;
    address constant MCD_ESM              = 0x0f8B44Df587Abe2533cE7D75cB004C127Fe1a267;
    address constant ILK_REGISTRY         = address(0);
    address constant CLIPPER_MOM          = 0x79FBDF16b366DFb14F66cE4Ac2815Ca7296405A0;
    address constant MCD_CLIP_LINK_A      = 0x832Dd5f17B30078a5E46Fdb8130A68cBc4a74dC0;
    address constant MCD_CLIP_CALC_LINK_A = 0x7B1696677107E48B152e9Bf400293e98B7D86Eb1;

    uint256 constant THOUSAND   = 10**3;
    uint256 constant MILLION    = 10**6;
    uint256 constant WAD        = 10**18;
    uint256 constant RAY        = 10**27;
    uint256 constant RAD        = 10**45;

    function actions() public override {
        address MCD_VAT          = DssExecLib.vat();
        address MCD_CAT          = DssExecLib.cat();
        address MCD_VOW          = DssExecLib.vow();
        address MCD_POT          = DssExecLib.pot();
        address MCD_SPOT         = DssExecLib.spotter();
        address MCD_END_OLD      = DssExecLib.end();
        address MCD_FLIP_LINK_A  = DssExecLib.flip("LINK-A");
        address ILK_REGISTRY_OLD = DssExecLib.reg();
        address PIP_LINK         = DssExecLib.getChangelogAddress("PIP_LINK");

        // ------------------  END  ------------------

        // Set contracts in END
        DssExecLib.setContract(MCD_END,  "vat", MCD_VAT);
        DssExecLib.setContract(MCD_END,  "cat", MCD_CAT);
        DssExecLib.setContract(MCD_END,  "dog", MCD_DOG);
        DssExecLib.setContract(MCD_END,  "vow", MCD_VOW);
        DssExecLib.setContract(MCD_END,  "pot", MCD_POT);
        DssExecLib.setContract(MCD_END, "spot", MCD_SPOT);

        // Authorize the new END in contracts
        DssExecLib.authorize(MCD_VAT, MCD_END);
        DssExecLib.authorize(MCD_CAT, MCD_END);
        DssExecLib.authorize(MCD_DOG, MCD_END);
        DssExecLib.authorize(MCD_VOW, MCD_END);
        DssExecLib.authorize(MCD_POT, MCD_END);
        DssExecLib.authorize(MCD_SPOT, MCD_END);

        // Set wait time in END
        Fileable(MCD_END).file("wait", EndAbstract(MCD_END_OLD).wait());

        // Deauthorize the old END in contracts
        DssExecLib.deauthorize(MCD_VAT, MCD_END_OLD);
        DssExecLib.deauthorize(MCD_CAT, MCD_END_OLD);
        DssExecLib.deauthorize(MCD_VOW, MCD_END_OLD);
        DssExecLib.deauthorize(MCD_POT, MCD_END_OLD);
        DssExecLib.deauthorize(MCD_SPOT, MCD_END_OLD);

        // Deauthorize the old END from all the FLIPS
        // Authorize the new END in all the FLIPS
        bytes32[] memory ilks = IlkRegistryAbstract(ILK_REGISTRY_OLD).list();
        address[] memory flips = new address[](ilks.length);
        for (uint256 i = 0; i < ilks.length; i++) {
            bytes32 ilk = ilks[i];

            address flip = DssExecLib.flip(ilk);
            flips[i] = flip;
            DssExecLib.deauthorize(flip, MCD_END_OLD);
            DssExecLib.authorize(flip, MCD_END);

            try DssExecLib.removeReaderFromOSMWhitelist(IlkRegistryAbstract(ILK_REGISTRY_OLD).pip(ilk), MCD_END_OLD) {} catch {}
            try DssExecLib.addReaderToOSMWhitelist(IlkRegistryAbstract(ILK_REGISTRY_OLD).pip(ilk), MCD_END) {} catch {}
        }

        // ------------------  ESM  ------------------

        require(ESMAbstract(MCD_ESM).end() == MCD_END, "DssSpell/error-esm-end");

        // Authorize new ESM to execute in new END
        DssExecLib.authorize(MCD_END, MCD_ESM);

        // Authorize new ESM to execute in VAT
        DssExecLib.authorize(MCD_VAT, MCD_ESM);

        // Make every flipper relies the MCD_ESM
        for (uint256 i = 0; i < flips.length; i++) {
            DssExecLib.authorize(flips[i], MCD_ESM);
        }

        // ------------------  DOG  ------------------

        // Set VOW in the DOG
        DssExecLib.setContract(MCD_DOG, "vow", MCD_VOW);

        // Authorize DOG can access to VAT
        DssExecLib.authorize(MCD_VAT, MCD_DOG);

        // Authorize DOG can access to VOW
        DssExecLib.authorize(MCD_VOW, MCD_DOG);

        Fileable(MCD_DOG).file("Hole", 100 * MILLION * RAD);


        // --------------  CLIPPER_MOM  --------------

        require(ClipperMomAbstract(CLIPPER_MOM).spotter() == MCD_SPOT, "DssSpell/error-clipper-mom-spotter");

        ClipperMomAbstract(CLIPPER_MOM).setAuthority(DssExecLib.getChangelogAddress("MCD_ADM"));

        // ----------------  LINK-A  -----------------

        require(ClipAbstract(MCD_CLIP_LINK_A).vat() == MCD_VAT, "DssSpell/error-clip-vat");
        require(ClipAbstract(MCD_CLIP_LINK_A).dog() == MCD_DOG, "DssSpell/error-clip-dog");
        require(ClipAbstract(MCD_CLIP_LINK_A).spotter() == MCD_SPOT, "DssSpell/error-clip-spot");
        require(ClipAbstract(MCD_CLIP_LINK_A).ilk() == "LINK-A", "DssSpell/error-clip-ilk");

        // Set CLIP for LINK-A in the DOG
        DssExecLib.setContract(MCD_DOG, "LINK-A", "clip", MCD_CLIP_LINK_A);

        // Set VOW in the LINK-A CLIP
        DssExecLib.setContract(MCD_CLIP_LINK_A, "vow", MCD_VOW);

        // Set CALC in the LINK-A CLIP
        DssExecLib.setContract(MCD_CLIP_LINK_A, "calc", MCD_CLIP_CALC_LINK_A);

        // Authorize CLIP can access to VAT
        DssExecLib.authorize(MCD_VAT, MCD_CLIP_LINK_A);

        // Authorize CLIP can access to DOG
        DssExecLib.authorize(MCD_DOG, MCD_CLIP_LINK_A);

        // Authorize DOG can kick auctions on CLIP
        DssExecLib.authorize(MCD_CLIP_LINK_A, MCD_DOG);

        // Authorize the new END to access the LINK CLIP
        DssExecLib.authorize(MCD_CLIP_LINK_A, MCD_END);

        // Authorize CLIPPERMOM can set the stopped flag in CLIP
        DssExecLib.authorize(MCD_CLIP_LINK_A, CLIPPER_MOM);

        // Authorize new ESM to execute in LINK-A Clipper
        DssExecLib.authorize(MCD_CLIP_LINK_A, MCD_ESM);

        // Whitelist CLIP in the LINK osm
        DssExecLib.addReaderToOSMWhitelist(PIP_LINK, MCD_CLIP_LINK_A);

        // Whitelist CLIPPER_MOM in the LINK osm
        DssExecLib.addReaderToOSMWhitelist(PIP_LINK, CLIPPER_MOM);

        // No more auctions kicked via the CAT:
        DssExecLib.deauthorize(MCD_FLIP_LINK_A, MCD_CAT);

        // No more circuit breaker for the FLIP in LINK-A:
        DssExecLib.deauthorize(MCD_FLIP_LINK_A, DssExecLib.flipperMom());

        Fileable(MCD_DOG).file("LINK-A", "hole", 6 * MILLION * RAD);
        Fileable(MCD_DOG).file("LINK-A", "chop", 113 * WAD / 100);
        Fileable(MCD_CLIP_LINK_A).file("buf", 130 * RAY / 100);
        Fileable(MCD_CLIP_LINK_A).file("tail", 140 minutes);
        Fileable(MCD_CLIP_LINK_A).file("cusp", 40 * RAY / 100);
        Fileable(MCD_CLIP_LINK_A).file("chip", 1 * WAD / 1000);
        Fileable(MCD_CLIP_LINK_A).file("tip", 0);
        Fileable(MCD_CLIP_CALC_LINK_A).file("cut", 99 * RAY / 100); // 1% cut
        Fileable(MCD_CLIP_CALC_LINK_A).file("step", 90 seconds);

        //  Tolerance currently set to 50%.
        //   n.b. 600000000000000000000000000 == 40% acceptable drop
        ClipperMomAbstract(CLIPPER_MOM).setPriceTolerance(MCD_CLIP_LINK_A, 50 * RAY / 100);

        ClipAbstract(MCD_CLIP_LINK_A).upchost();

        // Replace flip to clip in the ilk registry
        DssExecLib.setContract(ILK_REGISTRY, "LINK-A", "xlip", MCD_CLIP_LINK_A);
        Fileable(ILK_REGISTRY).file("LINK-A", "class", 1);


        // ------------------  CHAINLOG  -----------------

        address log = DssExecLib.getChangelogAddress("CHANGELOG");

        DssExecLib.setChangelogAddress("MCD_DOG", MCD_DOG);
        DssExecLib.setChangelogAddress("MCD_END", MCD_END);
        DssExecLib.setChangelogAddress("MCD_ESM", MCD_ESM);
        DssExecLib.setChangelogAddress("CLIPPER_MOM", CLIPPER_MOM);
        DssExecLib.setChangelogAddress("MCD_CLIP_LINK_A", MCD_CLIP_LINK_A);
        DssExecLib.setChangelogAddress("MCD_CLIP_CALC_LINK_A", MCD_CLIP_CALC_LINK_A);
        DssExecLib.setChangelogAddress("ILK_REGISTRY", ILK_REGISTRY);
        ChainlogLike(log).removeAddress("MCD_FLIP_LINK_A");

        DssExecLib.setChangelogVersion("1.3.0");
    }
}

contract DssSpell is DssExec {
    DssSpellAction internal action_ = new DssSpellAction();
    constructor() DssExec(action_.description(), block.timestamp + 30 days, address(action_)) public {}
}
