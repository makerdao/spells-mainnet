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
import "dss-interfaces/dss/GemJoinAbstract.sol";
import "dss-interfaces/ERC/GemAbstract.sol";
import "dss-interfaces/dss/MedianAbstract.sol";


interface Initializable {
    function init(bytes32 ilk) external;
}

interface VatLike {
    function ilks(bytes32 ilk) external view returns (uint256 Art, uint256 rate, uint256 spot, uint256 line, uint256 dust);
}

interface RwaLiquidationLike {
    function ilks(bytes32) external view returns (string memory doc, address pip, uint48 tau, uint48 toc);
    function init(bytes32 ilk, uint256 val, string calldata doc, uint48 tau) external;
}

interface RwaUrnLike {
    function lock(uint256 wad) external;
    function hope(address usr) external;
}

interface RwaInputConduitLike {
    function mate(address usr) external;
    function file(bytes32 what, address data) external;
}

interface RwaOutputConduitLike {
    function file(bytes32 what, address data) external;
    function hope(address usr) external;
    function mate(address usr) external;
    function kiss(address who) external;
}

interface VestLike {
    function restrict(uint256 _id) external;
    function create(address _usr, uint256 _tot, uint256 _bgn, uint256 _tau, uint256 _eta, address _mgr) external returns (uint256 id);
    function yank(uint256 _id) external;
}
interface NetworkPaymentAdapterLike {
    function bufferMax() external view returns (uint256);
    function minimumPayment() external view returns (uint256);
    function file(bytes32 what, uint256 data) external;
    function file(bytes32 what, address data) external;
}

interface DssCronSequencerLike {
    function windows(bytes32) external view returns (uint256 start, uint256 length);
}

interface PoolConfiguratorLike {
    struct InitReserveInput {
        address aTokenImpl;
        address stableDebtTokenImpl;
        address variableDebtTokenImpl;
        uint8 underlyingAssetDecimals;
        address interestRateStrategyAddress;
        address underlyingAsset;
        address treasury;
        address incentivesController;
        string aTokenName;
        string aTokenSymbol;
        string variableDebtTokenName;
        string variableDebtTokenSymbol;
        string stableDebtTokenName;
        string stableDebtTokenSymbol;
        bytes params;
    }
    function initReserves(InitReserveInput[] calldata input) external;
    function configureReserveAsCollateral(
        address asset,
        uint256 ltv,
        uint256 liquidationThreshold,
        uint256 liquidationBonus
    ) external;
    function setBorrowableInIsolation(address asset, bool borrowable) external;
    function setDebtCeiling(address asset, uint256 newDebtCeiling) external;
}

interface AaveOracleLike {
    function setAssetSources(address[] calldata assets, address[] calldata sources) external;
}

contract DssSpellAction is DssAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: cast keccak -- "$(wget 'https://raw.githubusercontent.com/makerdao/community/ce40e721ba58dc631ee1b66f5259423dd8e504ce/governance/votes/Executive%20vote%20-%20May%2024%2C%202023.md' -q -O - 2>/dev/null)"
    string public constant override description =
        "2023-05-24 MakerDAO Executive Spell | Hash: 0xfe3ea529455620ded327e3f6781e75c799567ce8d87824c6585671c8fe392946";

    // Set office hours according to the summary
    function officeHours() public pure override returns (bool) {
        return true;
    }

    uint256 internal constant RAD                            = 10 ** 45;
    uint256 internal constant WAD                            = 10 ** 18;
    uint256 internal constant MILLION                        = 10 ** 6;
    uint256 internal constant HUNDRED                        = 10 ** 2;

    // -- RWA014 MIP21 components --
    address internal constant RWA014                         = 0x75dCa04C4aCC1FfB0AEF940e5b49e2C17416008a;
    address internal constant MCD_JOIN_RWA014_A              = 0xAd722E51569EF41861fFf5e11942a8E07c7C309e;
    address internal constant RWA014_A_URN                   = 0xf082566Ac42566cF7B392C8e58116a27eEdcBe63;
    address internal constant RWA014_A_JAR                   = 0x71eC6d5Ee95B12062139311CA1fE8FD698Cbe0Cf;
    address internal constant RWA014_A_INPUT_CONDUIT_URN     = 0x6B86bA08Bd7796464cEa758061Ac173D0268cf49;
    address internal constant RWA014_A_INPUT_CONDUIT_JAR     = 0x391470cD3D8307AdC051d878A95Fa9459F800Dbc;
    address internal constant RWA014_A_OUTPUT_CONDUIT        = 0xD7cBDFdE553DE2063caAfBF230Be135e5DbB5064;
    string  internal constant RWA014_DOC                     = "QmT2Dr1tTw4idtVXZHxjT5Cs22KsNJyZgmYy9LGf9kR7vU";
    uint256 internal constant RWA014_A_INITIAL_PRICE         = 500 * MILLION * WAD;
    uint48  internal constant RWA014_A_TAU                   = 0;
    // Ilk registry params
    uint256 internal constant RWA014_REG_CLASS_RWA           = 3;
    // Remaining params
    uint256 internal constant RWA014_A_LINE                  = 500 * MILLION;
    uint256 internal constant RWA014_A_MAT                   = 100_00;
    // Operator address
    address internal constant RWA014_A_OPERATOR              = 0x3064D13712338Ee0E092b66Afb3B054F0b7779CB;
    // Custody address
    address internal constant RWA014_A_COINBASE_CUSTODY      = 0x2E5F1f08EBC01d6136c95a40e19D4c64C0be772c;
    // -- RWA014 END --

    // 24 May 2023 12:00:00 AM UTC
    uint256 internal constant MAY_24_2023                    = 1684886400;
    // 23 May 2023 11:59:59 PM UTC
    uint256 internal constant MAY_23_2024                    = 1716508799;
    // 23 May 2026 11:59:59 PM UTC
    uint256 internal constant MAY_23_2026                    = 1779580799;

    // Keeper Network
    address internal constant GELATO_PAYMENT_ADAPTER         = 0x0B5a34D084b6A5ae4361de033d1e6255623b41eD;
    address internal constant GELATO_TREASURY                = 0xbfDC6b9944B7EFdb1e2Bc9D55ae9424a2a55b206;
    address internal constant KEEP3R_PAYMENT_ADAPTER         = 0xaeFed819b6657B3960A8515863abe0529Dfc444A;
    address internal constant KEEP3R_TREASURY                = 0x4DfC6DA2089b0dfCF04788b341197146Ea97f743;
    address internal constant CHAINLINK_PAYMENT_ADAPTER      = 0xfB5e1D841BDA584Af789bDFABe3c6419140EC065;
    address internal constant TECHOPS_VEST_STREAMING         = 0x5A6007d17302238D63aB21407FF600a67765f982;

    // Ecosystem Scope
    address internal constant ECOSYSTEM_SCOPE_WALLET         = 0x6E51E0b5813152880C1389E3e860e69E06aD04D9;

    // -- Spark GNO Onboarding components --
    address internal constant SPARK_POOL_CONFIGURATOR        = 0x542DBa469bdE58FAeE189ffB60C6b49CE60E0738;
    address internal constant SPARK_AAVE_ORACLE              = 0x8105f69D9C41644c6A0803fDA7D03Aa70996cFD9;
    address internal constant SPARK_ATOKEN_IMPL              = 0x6175ddEc3B9b38c88157C10A01ed4A3fa8639cC6;
    address internal constant SPARK_STABLE_DEBT_TOKEN_IMPL   = 0x026a5B6114431d8F3eF2fA0E1B2EDdDccA9c540E;
    address internal constant SPARK_VARIABLE_DEBT_TOKEN_IMPL = 0x86C71796CcDB31c3997F8Ec5C2E3dB3e9e40b985;
    address internal constant SPARK_INTEREST_RATE_STRATEGY   = 0x554265A713D6746A62d86A797254590784D436AA;
    address internal constant SPARK_TREASURY                 = 0xb137E7d16564c81ae2b0C8ee6B55De81dd46ECe5;
    address internal constant SPARK_GNO_ORACLE               = 0x4A7Ad931cb40b564A1C453545059131B126BC828;
    address internal constant GNO_MEDIANIZER                 = 0x31BFA908637C29707e155Cfac3a50C9823bF8723;
    
    address internal constant DSS_CRON_SEQUENCER             = 0x238b4E35dAed6100C6162fAE4510261f88996EC9;
    address internal immutable MCD_VEST_DAI                  = DssExecLib.getChangelogAddress("MCD_VEST_DAI");
    address internal immutable REGISTRY                      = DssExecLib.reg();
    address internal immutable MIP21_LIQUIDATION_ORACLE      = DssExecLib.getChangelogAddress("MIP21_LIQUIDATION_ORACLE");
    address internal immutable ESM                           = DssExecLib.getChangelogAddress("MCD_ESM");
    address internal immutable MCD_VAT                       = DssExecLib.vat();
    address internal immutable MCD_JUG                       = DssExecLib.jug();
    address internal immutable MCD_SPOT                      = DssExecLib.spotter();
    address internal immutable MCD_DAI                       = DssExecLib.dai();


    function onboardRWA014() internal {
        bytes32 ilk      = "RWA014-A";

        // Init the RwaLiquidationOracle
        RwaLiquidationLike(MIP21_LIQUIDATION_ORACLE).init(ilk, RWA014_A_INITIAL_PRICE, RWA014_DOC, RWA014_A_TAU);
        (, address pip, , ) = RwaLiquidationLike(MIP21_LIQUIDATION_ORACLE).ilks(ilk);

        // Init RWA014 in Vat
        Initializable(MCD_VAT).init(ilk);
        // Init RWA014 in Jug
        Initializable(MCD_JUG).init(ilk);

        // Allow RWA014 Join to modify Vat registry
        DssExecLib.authorize(MCD_VAT, MCD_JOIN_RWA014_A);

        // 500m debt ceiling
        DssExecLib.increaseIlkDebtCeiling(ilk, RWA014_A_LINE, /* _global = */ true);

        // Set price feed for RWA014
        DssExecLib.setContract(MCD_SPOT, ilk, "pip", pip);

        // Set minimum collateralization ratio
        DssExecLib.setIlkLiquidationRatio(ilk, RWA014_A_MAT);

        // Poke the spotter to pull in a price
        DssExecLib.updateCollateralPrice(ilk);

        // Give the urn permissions on the join adapter
        DssExecLib.authorize(MCD_JOIN_RWA014_A, RWA014_A_URN);

        // MCD_PAUSE_PROXY and OPERATOR permission on URN
        RwaUrnLike(RWA014_A_URN).hope(address(this));
        RwaUrnLike(RWA014_A_URN).hope(address(RWA014_A_OPERATOR));

        // MCD_PAUSE_PROXY and OPERATOR permission on RWA014_A_OUTPUT_CONDUIT
        RwaOutputConduitLike(RWA014_A_OUTPUT_CONDUIT).hope(address(this));
        RwaOutputConduitLike(RWA014_A_OUTPUT_CONDUIT).mate(address(this));
        RwaOutputConduitLike(RWA014_A_OUTPUT_CONDUIT).hope(RWA014_A_OPERATOR);
        RwaOutputConduitLike(RWA014_A_OUTPUT_CONDUIT).mate(RWA014_A_OPERATOR);
        // Coinbase custody whitelist for URN destination address
        RwaOutputConduitLike(RWA014_A_OUTPUT_CONDUIT).kiss(address(RWA014_A_COINBASE_CUSTODY));
        // Set "quitTo" address for RWA014_A_OUTPUT_CONDUIT
        RwaOutputConduitLike(RWA014_A_OUTPUT_CONDUIT).file("quitTo", RWA014_A_URN);

        // MCD_PAUSE_PROXY and OPERATOR permission on RWA014_A_INPUT_CONDUIT_URN
        RwaInputConduitLike(RWA014_A_INPUT_CONDUIT_URN).mate(address(this));
        RwaInputConduitLike(RWA014_A_INPUT_CONDUIT_URN).mate(RWA014_A_OPERATOR);
        // Set "quitTo" address for RWA014_A_INPUT_CONDUIT_URN
        RwaInputConduitLike(RWA014_A_INPUT_CONDUIT_URN).file("quitTo", RWA014_A_COINBASE_CUSTODY);

        // MCD_PAUSE_PROXY and OPERATOR permission on RWA014_A_INPUT_CONDUIT_JAR
        RwaInputConduitLike(RWA014_A_INPUT_CONDUIT_JAR).mate(address(this));
        RwaInputConduitLike(RWA014_A_INPUT_CONDUIT_JAR).mate(RWA014_A_OPERATOR);
        // Set "quitTo" address for RWA014_A_INPUT_CONDUIT_JAR
        RwaInputConduitLike(RWA014_A_INPUT_CONDUIT_JAR).file("quitTo", RWA014_A_COINBASE_CUSTODY);

        // Add RWA014 contract to the changelog
        DssExecLib.setChangelogAddress("RWA014",                     RWA014);
        DssExecLib.setChangelogAddress("PIP_RWA014",                 pip);
        DssExecLib.setChangelogAddress("MCD_JOIN_RWA014_A",          MCD_JOIN_RWA014_A);
        DssExecLib.setChangelogAddress("RWA014_A_URN",               RWA014_A_URN);
        DssExecLib.setChangelogAddress("RWA014_A_JAR",               RWA014_A_JAR);
        DssExecLib.setChangelogAddress("RWA014_A_INPUT_CONDUIT_URN", RWA014_A_INPUT_CONDUIT_URN);
        DssExecLib.setChangelogAddress("RWA014_A_INPUT_CONDUIT_JAR", RWA014_A_INPUT_CONDUIT_JAR);
        DssExecLib.setChangelogAddress("RWA014_A_OUTPUT_CONDUIT",    RWA014_A_OUTPUT_CONDUIT);

        // Add RWA014 to ILK REGISTRY
        IlkRegistryAbstract(REGISTRY).put(
            ilk,
            MCD_JOIN_RWA014_A,
            RWA014,
            GemAbstract(RWA014).decimals(),
            RWA014_REG_CLASS_RWA,
            pip,
            address(0),
            "RWA014-A: Coinbase Custody",
            GemAbstract(RWA014).symbol()
        );
    }

    function actions() public override {

        // ---------- RWA014-A Onboarding ----------
        // Poll: https://vote.makerdao.com/polling/QmdRELY7#poll-detail
        // Forum: https://forum.makerdao.com/t/coinbase-custody-legal-assessment/20384

        onboardRWA014();
        // Lock RWA014 Token in the URN
        GemAbstract(RWA014).approve(RWA014_A_URN, 1 * WAD);
        RwaUrnLike(RWA014_A_URN).lock(1 * WAD);

        // ----- Additional ESM authorization -----
        DssExecLib.authorize(MCD_JOIN_RWA014_A, ESM);
        DssExecLib.authorize(RWA014_A_URN, ESM);
        DssExecLib.authorize(RWA014_A_OUTPUT_CONDUIT, ESM);
        DssExecLib.authorize(RWA014_A_INPUT_CONDUIT_URN, ESM);
        DssExecLib.authorize(RWA014_A_INPUT_CONDUIT_JAR, ESM);

        // --------- Keeper Network Amendments ---------
        // Poll: https://vote.makerdao.com/polling/QmZZJcCj#poll-detail

        // Yank DAI stream ID 16 to Chainlink Automation - being replaced by new stream
        VestLike(MCD_VEST_DAI).yank(16);


        // GELATO    | 1,500 DAI/day | 1_644_000 DAI | 3 years | Vest Target: 0x0B5a34D084b6A5ae4361de033d1e6255623b41eD | Treasury: 0xbfDC6b9944B7EFdb1e2Bc9D55ae9424a2a55b206
        (,uint256 windowLengthGelato) = DssCronSequencerLike(DSS_CRON_SEQUENCER).windows(bytes32("GELATO"));
        require(windowLengthGelato == 13, "Gelato/incorrect-window-length");
        require(NetworkPaymentAdapterLike(GELATO_PAYMENT_ADAPTER).bufferMax() == 20_000 * WAD, "Gelato-Payment-Adapter/incorrect-buffer-max");
        require(NetworkPaymentAdapterLike(GELATO_PAYMENT_ADAPTER).minimumPayment() == 4_000 * WAD, "Gelato-Payment-Adapter/incorrect-minimum-payment");
        uint256 gelatoVestId = VestLike(MCD_VEST_DAI).create(
                GELATO_PAYMENT_ADAPTER,    // usr
                1_644_000 * WAD,           // tot
                MAY_24_2023,               // bgn
                MAY_23_2026 - MAY_24_2023, // tau
                0,                         // eta
                address(0)                 // mgr
        );
        VestLike(MCD_VEST_DAI).restrict(gelatoVestId);
        NetworkPaymentAdapterLike(GELATO_PAYMENT_ADAPTER).file("vestId", gelatoVestId);
        NetworkPaymentAdapterLike(GELATO_PAYMENT_ADAPTER).file("treasury", GELATO_TREASURY);

        // KEEP3R    | 1,500 DAI/day | 1_644_000 DAI | 3 years | Vest Target: 0xaeFed819b6657B3960A8515863abe0529Dfc444A | Treasury: 0x4DfC6DA2089b0dfCF04788b341197146Ea97f743
        (,uint256 windowLengthKeeper) = DssCronSequencerLike(DSS_CRON_SEQUENCER).windows(bytes32("KEEP3R"));
        require(windowLengthKeeper == 13, "Keep3r/incorrect-window-length");
        require(NetworkPaymentAdapterLike(KEEP3R_PAYMENT_ADAPTER).bufferMax() == 20_000 * WAD, "Keep3r-Payment-Adapter/incorrect-buffer-max");
        require(NetworkPaymentAdapterLike(KEEP3R_PAYMENT_ADAPTER).minimumPayment() == 4_000 * WAD, "Keep3r-Payment-Adapter/incorrect-minimum-payment");
        uint256 kepperVestId = VestLike(MCD_VEST_DAI).create(
                KEEP3R_PAYMENT_ADAPTER,    // usr
                1_644_000 * WAD,           // tot
                MAY_24_2023,               // bgn
                MAY_23_2026 - MAY_24_2023, // tau
                0,                         // eta
                address(0)                 // mgr
        );
        VestLike(MCD_VEST_DAI).restrict(kepperVestId);
        NetworkPaymentAdapterLike(KEEP3R_PAYMENT_ADAPTER).file("vestId", kepperVestId);
        NetworkPaymentAdapterLike(KEEP3R_PAYMENT_ADAPTER).file("treasury", KEEP3R_TREASURY);

        // CHAINLINK | 1,500 DAI/day | 1_644_000 DAI | 3 years | Vest Target: 0xfB5e1D841BDA584Af789bDFABe3c6419140EC065
        (,uint256 windowLengthChainlink) = DssCronSequencerLike(DSS_CRON_SEQUENCER).windows(bytes32("CHAINLINK"));
        require(windowLengthChainlink == 13, "Chainling/incorrect-window-length");
        require(NetworkPaymentAdapterLike(CHAINLINK_PAYMENT_ADAPTER).bufferMax() == 20_000 * WAD, "Chainlink-Payment-Adapter/incorrect-buffer-max");
        require(NetworkPaymentAdapterLike(CHAINLINK_PAYMENT_ADAPTER).minimumPayment() == 4_000 * WAD, "Chainlink-Payment-Adapter/incorrect-minimum-payment");
        uint256 chainlinkVestId = VestLike(MCD_VEST_DAI).create(
                CHAINLINK_PAYMENT_ADAPTER, // usr
                1_644_000 * WAD,           // tot
                MAY_24_2023,               // bgn
                MAY_23_2026 - MAY_24_2023, // tau
                0,                         // eta
                address(0)                 // mgr
        );
        VestLike(MCD_VEST_DAI).restrict(chainlinkVestId);
        NetworkPaymentAdapterLike(CHAINLINK_PAYMENT_ADAPTER).file("vestId", chainlinkVestId);

        // TECHOPS   | 1,000 DAI/day | 366_000 DAI   | 1 years | Vest Target: 0x5A6007d17302238D63aB21407FF600a67765f982
        VestLike(MCD_VEST_DAI).restrict(
            VestLike(MCD_VEST_DAI).create(
                TECHOPS_VEST_STREAMING,    // usr
                366_000 * WAD,             // tot
                MAY_24_2023,               // bgn
                MAY_23_2024 - MAY_24_2023, // tau
                0,                         // eta
                address(0)                 // mgr
            )
        );


        // --------- CAIS Bootstrap Funding ---------
        // Poll: https://vote.makerdao.com/polling/Qmc6Wqrc#poll-detail
        // CAIS Budget - 100,000 DAI - 0x6E51E0b5813152880C1389E3e860e69E06aD04D9
        DssExecLib.sendPaymentFromSurplusBuffer(ECOSYSTEM_SCOPE_WALLET, 100_000);


        // --------- Onboard GNO to Spark ---------
        // Poll: https://vote.makerdao.com/polling/QmXdGdxS#poll-detail
        // Forum: https://forum.makerdao.com/t/onboarding-of-gno-to-spark/20831
        // List of addresses: https://github.com/marsfoundation/sparklend/blob/master/script/output/5/spark-latest.json
        {
            // Whitelist the GNO Fig adapter
            MedianAbstract(GNO_MEDIANIZER).kiss(SPARK_GNO_ORACLE);

            // Set DAI as a borrowable asset in isolation mode
            PoolConfiguratorLike(SPARK_POOL_CONFIGURATOR).setBorrowableInIsolation(MCD_DAI, true);

            // Add GNO
            address token = DssExecLib.getChangelogAddress("GNO");
            PoolConfiguratorLike.InitReserveInput[] memory input = new PoolConfiguratorLike.InitReserveInput[](1);
            input[0] = PoolConfiguratorLike.InitReserveInput({
                aTokenImpl: SPARK_ATOKEN_IMPL,
                stableDebtTokenImpl: SPARK_STABLE_DEBT_TOKEN_IMPL,
                variableDebtTokenImpl: SPARK_VARIABLE_DEBT_TOKEN_IMPL,
                underlyingAssetDecimals: GemAbstract(token).decimals(),
                interestRateStrategyAddress: SPARK_INTEREST_RATE_STRATEGY,      // Dummy strategy - compare to other borrow-disabled asset like sDAI
                underlyingAsset: token,
                treasury: SPARK_TREASURY,
                incentivesController: address(0),
                aTokenName: "Spark GNO",
                aTokenSymbol: "spGNO",
                variableDebtTokenName: "Spark Variable Debt GNO",
                variableDebtTokenSymbol: "variableDebtGNO",
                stableDebtTokenName: "Spark Stable Debt GNO",
                stableDebtTokenSymbol: "stableDebtGNO",
                params: ""
            });
            PoolConfiguratorLike(SPARK_POOL_CONFIGURATOR).initReserves(input);
            PoolConfiguratorLike(SPARK_POOL_CONFIGURATOR).configureReserveAsCollateral({
                asset: token, 
                ltv: 20_00,
                liquidationThreshold: 25_00,
                liquidationBonus: 110_00
            });
            PoolConfiguratorLike(SPARK_POOL_CONFIGURATOR).setDebtCeiling(token, 5 * MILLION * HUNDRED);

            address[] memory tokens = new address[](1);
            tokens[0] = token;
            address[] memory oracles = new address[](1);
            oracles[0] = SPARK_GNO_ORACLE;
            AaveOracleLike(SPARK_AAVE_ORACLE).setAssetSources(
                tokens,
                oracles
            );
        }

        // Reduce Maker Protocol GNO Debt Ceiling to Zero
        (,,,uint256 line,) = VatLike(MCD_VAT).ilks("GNO-A");
        DssExecLib.removeIlkFromAutoLine("GNO-A");
        DssExecLib.decreaseIlkDebtCeiling("GNO-A", line / RAD, true);

        // Bump the chainlog
        DssExecLib.setChangelogVersion("1.14.12");
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) {}
}
