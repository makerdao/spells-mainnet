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

import { VestAbstract } from "dss-interfaces/dss/VestAbstract.sol";
import { GemAbstract } from "dss-interfaces/ERC/GemAbstract.sol";

interface MkrSkyLike {
    function mkrToSky(address usr, uint256 wad) external;
    function rate() external view returns (uint256);
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
    // Hash: cast keccak -- "$(wget 'TODO' -q -O - 2>/dev/null)"
    string public constant override description = "2025-02-06 MakerDAO Executive Spell | Hash: TODO";

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
    uint256 internal constant WAD = 10 ** 18;

    // ---------- Contracts ----------
    GemAbstract internal immutable DAI  = GemAbstract(DssExecLib.dai());
    GemAbstract internal immutable MKR  = GemAbstract(DssExecLib.mkr());
    GemAbstract internal immutable SKY  = GemAbstract(DssExecLib.getChangelogAddress("SKY"));
    address internal immutable DAI_USDS = DssExecLib.getChangelogAddress("DAI_USDS");
    address internal immutable MKR_SKY  = DssExecLib.getChangelogAddress("MKR_SKY");

    // ---------- Constant Values ----------
    uint256 internal immutable MKR_SKY_RATE = MkrSkyLike(DssExecLib.getChangelogAddress("MKR_SKY")).rate();

    // ---------- Helper Functions ----------
    /// @notice wraps the operations required to transfer USDS from the surplus buffer.
    /// @param usr The USDS receiver.
    /// @param wad The USDS amount in wad precision (10 ** 18).
    function _transferUsds(address usr, uint256 wad) internal {
        // Note: Enforce whole units to avoid rounding errors
        require(wad % WAD == 0, "transferUsds/non-integer-wad");
        // Note: DssExecLib currently only supports Dai transfers from the surplus buffer.
        DssExecLib.sendPaymentFromSurplusBuffer(address(this), wad / WAD);
        // Note: Approve DAI_USDS for the amount sent to be able to convert it.
        DAI.approve(DAI_USDS, wad);
        // Note: Convert Dai to USDS for `usr`.
        DaiUsdsLike(DAI_USDS).daiToUsds(usr, wad);
    }

    /// @notice wraps the operations required to transfer SKY from the treasury.
    /// @param usr The SKY receiver.
    /// @param wad The SKY amount in wad precision (10 ** 18).
    function _transferSky(address usr, uint256 wad) internal {
        // Note: Calculate the equivalent amount of MKR required
        uint256 mkrWad = wad / MKR_SKY_RATE;
        // Note: if rounding error is expected, add an extra wei of MKR
        if (wad % MKR_SKY_RATE != 0) { mkrWad++; }
        // Note: Approve MKR_SKY for the amount sent to be able to convert it
        MKR.approve(MKR_SKY, mkrWad);
        // Note: Convert the calculated amount to SKY for `PAUSE_PROXY`
        MkrSkyLike(MKR_SKY).mkrToSky(address(this), mkrWad);
        // Note: Transfer originally requested amount, leaving extra on the `PAUSE_PROXY`
        SKY.transfer(usr, wad);
    }

    // ---------- Wallets ----------

    // ---------- Spark Proxy Spell ----------
    // Spark Proxy: https://github.com/marsfoundation/sparklend-deployments/blob/bba4c57d54deb6a14490b897c12a949aa035a99b/script/output/1/primary-sce-latest.json#L2
    address internal constant SPARK_PROXY = 0x3300f198988e4C9C63F75dF86De36421f06af8c4;
    address internal constant SPARK_SPELL = address(0);

    function actions() public override {
        // ---------- Action ----------
        // Forum: TODO

        // Increase ETH-A Stability Fee by N percentage point from X.YZ% to A.BC%
        // DssExecLib.setIlkStabilityFee("ILK-NAME", X_PCT_RATE, /* doDrip = */ true);
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) {}
}
