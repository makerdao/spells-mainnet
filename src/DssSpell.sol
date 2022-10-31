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

import { DssSpellCollateralAction } from "./DssSpellCollateral.sol";

interface DssVestLike {
    function yank(uint256) external;
}

interface GemLike {
    function transfer(address, uint256) external returns (bool);
}

contract DssSpellAction is DssAction, DssSpellCollateralAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: cast keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/TODO/governance/votes/Executive%20vote%20-%20November%2002%2C%202022.md -q -O - 2>/dev/null)"

    string public constant override description =
        "2022-11-02 MakerDAO Executive Spell | Hash: 0x";

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
    // uint256 internal constant ONE_FIVE_PCT_RATE = 1000000000472114805215157978;

    // --- Math ---
    // uint256 internal constant WAD = 10 ** 18;

    address constant EVENTS_001 = 0x3D274fbAc29C92D2F624483495C0113B44dBE7d2;
    address constant SH_001     = 0xc657aC882Fb2D6CcF521801da39e910F8519508d;
    address constant RWF_001    = 0x96d7b01Cc25B141520C717fa369844d34FF116ec;
    address constant BLOCKTOWER = 0x117786ad59BC2f13cf25B2359eAa521acB0aDCD9;
    address constant OASISAPP   = 0x55Dc2Be8020bCa72E58e665dC931E03B749ea5E0;

    DssVestLike immutable MCD_VEST_DAI          = DssVestLike(DssExecLib.getChangelogAddress("MCD_VEST_DAI"));
    DssVestLike immutable MCD_VEST_DAI_LEGACY   = DssVestLike(DssExecLib.getChangelogAddress("MCD_VEST_DAI_LEGACY"));
    DssVestLike immutable MCD_VEST_MKR_TREASURY = DssVestLike(DssExecLib.getChangelogAddress("MCD_VEST_MKR_TREASURY"));
    GemLike     immutable MKR                   = GemLike(DssExecLib.mkr());
    address     immutable PIP_RETH              = DssExecLib.getChangelogAddress("PIP_RETH");

    function actions() public override {


        // Includes changes from the DssSpellCollateralAction
        // collateralAction();


        // CU Offboarding - Yank DAI Streams
        // https://forum.makerdao.com/t/executive-vote-cu-offboarding-next-steps/18522

        // Yank DAI Stream #4 (EVENTS-001)
        // https://mips.makerdao.com/mips/details/MIP39c3SP4#sentence-summary
        MCD_VEST_DAI.yank(4);

        // Yank DAI Stream #5 (SH-001)
        // https://mips.makerdao.com/mips/details/MIP39c3SP3#sentence-summary
        MCD_VEST_DAI.yank(5);

        // Yank DAI Stream #35 (RWF-001)
        // https://mips.makerdao.com/mips/details/MIP39c3SP5#sentence-summary
        MCD_VEST_DAI_LEGACY.yank(35);


        // CU Offboarding - Yank MKR Stream
        // Yank MKR Stream #23 (SH-001)
        // https://mips.makerdao.com/mips/details/MIP39c3SP3#sentence-summary
        MCD_VEST_MKR_TREASURY.yank(23);


        // CU Offboarding - DAI Golden Parachutes
        // EVENTS-001 - 167,666 DAI - 0x3D274fbAc29C92D2F624483495C0113B44dBE7d2
        // https://mips.makerdao.com/mips/details/MIP39c3SP4#sentence-summary

        DssExecLib.sendPaymentFromSurplusBuffer(EVENTS_001, 167_666);

        // SH-001 - 43,332.0 DAI - 0xc657aC882Fb2D6CcF521801da39e910F8519508d
        // https://mips.makerdao.com/mips/details/MIP39c3SP3#sentence-summary
        DssExecLib.sendPaymentFromSurplusBuffer(SH_001, 43_332);


        // CU Offboarding - MKR Golden Parachutes
        // https://forum.makerdao.com/t/executive-vote-cu-offboarding-next-steps/18522

        // SH-001 - 26.04 MKR - 0xc657aC882Fb2D6CcF521801da39e910F8519508d
        // https://mips.makerdao.com/mips/details/MIP39c3SP4#sentence-summary
        MKR.transfer(SH_001, 26.04 ether);  // note: ether is a keyword helper, only MKR is transferred here

        // RWF-001 - 143.46 MKR - 0x96d7b01Cc25B141520C717fa369844d34FF116ec
        // https://mips.makerdao.com/mips/details/MIP39c3SP5#sentence-summary
        MKR.transfer(RWF_001, 143.46 ether);  // note: ether is a keyword helper, only MKR is transferred here

        // SPF Funding
        // BlockTower Legal and Risk Work SPF - 258,000 DAI - 0x117786ad59BC2f13cf25B2359eAa521acB0aDCD9
        // https://mips.makerdao.com/mips/details/MIP39c3SP5#sentence-summary
        DssExecLib.sendPaymentFromSurplusBuffer(BLOCKTOWER, 258_000);


        // Oracle Whitelisting - carried over from last week, see confirms from Nik in week 43 sheet
        // https://vote.makerdao.com/polling/QmZzFPFs#vote-breakdown
        // Whitelist Oasis.app on RETH/USD oracle
        // https://forum.makerdao.com/t/mip10c9-sp31-proposal-to-whitelist-oasis-app-on-rethusd-oracle/18195
        // Oasis.app - 0x55Dc2Be8020bCa72E58e665dC931E03B749ea5E0 - OSM
        DssExecLib.addReaderToWhitelist(PIP_RETH, OASISAPP);

    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) public {}
}
