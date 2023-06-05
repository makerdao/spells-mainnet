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

interface VatLike {
    function Line() external view returns (uint256);
    function file(bytes32 what, uint256 data) external;
    function ilks(bytes32 ilk) external view returns (uint256 Art, uint256 rate, uint256 spot, uint256 line, uint256 dust);
}

interface DssVestLike {
    function create(address, uint256, uint256, uint256, uint256, address) external returns (uint256);
    function file(bytes32, uint256) external;
    function restrict(uint256) external;
}
interface RwaLiquidationLike {
    function ilks(bytes32) external view returns (string memory, address, uint48, uint48);
    function init(bytes32, uint256, string calldata, uint48) external;
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
    function pick(address who) external;
    function push() external;
    function push(uint256 wad) external;
}

contract DssSpellAction is DssAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: cast keccak -- "$(wget 'https://raw.githubusercontent.com/makerdao/community/ce40e721ba58dc631ee1b66f5259423dd8e504ce/governance/votes/Executive%20vote%20-%20May%2024%2C%202023.md' -q -O - 2>/dev/null)"
    string public constant override description =
        "2023-05-24 MakerDAO Executive Spell | Hash: 0xfe3ea529455620ded327e3f6781e75c799567ce8d87824c6585671c8fe392946";
    VatLike internal immutable vat = VatLike(DssExecLib.getChangelogAddress("MCD_VAT"));
    DssVestLike internal immutable vest = DssVestLike(DssExecLib.getChangelogAddress("MCD_VEST_MKR_TREASURY"));
    RwaLiquidationLike immutable rwaLiquidation = RwaLiquidationLike(DssExecLib.getChangelogAddress("MIP21_LIQUIDATION_ORACLE"));

    // Set office hours according to the summary
    function officeHours() public pure override returns (bool) {
        return true;
    }

    uint256 internal constant RAD               = 10 ** 45;
    uint256 internal constant WAD               = 10 ** 18;
    uint256 internal constant MILLION           = 10 ** 6;

    uint256 internal constant THREE_PT_FOUR_NINE    = 1000000001087798189708544327;
    uint256 internal constant THREE_PT_SEVEN_FOUR   = 1000000001164306917698440949;
    uint256 internal constant FOUR_PT_TWO_FOUR      = 1000000001316772794769098706;
    uint256 internal constant FIVE_PT_EIGHT         = 1000000001787808646832390371;
    uint256 internal constant SIX_PT_THREE          = 1000000001937312893803622469;
    uint256 internal constant FIVE_PT_FIVE_FIVE     = 1000000001712791360746325100;

    address internal constant SPARK_ACL_MANAGER = 0xdA135Cd78A086025BcdC87B038a1C462032b510C;
    address internal constant SPARK_PROXY = 0x3300f198988e4C9C63F75dF86De36421f06af8c4;
    // TODO add the address when SPARK_SPELL is deployed
    address internal constant SPARK_SPELL = 0x3068FA0B6Fc6A5c998988a271501fF7A6892c6Ff;

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
    uint256 internal constant RWA015_REG_CLASS_RWA = 3;

    // RWA Oracle Params
    uint256 internal constant RWA015_A_INITIAL_PRICE = 2_500_000;
    string  internal constant RWA015_DOC             = "QmdbPyQLDdGQhKGXBgod7TbQmrUJ7tiN9aX1zSL7bmtkTN";
    uint48  internal constant RWA015_A_TAU           = 0;

    // Remaining params
    uint256 internal constant RWA015_A_LINE = 2_500_000;
    uint256 internal constant RWA015_A_MAT  = 100_00;
    // -- RWA015 END --

    address internal immutable reg  = DssExecLib.reg();
    address internal immutable jug  = DssExecLib.jug();
    address internal immutable spot = DssExecLib.spotter();
    address internal immutable esm  = DssExecLib.esm();

    function _updateDoc(bytes32 ilk, string memory doc) internal {
        ( , address pip, uint48 tau, ) = rwaLiquidation.ilks(ilk);
        require(pip != address(0), "DssSpell/unexisting-rwa-ilk");

        // Init the RwaLiquidationOracle to reset the doc
        rwaLiquidation.init(
            ilk, // ilk to update
            0,   // price ignored if init() has already been called
            doc, // new legal document
            tau  // old tau value
        );
    }

    function onboardRWA015A() internal {
        bytes32 ilk = "RWA015-A";

        // Init the RwaLiquidationOracle
        RwaLiquidationLike(rwaLiquidation).init(
            ilk,
            // We are not using DssExecLib, so the precision has to be set explicitly
            RWA015_A_INITIAL_PRICE * WAD,
            RWA015_DOC,
            RWA015_A_TAU
        );
        (, address pip, , ) = RwaLiquidationLike(rwaLiquidation).ilks(ilk);

        // Init RWA015 in Vat
        Initializable(address(vat)).init(ilk);
        // Init RWA015 in Jug
        Initializable(jug).init(ilk);

        // Allow RWA015 Join to modify Vat registry
        DssExecLib.authorize(address(vat), MCD_JOIN_RWA015_A);

        // 500m debt ceiling
        DssExecLib.increaseIlkDebtCeiling(ilk, RWA015_A_LINE, /* _global = */ true);

        // Set price feed for RWA015
        DssExecLib.setContract(spot, ilk, "pip", pip);

        // Set minimum collateralization ratio
        DssExecLib.setIlkLiquidationRatio(ilk, RWA015_A_MAT);

        // Poke the spotter to pull in a price
        DssExecLib.updateCollateralPrice(ilk);

        // Give the urn permissions on the join adapter
        DssExecLib.authorize(MCD_JOIN_RWA015_A, RWA015_A_URN);

        // OPERATOR permission on URN
        RwaUrnLike(RWA015_A_URN).hope(address(RWA015_A_OPERATOR));

        // OPERATOR permission on RWA015_A_OUTPUT_CONDUIT
        RwaOutputConduitLike(RWA015_A_OUTPUT_CONDUIT).hope(RWA015_A_OPERATOR);
        RwaOutputConduitLike(RWA015_A_OUTPUT_CONDUIT).mate(RWA015_A_OPERATOR);
        // Custody whitelist for output conduit destination address
        RwaOutputConduitLike(RWA015_A_OUTPUT_CONDUIT).kiss(address(RWA015_A_CUSTODY));
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
        IlkRegistryAbstract(reg).put(
            ilk,
            MCD_JOIN_RWA015_A,
            RWA015,
            GemAbstract(RWA015).decimals(),
            RWA015_REG_CLASS_RWA,
            pip,
            address(0),
            "RWA015-A: BlockTower Andromeda",
            GemAbstract(RWA015).symbol()
        );

        // ----- Additional ESM authorization -----
        DssExecLib.authorize(MCD_JOIN_RWA015_A,          esm);
        DssExecLib.authorize(RWA015_A_URN,               esm);
        DssExecLib.authorize(RWA015_A_OUTPUT_CONDUIT,    esm);
        DssExecLib.authorize(RWA015_A_INPUT_CONDUIT_URN, esm);
        DssExecLib.authorize(RWA015_A_INPUT_CONDUIT_JAR, esm);
    }

    function bootstrapRWA015A() internal {
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
        // For Goerli we push only 100 Dai
        RwaOutputConduitLike(RWA015_A_OUTPUT_CONDUIT).push(100 * WAD);
        // For Mainnet we push the entire balance
        // RwaOutputConduitLike(RWA015_A_OUTPUT_CONDUIT).push();

        // Revoke all granted permissions from MCD_PAUSE_PROXY
        RwaUrnLike(RWA015_A_URN).nope(address(this));
        RwaOutputConduitLike(RWA015_A_OUTPUT_CONDUIT).nope(address(this));
        RwaOutputConduitLike(RWA015_A_OUTPUT_CONDUIT).hate(address(this));
        RwaInputConduitLike(RWA015_A_INPUT_CONDUIT_URN).hate(address(this));
        RwaInputConduitLike(RWA015_A_INPUT_CONDUIT_JAR).hate(address(this));
    }

    function actions() public override {
        uint256 line;

        // --- BlockTower Vault Debt Ceiling Adjustments ---
        // Poll: https://vote.makerdao.com/polling/QmPMrvfV#poll-detail
        // Forum: https://forum.makerdao.com/t/blocktower-credit-rwa-vaults-parameters-shift/20707

        // Decrease the Debt Ceiling (line) of BlockTower S1 (RWA010-A) from 20 million Dai to zero Dai.
        DssExecLib.setIlkDebtCeiling("RWA010-A", 0);
        // Decrease the Debt Ceiling (line) of BlockTower S2 (RWA011-A) from 30 million Dai to zero Dai.
        DssExecLib.setIlkDebtCeiling("RWA011-A", 0);
        // Increase the Debt Ceiling (line) of BlockTower S3 (RWA012-A) from 30 million Dai to 80 million Dai.
        DssExecLib.increaseIlkDebtCeiling("RWA012-A", 50 * MILLION, /* do not increase global line */ false);
        _updateDoc("RWA010-A", "QmY382BPa5UQfmpTfi6KhjqQHtqq1fFFg2owBfsD2LKmYU");
        _updateDoc("RWA011-A", "QmY382BPa5UQfmpTfi6KhjqQHtqq1fFFg2owBfsD2LKmYU");
        _updateDoc("RWA012-A", "QmY382BPa5UQfmpTfi6KhjqQHtqq1fFFg2owBfsD2LKmYU");
        _updateDoc("RWA013-A", "QmY382BPa5UQfmpTfi6KhjqQHtqq1fFFg2owBfsD2LKmYU");

        // --- MKR Vesting Transfers ---
        // Sidestream - 348.28 MKR - 0xb1f950a51516a697E103aaa69E152d839182f6Fe
        // Poll: N/A
        // MIP: https://mips.makerdao.com/mips/details/MIP40c3SP44#estimated-mkr-expenditure

        // Skip for goerli

        // DUX - 225.12 MKR - 0x5A994D8428CCEbCC153863CCdA9D2Be6352f89ad
        // Poll: N/A
        // MIP: https://mips.makerdao.com/mips/details/MIP40c3SP27

        // Skip for goerli

        // --- Stability Scope Defined Parameter Adjustments ---
        // Poll: https://vote.makerdao.com/polling/QmaoGpAQ#poll-detail
        // Forum: https://forum.makerdao.com/t/stability-scope-parameter-changes-2-non-scope-defined-parameter-changes-may-2023/20981#stability-scope-parameter-changes-proposal-6

        // Increase DSR to 3.49%
        DssExecLib.setDSR(THREE_PT_FOUR_NINE, true);

        // Set ETH-A Stability Fee to 3.74%
        DssExecLib.setIlkStabilityFee("ETH-A", THREE_PT_SEVEN_FOUR, /* doDrip = */ true);

        // Set ETH-B Stability Fee to 4.24%
        DssExecLib.setIlkStabilityFee("ETH-B", FOUR_PT_TWO_FOUR, /* doDrip = */ true);

        // Set ETH-C Stability Fee to 3.49%
        DssExecLib.setIlkStabilityFee("ETH-C", THREE_PT_FOUR_NINE, /* doDrip = */ true);

        // Set WSTETH-A Stability Fee to 3.74%
        DssExecLib.setIlkStabilityFee("WSTETH-A", THREE_PT_SEVEN_FOUR, /* doDrip = */ true);

        // Set WSTETH-B Stability Fee to 3.49%
        DssExecLib.setIlkStabilityFee("WSTETH-B", THREE_PT_FOUR_NINE, /* doDrip = */ true);

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
        DssExecLib.setChangelogAddress("EXEC_PROXY_SPARK", SPARK_PROXY);

        // --- Non-Scope Defined Parameter Adjustments ---
        // Poll: https://vote.makerdao.com/polling/QmQXhS3Z#poll-detail
        // Forum: https://forum.makerdao.com/t/stability-scope-parameter-changes-2-non-scope-defined-parameter-changes-may-2023/20981

        // Increase rETH-A line to 50 million DAI
        // Increase rETH-A gap to 5 million DAI
        DssExecLib.setIlkAutoLineParameters("RETH-A", /* line */ 50 * MILLION, /* gap */ 5 * MILLION, /* ttl */ 8 hours);

        // Increase rETH-A Stability Fee to 3.74%
        DssExecLib.setIlkStabilityFee("RETH-A", THREE_PT_SEVEN_FOUR, true);

        // Increase CRVV1ETHSTETH-A Stability Fee to 4.24%
        // NOTE: disabled for goerli because the collateral is not on the chain
        // DssExecLib.setIlkStabilityFee("CRVV1ETHSTETH-A", FOUR_PT_TWO_FOUR, true);

        // Increase WBTC-A Stability Fee to 5.80%
        DssExecLib.setIlkStabilityFee("WBTC-A", FIVE_PT_EIGHT, true);

        // Increase WBTC-B Stability Fee to 6.30%
        DssExecLib.setIlkStabilityFee("WBTC-B", SIX_PT_THREE, true);

        // Increase WBTC-C Stability Fee to 5.55%
        DssExecLib.setIlkStabilityFee("WBTC-C", FIVE_PT_FIVE_FIVE, true);

        // --- RWA015 (BlockTower Andromeda) ---
        // Poll: https://vote.makerdao.com/polling/QmbudkVR#poll-detail
        // Forum links:
        //   - https://forum.makerdao.com/t/mip90-liquid-aaa-structured-credit-money-market-fund/18428
        //   - https://forum.makerdao.com/t/project-andromeda-risk-legal-assessment/20969
        //   - https://forum.makerdao.com/t/rwa015-project-andromeda-technical-assessment/20974
        onboardRWA015A();
        bootstrapRWA015A();

        // --- USDP PSM Debt Ceiling ---
        // Poll: https://vote.makerdao.com/polling/QmQYSLHH#poll-detail
        // Forum: https://forum.makerdao.com/t/reducing-psm-usdp-a-debt-ceiling/20980
        // Set PSM-USDP-A Debt Ceiling to 0 and remove from autoline
        (,,,line,) = vat.ilks("PSM-PAX-A");
        // do not decrease the debt ceiling according to the point in
        // https://github.com/makerdao/spells-goerli/pull/202#discussion_r1217131039
        DssExecLib.decreaseIlkDebtCeiling("PSM-PAX-A", line / RAD, /* decrease global ceiling */ true);
        DssExecLib.removeIlkFromAutoLine("PSM-PAX-A");

        DssExecLib.setChangelogVersion("1.14.13");
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) {}
}
