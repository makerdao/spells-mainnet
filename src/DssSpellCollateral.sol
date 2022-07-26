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
import "dss-interfaces/dapp/DSTokenAbstract.sol";
import "dss-interfaces/dss/ChainlogAbstract.sol";
import "dss-interfaces/dss/GemJoinAbstract.sol";
import "dss-interfaces/dss/IlkRegistryAbstract.sol";
import "dss-interfaces/ERC/GemAbstract.sol";

interface Initializeable {
    function init(bytes32) external;
}

interface RwaLiquidationLike {
    function ilks(bytes32) external returns (string memory, address, uint48, uint48);
    function init(bytes32, uint256, string calldata, uint48) external;
}

interface RwaUrnLike {
    function vat() external view returns(address);
    function jug() external view returns(address);
    function gemJoin() external view returns(address);
    function daiJoin() external view returns(address);
    function hope(address) external;
    function lock(uint256) external;
}

interface RwaOutputConduitLike {
    function hope(address) external;
    function mate(address) external;
}

interface RwaInputConduitLike {
    function mate(address usr) external;
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
    //    https://ipfs.io/ipfs/QmX2QMoM1SZq2XMoTbMak8pZP86Y2icpgPAKDjQg4r4YHn
    //

    uint256 constant ZERO_ZERO_FIVE_PCT_RATE = 1000000000015850933588756013;

    // --- Math ---
    uint256 public constant WAD = 10**18;
    uint256 public constant RAY = 10**27;
    uint256 public constant RAD = 10**45;

    // -- RWA008 MIP21 components --
    address constant RWA008                    = 0xb9737098b50d7c536b6416dAeB32879444F59fCA;
    address constant MCD_JOIN_RWA008_A         = 0xF4D4184413d97C8C8a4f0437AbEa711bc5991a7e;
    address constant RWA008_A_URN              = 0x593f2A49A7aA5e0c333edB4e3abB10654F68069c;
    address constant RWA008_A_URN_CLOSE_HELPER = 0xCfc4043675EE82EEAe63C90D6eb3aB2dcf833431;
    address constant RWA008_A_INPUT_CONDUIT    = 0x7032546Ba3F6E8866334556a354e67B905aA4470;
    address constant RWA008_A_OUTPUT_CONDUIT   = 0x21CF5Ad1311788D762f9035829f81B9f54610F0C;
    // SocGen's wallet
    address constant RWA008_A_OPERATOR         = 0x03f1A14A5b31e2f1751b6db368451dFCEA5A0439;
    // DIIS Group wallet
    address constant RWA008_A_MATE             = 0xb9444802F0831A3EB9f90E24EFe5FfA20138d684;

    string  constant RWA008_DOC                = "QmdfzY6p5EpkYMN8wcomF2a1GsJbhkPiRQVRYSPfS4NZtB";
    /**
     * The Future Value of the debt ceiling by the end of the agreement:
     *   - 30,000,00 USD: Debt Ceiling
     *   - 0.05% per year: Stability Fee
     *   - 2.9 years: Duration of the Loan
     *
     *     bc -l <<< 'scale=18; (30000000 * e( l(1.0005) * 2.9 ))'
     */
    uint256 constant RWA008_A_INITIAL_PRICE    = 30_043_520_665599336150000000;
    uint48  constant RWA008_A_TAU              = 0;

    // Ilk registry params
    uint256 constant RWA008_REG_CLASS_RWA      = 3;

    // Remaining params
    uint256 constant RWA008_A_LINE             = 30_000_000;
    uint256 constant RWA008_A_MAT              = 100_00; // 100% in basis-points
    uint256 constant RWA008_A_RATE             = ZERO_ZERO_FIVE_PCT_RATE;
    // -- RWA008 end --

    function onboardRwa008(
        ChainlogAbstract CHANGELOG,
        IlkRegistryAbstract REGISTRY,
        address MIP21_LIQUIDATION_ORACLE,
        address MCD_VAT,
        address MCD_JUG,
        address MCD_SPOT,
        address MCD_JOIN_DAI
    ) internal {
        // RWA008-A collateral deploy
        bytes32 ilk      = "RWA008-A";
        uint256 decimals = DSTokenAbstract(RWA008).decimals();

        // Sanity checks
        require(GemJoinAbstract(MCD_JOIN_RWA008_A).vat() == MCD_VAT,  "join-vat-not-match");
        require(GemJoinAbstract(MCD_JOIN_RWA008_A).ilk() == ilk,      "join-ilk-not-match");
        require(GemJoinAbstract(MCD_JOIN_RWA008_A).gem() == RWA008,   "join-gem-not-match");
        require(GemJoinAbstract(MCD_JOIN_RWA008_A).dec() == decimals, "join-dec-not-match");

        require(RwaUrnLike(RWA008_A_URN).vat() == MCD_VAT,               "urn-vat-not-match");
        require(RwaUrnLike(RWA008_A_URN).jug() == MCD_JUG,               "urn-jug-not-match");
        require(RwaUrnLike(RWA008_A_URN).daiJoin() == MCD_JOIN_DAI,      "urn-daijoin-not-match");
        require(RwaUrnLike(RWA008_A_URN).gemJoin() == MCD_JOIN_RWA008_A, "urn-gemjoin-not-match");

        // Init the RwaLiquidationOracle
        RwaLiquidationLike(MIP21_LIQUIDATION_ORACLE).init(ilk, RWA008_A_INITIAL_PRICE, RWA008_DOC, RWA008_A_TAU);
        (, address pip, , ) = RwaLiquidationLike(MIP21_LIQUIDATION_ORACLE).ilks(ilk);

        // Set price feed for RWA008
        DssExecLib.setContract(MCD_SPOT, ilk, "pip", pip);

        // Init RWA008 in Vat
        Initializable(MCD_VAT).init(ilk);
        // Init RWA008 in Jug
        Initializable(MCD_JUG).init(ilk);

        // Allow RWA008 Join to modify Vat registry
        DssExecLib.authorize(MCD_VAT, MCD_JOIN_RWA008_A);

        // Set the debt ceiling
        DssExecLib.increaseIlkDebtCeiling(ilk, RWA008_A_LINE, /* _global = */ true);

        // Set the stability fee
        DssExecLib.setIlkStabilityFee(ilk, RWA008_A_RATE, /* _doDrip = */ false);

        // Set the collateralization ratio
        DssExecLib.setIlkLiquidationRatio(ilk, RWA008_A_MAT);

        // Poke the spotter to pull in a price
        DssExecLib.updateCollateralPrice(ilk);

        // Give the urn permissions on the join adapter
        DssExecLib.authorize(MCD_JOIN_RWA008_A, RWA008_A_URN);

        // Helper contract permisison on URN
        RwaUrnLike(RWA008_A_URN).hope(RWA008_A_URN_CLOSE_HELPER);
        RwaUrnLike(RWA008_A_URN).hope(RWA008_A_OPERATOR);

        // Set up output conduit
        RwaOutputConduitLike(RWA008_A_OUTPUT_CONDUIT).hope(RWA008_A_OPERATOR);

        // Whitelist DIIS Group in the conduits
        RwaOutputConduitLike(RWA008_A_OUTPUT_CONDUIT).mate(RWA008_A_MATE);
        RwaInputConduitLike(RWA008_A_INPUT_CONDUIT)  .mate(RWA008_A_MATE);

        // Whitelist Socgen in the conduits as a fallback for DIIS Group
        RwaOutputConduitLike(RWA008_A_OUTPUT_CONDUIT).mate(RWA008_A_OPERATOR);
        RwaInputConduitLike(RWA008_A_INPUT_CONDUIT)  .mate(RWA008_A_OPERATOR);

        // Add RWA008 contract to the changelog
        CHANGELOG.setAddress("RWA008",                  RWA008);
        CHANGELOG.setAddress("PIP_RWA008",              pip);
        CHANGELOG.setAddress("MCD_JOIN_RWA008_A",       MCD_JOIN_RWA008_A);
        CHANGELOG.setAddress("RWA008_A_URN",            RWA008_A_URN);
        CHANGELOG.setAddress("RWA008_A_INPUT_CONDUIT",  RWA008_A_INPUT_CONDUIT);
        CHANGELOG.setAddress("RWA008_A_OUTPUT_CONDUIT", RWA008_A_OUTPUT_CONDUIT);

        REGISTRY.put(
            ilk,
            MCD_JOIN_RWA008_A,
            RWA008,
            decimals,
            RWA008_REG_CLASS_RWA,
            pip,
            address(0),
            "RWA008-A: SG Forge OFH",
            GemAbstract(RWA008).symbol()
        );
    }

    function onboardNewCollaterals() internal {
        ChainlogAbstract CHANGELOG       = ChainlogAbstract(DssExecLib.LOG);
        IlkRegistryAbstract REGISTRY     = IlkRegistryAbstract(DssExecLib.reg());
        address MIP21_LIQUIDATION_ORACLE = 0x88f88Bb9E66241B73B84f3A6E197FbBa487b1E30;
        address MCD_VAT                  = DssExecLib.vat();
        address MCD_JUG                  = DssExecLib.jug();
        address MCD_SPOT                 = DssExecLib.spotter();
        address MCD_JOIN_DAI             = DssExecLib.daiJoin();

        // --------------------------- RWA Collateral onboarding ---------------------------

        // Onboard SocGen: https://vote.makerdao.com/polling/QmajCtnG
        onboardRwa008(CHANGELOG, REGISTRY, MIP21_LIQUIDATION_ORACLE, MCD_VAT, MCD_JUG, MCD_SPOT, MCD_JOIN_DAI);
    }

    function offboardCollaterals() internal {}
}

