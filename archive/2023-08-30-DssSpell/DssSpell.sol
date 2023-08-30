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

interface RwaLiquidationOracleLike {
    function tell(bytes32 ilk) external;
}

interface ChainlogLike {
    function removeAddress(bytes32) external;
}

interface RwaInputConduitLike {
    function mate(address usr) external;
    function file(bytes32 what, address data) external;
}

interface DssVestLike {
    function yank(uint256) external;
}

interface ProxyLike {
    function exec(address target, bytes calldata args) external payable returns (bytes memory out);
}

interface FlliperMomLike {
    function setOwner(address owner_) external;
}

contract DssSpellAction is DssAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: cast keccak -- "$(wget 'https://raw.githubusercontent.com/makerdao/community/64b0d8425a316c40d1fc464c084d800e3b17c1f3/governance/votes/Executive%20vote%20-%20August%2030%2C%202023.md' -q -O - 2>/dev/null)"
    string public constant override description =
        "2023-08-30 MakerDAO Executive Spell | Hash: 0xd4f061429b564e422f18f0289a0f956f0229edbeead40b51ad69d52b27f7e591";

    GemAbstract internal immutable MKR                         = GemAbstract(DssExecLib.mkr());
    address internal immutable MCD_ESM                         = DssExecLib.esm();
    address internal immutable MCD_VOW                         = DssExecLib.vow();
    address internal immutable MCD_FLIPPER_MOM                 = DssExecLib.flipperMom();
    address internal immutable MIP21_LIQUIDATION_ORACLE        = DssExecLib.getChangelogAddress("MIP21_LIQUIDATION_ORACLE");
    address internal immutable MCD_VEST_DAI                    = DssExecLib.getChangelogAddress("MCD_VEST_DAI");
    address internal immutable MCD_VEST_MKR_TREASURY           = DssExecLib.getChangelogAddress("MCD_VEST_MKR_TREASURY");
    address internal immutable RWA015_A_INPUT_CONDUIT_URN_USDC = DssExecLib.getChangelogAddress("RWA015_A_INPUT_CONDUIT_URN");
    address internal immutable RWA015_A_INPUT_CONDUIT_JAR_USDC = DssExecLib.getChangelogAddress("RWA015_A_INPUT_CONDUIT_JAR");

    // Set office hours according to the summary
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

    address internal constant RWA015_A_OPERATOR               = 0x23a10f09Fac6CCDbfb6d9f0215C795F9591D7476;
    address internal constant RWA015_A_CUSTODY                = 0x65729807485F6f7695AF863d97D62140B7d69d83;
    // BlockTower Input Conduits
    address internal constant RWA015_A_INPUT_CONDUIT_URN_GUSD = 0xAB80C37cB5b21238D975c2Cea46e0F12b3d84B06;
    address internal constant RWA015_A_INPUT_CONDUIT_JAR_GUSD = 0x13C31b41E671401c7BC2bbd44eF33B6E9eaa1E7F;
    address internal constant RWA015_A_INPUT_CONDUIT_URN_PAX  = 0x4f7f76f31CE6Bb20809aaCE30EfD75217Fbfc217;
    address internal constant RWA015_A_INPUT_CONDUIT_JAR_PAX  = 0x79Fc3810735959db3C6D4fc64F7F7b5Ce48d1CEc;

    // ---------- Launch Project Transfers ----------
    address internal constant LAUNCH_PROJECT_FUNDING          = 0x3C5142F28567E6a0F172fd0BaaF1f2847f49D02F;

    // Contracts pulled from Spark official deployment repository
    // Spark Proxy: https://github.com/marsfoundation/sparklend/blob/d42587ba36523dcff24a4c827dc29ab71cd0808b/script/output/5/primary-sce-latest.json#L2
    address internal constant SPARK_PROXY                     = 0x3300f198988e4C9C63F75dF86De36421f06af8c4;

    // ---------- Trigger Spark Proxy Spell ----------
    address internal constant SPARK_SPELL                     = 0xFBdB6C5596Fc958B432Bf1c99268C72B1515DFf0;

    function actions() public override {
        // ---------- Management of ConsolFreight (RWA003-A) Default ----------
        // Forum: https://forum.makerdao.com/t/consolfreight-rwa-003-cf4-drop-default/21745

        // Set DC to 0
        // Note: it was agreed with GovAlpha that there will be no global DC reduction this time.
        DssExecLib.setIlkDebtCeiling("RWA003-A", 0);
        // Call tell() on RWALiquidationOracle
        RwaLiquidationOracleLike(MIP21_LIQUIDATION_ORACLE).tell("RWA003-A");

        // ---------- Auth ESM on the Vow ----------
        // Forum: http://forum.makerdao.com/t/overlooked-vectors-for-post-shutdown-governance-attacks-postmortem/20696/5

        DssExecLib.authorize(MCD_VOW, MCD_ESM);

        // ---------- BlockTower Andromeda Input Conduit Chainlog Additions ----------
        // Forum: http://forum.makerdao.com/t/overlooked-vectors-for-post-shutdown-governance-attacks-postmortem/20696/5

        // OPERATOR permission on RWA015_A_INPUT_CONDUIT_URN_GUSD
        RwaInputConduitLike(RWA015_A_INPUT_CONDUIT_URN_GUSD).mate(RWA015_A_OPERATOR);
        // Set "quitTo" address for RWA015_A_INPUT_CONDUIT_URN_GUSD
        RwaInputConduitLike(RWA015_A_INPUT_CONDUIT_URN_GUSD).file("quitTo", RWA015_A_CUSTODY);
        // OPERATOR permission on RWA015_A_INPUT_CONDUIT_JAR_GUSD
        RwaInputConduitLike(RWA015_A_INPUT_CONDUIT_JAR_GUSD).mate(RWA015_A_OPERATOR);
        // Set "quitTo" address for RWA015_A_INPUT_CONDUIT_JAR_GUSD
        RwaInputConduitLike(RWA015_A_INPUT_CONDUIT_JAR_GUSD).file("quitTo", RWA015_A_CUSTODY);

        // OPERATOR permission on RWA015_A_INPUT_CONDUIT_URN_PAX
        RwaInputConduitLike(RWA015_A_INPUT_CONDUIT_URN_PAX).mate(RWA015_A_OPERATOR);
        // Set "quitTo" address for RWA015_A_INPUT_CONDUIT_URN_PAX
        RwaInputConduitLike(RWA015_A_INPUT_CONDUIT_URN_PAX).file("quitTo", RWA015_A_CUSTODY);
        // OPERATOR permission on RWA015_A_INPUT_CONDUIT_JAR_PAX
        RwaInputConduitLike(RWA015_A_INPUT_CONDUIT_JAR_PAX).mate(RWA015_A_OPERATOR);
        // Set "quitTo" address for RWA015_A_INPUT_CONDUIT_JAR_PAX
        RwaInputConduitLike(RWA015_A_INPUT_CONDUIT_JAR_PAX).file("quitTo", RWA015_A_CUSTODY);

        // Authorize ESM
        DssExecLib.authorize(RWA015_A_INPUT_CONDUIT_URN_GUSD, MCD_ESM);
        DssExecLib.authorize(RWA015_A_INPUT_CONDUIT_JAR_GUSD, MCD_ESM);
        DssExecLib.authorize(RWA015_A_INPUT_CONDUIT_URN_PAX,  MCD_ESM);
        DssExecLib.authorize(RWA015_A_INPUT_CONDUIT_JAR_PAX,  MCD_ESM);

        // Add RWA015 Conduits to the changelog
        DssExecLib.setChangelogAddress("RWA015_A_INPUT_CONDUIT_URN_GUSD", RWA015_A_INPUT_CONDUIT_URN_GUSD);
        DssExecLib.setChangelogAddress("RWA015_A_INPUT_CONDUIT_JAR_GUSD", RWA015_A_INPUT_CONDUIT_JAR_GUSD);
        DssExecLib.setChangelogAddress("RWA015_A_INPUT_CONDUIT_URN_PAX",  RWA015_A_INPUT_CONDUIT_URN_PAX);
        DssExecLib.setChangelogAddress("RWA015_A_INPUT_CONDUIT_JAR_PAX",  RWA015_A_INPUT_CONDUIT_JAR_PAX);

        // Replace name for USDC Input Conduits in changelog
        ChainlogLike(DssExecLib.LOG).removeAddress("RWA015_A_INPUT_CONDUIT_URN");
        ChainlogLike(DssExecLib.LOG).removeAddress("RWA015_A_INPUT_CONDUIT_JAR");
        DssExecLib.setChangelogAddress("RWA015_A_INPUT_CONDUIT_URN_USDC",  RWA015_A_INPUT_CONDUIT_URN_USDC);
        DssExecLib.setChangelogAddress("RWA015_A_INPUT_CONDUIT_JAR_USDC",  RWA015_A_INPUT_CONDUIT_JAR_USDC);

        // ---------- Chainlog Cleanup ----------
        // Discussion: https://github.com/makerdao/spells-mainnet/issues/354

        // Deauth FlliperMom
        DssExecLib.setAuthority(MCD_FLIPPER_MOM, address(0));
        FlliperMomLike(MCD_FLIPPER_MOM).setOwner(address(0));

        ChainlogLike(DssExecLib.LOG).removeAddress("FLIPPER_MOM");
        ChainlogLike(DssExecLib.LOG).removeAddress("FLIP_FAB");

        // ---------- Yank GovAlpha Budget Streams ----------
        // Forum: https://forum.makerdao.com/t/spell-contents-2023-08-30/21730

        DssVestLike(MCD_VEST_DAI).yank(17);
        DssVestLike(MCD_VEST_MKR_TREASURY).yank(34);

        // ---------- Launch Project Dai Transfer ----------
        // Discussion: https://forum.makerdao.com/t/utilization-of-the-launch-project-under-the-accessibility-scope/21468/4

        DssExecLib.sendPaymentFromSurplusBuffer(LAUNCH_PROJECT_FUNDING, 941_993);

        // ---------- Launch Project MKR Transfer ----------
        // Discussion: https://forum.makerdao.com/t/utilization-of-the-launch-project-under-the-accessibility-scope/21468/4

        MKR.transfer(LAUNCH_PROJECT_FUNDING, 210.83 ether); // NOTE: 'ether' is a keyword helper, only MKR is transferred here

        // ---------- Trigger Spark Proxy Spell ----------
        // Forum: https://forum.makerdao.com/t/phoenix-labs-proposed-changes-for-spark-for-august-18th-spell/21612
        // Vote: https://vote.makerdao.com/polling/QmbMR8PU

        ProxyLike(SPARK_PROXY).exec(SPARK_SPELL, abi.encodeWithSignature("execute()"));

        // Bump Changelog
        DssExecLib.setChangelogVersion("1.16.0");
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) {}
}
