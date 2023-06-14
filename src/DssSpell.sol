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
import "dss-interfaces/dss/IlkRegistryAbstract.sol";
import "dss-interfaces/ERC/GemAbstract.sol";
import "dss-interfaces/dapp/DSTokenAbstract.sol";

interface GemLike {
    function transfer(address, uint256) external returns (bool);
}

interface VatLike {
    function ilks(bytes32) external view returns (uint256 Art, uint256 rate, uint256 spot, uint256 line, uint256 dust);
}

interface RwaLiquidationLike {
    function ilks(bytes32) external view returns (string memory doc, address pip, uint48 tau, uint48 toc);
    function init(bytes32 ilk, uint256 val, string memory doc, uint48 tau) external;
    function bump(bytes32 ilk, uint256 val) external;
}

interface ACLManagerLike {
    function addPoolAdmin(address admin) external;
}

interface ProxyLike {
    function exec(address target, bytes calldata args) external payable returns (bytes memory out);
}

interface Initializable {
    function init(bytes32 ilk) external;
}

interface RwaUrnLike {
    function hope(address usr) external;
    function nope(address usr) external;
    function lock(uint256 wad) external;
    function draw(uint256 wad) external;
}

interface RwaInputConduitLike {
    function mate(address usr) external;
    function hate(address usr) external;
    function file(bytes32 what, address data) external;
}

interface RwaOutputConduitLike {
    function file(bytes32 what, address data) external;
    function hope(address usr) external;
    function nope(address usr) external;
    function mate(address usr) external;
    function hate(address usr) external;
    function kiss(address who) external;
}

contract DssSpellAction is DssAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: cast keccak -- "$(wget 'https://raw.githubusercontent.com/makerdao/community/78ca48d951e0b1a80d233497dbbb8a0ebd63749d/governance/votes/Executive%20vote%20-%20June%2014%2C%202023.md' -q -O - 2>/dev/null)"
    string public constant override description =
        "2023-06-07 MakerDAO Executive Spell | Hash: 0xfc04cb79584d4541ccf1635f112991de995733143468afeb6bba99b8a678ea0d";

    address internal immutable MIP21_LIQUIDATION_ORACLE = DssExecLib.getChangelogAddress("MIP21_LIQUIDATION_ORACLE");
    address internal immutable REGISTRY = DssExecLib.reg();
    address internal immutable MCD_JUG  = DssExecLib.jug();
    address internal immutable MCD_SPOT = DssExecLib.spotter();
    address internal immutable MCD_ESM  = DssExecLib.esm();
    address internal immutable MCD_VAT  = DssExecLib.vat();

    // Set office hours according to the summary
    function officeHours() public pure override returns (bool) {
        return true;
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

    uint256 internal constant THREE_PT_FOUR_NINE_PCT_RATE    = 1000000001087798189708544327;
    uint256 internal constant THREE_PT_SEVEN_FOUR_PCT_RATE   = 1000000001164306917698440949;
    uint256 internal constant FOUR_PT_TWO_FOUR_PCT_RATE      = 1000000001316772794769098706;
    uint256 internal constant FIVE_PT_EIGHT_PCT_RATE         = 1000000001787808646832390371;
    uint256 internal constant SIX_PT_THREE_PCT_RATE          = 1000000001937312893803622469;
    uint256 internal constant FIVE_PT_FIVE_FIVE_PCT_RATE     = 1000000001712791360746325100;

    uint256 internal constant MILLION           = 10 ** 6;
    uint256 internal constant WAD               = 10 ** 18;
    uint256 internal constant RAD               = 10 ** 45;

    // -- Spark Components --
    address internal constant SPARK_ACL_MANAGER = 0xdA135Cd78A086025BcdC87B038a1C462032b510C;
    address internal constant SPARK_PROXY = 0x3300f198988e4C9C63F75dF86De36421f06af8c4;
    address internal constant SPARK_SPELL = 0x41D7c79aE5Ecba7428283F66998DedFD84451e0e;

    // -- RWA015 components --
    address internal constant RWA015                     = 0xf5E5E706EfC841BeD1D24460Cd04028075cDbfdE;
    address internal constant MCD_JOIN_RWA015_A          = 0x8938988f7B368f74bEBdd3dcd8D6A3bd18C15C0b;
    address internal constant RWA015_A_URN               = 0xebFDaa143827FD0fc9C6637c3604B75Bbcfb7284;
    address internal constant RWA015_A_JAR               = 0xc27C3D3130563C1171feCC4F76C217Db603997cf;
    address internal constant RWA015_A_INPUT_CONDUIT_URN = 0xe08cb5E24862eA86328295D5E5c08972203C20D8;
    address internal constant RWA015_A_INPUT_CONDUIT_JAR = 0xB9373C557f3aE8cDdD068c1644ED226CfB18A997;
    address internal constant RWA015_A_OUTPUT_CONDUIT    = 0xC35E60736ec2E3de612535dba2dFB1f4130C82c3;
    // Operator address
    address internal constant RWA015_A_OPERATOR          = 0x23a10f09Fac6CCDbfb6d9f0215C795F9591D7476;
    // Custody address
    address internal constant RWA015_A_CUSTODY           = 0x65729807485F6f7695AF863d97D62140B7d69d83;

    // Ilk registry params
    uint256 internal constant RWA015_A_REG_CLASS_RWA = 3;

    // RWA Oracle Params
    uint256 internal constant RWA015_A_INITIAL_PRICE = 2_500_000 * WAD;
    string  internal constant RWA015_A_DOC           = "QmdbPyQLDdGQhKGXBgod7TbQmrUJ7tiN9aX1zSL7bmtkTN";
    uint48  internal constant RWA015_A_TAU           = 0;

    // Remaining params
    uint256 internal constant RWA015_A_LINE = 2_500_000;
    uint256 internal constant RWA015_A_MAT  = 100_00;
    // -- RWA015 END --

    // -- MKR TRANSFERS --
    GemLike immutable MKR                       = GemLike(DssExecLib.mkr());
    address internal constant SIDESTREAM_WALLET = 0xb1f950a51516a697E103aaa69E152d839182f6Fe;
    address internal constant DUX_WALLET        = 0x5A994D8428CCEbCC153863CCdA9D2Be6352f89ad;

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

    function _onboardRWA015A() internal {
        bytes32 ilk = "RWA015-A";

        // Init the RwaLiquidationOracle
        RwaLiquidationLike(MIP21_LIQUIDATION_ORACLE).init(ilk, RWA015_A_INITIAL_PRICE, RWA015_A_DOC, RWA015_A_TAU);
        (, address pip, , ) = RwaLiquidationLike(MIP21_LIQUIDATION_ORACLE).ilks(ilk);

        // Init RWA015 in Vat
        Initializable(MCD_VAT).init(ilk);
        // Init RWA015 in Jug
        Initializable(MCD_JUG).init(ilk);

        // Allow RWA015 Join to modify Vat registry
        DssExecLib.authorize(MCD_VAT, MCD_JOIN_RWA015_A);

        // Stability Fee is 0 for this ilk

        // 2_500_000 debt ceiling
        DssExecLib.increaseIlkDebtCeiling(ilk, RWA015_A_LINE, /* _global = */ true);

        // Set price feed for RWA015
        DssExecLib.setContract(MCD_SPOT, ilk, "pip", pip);

        // Set minimum collateralization ratio
        DssExecLib.setIlkLiquidationRatio(ilk, RWA015_A_MAT);

        // Poke the spotter to pull in a price
        DssExecLib.updateCollateralPrice(ilk);

        // Give the urn permissions on the join adapter
        DssExecLib.authorize(MCD_JOIN_RWA015_A, RWA015_A_URN);

        // OPERATOR permission on URN
        RwaUrnLike(RWA015_A_URN).hope(RWA015_A_OPERATOR);

        // OPERATOR permission on RWA015_A_OUTPUT_CONDUIT
        RwaOutputConduitLike(RWA015_A_OUTPUT_CONDUIT).hope(RWA015_A_OPERATOR);
        RwaOutputConduitLike(RWA015_A_OUTPUT_CONDUIT).mate(RWA015_A_OPERATOR);
        // Custody whitelist for output conduit destination address
        RwaOutputConduitLike(RWA015_A_OUTPUT_CONDUIT).kiss(RWA015_A_CUSTODY);
        // Set "quitTo" address for RWA015_A_OUTPUT_CONDUIT
        RwaOutputConduitLike(RWA015_A_OUTPUT_CONDUIT).file("quitTo", RWA015_A_URN);

        // OPERATOR permission on RWA015_A_INPUT_CONDUIT_URN
        RwaInputConduitLike(RWA015_A_INPUT_CONDUIT_URN).mate(RWA015_A_OPERATOR);
        // Set "quitTo" address for RWA015_A_INPUT_CONDUIT_URN
        RwaInputConduitLike(RWA015_A_INPUT_CONDUIT_URN).file("quitTo", RWA015_A_CUSTODY);

        // OPERATOR permission on RWA015_A_INPUT_CONDUIT_JAR
        RwaInputConduitLike(RWA015_A_INPUT_CONDUIT_JAR).mate(RWA015_A_OPERATOR);
        // Set "quitTo" address for RWA015_A_INPUT_CONDUIT_JAR
        RwaInputConduitLike(RWA015_A_INPUT_CONDUIT_JAR).file("quitTo", RWA015_A_CUSTODY);

        // Add RWA015 contract to the changelog
        DssExecLib.setChangelogAddress("RWA015",                     RWA015);
        DssExecLib.setChangelogAddress("PIP_RWA015",                 pip);
        DssExecLib.setChangelogAddress("MCD_JOIN_RWA015_A",          MCD_JOIN_RWA015_A);
        DssExecLib.setChangelogAddress("RWA015_A_URN",               RWA015_A_URN);
        DssExecLib.setChangelogAddress("RWA015_A_JAR",               RWA015_A_JAR);
        DssExecLib.setChangelogAddress("RWA015_A_INPUT_CONDUIT_URN", RWA015_A_INPUT_CONDUIT_URN);
        DssExecLib.setChangelogAddress("RWA015_A_INPUT_CONDUIT_JAR", RWA015_A_INPUT_CONDUIT_JAR);
        DssExecLib.setChangelogAddress("RWA015_A_OUTPUT_CONDUIT",    RWA015_A_OUTPUT_CONDUIT);

        // Add RWA015 to ILK REGISTRY
        IlkRegistryAbstract(REGISTRY).put(
            ilk,
            MCD_JOIN_RWA015_A,
            RWA015,
            GemAbstract(RWA015).decimals(),
            RWA015_A_REG_CLASS_RWA,
            pip,
            address(0),
            "RWA015-A: BlockTower Andromeda",
            GemAbstract(RWA015).symbol()
        );

        // ----- Additional ESM authorization -----
        DssExecLib.authorize(MCD_JOIN_RWA015_A,          MCD_ESM);
        DssExecLib.authorize(RWA015_A_URN,               MCD_ESM);
        DssExecLib.authorize(RWA015_A_OUTPUT_CONDUIT,    MCD_ESM);
        DssExecLib.authorize(RWA015_A_INPUT_CONDUIT_URN, MCD_ESM);
        DssExecLib.authorize(RWA015_A_INPUT_CONDUIT_JAR, MCD_ESM);

        // Bootstrap
        // Grant all required permissions for MCD_PAUSE_PROXY
        RwaUrnLike(RWA015_A_URN).hope(address(this));
        RwaOutputConduitLike(RWA015_A_OUTPUT_CONDUIT).hope(address(this));
        RwaOutputConduitLike(RWA015_A_OUTPUT_CONDUIT).mate(address(this));
        RwaInputConduitLike(RWA015_A_INPUT_CONDUIT_URN).mate(address(this));
        RwaInputConduitLike(RWA015_A_INPUT_CONDUIT_JAR).mate(address(this));

        // Lock RWA015 Token in the URN
        GemAbstract(RWA015).approve(RWA015_A_URN, 1 * WAD);
        RwaUrnLike(RWA015_A_URN).lock(1 * WAD);
        // Draw until the current debt ceiling
        RwaUrnLike(RWA015_A_URN).draw(RWA015_A_LINE * WAD);

        // Pick the destination for the assets
        RwaOutputConduitLike(RWA015_A_OUTPUT_CONDUIT).pick(RWA015_A_CUSTODY);
        // Swap Dai for the chosen stablecoin through the PSM and send it to the picked address.
        RwaOutputConduitLike(RWA015_A_OUTPUT_CONDUIT).push();

        // Revoke all granted permissions from MCD_PAUSE_PROXY
        RwaUrnLike(RWA015_A_URN).nope(address(this));
        RwaOutputConduitLike(RWA015_A_OUTPUT_CONDUIT).nope(address(this));
        RwaOutputConduitLike(RWA015_A_OUTPUT_CONDUIT).hate(address(this));
        RwaInputConduitLike(RWA015_A_INPUT_CONDUIT_URN).hate(address(this));
        RwaInputConduitLike(RWA015_A_INPUT_CONDUIT_JAR).hate(address(this));

    }

    function actions() public override {
        // --- BlockTower Vault Debt Ceiling Adjustments ---
        // Poll: https://vote.makerdao.com/polling/QmPMrvfV#poll-detail
        // Forum: https://forum.makerdao.com/t/blocktower-credit-rwa-vaults-parameters-shift/20707

        (uint256 RWA010_A_ART, , , ,) = VatLike(MCD_VAT).ilks("RWA010-A");
        (uint256 RWA011_A_ART, , , ,) = VatLike(MCD_VAT).ilks("RWA011-A");

        if (RWA010_A_ART + RWA011_A_ART == 0) {
            // Decrease the Debt Ceiling (line) of BlockTower S1 (RWA010-A) from 20 million DAI to 0 DAI.
            DssExecLib.setIlkDebtCeiling("RWA010-A", 0);
            // Decrease the Debt Ceiling (line) of BlockTower S2 (RWA011-A) from 30 million DAI to 0 DAI.
            DssExecLib.setIlkDebtCeiling("RWA011-A", 0);
            // Increase the Debt Ceiling (line) of BlockTower S3 (RWA012-A) from 30 million DAI to 80 million DAI.
            // Note: Do not increase global Line because there is no net change from these operations
            DssExecLib.setIlkDebtCeiling("RWA012-A", 80 * MILLION);

            // Increase the price to enable DAI to be drawn -- value corresponds to
            // Debt ceiling * [ (1 + RWA stability fee ) ^ (minimum deal duration in years) ] * liquidation ratio
            // 80M * 1.04^5 * 1.00 as a WAD
            RwaLiquidationLike(MIP21_LIQUIDATION_ORACLE).bump(
                "RWA012-A",
                 97_332_233 * WAD
            );
            // Update the RWA012-A `spot` value in Vat
            DssExecLib.updateCollateralPrice("RWA012-A");
        }


        _updateDoc("RWA010-A", "QmY382BPa5UQfmpTfi6KhjqQHtqq1fFFg2owBfsD2LKmYU");
        _updateDoc("RWA011-A", "QmY382BPa5UQfmpTfi6KhjqQHtqq1fFFg2owBfsD2LKmYU");
        _updateDoc("RWA012-A", "QmY382BPa5UQfmpTfi6KhjqQHtqq1fFFg2owBfsD2LKmYU");
        _updateDoc("RWA013-A", "QmY382BPa5UQfmpTfi6KhjqQHtqq1fFFg2owBfsD2LKmYU");

        // --- MKR Vesting Transfers ---
        // Sidestream - 348.28 MKR - 0xb1f950a51516a697E103aaa69E152d839182f6Fe
        // Poll: N/A
        // MIP: https://mips.makerdao.com/mips/details/MIP40c3SP44#estimated-mkr-expenditure

        MKR.transfer(SIDESTREAM_WALLET, 34828 * WAD / 100);

        // DUX - 225.12 MKR - 0x5A994D8428CCEbCC153863CCdA9D2Be6352f89ad
        // Poll: N/A
        // MIP: https://mips.makerdao.com/mips/details/MIP40c3SP27#total-mkr-expenditure-cap

        MKR.transfer(DUX_WALLET, 22512 * WAD / 100);

        // --- Stability Scope Defined Parameter Adjustments ---
        // Poll: https://vote.makerdao.com/polling/QmaoGpAQ#poll-detail
        // Forum: https://forum.makerdao.com/t/stability-scope-parameter-changes-2-non-scope-defined-parameter-changes-may-2023/20981#stability-scope-parameter-changes-proposal-6

        // Increase the DSR from 1.00% to 3.49%
        DssExecLib.setDSR(THREE_PT_FOUR_NINE_PCT_RATE, /* doDrip = */ true);

        // Increase the ETH-A Stability Fee from 1.75% to 3.74%
        DssExecLib.setIlkStabilityFee("ETH-A", THREE_PT_SEVEN_FOUR_PCT_RATE, /* doDrip = */ true);

        // Increase the ETH-B Stability Fee from 3.25% to 4.24%
        DssExecLib.setIlkStabilityFee("ETH-B", FOUR_PT_TWO_FOUR_PCT_RATE, /* doDrip = */ true);

        // Increase the ETH-C Stability Fee from 1.00% to 3.49%
        DssExecLib.setIlkStabilityFee("ETH-C", THREE_PT_FOUR_NINE_PCT_RATE, /* doDrip = */ true);

        // Increase the WSTETH-A Stability Fee from 1.75% to 3.74%
        DssExecLib.setIlkStabilityFee("WSTETH-A", THREE_PT_SEVEN_FOUR_PCT_RATE, /* doDrip = */ true);

        // Increase the WSTETH-B Stability Fee from 1.00% to 3.49%
        DssExecLib.setIlkStabilityFee("WSTETH-B", THREE_PT_FOUR_NINE_PCT_RATE, /* doDrip = */ true);

        // --- Spark Protocol Parameter Changes ---
        // D3M Parameter Adjustments Poll: https://vote.makerdao.com/polling/QmWatYqy#poll-detail
        // Executive Proxy Poll: https://vote.makerdao.com/polling/Qmc9fd3j#poll-detail
        // Onboard rETH Poll: https://vote.makerdao.com/polling/QmeEV7ph#vote-breakdown (Inside Proxy Spell)
        // DAI Interest Rate Strategy Poll: https://vote.makerdao.com/polling/QmWodV1J#poll-detail (Inside Proxy Spell)
        // Forum: https://forum.makerdao.com/t/2023-05-24-spark-protocol-updates/20958
        DssExecLib.setIlkAutoLineParameters("DIRECT-SPARK-DAI", /* line */ 20 * MILLION, /* gap */ 20 * MILLION, /* ttl */ 8 hours);
        DssExecLib.authorize(SPARK_PROXY, DssExecLib.esm());
        ACLManagerLike(SPARK_ACL_MANAGER).addPoolAdmin(SPARK_PROXY);
        ProxyLike(SPARK_PROXY).exec(SPARK_SPELL, abi.encodeWithSignature("execute()"));
        DssExecLib.setChangelogAddress("SUBPROXY_SPARK", SPARK_PROXY);

        // --- Non-Scope Defined Parameter Adjustments ---
        // Poll: https://vote.makerdao.com/polling/QmQXhS3Z#poll-detail
        // Forum: https://forum.makerdao.com/t/stability-scope-parameter-changes-2-non-scope-defined-parameter-changes-may-2023/20981

        // Increase RETH-A line from 20 million DAI to 50 million DAI
        // Increase RETH-A gap from 3 million DAI to 5 million DAI
        DssExecLib.setIlkAutoLineParameters("RETH-A", /* line */ 50 * MILLION, /* gap */ 5 * MILLION, /* ttl */ 8 hours);

        // Increase the RETH-A Stability Fee from 0.75% to 3.74%
        DssExecLib.setIlkStabilityFee("RETH-A", THREE_PT_SEVEN_FOUR_PCT_RATE, true);

        // Increase the CRVV1ETHSTETH-A Stability Fee from 1.75% to 4.24%
        DssExecLib.setIlkStabilityFee("CRVV1ETHSTETH-A", FOUR_PT_TWO_FOUR_PCT_RATE, true);

        // Increase the WBTC-A Stability Fee from 4.90% to 5.80%
        DssExecLib.setIlkStabilityFee("WBTC-A", FIVE_PT_EIGHT_PCT_RATE, true);

        // Increase the WBTC-B Stability Fee from 4.90% to 6.30%
        DssExecLib.setIlkStabilityFee("WBTC-B", SIX_PT_THREE_PCT_RATE, true);

        // Increase the WBTC-C Stability Fee from 4.90% to 5.55%
        DssExecLib.setIlkStabilityFee("WBTC-C", FIVE_PT_FIVE_FIVE_PCT_RATE, true);

        // --- RWA015 (BlockTower Andromeda) ---
        // Poll: https://vote.makerdao.com/polling/QmbudkVR#poll-detail
        // Forum links:
        //   - https://forum.makerdao.com/t/mip90-liquid-aaa-structured-credit-money-market-fund/18428
        //   - https://forum.makerdao.com/t/project-andromeda-risk-legal-assessment/20969
        //   - https://forum.makerdao.com/t/rwa015-project-andromeda-technical-assessment/20974
        _onboardRWA015A();

        // --- USDP PSM Debt Ceiling ---
        // Poll: https://vote.makerdao.com/polling/QmQYSLHH#poll-detail
        // Forum: https://forum.makerdao.com/t/reducing-psm-usdp-a-debt-ceiling/20980
        // Reduce the PSM-PAX-A Debt Ceiling from 500 million DAI to 0 DAI

        // Do not decrease the global Line according to the point in
        // https://github.com/makerdao/spells-goerli/pull/202#discussion_r1217131039
        DssExecLib.removeIlkFromAutoLine("PSM-PAX-A");
        DssExecLib.setIlkDebtCeiling("PSM-PAX-A", 0);

        DssExecLib.setChangelogVersion("1.14.13");
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) {}
}
