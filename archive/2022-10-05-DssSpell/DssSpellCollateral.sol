// SPDX-FileCopyrightText: © 2022 Dai Foundation <www.daifoundation.org>
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

import "dss-exec-lib/DssExecLib.sol";
import "dss-interfaces/dss/GemJoinAbstract.sol";
import "dss-interfaces/dss/IlkRegistryAbstract.sol";
import "dss-interfaces/ERC/GemAbstract.sol";

interface RwaLiquidationLike {
    function ilks(bytes32) external returns (string memory, address, uint48, uint48);
    function init(bytes32, uint256, string calldata, uint48) external;
}

interface RwaUrnLike {
    function vat() external view returns(address);
    function jug() external view returns(address);
    function gemJoin() external view returns(address);
    function daiJoin() external view returns(address);
    function outputConduit() external view returns(address);
    function hope(address) external;
}

interface RwaJarLike {
    function chainlog() external view returns(address);
    function dai() external view returns(address);
    function daiJoin() external view returns(address);
}

interface RwaOutputConduitLike {
    function dai() external view returns(address);
    function gem() external view returns(address);
    function psm() external view returns(address);
    function file(bytes32 what, address data) external;
    function hope(address) external;
    function mate(address) external;
    function kiss(address) external;
}

interface RwaInputConduitLike {
    function dai() external view returns(address);
    function gem() external view returns(address);
    function psm() external view returns(address);
    function to() external view returns(address);
    function mate(address usr) external;
    function file(bytes32 what, address data) external;
}
contract DssSpellCollateralAction {
    // --- Rates ---
    // Many of the settings that change weekly rely on the rate accumulator
    // described at https://docs.makerdao.com/smart-contract-modules/rates-module
    // To check this yourself, use the following rate calculation (example 8%):
    //
    // $ bc -l <<< 'scale=27; e( l(1.08)/(60 * 60 * 24 * 365) )'
    //
    // A table of rates can be found at
    //    https://ipfs.io/ipfs/QmVp4mhhbwWGTfbh2BzwQB9eiBrQBKiqcPRZCaAxNUaar6

    // --- Math ---
    uint256 internal constant WAD = 10**18;

    // -- RWA007 MIP21 components --
    address internal constant RWA007                         = 0x078fb926b041a816FaccEd3614Cf1E4bc3C723bD;
    address internal constant MCD_JOIN_RWA007_A              = 0x476aaD14F42469989EFad0b7A31f07b795FF0621;
    address internal constant RWA007_A_URN                   = 0x481bA2d2e86a1c41427893899B5B0cEae41c6726;
    address internal constant RWA007_A_JAR                   = 0xef1B095F700BE471981aae025f92B03091c3AD47;
    // Goerli: Coinbase / Mainnet: Coinbase
    address internal constant RWA007_A_OUTPUT_CONDUIT        = 0x701C3a384c613157bf473152844f368F2d6EF191;
    // Jar and URN Input Conduits
    address internal constant RWA007_A_INPUT_CONDUIT_URN     = 0x58f5e979eF74b60a9e5F955553ab8e0e65ba89c9;
    address internal constant RWA007_A_INPUT_CONDUIT_JAR     = 0xc8bb4e2B249703640e89265e2Ae7c9D5eA2aF742;

    // MIP21_LIQUIDATION_ORACLE params

    // https://gateway.pinata.cloud/ipfs/QmRLwB7Ty3ywSzq17GdDdwHvsZGwBg79oUTpSTJGtodToY
    string  internal constant RWA007_DOC                     = "QmRLwB7Ty3ywSzq17GdDdwHvsZGwBg79oUTpSTJGtodToY";
    // There is no DssExecLib helper, so WAD precision is used.
    uint256 internal constant RWA007_A_INITIAL_PRICE         = 250_000_000 * WAD;
    uint48  internal constant RWA007_A_TAU                   = 0;

    // Ilk registry params
    uint256 internal constant RWA007_REG_CLASS_RWA           = 3;

    // Remaining params
    uint256 internal constant RWA007_A_LINE                  = 1_000_000;
    uint256 internal constant RWA007_A_MAT                   = 100_00; // 100% in basis-points

    // Monetalis operator address
    address internal constant RWA007_A_OPERATOR              = 0x94cfBF071f8be325A5821bFeAe00eEbE9CE7c279;
    // Coinbase custody address
    address internal constant RWA007_A_COINBASE_CUSTODY      = 0xC3acf3B96E46Aa35dBD2aA3BD12D23c11295E774;

    // -- RWA007 END --

    function onboardRwa007(
        IlkRegistryAbstract REGISTRY,
        address MIP21_LIQUIDATION_ORACLE,
        address MCD_VAT,
        address MCD_JUG,
        address MCD_SPOT,
        address MCD_JOIN_DAI,
        address MCD_PSM_USDC_A
    ) internal {
        // RWA007-A collateral deploy
        bytes32 ilk      = "RWA007-A";
        uint256 decimals = GemAbstract(RWA007).decimals();

        // Sanity checks
        require(GemJoinAbstract(MCD_JOIN_RWA007_A).vat()                             == MCD_VAT,                                    "join-vat-not-match");
        require(GemJoinAbstract(MCD_JOIN_RWA007_A).ilk()                             == ilk,                                        "join-ilk-not-match");
        require(GemJoinAbstract(MCD_JOIN_RWA007_A).gem()                             == RWA007,                                     "join-gem-not-match");
        require(GemJoinAbstract(MCD_JOIN_RWA007_A).dec()                             == decimals,                                   "join-dec-not-match");

        require(RwaUrnLike(RWA007_A_URN).vat()                                       == MCD_VAT,                                    "urn-vat-not-match");
        require(RwaUrnLike(RWA007_A_URN).jug()                                       == MCD_JUG,                                    "urn-jug-not-match");
        require(RwaUrnLike(RWA007_A_URN).daiJoin()                                   == MCD_JOIN_DAI,                               "urn-daijoin-not-match");
        require(RwaUrnLike(RWA007_A_URN).gemJoin()                                   == MCD_JOIN_RWA007_A,                          "urn-gemjoin-not-match");
        require(RwaUrnLike(RWA007_A_URN).outputConduit()                             == RWA007_A_OUTPUT_CONDUIT,                    "urn-outputconduit-not-match");
        
        require(RwaJarLike(RWA007_A_JAR).chainlog()                                  == DssExecLib.LOG,                             "jar-chainlog-not-match");
        require(RwaJarLike(RWA007_A_JAR).dai()                                       == DssExecLib.dai(),                           "jar-dai-not-match");
        require(RwaJarLike(RWA007_A_JAR).daiJoin()                                   == MCD_JOIN_DAI,                               "jar-daijoin-not-match");

        require(RwaOutputConduitLike(RWA007_A_OUTPUT_CONDUIT).dai()                  == DssExecLib.dai(),                           "output-conduit-dai-not-match");
        require(RwaOutputConduitLike(RWA007_A_OUTPUT_CONDUIT).gem()                  == DssExecLib.getChangelogAddress("USDC"),     "output-conduit-gem-not-match");
        require(RwaOutputConduitLike(RWA007_A_OUTPUT_CONDUIT).psm()                  == MCD_PSM_USDC_A,                             "output-conduit-psm-not-match");
        
        require(RwaInputConduitLike(RWA007_A_INPUT_CONDUIT_URN).psm()                == MCD_PSM_USDC_A,                             "input-conduit-urn-psm-not-match");
        require(RwaInputConduitLike(RWA007_A_INPUT_CONDUIT_URN).to()                 == RWA007_A_URN,                               "input-conduit-urn-to-not-match");
        require(RwaInputConduitLike(RWA007_A_INPUT_CONDUIT_URN).dai()                == DssExecLib.dai(),                           "input-conduit-urn-dai-not-match");
        require(RwaInputConduitLike(RWA007_A_INPUT_CONDUIT_URN).gem()                == DssExecLib.getChangelogAddress("USDC"),     "input-conduit-urn-gem-not-match");

        require(RwaInputConduitLike(RWA007_A_INPUT_CONDUIT_JAR).psm()                == MCD_PSM_USDC_A,                             "input-conduit-jar-psm-not-match");
        require(RwaInputConduitLike(RWA007_A_INPUT_CONDUIT_JAR).to()                 == RWA007_A_JAR,                               "input-conduit-jar-to-not-match");
        require(RwaInputConduitLike(RWA007_A_INPUT_CONDUIT_JAR).dai()                == DssExecLib.dai(),                           "input-conduit-jar-dai-not-match");
        require(RwaInputConduitLike(RWA007_A_INPUT_CONDUIT_JAR).gem()                == DssExecLib.getChangelogAddress("USDC"),     "input-conduit-jar-gem-not-match");


        // Init the RwaLiquidationOracle
        RwaLiquidationLike(MIP21_LIQUIDATION_ORACLE).init(ilk, RWA007_A_INITIAL_PRICE, RWA007_DOC, RWA007_A_TAU);
        (, address pip, , ) = RwaLiquidationLike(MIP21_LIQUIDATION_ORACLE).ilks(ilk);

        // Init RWA007 in Vat
        Initializable(MCD_VAT).init(ilk);
        // Init RWA007 in Jug
        Initializable(MCD_JUG).init(ilk);

        // Allow RWA007 Join to modify Vat registry
        DssExecLib.authorize(MCD_VAT, MCD_JOIN_RWA007_A);

        // 1m debt ceiling
        DssExecLib.increaseIlkDebtCeiling(ilk, RWA007_A_LINE, /* _global = */ true);

        // Set price feed for RWA007
        DssExecLib.setContract(MCD_SPOT, ilk, "pip", pip);

        // Set collateralization ratio
        DssExecLib.setIlkLiquidationRatio(ilk, RWA007_A_MAT);

        // Poke the spotter to pull in a price
        DssExecLib.updateCollateralPrice(ilk);

        // Give the urn permissions on the join adapter
        DssExecLib.authorize(MCD_JOIN_RWA007_A, RWA007_A_URN);

        // MCD_PAUSE_PROXY and Monetalis permission on URN
        RwaUrnLike(RWA007_A_URN).hope(address(this));
        RwaUrnLike(RWA007_A_URN).hope(address(RWA007_A_OPERATOR));

        // MCD_PAUSE_PROXY and Monetalis permission on RWA007_A_OUTPUT_CONDUIT
        RwaOutputConduitLike(RWA007_A_OUTPUT_CONDUIT).hope(address(this));
        RwaOutputConduitLike(RWA007_A_OUTPUT_CONDUIT).mate(address(this));
        RwaOutputConduitLike(RWA007_A_OUTPUT_CONDUIT).hope(RWA007_A_OPERATOR);
        RwaOutputConduitLike(RWA007_A_OUTPUT_CONDUIT).mate(RWA007_A_OPERATOR);
        // Coinbase custody whitelist for URN destination address
        RwaOutputConduitLike(RWA007_A_OUTPUT_CONDUIT).kiss(address(RWA007_A_COINBASE_CUSTODY));
        // Set "quitTo" address for RWA007_A_OUTPUT_CONDUIT
        RwaOutputConduitLike(RWA007_A_OUTPUT_CONDUIT).file("quitTo", RWA007_A_URN);

        // MCD_PAUSE_PROXY and Monetalis permission on RWA007_A_INPUT_CONDUIT_URN
        RwaInputConduitLike(RWA007_A_INPUT_CONDUIT_URN).mate(address(this));
        RwaInputConduitLike(RWA007_A_INPUT_CONDUIT_URN).mate(RWA007_A_OPERATOR);
        // Set "quitTo" address for RWA007_A_INPUT_CONDUIT_URN
        RwaInputConduitLike(RWA007_A_INPUT_CONDUIT_URN).file("quitTo", RWA007_A_COINBASE_CUSTODY);

        // MCD_PAUSE_PROXY and Monetalis permission on RWA007_A_INPUT_CONDUIT_JAR
        RwaInputConduitLike(RWA007_A_INPUT_CONDUIT_JAR).mate(address(this));
        RwaInputConduitLike(RWA007_A_INPUT_CONDUIT_JAR).mate(RWA007_A_OPERATOR);
        // Set "quitTo" address for RWA007_A_INPUT_CONDUIT_JAR
        RwaInputConduitLike(RWA007_A_INPUT_CONDUIT_JAR).file("quitTo", RWA007_A_COINBASE_CUSTODY);

        // Add RWA007 contract to the changelog
        DssExecLib.setChangelogAddress("RWA007",                     RWA007);
        DssExecLib.setChangelogAddress("PIP_RWA007",                 pip);
        DssExecLib.setChangelogAddress("MCD_JOIN_RWA007_A",          MCD_JOIN_RWA007_A);
        DssExecLib.setChangelogAddress("RWA007_A_URN",               RWA007_A_URN);
        DssExecLib.setChangelogAddress("RWA007_A_JAR",               RWA007_A_JAR);
        DssExecLib.setChangelogAddress("RWA007_A_INPUT_CONDUIT_URN", RWA007_A_INPUT_CONDUIT_URN);
        DssExecLib.setChangelogAddress("RWA007_A_INPUT_CONDUIT_JAR", RWA007_A_INPUT_CONDUIT_JAR);
        DssExecLib.setChangelogAddress("RWA007_A_OUTPUT_CONDUIT",    RWA007_A_OUTPUT_CONDUIT);

        // Add RWA007 to ILK REGISTRY
        REGISTRY.put(
            ilk,
            MCD_JOIN_RWA007_A,
            RWA007,
            decimals,
            RWA007_REG_CLASS_RWA,
            pip,
            address(0),
            "RWA007-A: Monetalis Clydesdale",
            GemAbstract(RWA007).symbol()
        );
    }

    function onboardNewCollaterals() internal {
        IlkRegistryAbstract REGISTRY     = IlkRegistryAbstract(DssExecLib.reg());
        address MIP21_LIQUIDATION_ORACLE = DssExecLib.getChangelogAddress("MIP21_LIQUIDATION_ORACLE");
        address MCD_PSM_USDC_A           = DssExecLib.getChangelogAddress("MCD_PSM_USDC_A");
        address MCD_VAT                  = DssExecLib.vat();
        address MCD_JUG                  = DssExecLib.jug();
        address MCD_SPOT                 = DssExecLib.spotter();
        address MCD_JOIN_DAI             = DssExecLib.daiJoin();

        // --------------------------- RWA Collateral onboarding ---------------------------

        // Onboard Monetalis: https://vote.makerdao.com/polling/QmXHM6us
        onboardRwa007(REGISTRY, MIP21_LIQUIDATION_ORACLE, MCD_VAT, MCD_JUG, MCD_SPOT, MCD_JOIN_DAI, MCD_PSM_USDC_A);
    }
}
