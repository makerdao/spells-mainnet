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
import {GemAbstract} from "dss-interfaces/ERC/GemAbstract.sol";

interface ProxyLike {
    function exec(address target, bytes calldata args) external payable returns (bytes memory out);
}

interface PauseLike {
    function setDelay(uint256) external;
}

interface DaiUsdsLike {
    function daiToUsds(address usr, uint256 wad) external;
}

interface MkrSkyLike {
    function mkrToSky(address usr, uint256 wad) external;
    function rate() external view returns (uint256);
}

contract DssSpellAction is DssAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: cast keccak -- "$(wget 'https://raw.githubusercontent.com/makerdao/community/aa58678ff632f8e25047a345709cd3c9f1819e4f/governance/votes/Executive%20vote%20-%20November%2014%2C%202024.md' -q -O - 2>/dev/null)"
    string public constant override description = "2024-11-28 MakerDAO Executive Spell | Hash: TODO";

    // Set office hours according to the summary
    function officeHours() public pure override returns (bool) {
        return false;
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
    uint256 internal constant THOUSAND = 10 ** 3;
    uint256 internal constant MILLION = 10 ** 6;
    uint256 internal constant WAD = 10 ** 18;

    // ---------- MCD Addresses ----------
    GemAbstract internal immutable MKR                     = GemAbstract(DssExecLib.mkr());
    GemAbstract internal immutable DAI                     = GemAbstract(DssExecLib.dai());
    address internal immutable MCD_PAUSE                   = DssExecLib.getChangelogAddress("MCD_PAUSE");
    address internal immutable DAI_USDS                    = DssExecLib.getChangelogAddress("DAI_USDS");
    address internal immutable MKR_SKY                     = DssExecLib.getChangelogAddress("MKR_SKY");
    uint256 internal immutable MKR_SKY_RATE                = MkrSkyLike(DssExecLib.getChangelogAddress("MKR_SKY")).rate();
    address internal immutable MCD_ESM                     = DssExecLib.getChangelogAddress("MCD_ESM");

    // ---------- Wallets ----------
    address internal constant LAUNCH_PROJECT_FUNDING       = 0x3C5142F28567E6a0F172fd0BaaF1f2847f49D02F;
    address internal constant LIQUIDITY_BOOTSTRAPPING      = 0xD8507ef0A59f37d15B5D7b630FA6EEa40CE4AFdD;
    address internal constant INTEGRATION_BOOST_INITIATIVE = 0xD6891d1DFFDA6B0B1aF3524018a1eE2E608785F7;
    address internal constant BLUE                         = 0xb6C09680D822F162449cdFB8248a7D3FC26Ec9Bf;
    address internal constant BONAPUBLICA                  = 0x167c1a762B08D7e78dbF8f24e5C3f1Ab415021D3;
    address internal constant BYTERON                      = 0xc2982e72D060cab2387Dba96b846acb8c96EfF66;
    address internal constant CLOAKY                       = 0x869b6d5d8FA7f4FFdaCA4D23FFE0735c5eD1F818;
    address internal constant JULIACHANG                   = 0x252abAEe2F4f4b8D39E5F12b163eDFb7fac7AED7;
    address internal constant VIGILANT                     = 0x2474937cB55500601BCCE9f4cb0A0A72Dc226F61;
    address internal constant CLOAKY_KOHLA_2               = 0x73dFC091Ad77c03F2809204fCF03C0b9dccf8c7a;
    address internal constant CLOAKY_ENNOIA                = 0xA7364a1738D0bB7D1911318Ca3FB3779A8A58D7b;

    // ---------- Spark Proxy Spell ----------
    // Spark Proxy: https://github.com/marsfoundation/sparklend-deployments/blob/bba4c57d54deb6a14490b897c12a949aa035a99b/script/output/1/primary-sce-latest.json#L2
    address internal constant SPARK_PROXY = 0x3300f198988e4C9C63F75dF86De36421f06af8c4;
    address internal constant SPARK_SPELL = 0x6c87D984689CeD0bB367A58722aC74013F82267d;

    function actions() public override {
        // ---------- DIRECT-SPK-AAVE-LIDO-USDS DDM line increase ----------
        // Forum: TODO
        // Poll: TODO

        // Increase DIRECT-SPK-AAVE-LIDO-USDS DDM line by 100 million, USDS from 100 million USDS to 200 million USDS
        DssExecLib.setIlkAutoLineDebtCeiling("DIRECT-SPK-AAVE-LIDO-USDS", 200 * MILLION);

        // ---------- Surplus Buffer Upper Limit increase ----------
        // Forum: TODO
        // Poll: TODO

        // Increase the Surplus Buffer Upper Limit by 60 million DAI, from 60 million DAI to 120 million DAI
        DssExecLib.setSurplusBuffer(120 * MILLION);

        // ---------- Add emergency spells to the chainlog ----------
        // Forum: TODO
        // Poll: TODO

        // TBC

        // ---------- Rate Changes ----------
        // Forum: TODO
        // Poll: TODO

        // TBC

        // ---------- GSM Delay increase ----------
        // Forum: TODO
        // Poll: TODO

        // Increase GSM Delay by 14 hours, from 16 hours to 30 hours
        PauseLike(MCD_PAUSE).setDelay(30 hours);

        // ---------- Launch Project Funding ----------
        // Forum: TODO
        // Poll: TODO

        // Transfer 10,000,000 USDS to 0x3C5142F28567E6a0F172fd0BaaF1f2847f49D02F
        _transferUsds(LAUNCH_PROJECT_FUNDING, 10 * MILLION * WAD);

        // Transfer 24,000,000 SKY to 0x3C5142F28567E6a0F172fd0BaaF1f2847f49D02F
        _transferSky(LAUNCH_PROJECT_FUNDING, 24 * MILLION * WAD);

        // ---------- Sky Ecosystem Liquidity Bootstrapping Funding ----------
        // Forum: TODO
        // Poll: TODO

        // Transfer 6,000,000 USDS to 0xD8507ef0A59f37d15B5D7b630FA6EEa40CE4AFdD
        _transferUsds(LIQUIDITY_BOOTSTRAPPING, 6 * MILLION * WAD);

        // ---------- Integration Boost Funding ----------
        // Forum: TODO
        // Poll: TODO

        // Transfer 3,000,000 USDS to 0xD6891d1DFFDA6B0B1aF3524018a1eE2E608785F7
        _transferUsds(INTEGRATION_BOOST_INITIATIVE, 3 * MILLION * WAD);

        // ---------- ESM Minimum Threshold increase ----------
        // Forum: TODO
        // Poll: TODO

        // Increase ESM Minimum Threshold by 200,000 MKR, from 300,000 MKR to 500,000 MKR
        DssExecLib.setValue(MCD_ESM, "min", 500 * THOUSAND * WAD);

        // ---------- October 2024 AD Compensation ----------
        // Forum: TODO
        // Poll: TODO

        // BLUE - 2,968 USDS - 0xb6C09680D822F162449cdFB8248a7D3FC26Ec9Bf
        _transferUsds(BLUE,        2_968 * WAD);
        // Bonapublica - 4,000 USDS  - 0x167c1a762B08D7e78dbF8f24e5C3f1Ab415021D3
        _transferUsds(BONAPUBLICA, 4_000 * WAD);
        // Byteron - 1,733 USDS  - 0xc2982e72D060cab2387Dba96b846acb8c96EfF66
        _transferUsds(BYTERON,     1_733 * WAD);
        // Cloaky - 4,000 USDS  - 0x869b6d5d8FA7f4FFdaCA4D23FFE0735c5eD1F818
        _transferUsds(CLOAKY,      4_000 * WAD);
        // JuliaChang - 4,000 USDS  - 0x252abAEe2F4f4b8D39E5F12b163eDFb7fac7AED7
        _transferUsds(JULIACHANG,  4_000 * WAD);
        // vigilant - 4,000 USDS  - 0x2474937cB55500601BCCE9f4cb0A0A72Dc226F61
        _transferUsds(VIGILANT,    4_000 * WAD);

        // ---------- Atlas Core Development Payments ----------
        // Forum: TODO
        // Poll: TODO

        // Kohla (Cloaky) - 20,000 USDS - 0x73dFC091Ad77c03F2809204fCF03C0b9dccf8c7a
        _transferUsds(CLOAKY_KOHLA_2,  20_000 * WAD);
        // Ennoia (Cloaky) - 20,110 USDS - 0xA7364a1738D0bB7D1911318Ca3FB3779A8A58D7b
        _transferUsds(CLOAKY_ENNOIA,   20_110 * WAD);
        // BLUE - 50,167 USDS - 0xb6C09680D822F162449cdFB8248a7D3FC26Ec9Bf
        _transferUsds(BLUE,            50_167 * WAD);
        // BLUE - 330,000 SKY - 0xb6C09680D822F162449cdFB8248a7D3FC26Ec9Bf
        _transferSky(BLUE,            330_000 * WAD);

        // ---------- Spark Proxy Spell ----------
        // Forum: TODO
        // Poll: TODO

        // Execute Spark Proxy Spell at 0x6c87D984689CeD0bB367A58722aC74013F82267d
        // ProxyLike(SPARK_PROXY).exec(SPARK_SPELL, abi.encodeWithSignature("execute()"));
    }

    /// @notice wraps the operations required to transfer USDS from the surplus buffer
    /// @param usr The USDS receiver.
    /// @param wad The USDS amount in wad precision (10**18)
    function _transferUsds(address usr, uint256 wad) internal {
        // Note: Enforce whole units to avoid rounding errors
        require(wad % WAD == 0, "transferUsds/non-integer-wad");
        // Note: DssExecLib currently only supports Dai transfers from the surplus buffer.
        DssExecLib.sendPaymentFromSurplusBuffer(address(this), wad / WAD);
        // Note: Approve DAI_USDS for the amount sent to be able to convert it.
        DAI.approve(DAI_USDS, wad);
        // Transfer 3,000,000 USDS to 0xD6891d1DFFDA6B0B1aF3524018a1eE2E608785F7
        DaiUsdsLike(DAI_USDS).daiToUsds(usr, wad);
    }

    /// @notice wraps the operations required to transfer SKY from the surplus buffer
    /// @param usr The SKY receiver.
    /// @param wad The SKY amount in wad precision (10**18).
    function _transferSky(address usr, uint256 wad) internal {
        // Note: Enforce exact conversion to avoid rounding errors
        require(wad % MKR_SKY_RATE == 0, "transferSky/non-exact-conversion");
        // Note: Calculate the amount of MKR required
        uint256 mkrWad = wad / MKR_SKY_RATE;
        // Note: Approve MKR_SKY for the amount sent to be able to convert it
        MKR.approve(MKR_SKY, mkrWad);
        // Note: Convert the calculated amount to SKY for `usr`
        MkrSkyLike(MKR_SKY).mkrToSky(usr, mkrWad);
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) {}
}
