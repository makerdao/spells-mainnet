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
import { DssInstance, MCD } from "dss-test/MCD.sol";

// Note: source code matches https://github.com/makerdao/dss-flappers/blob/95431f3d4da66babf81c6e1138bd05f5ddc5e516/deploy/FlapperInit.sol
import { FlapperInit, FlapperUniV2Config } from "src/dependencies/dss-flappers/FlapperInit.sol";

interface MkrSkyLike {
    function mkrToSky(address usr, uint256 mkrAmt) external;
}

interface DaiUsdsLike {
    function daiToUsds(address usr, uint256 wad) external;
}

interface ProxyLike {
    function exec(address target, bytes calldata args) external payable returns (bytes memory out);
}

contract DssSpellAction is DssAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: cast keccak -- "$(wget 'https://raw.githubusercontent.com/makerdao/community/8aff80b3462461352120c9dc79598dc6dc617bdf/governance/votes/Executive%20Vote%20-%20September%2027%2C%202024.md' -q -O - 2>/dev/null)"
    string public constant override description =
        "2024-09-27 MakerDAO Executive Spell | Hash: 0x29461f373c49e25adfb11412908a06dc50d0817c8de117d189881057b71ad2a6";

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
    // uint256 internal constant X_PCT_RATE = ;

    // ---------- Math ----------
    uint256 internal constant WAD = 10 ** 18;
    uint256 internal constant RAD = 10 ** 45;

    // ---------- Contracts ----------
    GemAbstract internal immutable MKR                  = GemAbstract(DssExecLib.mkr());
    GemAbstract internal immutable DAI                  = GemAbstract(DssExecLib.dai());
    GemAbstract internal immutable SKY                  = GemAbstract(DssExecLib.getChangelogAddress("SKY"));
    address internal immutable MCD_PAUSE_PROXY          = DssExecLib.pauseProxy();
    address internal immutable MKR_SKY                  = DssExecLib.getChangelogAddress("MKR_SKY");
    address internal immutable DAI_USDS                 = DssExecLib.getChangelogAddress("DAI_USDS");
    address internal immutable USDS                     = DssExecLib.getChangelogAddress("USDS");
    address internal immutable MCD_SPLIT                = DssExecLib.getChangelogAddress("MCD_SPLIT");
    address internal immutable MCD_VOW                  = DssExecLib.getChangelogAddress("MCD_VOW");
    address internal constant UNIV2USDSSKY              = 0x2621CC0B3F3c079c1Db0E80794AA24976F0b9e3c;
    address internal constant SWAP_ONLY_FLAPPER         = 0x374D9c3d5134052Bc558F432Afa1df6575f07407;
    address internal constant SWAP_ONLY_FLAP_SKY_ORACLE = 0x61A12E5b1d5E9CC1302a32f0df1B5451DE6AE437;

    // ---------- Wallets ----------
    address internal constant BLUE                 = 0xb6C09680D822F162449cdFB8248a7D3FC26Ec9Bf;
    address internal constant CLOAKY               = 0x869b6d5d8FA7f4FFdaCA4D23FFE0735c5eD1F818;
    address internal constant CLOAKY_KOHLA_2       = 0x73dFC091Ad77c03F2809204fCF03C0b9dccf8c7a;
    address internal constant CLOAKY_ENNOIA        = 0xA7364a1738D0bB7D1911318Ca3FB3779A8A58D7b;
    address internal constant JULIACHANG           = 0x252abAEe2F4f4b8D39E5F12b163eDFb7fac7AED7;
    address internal constant BYTERON              = 0xc2982e72D060cab2387Dba96b846acb8c96EfF66;
    address internal constant ROCKY                = 0xC31637BDA32a0811E39456A59022D2C386cb2C85;
    address internal constant BONAPUBLICA          = 0x167c1a762B08D7e78dbF8f24e5C3f1Ab415021D3;
    address internal constant SOLANA_BOOTSTRAPPING = 0xD8507ef0A59f37d15B5D7b630FA6EEa40CE4AFdD;

    // ---------- Spark Proxy Spell ----------
    // Spark Proxy: https://github.com/marsfoundation/sparklend-deployments/blob/bba4c57d54deb6a14490b897c12a949aa035a99b/script/output/1/primary-sce-latest.json#L2
    address internal constant SPARK_PROXY = 0x3300f198988e4C9C63F75dF86De36421f06af8c4;
    address internal constant SPARK_SPELL = 0xc80621140bEe6A105C180Ae7cb0a084c2409C738;

    function actions() public override {
        // ---------- SBE Updates ----------
        // Forum: https://forum.makerdao.com/t/smart-burn-engine-transaction-analysis-and-parameter-reconfiguration-update-9/25078
        // Poll: https://vote.makerdao.com/polling/QmSxswGN

        // Note: DssInstance is required by multiple init calls below
        DssInstance memory dss = MCD.loadFromChainlog(DssExecLib.LOG);

        // Init new Flapper by calling FlapperInit.initFlapperUniV2 with the following parameters:
        FlapperInit.initFlapperUniV2(

            // Note: DssInstance is required by the init library
            dss,

            // Init new Flapper with flapper_: FlapperUniV2SwapOnly (0x374D9c3d5134052Bc558F432Afa1df6575f07407)
            SWAP_ONLY_FLAPPER,

            FlapperUniV2Config({

                // Init new Flapper with want: 0.98 * WAD
                want: 98 * WAD / 100,

                // Init new Flapper with pip: SWAP_ONLY_FLAP_SKY_ORACLE (0x61A12E5b1d5E9CC1302a32f0df1B5451DE6AE437)
                pip: SWAP_ONLY_FLAP_SKY_ORACLE,

                // Init new Flapper with pair: PAIR_USDS_SKY (0x2621CC0B3F3c079c1Db0E80794AA24976F0b9e3c)
                pair: UNIV2USDSSKY,

                // Init new Flapper with usds: dss.chainlog.getAddress("USDS")
                usds: USDS,

                // Init new Flapper with splitter: dss.chainlog.getAddress("MCD_SPLIT")
                splitter: MCD_SPLIT,

                // Init new Flapper with prevChainlogKey: bytes32(0)
                prevChainlogKey: bytes32(0),

                // Init new Flapper with chainlogKey: "MCD_FLAP"
                chainlogKey: "MCD_FLAP"
            })
        );

        // Init new OracleWrapper by calling FlapperInit.initOracleWrapper with the following parameters:
        FlapperInit.initOracleWrapper(
            // Note: DssInstance is required by the init library
            dss,

            // Init new OracleWrapper with wrapper_: SWAP_ONLY_FLAP_SKY_ORACLE (0x61A12E5b1d5E9CC1302a32f0df1B5451DE6AE437)
            SWAP_ONLY_FLAP_SKY_ORACLE,

            // Init new OracleWrapper with divisor: 24,000
            24_000,

            // Init new OracleWrapper with clKey: "FLAP_SKY_ORACLE"
            "FLAP_SKY_ORACLE"
        );

        // Increase vow.hop by 1386 seconds from 10249 seconds to 11635 seconds
        DssExecLib.setValue(MCD_SPLIT, "hop", 11_635);

        // Decrease vow.bump by 40000 USDS from 65000 USDS to 25000 USDS
        DssExecLib.setValue(MCD_VOW, "bump", 25_000 * RAD);

        // Note: bump minor chainlog version due to the new flapper contract
        DssExecLib.setChangelogVersion("1.19.0");

        // ---------- Sky Ecosystem Liquidity Bootstrapping ----------
        // Forum: https://forum.makerdao.com/t/atlas-edit-weekly-cycle-proposal-week-of-2024-09-23/25179

        // Transfer 10,000,000 DAI to the Pause Proxy from the Surplus Buffer
        DssExecLib.sendPaymentFromSurplusBuffer(MCD_PAUSE_PROXY, 10_000_000);

        // Note: we have to approve DAI_USDS contract to convert DAI into USDS
        DAI.approve(DAI_USDS, 10_000_000 * WAD);

        // Convert 10,000,000 DAI to USDS using DAI_USDS
        // Note: this is done by the next line of code

        // Transfer 10,000,000 USDS from PauseProxy to 0xD8507ef0A59f37d15B5D7b630FA6EEa40CE4AFdD
        DaiUsdsLike(DAI_USDS).daiToUsds(SOLANA_BOOTSTRAPPING, 10_000_000 * WAD);

        // Note: we have to approve MKR_SKY contract to convert MKR into SKY
        MKR.approve(MKR_SKY, 13_334 * WAD);

        // Convert 13,334 MKR held in Pause Proxy to SKY (use MKR_SKY contract)
        MkrSkyLike(MKR_SKY).mkrToSky(MCD_PAUSE_PROXY, 13_334 * WAD);

        // Transfer 320,000,000 SKY to 0xD8507ef0A59f37d15B5D7b630FA6EEa40CE4AFdD
        SKY.transfer(SOLANA_BOOTSTRAPPING, 320_000_000 * WAD);

        // ---------- Aligned Delegate DAI Compensation ----------
        // Forum: https://forum.makerdao.com/t/august-2024-aligned-delegate-compensation/25165
        // Mip: https://mips.makerdao.com/mips/details/MIP101#2-6-3-aligned-delegate-budget-and-participation-requirements

        // BLUE - 54167 DAI - 0xb6c09680d822f162449cdfb8248a7d3fc26ec9bf
        DssExecLib.sendPaymentFromSurplusBuffer(BLUE, 54_167);

        // Cloaky - 20417 DAI - 0x869b6d5d8FA7f4FFdaCA4D23FFE0735c5eD1F818
        DssExecLib.sendPaymentFromSurplusBuffer(CLOAKY, 20_417);

        // Kohla (Cloaky) - 10000 DAI - 0x73dFC091Ad77c03F2809204fCF03C0b9dccf8c7a
        DssExecLib.sendPaymentFromSurplusBuffer(CLOAKY_KOHLA_2, 10_000);

        // Ennoia (Cloaky) - 10000 DAI - 0xA7364a1738D0bB7D1911318Ca3FB3779A8A58D7b
        DssExecLib.sendPaymentFromSurplusBuffer(CLOAKY_ENNOIA, 10_000);

        // JuliaChang - 8333 DAI - 0x252abAEe2F4f4b8D39E5F12b163eDFb7fac7AED7
        DssExecLib.sendPaymentFromSurplusBuffer(JULIACHANG, 8_333);

        // Byteron - 8333 DAI - 0xc2982e72D060cab2387Dba96b846acb8c96EfF66
        DssExecLib.sendPaymentFromSurplusBuffer(BYTERON, 8_333);

        // Rocky - 8065 DAI - 0xC31637BDA32a0811E39456A59022D2C386cb2C85
        DssExecLib.sendPaymentFromSurplusBuffer(ROCKY, 8_065);

        // BONAPUBLICA - 5430 DAI - 0x167c1a762B08D7e78dbF8f24e5C3f1Ab415021D3
        DssExecLib.sendPaymentFromSurplusBuffer(BONAPUBLICA, 5_430);

        // ---------- Aligned Delegate MKR Compensation ----------
        // Forum: https://forum.makerdao.com/t/august-2024-aligned-delegate-compensation/25165
        // Mip: https://mips.makerdao.com/mips/details/MIP101#2-6-3-aligned-delegate-budget-and-participation-requirements

        // BLUE - 13.75 MKR - 0xb6c09680d822f162449cdfb8248a7d3fc26ec9bf
        MKR.transfer(BONAPUBLICA, 13.75 ether); // Note: 'ether' is a keyword helper, only MKR is transferred here

        // Cloaky - 12.00 MKR - 0x869b6d5d8FA7f4FFdaCA4D23FFE0735c5eD1F818
        MKR.transfer(CLOAKY, 12.00 ether); // Note: 'ether' is a keyword helper, only MKR is transferred here

        // JuliaChang - 1.25 MKR - 0x252abAEe2F4f4b8D39E5F12b163eDFb7fac7AED7
        MKR.transfer(JULIACHANG, 1.25 ether); // Note: 'ether' is a keyword helper, only MKR is transferred here

        // Byteron - 1.25 MKR - 0xc2982e72D060cab2387Dba96b846acb8c96EfF66
        MKR.transfer(BYTERON, 1.25 ether); // Note: 'ether' is a keyword helper, only MKR is transferred here

        // Rocky - 1.21 MKR - 0xC31637BDA32a0811E39456A59022D2C386cb2C85
        MKR.transfer(ROCKY, 1.21 ether); // Note: 'ether' is a keyword helper, only MKR is transferred here

        // ---------- Spark Spell ----------
        // Forum: https://forum.makerdao.com/t/sep-12-2024-proposed-changes-to-spark-for-upcoming-spell/25076
        // Poll: https://vote.makerdao.com/polling/QmPFkXna

        // Execute Spark Proxy Spell at 0xc80621140bEe6A105C180Ae7cb0a084c2409C738
        ProxyLike(SPARK_PROXY).exec(SPARK_SPELL, abi.encodeWithSignature("execute()"));
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) {}
}
