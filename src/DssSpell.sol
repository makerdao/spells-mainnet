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

interface ProxyLike {
    function exec(address target, bytes calldata args) external payable returns (bytes memory out);
}

contract DssSpellAction is DssAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: cast keccak -- "$(wget 'TODO' -q -O - 2>/dev/null)"
    string public constant override description =
        "2024-07-11 MakerDAO Executive Spell | Hash: TODO";

    // Set office hours according to the summary
    function officeHours() public pure override returns (bool) {
        return true;
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
    // uint256 internal constant X_PCT_1000000003022265980097387650RATE = ;
    uint256 internal constant SEVEN_PCT_RATE                = 1000000002145441671308778766;
    uint256 internal constant SEVEN_PT_TWO_FIVE_PCT_RATE    = 1000000002219443553326580536;
    uint256 internal constant SEVEN_PT_SEVEN_FIVE_PCT_RATE  = 1000000002366931224128103346;
    uint256 internal constant EIGHT_PCT_RATE                = 1000000002440418608258400030;
    uint256 internal constant EIGHT_PT_TWO_FIVE_PCT_RATE    = 1000000002513736079215619839;
    uint256 internal constant EIGHT_PT_FIVE_PCT_RATE        = 1000000002586884420913935572;
    uint256 internal constant EIGHT_PT_SEVEN_FIVE_PCT_RATE  = 1000000002659864411854984565;
    uint256 internal constant NINE_PT_TWO_FIVE_PCT_RATE     = 1000000002805322428706865331;

    // ---------- Contracts ----------
    GemAbstract internal immutable MKR = GemAbstract(DssExecLib.mkr());

    // ---------- Payment addresses ----------
    address internal constant AAVE_V3_TREASURY  = 0x464C71f6c2F760DdA6093dCB91C24c39e5d6e18c;
    address internal constant BLUE              = 0xb6C09680D822F162449cdFB8248a7D3FC26Ec9Bf;
    address internal constant JULIACHANG        = 0x252abAEe2F4f4b8D39E5F12b163eDFb7fac7AED7;
    address internal constant BYTERON           = 0xc2982e72D060cab2387Dba96b846acb8c96EfF66;
    address internal constant CLOAKY            = 0x869b6d5d8FA7f4FFdaCA4D23FFE0735c5eD1F818;
    address internal constant PBG               = 0x8D4df847dB7FfE0B46AF084fE031F7691C6478c2;
    address internal constant BONAPUBLICA       = 0x167c1a762B08D7e78dbF8f24e5C3f1Ab415021D3;
    address internal constant ROCKY             = 0xC31637BDA32a0811E39456A59022D2C386cb2C85;
    address internal constant VIGILANT          = 0x2474937cB55500601BCCE9f4cb0A0A72Dc226F61;
    address internal constant CLOAKY_KOHLA      = 0xA9D43465B43ab95050140668c87A2106C73CA811;
    address internal constant CLOAKY_ENNOIA     = 0xA7364a1738D0bB7D1911318Ca3FB3779A8A58D7b;
    address internal constant WBC               = 0xeBcE83e491947aDB1396Ee7E55d3c81414fB0D47;

    // ---------- Update Chainlink Keeper Network Treasury Address ----------
    address internal constant CHAINLINK_PAYMENT_ADAPTER = 0xfB5e1D841BDA584Af789bDFABe3c6419140EC065;
    address internal constant CHAINLINK_TREASURY_NEW    = 0xBE1cE564574377Acb17C2b7628E4F6dd38067a55;

    // ---------- Spark Spell ----------
    // Spark Proxy: https://github.com/marsfoundation/sparklend-deployments/blob/bba4c57d54deb6a14490b897c12a949aa035a99b/script/output/1/primary-sce-latest.json#L2
    address internal constant SPARK_PROXY = 0x3300f198988e4C9C63F75dF86De36421f06af8c4;
    address internal constant SPARK_SPELL = 0x91824fa4fd51E8440a122ffDd49C701F5C56D58e;

    function actions() public override {
        // ---------- Spark - Aave Revenue Share Payment ----------
        // Forum: https://forum.makerdao.com/t/spark-aave-revenue-share-calculation-payment-4-q2-2024/24572

        // AAVE - 219125 DAI - 0x464C71f6c2F760DdA6093dCB91C24c39e5d6e18c
        DssExecLib.sendPaymentFromSurplusBuffer(AAVE_V3_TREASURY, 219_125);

        // ---------- Update Chainlink Keeper Network Treasury Address ----------
        // Forum: https://forum.makerdao.com/t/amend-keeper-network-chainlink-automation-v2-1/24593

        // DssExecLib.setContract(CHAINLINK_PAYMENT_ADAPTER, "treasury", 0xBE1cE564574377Acb17C2b7628E4F6dd38067a55);
        DssExecLib.setContract(CHAINLINK_PAYMENT_ADAPTER, "treasury", CHAINLINK_TREASURY_NEW);

        // ---------- Stability Scope Parameter Changes ----------
        // Forum: https://forum.makerdao.com/t/stability-scope-parameter-changes-14/24594/1

        // Stability Fee (SF) changes:
        // Note: only heading, changes follow

        // ETH-A: Decrease by 1 percentage point, from 8.25% to 7.25%
        DssExecLib.setIlkStabilityFee("ETH-A", SEVEN_PT_TWO_FIVE_PCT_RATE, /* doDrip = */ true);

        // ETH-B: Decrease by 1 percentage point, from 8.75% to 7.75%
        DssExecLib.setIlkStabilityFee("ETH-B", SEVEN_PT_SEVEN_FIVE_PCT_RATE, /* doDrip = */ true);

        // ETH-C: Decrease by 1 percentage point, from 8% to 7%
        DssExecLib.setIlkStabilityFee("ETH-C", SEVEN_PCT_RATE, /* doDrip = */ true);

        // WSTETH-A: Decrease by 1 percentage point, from 9.25% to 8.25%
        DssExecLib.setIlkStabilityFee("WSTETH-A", EIGHT_PT_TWO_FIVE_PCT_RATE, /* doDrip = */ true);

        // WSTETH-B: Decrease by 1 percentage point, from 9% to 8%
        DssExecLib.setIlkStabilityFee("WSTETH-B", EIGHT_PCT_RATE, /* doDrip = */ true);

        // WBTC-A: Decrease by 1 percentage point, from 9.75% to 8.75%
        DssExecLib.setIlkStabilityFee("WBTC-A", EIGHT_PT_SEVEN_FIVE_PCT_RATE, /* doDrip = */ true);

        // WBTC-B: Decrease by 1 percentage point, from 10.25% to 9.25%
        DssExecLib.setIlkStabilityFee("WBTC-B", NINE_PT_TWO_FIVE_PCT_RATE, /* doDrip = */ true);

        // WBTC-C: Decrease by 1 percentage point, from 9.5% to 8.5%
        DssExecLib.setIlkStabilityFee("WBTC-C", EIGHT_PT_FIVE_PCT_RATE, /* doDrip = */ true);

        // Dai Savings Rate:
        // Note: only heading, changes follow

        // DSR: Decrease by 1 percentage point, from 8% to 7%
        DssExecLib.setDSR(SEVEN_PCT_RATE, /* doDrip = */ true);

        // ---------- Delegate Compensation ----------

        // BLUE - 41.67 MKR - 0xb6C09680D822F162449cdFB8248a7D3FC26Ec9Bf
        MKR.transfer(BLUE, 41.67 ether); // Note: 'ether' is a keyword helper, only MKR is transferred here

        // JuliaChang - 41.67 MKR - 0x252abAEe2F4f4b8D39E5F12b163eDFb7fac7AED7
        MKR.transfer(JULIACHANG, 41.67 ether); // Note: 'ether' is a keyword helper, only MKR is transferred here

        // Byteron - 38.98 MKR - 0xc2982e72D060cab2387Dba96b846acb8c96EfF66
        MKR.transfer(BYTERON, 38.98 ether); // Note: 'ether' is a keyword helper, only MKR is transferred here

        // Cloaky - 20.40 MKR - 0x869b6d5d8FA7f4FFdaCA4D23FFE0735c5eD1F818
        MKR.transfer(CLOAKY, 20.40 ether); // Note: 'ether' is a keyword helper, only MKR is transferred here

        // PBG - 16.58 MKR - 0x8D4df847dB7FfE0B46AF084fE031F7691C6478c2
        MKR.transfer(PBG, 16.58 ether); // Note: 'ether' is a keyword helper, only MKR is transferred here

        // BONAPUBLICA - 13.89 MKR - 0x167c1a762B08D7e78dbF8f24e5C3f1Ab415021D3
        MKR.transfer(BONAPUBLICA, 13.89 ether); // Note: 'ether' is a keyword helper, only MKR is transferred here

        // Rocky - 13.89 MKR - 0xC31637BDA32a0811E39456A59022D2C386cb2C85
        MKR.transfer(ROCKY, 13.89 ether); // Note: 'ether' is a keyword helper, only MKR is transferred here

        // vigilant - 12.55 MKR - 0x2474937cB55500601BCCE9f4cb0A0A72Dc226F61
        MKR.transfer(VIGILANT, 12.55 ether); // Note: 'ether' is a keyword helper, only MKR is transferred here

        // Ennoia (Cloaky) - 4.1 MKR - 0xA7364a1738D0bB7D1911318Ca3FB3779A8A58D7b
        MKR.transfer(CLOAKY_ENNOIA, 4.1 ether); // Note: 'ether' is a keyword helper, only MKR is transferred here

        // Kohla (Cloaky) - 4.1 MKR - 0xA9D43465B43ab95050140668c87A2106C73CA811
        MKR.transfer(CLOAKY_KOHLA, 4.1 ether); // Note: 'ether' is a keyword helper, only MKR is transferred here

        // WBC - 1.34 MKR - 0xeBcE83e491947aDB1396Ee7E55d3c81414fB0D47
        MKR.transfer(WBC, 1.34 ether); // Note: 'ether' is a keyword helper, only MKR is transferred here

        // ---------- Spark Spell ----------
        // Forum: https://forum.makerdao.com/t/stability-scope-parameter-changes-14/24594/1
        // Forum: https://forum.makerdao.com/t/jun-27-2024-proposed-changes-to-spark-for-upcoming-spell/24552
        // Poll: https://vote.makerdao.com/polling/QmTBsxR5

        // Trigger Spark Proxy Spell at 0x91824fa4fd51E8440a122ffDd49C701F5C56D58e
        ProxyLike(SPARK_PROXY).exec(SPARK_SPELL, abi.encodeWithSignature("execute()"));
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) {}
}
