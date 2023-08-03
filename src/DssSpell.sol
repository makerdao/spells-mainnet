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
import { MCD, DssInstance } from "dss-test/MCD.sol";

interface RwaLiquidationOracleLike {
    function ilks(bytes32 ilk) external view returns (string memory doc, address pip, uint48 tau, uint48 toc);
    function init(bytes32 ilk, uint256 val, string memory doc, uint48 tau) external;
    function tell(bytes32 ilk) external;
}

interface ProxyLike {
    function exec(address target, bytes calldata args) external payable returns (bytes memory out);
}

interface GemLike {
    function transfer(address dst, uint256 wad) external returns (bool);
}

contract DssSpellAction is DssAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: cast keccak -- "$(wget 'https://raw.githubusercontent.com/makerdao/community/ac220424c65680b0e766061e9a2ad330248a67d6/governance/votes/Executive%20Vote%20-%20August%202%2C%202023.md' -q -O - 2>/dev/null)"
    string public constant override description =
        "2023-08-02 MakerDAO Executive Spell | Hash: 0x4ec34da59c536fe3648034aea9d4209f4a5431efed2921eb2c8ba393089e0280";

    // Set office hours according to the summary
    function officeHours() public pure override returns (bool) {
        return false;
    }

    // ----- JAT1 DAO Resolution -----
    // Forum: https://forum.makerdao.com/t/clydesdale-quarterly-return-of-surplus-fund/21291
    // Poll: N/A
    // Approve DAO Resolution hash QmaGTVioBsCPfNoz9rbW7LU6YuzfgqHDZd92Hny5ACfL3p

    // Comma-separated list of DAO resolutions IPFS hashes.
    string public constant dao_resolutions = "QmaGTVioBsCPfNoz9rbW7LU6YuzfgqHDZd92Hny5ACfL3p";

    address internal immutable MIP21_LIQUIDATION_ORACLE = DssExecLib.getChangelogAddress("MIP21_LIQUIDATION_ORACLE");
    GemLike internal immutable MKR                      = GemLike(DssExecLib.mkr());

    // AVCs
    address internal constant IAMMEEOH        = 0x47f7A5d8D27f259582097E1eE59a07a816982AE9;
    address internal constant ACREDAOS        = 0xBF9226345F601150F64Ea4fEaAE7E40530763cbd;
    address internal constant SPACEXPONENTIAL = 0xFF8eEB643C5bfDf6A925f2a5F9aDC9198AF07b78;
    address internal constant RES             = 0x8c5c8d76372954922400e4654AF7694e158AB784;
    address internal constant LDF             = 0xC322E8Ec33e9b0a34c7cD185C616087D9842ad50;
    address internal constant OPENSKY         = 0x8e67eE3BbEb1743dc63093Af493f67C3c23C6f04;
    address internal constant DAVIDPHELPS     = 0xd56e3E325133EFEd6B1687C88571b8a91e517ab0;
    address internal constant SEEDLATAMETH    = 0x0087a081a9B430fd8f688c6ac5dD24421BfB060D;
    address internal constant STABLELAB_2     = 0xbDE65cf2352ed1Dde959f290E973d0fC5cEDFD08;
    address internal constant FLIPSIDEGOV     = 0x300901243d6CB2E74c10f8aB4cc89a39cC222a29;

    // Scopes
    address internal constant LAUNCH_PROJECT_FUNDING = 0x3C5142F28567E6a0F172fd0BaaF1f2847f49D02F;

    // Spark
    address internal constant SUBPROXY_SPARK = 0x3300f198988e4C9C63F75dF86De36421f06af8c4;
    address internal constant SPARK_SPELL    = 0x443f3f4328553f5f85dFc0BA3D59969708201E14;

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
    uint256 internal constant EIGHT_PCT_RATE = 1000000002440418608258400030;

    // --- MATH ---
    uint256 internal constant MILLION = 10 ** 6;

    function _updateDoc(bytes32 ilk, string memory doc) internal {
        ( , address pip, uint48 tau, ) = RwaLiquidationOracleLike(MIP21_LIQUIDATION_ORACLE).ilks(ilk);
        require(pip != address(0), "DssSpell/unexisting-rwa-ilk");

        // Init the RwaLiquidationOracle to reset the doc
        RwaLiquidationOracleLike(MIP21_LIQUIDATION_ORACLE).init(
            ilk, // ilk to update
            0,   // price ignored if init() has already been called
            doc, // new legal document
            tau  // old tau value
        );
    }

    function actions() public override {
        // ----- Enhanced DSR Activation -----
        // Poll: https://vote.makerdao.com/polling/QmcTRPLx
        // Forum: https://forum.makerdao.com/t/request-for-gov12-1-2-edit-to-the-stability-scope-to-quickly-implement-enhanced-dsr/21405

        // Increase the DSR by 4.81% from 3.19% to 8%
        DssExecLib.setDSR(EIGHT_PCT_RATE, /* doDrip = */ true);

        // ----- Spark D3M DC Increase -----
        // Poll: https://vote.makerdao.com/polling/QmSLj3HS
        // Forum: https://forum.makerdao.com/t/phoenix-labs-proposed-changes-for-spark/21422

        // Increase the DIRECT-SPARK-DAI Maximum Debt Ceiling by 180 million DAI from 20 million DAI to 200 million DAI
        // Keep gap and ttl at current settings (20 million and 8 hours respectively)
        DssExecLib.setIlkAutoLineDebtCeiling("DIRECT-SPARK-DAI", 200 * MILLION);

        // ----- HTC-DROP (RWA004-A) Changes -----
        // Poll: https://vote.makerdao.com/polling/QmR8cYb1
        // Forum: https://forum.makerdao.com/t/request-to-poll-decrease-debt-ceiling-for-harbor-trade-credit-htc-drop-to-0/21373

        // Set DC to 0
        // Note: it was agreed with GovAlpha that there will be no global DC reduction this time.
        DssExecLib.setIlkDebtCeiling("RWA004-A", 0);
        // Call tell() on RWALiquidationOracle
        RwaLiquidationOracleLike(MIP21_LIQUIDATION_ORACLE).tell("RWA004-A");

        // ----- New Silver (RWA002-A) Doc Update -----
        // Poll: https://vote.makerdao.com/polling/QmaU1eaD
        // Forum: https://forum.makerdao.com/t/rwa-002-new-silver-restructuring-risk-and-legal-assessment/21417

        // Update doc to QmTrrwZpnSZ41rbrpx267R7vfDFktseQe2W5NJ5xB7kkn1
        _updateDoc("RWA002-A", "QmTrrwZpnSZ41rbrpx267R7vfDFktseQe2W5NJ5xB7kkn1");

        // ----- AVC Member Compensation -----
        // Forum: https://forum.makerdao.com/t/avc-member-participation-rewards-q2-2023/21459

        // IamMeeoh - 14.90 MKR - 0x47f7A5d8D27f259582097E1eE59a07a816982AE9
        MKR.transfer(IAMMEEOH,        14.90 ether); // note: ether is a keyword helper, only MKR is transferred here
        // ACRE DAOs - 14.90 MKR - 0xBF9226345F601150F64Ea4fEaAE7E40530763cbd
        MKR.transfer(ACREDAOS,        14.90 ether); // note: ether is a keyword helper, only MKR is transferred here
        // Space Xponential - 11.92 MKR - 0xFF8eEB643C5bfDf6A925f2a5F9aDC9198AF07b78
        MKR.transfer(SPACEXPONENTIAL, 11.92 ether); // note: ether is a keyword helper, only MKR is transferred here
        // Res - 14.90 MKR - 0x8c5c8d76372954922400e4654AF7694e158AB784
        MKR.transfer(RES,             14.90 ether); // note: ether is a keyword helper, only MKR is transferred here
        // LDF - 11.92 MKR - 0xC322E8Ec33e9b0a34c7cD185C616087D9842ad50
        MKR.transfer(LDF,             11.92 ether); // note: ether is a keyword helper, only MKR is transferred here
        // opensky - 14.90 MKR - 0x8e67ee3bbeb1743dc63093af493f67c3c23c6f04
        MKR.transfer(OPENSKY,         14.90 ether); // note: ether is a keyword helper, only MKR is transferred here
        // David Phelps - 8.94 MKR - 0xd56e3E325133EFEd6B1687C88571b8a91e517ab0
        MKR.transfer(DAVIDPHELPS,      8.94 ether); // note: ether is a keyword helper, only MKR is transferred here
        // seedlatam.eth - 11.92 MKR - 0x0087a081a9b430fd8f688c6ac5dd24421bfb060d
        MKR.transfer(SEEDLATAMETH,    11.92 ether); // note: ether is a keyword helper, only MKR is transferred here
        // StableLab - 14.9 MKR - 0xbDE65cf2352ed1Dde959f290E973d0fC5cEDFD08
        MKR.transfer(STABLELAB_2,     14.90 ether); // note: ether is a keyword helper, only MKR is transferred here
        // flipsidegov - 14.9 MKR - 0x300901243d6CB2E74c10f8aB4cc89a39cC222a29
        MKR.transfer(FLIPSIDEGOV,     14.90 ether); // note: ether is a keyword helper, only MKR is transferred here

        // ----- Launch Project Funding -----
        // Forum: https://forum.makerdao.com/t/utilization-of-the-launch-project-under-the-accessibility-scope/21468

        // Launch Project - 2,000,000 DAI - 0x3C5142F28567E6a0F172fd0BaaF1f2847f49D02F
        DssExecLib.sendPaymentFromSurplusBuffer(LAUNCH_PROJECT_FUNDING, 2 * MILLION);

        // ----- Trigger Spark Proxy Spell -----
        // Poll: https://vote.makerdao.com/polling/QmZyFH21
        // Forum: https://forum.makerdao.com/t/phoenix-labs-proposed-changes-for-spark/21422

        // Trigger Spark Proxy Spell at 0xEd3BF79737d3A469A29a7114cA1084e8340a2f20 (goerli)
        ProxyLike(SUBPROXY_SPARK).exec(SPARK_SPELL, abi.encodeWithSignature("execute()"));
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) {}
}
