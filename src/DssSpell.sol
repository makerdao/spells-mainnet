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
import { GemAbstract } from "dss-interfaces/ERC/GemAbstract.sol";

interface RwaLiquidationLike {
    function ilks(bytes32) external view returns (string memory, address, uint48, uint48);
    function init(bytes32, uint256, string calldata, uint48) external;
}

interface InputConduitJarLike {
    function push(uint) external;
}

interface JarLike {
    function void() external;
}

contract DssSpellAction is DssAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: cast keccak -- "$(wget 'https://raw.githubusercontent.com/makerdao/community/4fa152956a992fe19ce1e8cce89920fcf896b304/governance/votes/Executive%20vote%20-%20February%2007%2C%202024.md' -q -O - 2>/dev/null)"
    string public constant override description =
        "2024-02-07 MakerDAO Executive Spell | Hash: 0xeafae0d525faaab32a2e67aeef2aff3cd59b80b2c466553986fe72917f4b14b7";

    // Set office hours according to the summary
    function officeHours() public pure override returns (bool) {
        return false;
    }

    // ---------- Rates ----------
    // Many of the settings that change weekly rely on the rate accumulator
    // described at https://docs.makerdao.com/smart-contract-modules/rates-module
    // To check this yourself, use the following rate calculation (example 8%):
    //
    // $ bc -l <<< 'scale=27; e( l(1.08)/(60 * 60 * 24 * 365) )'
    //
    // A table of rates can be found at
    //    https://ipfs.io/ipfs/QmVp4mhhbwWGTfbh2BzwQB9eiBrQBKiqcPRZCaAxNUaar6
    //
    // uint256 internal constant X_PCT_RATE = ;

    // ----------- MKR transfer Addresses -----------

    // Delegates
    address internal constant DEFENSOR          = 0x9542b441d65B6BF4dDdd3d4D2a66D8dCB9EE07a9;
    address internal constant BLUE              = 0xb6C09680D822F162449cdFB8248a7D3FC26Ec9Bf;
    address internal constant BONAPUBLICA       = 0x167c1a762B08D7e78dbF8f24e5C3f1Ab415021D3;
    address internal constant CLOAKY            = 0x869b6d5d8FA7f4FFdaCA4D23FFE0735c5eD1F818;
    address internal constant TRUENAME          = 0x612F7924c367575a0Edf21333D96b15F1B345A5d;
    address internal constant PBG               = 0x8D4df847dB7FfE0B46AF084fE031F7691C6478c2;
    address internal constant UPMAKER           = 0xbB819DF169670DC71A16F58F55956FE642cc6BcD;
    address internal constant VIGILANT          = 0x2474937cB55500601BCCE9f4cb0A0A72Dc226F61;
    address internal constant WBC               = 0xeBcE83e491947aDB1396Ee7E55d3c81414fB0D47;
    address internal constant JAG               = 0x58D1ec57E4294E4fe650D1CB12b96AE34349556f;

    // AAVE
    address constant internal AAVE_V3_TREASURY = 0x464C71f6c2F760DdA6093dCB91C24c39e5d6e18c;

    // ---------- Math ----------
    uint256 internal constant MILLION = 10 ** 6;
    uint256 internal constant HUNDRED = 10 ** 2;

    InputConduitJarLike internal immutable MCD_PSM_GUSD_A_INPUT_CONDUIT_JAR = InputConduitJarLike(DssExecLib.getChangelogAddress("MCD_PSM_GUSD_A_INPUT_CONDUIT_JAR"));
    JarLike internal immutable MCD_PSM_GUSD_A_JAR                           = JarLike(DssExecLib.getChangelogAddress("MCD_PSM_GUSD_A_JAR"));
    GemAbstract internal immutable MKR                                      = GemAbstract(DssExecLib.mkr());
    address internal immutable MIP21_LIQUIDATION_ORACLE                     = DssExecLib.getChangelogAddress("MIP21_LIQUIDATION_ORACLE");

    // Note: Function from https://github.com/makerdao/spells-goerli/blob/cd91b3e0ce234038d2e0ae047261177afac6f03c/archive/2024-01-12-DssSpell/DssSpell.sol#L54
    function _updateDoc(bytes32 ilk, string memory doc) internal {
        ( , address pip, uint48 tau, ) = RwaLiquidationLike(MIP21_LIQUIDATION_ORACLE).ilks(ilk);
        require(pip != address(0), "DssSpell/unexisting-rwa-ilk");

        // Init the RwaLiquidationOracle to reset the doc
        RwaLiquidationLike(MIP21_LIQUIDATION_ORACLE).init(
            ilk, // ilk to update
            0,   // price ignored if init() has already been called
            doc, // new legal document
            tau  // old tau value
        );
    }

    function actions() public override {
        // ---------- Auction Parameter Updates ----------
        // Forum: https://forum.makerdao.com/t/stability-scope-auction-parameters-changes-1-liquidation-throughput-limit/23508
        // Vote: https://vote.makerdao.com/polling/QmWLyYW7#poll-detail

        // Increase the WSTETH-A Local Liquidation Limit (ilk.hole) by 15 million DAI from 15 million DAI to 30 million DAI.
        DssExecLib.setIlkMaxLiquidationAmount("WSTETH-A", 30 * MILLION);

        // Increase the WSTETH-B Local Liquidation Limit (ilk.hole) by 10 million DAI from 10 million DAI to 20 million DAI.
        DssExecLib.setIlkMaxLiquidationAmount("WSTETH-B", 20 * MILLION);

        // Decrease the WBTC-A Local Liquidation Limit (ilk.hole) by 20 million DAI from 30 million DAI to 10 million DAI.
        DssExecLib.setIlkMaxLiquidationAmount("WBTC-A",   10 * MILLION);

        // Decrease the WBTC-B Local Liquidation Limit (ilk.hole) by 5 million DAI from 10 million DAI to 5 million DAI.
        DssExecLib.setIlkMaxLiquidationAmount("WBTC-B",   5  * MILLION);

        // Decrease the WBTC-C Local Liquidation Limit (ilk.hole) by 10 million DAI from 20 million DAI to 10 million DAI.
        DssExecLib.setIlkMaxLiquidationAmount("WBTC-C",   10 * MILLION);

        // Increase the Global Liquidation Limit (Hole) by 50 million DAI from 100 million DAI to 150 million DAI.
        DssExecLib.setMaxTotalDAILiquidationAmount(150 * MILLION);

        // ---------- Push GUSD out of input conduit ----------
        // Forum: https://forum.makerdao.com/t/executive-spell-gusd-input-conduit-management/23597
        // Raise PSM-GUSD-A DC to 597,660 DAI
        DssExecLib.setIlkDebtCeiling("PSM-GUSD-A", 597_660);

        // Call push() on MCD_PSM_GUSD_A_INPUT_CONDUIT_JAR (use push(uint256 amt)) to push 597,659 GUSD
        MCD_PSM_GUSD_A_INPUT_CONDUIT_JAR.push(597_659 * HUNDRED); // Note: adjusting value to GUSD decimals (2)

        // Call void() on MCD_PSM_GUSD_A_JAR
        MCD_PSM_GUSD_A_JAR.void();

        // Set PSM-GUSD-A DC to 0 DAI
        DssExecLib.setIlkDebtCeiling("PSM-GUSD-A", 0);

        // ---------- Aave SparkLend Revenue Share ----------
        // Forum: https://forum.makerdao.com/t/spark-aave-revenue-share-calculation-payment-2-q4-2023/23593
        // Transfer 100,603 DAI to 0x464C71f6c2F760DdA6093dCB91C24c39e5d6e18c
        DssExecLib.sendPaymentFromSurplusBuffer(AAVE_V3_TREASURY, 100_603);

        // ---------- RWA009 doc Update ----------
        // Forum: https://forum.makerdao.com/t/rwa009-hvbank-mip21-token-ces-domain-team-assessment/15861/16

        // Update HVBank (RWA009-A) doc to QmPzuLuJ5Xq6k6Hbop1W5s4V9ksvafYoqcW9sU5QRwz5h1
        _updateDoc("RWA009-A", "QmPzuLuJ5Xq6k6Hbop1W5s4V9ksvafYoqcW9sU5QRwz5h1");

        // ---------- Delegate Compensation ----------
        // Forum: https://forum.makerdao.com/t/january-2024-aligned-delegate-compensation/23604

        // 0xDefensor - 41.67 MKR - 0x9542b441d65B6BF4dDdd3d4D2a66D8dCB9EE07a9
        MKR.transfer(DEFENSOR, 41.67 ether); // NOTE: ether is a keyword helper, only MKR is transferred here
        // BLUE - 41.67 MKR - 0xb6C09680D822F162449cdFB8248a7D3FC26Ec9Bf
        MKR.transfer(BLUE, 41.67 ether); // NOTE: ether is a keyword helper, only MKR is transferred here
        // BONAPUBLICA - 41.67 MKR - 0x167c1a762B08D7e78dbF8f24e5C3f1Ab415021D3
        MKR.transfer(BONAPUBLICA, 41.67 ether); // NOTE: ether is a keyword helper, only MKR is transferred here
        // Cloaky - 41.67 MKR - 0x869b6d5d8FA7f4FFdaCA4D23FFE0735c5eD1F818
        MKR.transfer(CLOAKY, 41.67 ether); // NOTE: ether is a keyword helper, only MKR is transferred here
        // TRUE NAME - 41.67 MKR - 0x612F7924c367575a0Edf21333D96b15F1B345A5d
        MKR.transfer(TRUENAME, 41.67 ether); // NOTE: ether is a keyword helper, only MKR is transferred here
        // PBG - 13.89 MKR - 0x8D4df847dB7FfE0B46AF084fE031F7691C6478c2
        MKR.transfer(PBG, 13.89 ether); // NOTE: ether is a keyword helper, only MKR is transferred here
        // UPMaker - 13.89 MKR - 0xbB819DF169670DC71A16F58F55956FE642cc6BcD
        MKR.transfer(UPMAKER, 13.89 ether); // NOTE: ether is a keyword helper, only MKR is transferred here
        // vigilant - 13.89 MKR - 0x2474937cB55500601BCCE9f4cb0A0A72Dc226F61
        MKR.transfer(VIGILANT, 13.89 ether); // NOTE: ether is a keyword helper, only MKR is transferred here
        // WBC - 13.89 MKR - 0xeBcE83e491947aDB1396Ee7E55d3c81414fB0D47
        MKR.transfer(WBC, 13.89 ether); // NOTE: ether is a keyword helper, only MKR is transferred here
        // JAG - 13.71 MKR - 0x58D1ec57E4294E4fe650D1CB12b96AE34349556f
        MKR.transfer(JAG, 13.71 ether); // NOTE: ether is a keyword helper, only MKR is transferred here
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) {}
}
