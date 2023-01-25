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

pragma solidity 0.8.16;

import "dss-exec-lib/DssExec.sol";
import "dss-exec-lib/DssAction.sol";

interface ChainLogLike {
    function removeAddress(bytes32) external;
}

interface GemLike {
    function transfer(address, uint256) external returns (bool);
}

interface CageLike {
    function cage() external;
}

interface RegistryLike {
    function remove(bytes32) external;
}

interface VatLike {
    function Line() external view returns (uint256);
    function ilks(bytes32) external returns (uint256 Art, uint256 rate, uint256 spot, uint256 line, uint256 dust);
}

contract DssSpellAction is DssAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: cast keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/2d14219f8850d2261c1e65b7faa7cfecd138951f/governance/votes/Executive%20vote%20-%20January%2027%2C%202023.md -q -O - 2>/dev/null)"
    string public constant override description =
        "2023-01-27 MakerDAO Executive Spell | Hash: 0x0544972c4fa0e63df554701e9a8ed2d16fc8ca17b7ea719a35933913f9794967";

        // Turn office hours off
    function officeHours() public pure override returns (bool) {
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
    // uint256 internal constant X_PCT_RATE      = ;
    uint256 internal constant ZERO_PT_TWO_FIVE_PCT_RATE = 1000000000079175551708715274;

    uint256 internal constant MILLION = 10 ** 6;
    // uint256 internal constant RAY  = 10 ** 27;
    uint256 internal constant WAD     = 10 ** 18;

    ChainLogLike internal immutable CHAINLOG    = ChainLogLike(DssExecLib.getChangelogAddress("CHANGELOG"));
    VatLike      internal immutable VAT         = VatLike(DssExecLib.vat());
    address      internal immutable DOG         = DssExecLib.dog();

    address internal immutable FLASH_KILLER     = DssExecLib.getChangelogAddress("FLASH_KILLER");
    address internal immutable MCD_FLASH        = DssExecLib.getChangelogAddress("MCD_FLASH");
    address internal immutable MCD_FLASH_LEGACY = DssExecLib.getChangelogAddress("MCD_FLASH_LEGACY");

    address internal immutable MCD_PSM_PAX_A    = DssExecLib.getChangelogAddress("MCD_PSM_PAX_A");
    address internal immutable MCD_PSM_GUSD_A   = DssExecLib.getChangelogAddress("MCD_PSM_GUSD_A");

    address internal immutable MCD_JOIN_DIRECT_AAVEV2_DAI = DssExecLib.getChangelogAddress("MCD_JOIN_DIRECT_AAVEV2_DAI");
    address internal immutable MCD_CLIP_DIRECT_AAVEV2_DAI = DssExecLib.getChangelogAddress("MCD_CLIP_DIRECT_AAVEV2_DAI");
    address internal immutable DIRECT_MOM_LEGACY = DssExecLib.getChangelogAddress("DIRECT_MOM_LEGACY");

    address internal immutable CES_WALLET = 0x25307aB59Cd5d8b4E2C01218262Ddf6a89Ff86da;

    function actions() public override {

        // MOMC Parameter Changes
        // https://vote.makerdao.com/polling/QmYUi9Tk

        // Increase WSTETH-B Stability Fee to 0.25%
        DssExecLib.setIlkStabilityFee("WSTETH-B", ZERO_PT_TWO_FIVE_PCT_RATE, true);

        // Increase Compound v2 D3M Maximum Debt Ceiling to 20 million
        // Set Compound v2 D3M Target Available Debt to 5 million DAI (this might already be the case)
        DssExecLib.setIlkAutoLineParameters("DIRECT-COMPV2-DAI", 20 * MILLION, 5 * MILLION, 12 hours);

        // Increase the USDP PSM tin to 0.2%
        DssExecLib.setValue(MCD_PSM_PAX_A, "tin", 20 * WAD / 10000);   // 20 BPS


        // MKR Transfer for CES
        // https://vote.makerdao.com/polling/QmbNVQ1E

        // CES-001 - 96.15 MKR - 0x25307aB59Cd5d8b4E2C01218262Ddf6a89Ff86da
        GemLike(DssExecLib.mkr()).transfer(CES_WALLET, 96.15 ether); // ether as solidity alias


        // Cage DIRECT-AAVEV2-DAI
        // https://forum.makerdao.com/t/housekeeping-tasks-for-next-executive/19472

        CageLike(MCD_JOIN_DIRECT_AAVEV2_DAI).cage();
        bytes32 _ilk = "DIRECT-AAVEV2-DAI";
        DssExecLib.removeIlkFromAutoLine(_ilk);
        (,,, uint256 _line,) = VAT.ilks(_ilk);
        DssExecLib.setValue(address(VAT), _ilk, "line", 0);
        DssExecLib.setValue(address(VAT), "Line", VAT.Line() - _line);
        DssExecLib.setValue(MCD_CLIP_DIRECT_AAVEV2_DAI, "stopped", 3);
        DssExecLib.deauthorize(address(VAT), address(MCD_JOIN_DIRECT_AAVEV2_DAI));
        DssExecLib.deauthorize(address(VAT), address(MCD_CLIP_DIRECT_AAVEV2_DAI));
        DssExecLib.deauthorize(DOG, MCD_CLIP_DIRECT_AAVEV2_DAI);
        DssExecLib.deauthorize(MCD_CLIP_DIRECT_AAVEV2_DAI, DOG);
        DssExecLib.deauthorize(DssExecLib.end(), MCD_CLIP_DIRECT_AAVEV2_DAI);
        DssExecLib.deauthorize(DssExecLib.esm(), MCD_CLIP_DIRECT_AAVEV2_DAI);
        DssExecLib.deauthorize(MCD_JOIN_DIRECT_AAVEV2_DAI, address(this));
        DssExecLib.deauthorize(MCD_CLIP_DIRECT_AAVEV2_DAI, address(this));
        CHAINLOG.removeAddress("DIRECT_MOM_LEGACY");
        CHAINLOG.removeAddress("MCD_JOIN_DIRECT_AAVEV2_DAI");
        CHAINLOG.removeAddress("MCD_CLIP_DIRECT_AAVEV2_DAI");
        CHAINLOG.removeAddress("MCD_CLIP_CALC_DIRECT_AAVEV2_DAI");
        RegistryLike(DssExecLib.reg()).remove("DIRECT-AAVEV2-DAI");

        // Flash Mint Module Upgrade Completion
        // https://forum.makerdao.com/t/flashmint-module-housekeeping-task-for-next-executive/19472

        // Sunset MCD_FLASH_LEGACY and reduce DC to 0
        DssExecLib.setValue(MCD_FLASH_LEGACY, "max", 0);
        DssExecLib.deauthorize(address(VAT), MCD_FLASH_LEGACY);
        DssExecLib.deauthorize(MCD_FLASH_LEGACY, FLASH_KILLER);
        DssExecLib.deauthorize(MCD_FLASH_LEGACY, address(this));
        CHAINLOG.removeAddress("MCD_FLASH_LEGACY");

        // Increase DC of MCD_FLASH to 500 million DAI
        DssExecLib.setValue(MCD_FLASH, "max", 500 * MILLION * WAD);

        // Deauth FLASH_KILLER and remove from Chainlog
        // NOTE: Flash Killer's only ward is MCD_FLASH_LEGACY, Pause Proxy cannot deauth
        CHAINLOG.removeAddress("FLASH_KILLER");


        // PSM_GUSD_A tout decrease
        // Poll: https://vote.makerdao.com/polling/QmRRceEo
        // Forum: https://forum.makerdao.com/t/request-to-poll-psm-gusd-a-parameters/19416
        // Reduce PSM-GUSD-A tout from 0.1% to 0%
        DssExecLib.setValue(MCD_PSM_GUSD_A, "tout", 0);


        DssExecLib.setChangelogVersion("1.14.8");
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) {}
}
