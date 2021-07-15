// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2021 Maker Ecosystem Growth Holdings, INC.
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

import "dss-exec-lib/DssExec.sol";
import "dss-exec-lib/DssAction.sol";
import "lib/dss-interfaces/src/dss/GemJoinAbstract.sol";
import "lib/dss-interfaces/src/dss/IlkRegistryAbstract.sol";
import "lib/dss-interfaces/src/dapp/DSTokenAbstract.sol";
import "./CentrifugeCollateralValues.sol";

interface Initializable {
    function init(bytes32) external;
}

interface Hopeable {
    function hope(address) external;
}

interface Kissable {
    function kiss(address) external;
}

interface RwaLiquidationLike {
    function ilks(bytes32) external returns (string memory,address,uint48,uint48);
    function init(bytes32, uint256, string calldata, uint48) external;
}

contract DssSpellAction is DssAction {

    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/2a7a8c915695b7298fe725ee3dc6c613fa9d9bbe/governance/votes/Executive%20vote%20-%20April%2012%2C%202021.md -q -O - 2>/dev/null)"
    string public constant description = "RWA003-RWA006 integration";

    // Many of the settings that change weekly rely on the rate accumulator
    // described at https://docs.makerdao.com/smart-contract-modules/rates-module
    // To check this yourself, use the following rate calculation (example 8%):
    //
    // $ bc -l <<< 'scale=27; e( l(1.08)/(60 * 60 * 24 * 365) )'
    //
    // A table of rates can be found at
    //    https://ipfs.io/ipfs/QmefQMseb3AiTapiAKKexdKHig8wroKuZbmLtPLv4u2YwW
    //
    uint256 constant TWO_PCT            = 1000000000627937192491029810;
    uint256 constant FOUR_PT_FIVE_PCT   = 1000000001395766281313196627;
    uint256 constant SIX_PCT            = 1000000001847694957439350562;
    uint256 constant SEVEN_PCT          = 1000000002145441671308778766;

    // Math
    uint256 constant THOUSAND = 10 ** 3;
    uint256 constant MILLION  = 10 ** 6;
    uint256 constant WAD      = 10 ** 18;
    uint256 constant RAY      = 10 ** 27;
    uint256 constant RAD      = 10 ** 45;

    // Maker changelog 
    address public constant MAKER_CHANGELOG = 0xdA0Ab1e0017DEbCd72Be8599041a2aa3bA7e740F;

    function actions() public override {
        CentrifugeCollateralValues memory RWA003 = CentrifugeCollateralValues({
            MCD_JOIN: 0x4CCc7fED3912A32B6Cf7Db2FdA1554a9FF574099,
            GEM: 0xDBC559F5058E593981C48f4f09fA34323df42d51,
            OPERATOR: 0x45e17E350279a2f28243983053B634897BA03b64,
            INPUT_CONDUIT: 0x45e17E350279a2f28243983053B634897BA03b64,
            OUTPUT_CONDUIT: 0x45e17E350279a2f28243983053B634897BA03b64,
            URN:  0x993c239179D6858769996bcAb5989ab2DF75913F,
            LIQ: 0x2881c5dF65A8D81e38f7636122aFb456514804CC,
            gemID: "RWA003",
            joinID: "MCD_JOIN_RWA003_A",
            urnID: "RWA003_A_URN",
            inputConduitID: "RWA003_A_INPUT_CONDUIT",
            outputConduitID: "RWA003_A_OUTPUT_CONDUIT",
            pipID: "PIP_RWA003",
            ilk: "RWA003-A",
            ilkRegistryName: "RWA003-A: Centrifuge: ConsolFreight",
            RATE: SIX_PCT,
            CEIL: 2 * MILLION,
            PRICE: 2_247_200 * WAD,
            MAT: 10_500,
            TAU: 0,
            DOC: ""
        });

        CentrifugeCollateralValues memory RWA004 = CentrifugeCollateralValues({
            MCD_JOIN: 0xa92D4082BabF785Ba02f9C419509B7d08f2ef271,
            GEM: 0x146b0abaB80a60Bfa3b4fDDb5056bBcFa4f1fec1,
            OPERATOR: 0x303dFE04Be5731207c5213FbB54488B3aD9B9FE3,
            INPUT_CONDUIT: 0x303dFE04Be5731207c5213FbB54488B3aD9B9FE3,
            OUTPUT_CONDUIT: 0x303dFE04Be5731207c5213FbB54488B3aD9B9FE3,
            URN:  0xf22C7F5A2AecE1E85263e3cec522BDCD3e392B59,
            LIQ: 0x2881c5dF65A8D81e38f7636122aFb456514804CC,
            gemID: "RWA004",
            joinID: "MCD_JOIN_RWA004_A",
            urnID: "RWA004_A_URN",
            inputConduitID: "RWA004_A_INPUT_CONDUIT",
            outputConduitID: "RWA004_A_OUTPUT_CONDUIT",
            pipID: "PIP_RWA004",
            ilk: "RWA004-A",
            ilkRegistryName: "RWA004-A: Centrifuge: Harbor Trade Credit",
            RATE: SEVEN_PCT,
            CEIL: 7 * MILLION,
            PRICE: 8_014_300 * WAD,
            MAT: 11_000,
            TAU: 0,
            DOC: ""
        });

        CentrifugeCollateralValues memory RWA005 = CentrifugeCollateralValues({
            MCD_JOIN: 0x1233d0DBb55A4Bb41D711d4B584f8DDB15A2Ff88,
            GEM: 0xcB2A48D26970eE7193d66BAc6F1b3090f2E8f82B,
            OPERATOR: 0x17E5954Cdd3611Dd84e444F0ed555CC3a06cB319,
            INPUT_CONDUIT: 0x17E5954Cdd3611Dd84e444F0ed555CC3a06cB319,
            OUTPUT_CONDUIT: 0x17E5954Cdd3611Dd84e444F0ed555CC3a06cB319,
            URN:  0xdB9f0700EbBac596CCeF5b14D5e23664Db2A184f,
            LIQ: 0x2881c5dF65A8D81e38f7636122aFb456514804CC,
            gemID: "RWA005",
            joinID: "MCD_JOIN_RWA005_A",
            urnID: "RWA005_A_URN",
            inputConduitID: "RWA005_A_INPUT_CONDUIT",
            outputConduitID: "RWA005_A_OUTPUT_CONDUIT",
            pipID: "PIP_RWA005",
            ilk: "RWA005-A",
            ilkRegistryName: "RWA005-A: Centrifuge: Fortunafi",
            RATE: FOUR_PT_FIVE_PCT,
            CEIL: 15 * MILLION,
            PRICE: 16_380_375 * WAD,
            MAT: 10_500,
            TAU: 0,
            DOC: ""
        });

        CentrifugeCollateralValues memory RWA006 = CentrifugeCollateralValues({
            MCD_JOIN: 0x039B74bD0Adc35046B67E88509900D41b9D95430,
            GEM: 0x4E65F06574F1630B4fF756C898Fe02f276D53E86,
            OPERATOR: 0x652A3B3b91459504A8D1d785B0c923A34D638218,
            INPUT_CONDUIT: 0x652A3B3b91459504A8D1d785B0c923A34D638218,
            OUTPUT_CONDUIT: 0x652A3B3b91459504A8D1d785B0c923A34D638218,
            URN:  0x6fa6F9C11f5F129f6ECA4B391D9d32038A9666cD,
            LIQ: 0x2881c5dF65A8D81e38f7636122aFb456514804CC,
            gemID: "RWA006",
            joinID: "MCD_JOIN_RWA006_A",
            urnID: "RWA006_A_URN",
            inputConduitID: "RWA006_A_INPUT_CONDUIT",
            outputConduitID: "RWA006_A_OUTPUT_CONDUIT",
            pipID: "PIP_RWA006",
            ilk: "RWA006-A",
            ilkRegistryName: "RWA006-A: Centrifuge: Peoples Company",
            RATE: TWO_PCT,
            CEIL: 20 * MILLION,
            PRICE: 20_808_000 * WAD,
            MAT: 10_000,
            TAU: 0,
            DOC: ""
        });

        CentrifugeCollateralValues[4] memory collaterals = [RWA003, RWA004, RWA005, RWA006];

        // integrate rwa003-006
        for (uint i = 0; i < collaterals.length; i++) {
            integrateCentrifugeCollateral(collaterals[i]);
        }

        // increase debt ceiling of RWA002 from 5M to 20M
        DssExecLib.increaseGlobalDebtCeiling(15 * MILLION);
        DssExecLib.setIlkDebtCeiling("RWA002-A", 20 * MILLION);

        // bump changelog version
        DssExecLib.setChangelogVersion("1.1.x");
    }

    function integrateCentrifugeCollateral(CentrifugeCollateralValues memory collateral) internal {
        address MIP21_LIQUIDATION_ORACLE =
            DssExecLib.getChangelogAddress("MIP21_LIQUIDATION_ORACLE");

        address vat = DssExecLib.vat();

        // Sanity checks
        require(GemJoinAbstract(collateral.MCD_JOIN).vat() == vat, "join-vat-not-match");
        require(GemJoinAbstract(collateral.MCD_JOIN).ilk() == collateral.ilk, "join-ilk-not-match");
        require(GemJoinAbstract(collateral.MCD_JOIN).gem() == collateral.GEM, "join-gem-not-match");
        require(GemJoinAbstract(collateral.MCD_JOIN).dec() == DSTokenAbstract(collateral.GEM).decimals(), "join-dec-not-match");

        RwaLiquidationLike(MIP21_LIQUIDATION_ORACLE).init(
            collateral.ilk, collateral.PRICE, collateral.DOC, collateral.TAU
        );
        (,address pip,,) = RwaLiquidationLike(MIP21_LIQUIDATION_ORACLE).ilks(collateral.ilk);

        // Set price feed for RWA003
        DssExecLib.setContract(DssExecLib.spotter(), collateral.ilk, "pip", pip);

        // Init RWA-00x in Vat
        Initializable(vat).init(collateral.ilk);
        // Init RWA-00x in Jug
        Initializable(DssExecLib.jug()).init(collateral.ilk);

        // Allow RWA-00x Join to modify Vat registry
        DssExecLib.authorize(vat, collateral.MCD_JOIN);

        // Allow RwaLiquidationOracle to modify Vat registry
        // DssExecLib.authorize(vat, MIP21_LIQUIDATION_ORACLE);

        // Increase the global debt ceiling by the ilk ceiling
        DssExecLib.increaseGlobalDebtCeiling(collateral.CEIL);
        // Set the ilk debt ceiling
        DssExecLib.setIlkDebtCeiling(collateral.ilk, collateral.CEIL);

        // No dust
        // DssExecLib.setIlkMinVaultAmount(collateral.ilk, 0);

        // stability fee
        DssExecLib.setIlkStabilityFee(collateral.ilk, collateral.RATE, false);

        // collateralization ratio
        DssExecLib.setIlkLiquidationRatio(collateral.ilk, collateral.MAT);

        // poke the spotter to pull in a price
        DssExecLib.updateCollateralPrice(collateral.ilk);

        // give the urn permissions on the join adapter
        // DssExecLib.authorize(collateral.MCD_JOIN, collateral.URN);

        // set up the urn
        Hopeable(collateral.URN).hope(collateral.OPERATOR);

        // set up output conduit
        // Hopeable(collateral.OUTPUT_CONDUIT).hope(collateral.OPERATOR));

        // Authorize the SC Domain team deployer address on the output conduit
        // during introductory phase. This allows the SC team to assist in the
        // testing of a complete circuit. Once a broker dealer arrangement is
        // established the deployer address should be `deny`ed on the conduit.
        // Kissable(collateral.OUTPUT_CONDUIT).kiss(SC_DOMAIN_DEPLOYER_07);

        // add RWA-00x contract to the changelog
        DssExecLib.setChangelogAddress(collateral.gemID, collateral.GEM);
        DssExecLib.setChangelogAddress(collateral.pipID, pip);
        DssExecLib.setChangelogAddress(collateral.joinID, collateral.MCD_JOIN);
        DssExecLib.setChangelogAddress(collateral.urnID, collateral.URN);
        DssExecLib.setChangelogAddress(
            collateral.inputConduitID, collateral.INPUT_CONDUIT
        );
        DssExecLib.setChangelogAddress(
            collateral.outputConduitID, collateral.OUTPUT_CONDUIT
        );

        address ILK_REGISTRY = DssExecLib.getChangelogAddress("ILK_REGISTRY");
        IlkRegistryAbstract(ILK_REGISTRY).put(
            collateral.ilk,
            collateral.MCD_JOIN,
            collateral.GEM,
            DSTokenAbstract(collateral.GEM).decimals(),
            3,
            pip,
            address(0),
            collateral.ilkRegistryName,
            bytes32ToStr(collateral.ilk)
        );
    }

    function bytes32ToStr(bytes32 _bytes32) internal pure returns (string memory) {
        bytes memory bytesArray = new bytes(32);
        for (uint256 i; i < 32; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return string(bytesArray);
    }

}

contract DssSpell is DssExec {
    DssSpellAction internal action_ = new DssSpellAction();
    constructor() DssExec(action_.description(), block.timestamp + 30 days, address(action_)) public {}
}