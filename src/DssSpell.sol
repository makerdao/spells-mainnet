// SPDX-License-Identifier: GPL-3.0-or-later
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
pragma solidity 0.6.11;

import "dss-exec-lib/DssExec.sol";
import "dss-exec-lib/DssAction.sol";
import "lib/dss-interfaces/src/dss/GemJoinAbstract.sol";
import "lib/dss-interfaces/src/dapp/DSTokenAbstract.sol";

interface Initializable {
    function init(bytes32) external;
}

interface Hopeable {
    function hope(address) external;
}

interface RwaLiquidationLike {
    function ilks(bytes32) external returns (bytes32,address,uint48,uint48);
    function init(bytes32, uint256, string calldata, uint48) external;
}

contract DssSpellAction is DssAction {

    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/5925c52da6f8d485447228ca5acd435997522de6/governance/votes/Executive%20vote%20-%20March%205%2C%202021.md -q -O - 2>/dev/null)"
    string public constant description =
        "2021-03-05 MakerDAO Executive Spell | Hash: 0xb9829a5159cc2270de0592c8fcb9f7cbcc79491e26ad7ded78afb7994227f18b";


    // Many of the settings that change weekly rely on the rate accumulator
    // described at https://docs.makerdao.com/smart-contract-modules/rates-module
    // To check this yourself, use the following rate calculation (example 8%):
    //
    // $ bc -l <<< 'scale=27; e( l(1.08)/(60 * 60 * 24 * 365) )'
    //
    // A table of rates can be found at
    //    https://ipfs.io/ipfs/QmefQMseb3AiTapiAKKexdKHig8wroKuZbmLtPLv4u2YwW
    //
    uint256 constant THREE_PCT_RATE  = 1000000000937303470807876289;

    uint256 constant WAD        = 10**18;
    uint256 constant RAD        = 10**45;

    address constant RWA001_OPERATOR           = 0x7709f0840097170E5cB1F8c890AcB8601d73b35f;
    address constant RWA001_GEM                = 0x10b2aA5D77Aa6484886d8e244f0686aB319a270d;
    address constant MCD_JOIN_RWA001_A         = 0x476b81c12Dc71EDfad1F64B9E07CaA60F4b156E2;
    address constant RWA001_A_URN              = 0xa3342059BcDcFA57a13b12a35eD4BBE59B873005;
    address constant RWA001_A_INPUT_CONDUIT    = 0x486C85e2bb9801d14f6A8fdb78F5108a0fd932f2;
    address constant RWA001_A_OUTPUT_CONDUIT   = 0xb3eFb912e1cbC0B26FC17388Dd433Cecd2206C3d;
    address constant MIP21_LIQUIDATION_ORACLE  = 0x88f88Bb9E66241B73B84f3A6E197FbBa487b1E30;

    uint256 constant RWA001_A_INITIAL_PRICE = 1060 * WAD;


    // MIP13c3-SP4 Declaration of Intent & Commercial Points -
    //   Off-Chain Asset Backed Lender to onboard Real World Assets
    //   as Collateral for a DAI loan
    //
    // https://ipfs.io/ipfs/QmdmAUTU3sd9VkdfTZNQM6krc9jsKgF2pz7W1qvvfJo1xk
    string constant DOC = "QmdmAUTU3sd9VkdfTZNQM6krc9jsKgF2pz7W1qvvfJo1xk";

    function actions() public override {

        // Increase ETH-A target available debt (gap) from 30M to 80M
        DssExecLib.setIlkAutoLineParameters("ETH-A", 2_500 * MILLION, 80 * MILLION, 12 hours);

        // Decrease the bid duration (ttl) and max auction duration (tau) from 6 to 4 hours to all the ilks with liquidation on
        DssExecLib.setIlkBidDuration("ETH-A", 4 hours);
        DssExecLib.setIlkAuctionDuration("ETH-A", 4 hours);
        DssExecLib.setIlkBidDuration("ETH-B", 4 hours);
        DssExecLib.setIlkAuctionDuration("ETH-B", 4 hours);
        DssExecLib.setIlkBidDuration("BAT-A", 4 hours);
        DssExecLib.setIlkAuctionDuration("BAT-A", 4 hours);
        DssExecLib.setIlkBidDuration("WBTC-A", 4 hours);
        DssExecLib.setIlkAuctionDuration("WBTC-A", 4 hours);
        DssExecLib.setIlkBidDuration("KNC-A", 4 hours);
        DssExecLib.setIlkAuctionDuration("KNC-A", 4 hours);
        DssExecLib.setIlkBidDuration("ZRX-A", 4 hours);
        DssExecLib.setIlkAuctionDuration("ZRX-A", 4 hours);
        DssExecLib.setIlkBidDuration("MANA-A", 4 hours);
        DssExecLib.setIlkAuctionDuration("MANA-A", 4 hours);
        DssExecLib.setIlkBidDuration("USDT-A", 4 hours);
        DssExecLib.setIlkAuctionDuration("USDT-A", 4 hours);
        DssExecLib.setIlkBidDuration("COMP-A", 4 hours);
        DssExecLib.setIlkAuctionDuration("COMP-A", 4 hours);
        DssExecLib.setIlkBidDuration("LRC-A", 4 hours);
        DssExecLib.setIlkAuctionDuration("LRC-A", 4 hours);
        DssExecLib.setIlkBidDuration("LINK-A", 4 hours);
        DssExecLib.setIlkAuctionDuration("LINK-A", 4 hours);
        DssExecLib.setIlkBidDuration("BAL-A", 4 hours);
        DssExecLib.setIlkAuctionDuration("BAL-A", 4 hours);
        DssExecLib.setIlkBidDuration("YFI-A", 4 hours);
        DssExecLib.setIlkAuctionDuration("YFI-A", 4 hours);
        DssExecLib.setIlkBidDuration("UNI-A", 4 hours);
        DssExecLib.setIlkAuctionDuration("UNI-A", 4 hours);
        DssExecLib.setIlkBidDuration("RENBTC-A", 4 hours);
        DssExecLib.setIlkAuctionDuration("RENBTC-A", 4 hours);
        DssExecLib.setIlkBidDuration("AAVE-A", 4 hours);
        DssExecLib.setIlkAuctionDuration("AAVE-A", 4 hours);
        DssExecLib.setIlkBidDuration("UNIV2DAIETH-A", 4 hours);
        DssExecLib.setIlkAuctionDuration("UNIV2DAIETH-A", 4 hours);
        DssExecLib.setIlkBidDuration("UNIV2WBTCETH-A", 4 hours);
        DssExecLib.setIlkAuctionDuration("UNIV2WBTCETH-A", 4 hours);
        DssExecLib.setIlkBidDuration("UNIV2USDCETH-A", 4 hours);
        DssExecLib.setIlkAuctionDuration("UNIV2USDCETH-A", 4 hours);
        DssExecLib.setIlkBidDuration("UNIV2DAIUSDC-A", 4 hours);
        DssExecLib.setIlkAuctionDuration("UNIV2DAIUSDC-A", 4 hours);
        DssExecLib.setIlkBidDuration("UNIV2ETHUSDT-A", 4 hours);
        DssExecLib.setIlkAuctionDuration("UNIV2ETHUSDT-A", 4 hours);
        DssExecLib.setIlkBidDuration("UNIV2LINKETH-A", 4 hours);
        DssExecLib.setIlkAuctionDuration("UNIV2LINKETH-A", 4 hours);
        DssExecLib.setIlkBidDuration("UNIV2UNIETH-A", 4 hours);
        DssExecLib.setIlkAuctionDuration("UNIV2UNIETH-A", 4 hours);
        DssExecLib.setIlkBidDuration("UNIV2WBTCDAI-A", 4 hours);
        DssExecLib.setIlkAuctionDuration("UNIV2WBTCDAI-A", 4 hours);
        DssExecLib.setIlkBidDuration("UNIV2AAVEETH-A", 4 hours);
        DssExecLib.setIlkAuctionDuration("UNIV2AAVEETH-A", 4 hours);
        DssExecLib.setIlkBidDuration("UNIV2DAIUSDT-A", 4 hours);
        DssExecLib.setIlkAuctionDuration("UNIV2DAIUSDT-A", 4 hours);

        // Increase the box parameter from 15M to 20M
        DssExecLib.setMaxTotalDAILiquidationAmount(20 * MILLION);

        // Increase the minimum bid increment (beg) from 3% to 5% for the following collaterals
        DssExecLib.setIlkMinAuctionBidIncrease("ETH-B", 500);
        DssExecLib.setIlkMinAuctionBidIncrease("UNIV2USDCETH-A", 500);
        DssExecLib.setIlkMinAuctionBidIncrease("UNIV2WBTCETH-A", 500);
        DssExecLib.setIlkMinAuctionBidIncrease("UNIV2DAIUSDC-A", 500);
        DssExecLib.setIlkMinAuctionBidIncrease("UNIV2DAIETH-A", 500);
        DssExecLib.setIlkMinAuctionBidIncrease("UNIV2UNIETH-A", 500);
        DssExecLib.setIlkMinAuctionBidIncrease("UNIV2ETHUSDT-A", 500);
        DssExecLib.setIlkMinAuctionBidIncrease("UNIV2LINKETH-A", 500);
        DssExecLib.setIlkMinAuctionBidIncrease("UNIV2WBTCDAI-A", 500);
        DssExecLib.setIlkMinAuctionBidIncrease("UNIV2AAVEETH-A", 500);
        DssExecLib.setIlkMinAuctionBidIncrease("UNIV2DAIUSDT-A", 500);

        // RWA001-A collateral deploy
        bytes32 ilk = "RWA001-A";

        address vat = DssExecLib.vat();

        // Sanity checks
        require(GemJoinAbstract(MCD_JOIN_RWA001_A).vat() == vat, "join-vat-not-match");
        require(GemJoinAbstract(MCD_JOIN_RWA001_A).ilk() == ilk, "join-ilk-not-match");
        require(GemJoinAbstract(MCD_JOIN_RWA001_A).gem() == RWA001_GEM, "join-gem-not-match");
        require(GemJoinAbstract(MCD_JOIN_RWA001_A).dec() == DSTokenAbstract(RWA001_GEM).decimals(), "join-dec-not-match");

        // init the RwaLiquidationOracle
        // doc: "doc"
        // tau: 5 minutes
        RwaLiquidationLike(MIP21_LIQUIDATION_ORACLE).init(
            ilk, RWA001_A_INITIAL_PRICE, DOC, 7890000
        );
        (,address pip,,) = RwaLiquidationLike(MIP21_LIQUIDATION_ORACLE).ilks(ilk);

        // Set price feed for RWA001
        DssExecLib.setContract(DssExecLib.spotter(), ilk, "pip", pip);

        // Init RWA-001 in Vat
        Initializable(vat).init(ilk);
        // Init RWA-001 in Jug
        Initializable(DssExecLib.jug()).init(ilk);

        // Allow RWA-001 Join to modify Vat registry
        DssExecLib.authorize(vat, MCD_JOIN_RWA001_A);

        // Allow RwaLiquidationOracle to modify Vat registry
        DssExecLib.authorize(vat, MIP21_LIQUIDATION_ORACLE);

        // Increase the global debt ceiling by the ilk ceiling
        DssExecLib.increaseGlobalDebtCeiling(1_000);
        // Set the ilk debt ceiling
        DssExecLib.setIlkDebtCeiling(ilk, 1_000);

        // No dust
        // DssExecLib.setIlkMinVaultAmount(ilk, 0);

        // 3% stability fee
        DssExecLib.setIlkStabilityFee(ilk, THREE_PCT_RATE, true);

        // collateralization ratio 100%
        DssExecLib.setIlkLiquidationRatio(ilk, 10_000);

        // poke the spotter to pull in a price
        DssExecLib.updateCollateralPrice(ilk);

        // give the urn permissions on the join adapter
        DssExecLib.authorize(MCD_JOIN_RWA001_A, RWA001_A_URN);

        // set up the urn
        Hopeable(RWA001_A_URN).hope(RWA001_OPERATOR);

        // set up output conduit
        Hopeable(RWA001_A_OUTPUT_CONDUIT).hope(RWA001_OPERATOR);
        // could potentially kiss some BD addresses if they are available

        // add RWA-001 contract to the changelog
        DssExecLib.setChangelogAddress("RWA001", RWA001_GEM);
        DssExecLib.setChangelogAddress("PIP_RWA001", pip);
        DssExecLib.setChangelogAddress("MCD_JOIN_RWA001_A", MCD_JOIN_RWA001_A);
        DssExecLib.setChangelogAddress("MIP21_LIQUIDATION_ORACLE", MIP21_LIQUIDATION_ORACLE);
        DssExecLib.setChangelogAddress("RWA001_A_URN", RWA001_A_URN);
        DssExecLib.setChangelogAddress("RWA001_A_INPUT_CONDUIT", RWA001_A_INPUT_CONDUIT);
        DssExecLib.setChangelogAddress("RWA001_A_OUTPUT_CONDUIT", RWA001_A_OUTPUT_CONDUIT);

        // bump changelog version
        DssExecLib.setChangelogVersion("1.2.9");
    }
}

contract DssSpell is DssExec {
    DssSpellAction internal action_ = new DssSpellAction();
    constructor() DssExec(action_.description(), block.timestamp + 30 days, address(action_)) public {}
}
