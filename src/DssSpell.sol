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

contract DssSpellAction is DssAction {

    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/TODO/governance/votes/TODO.md -q -O - 2>/dev/null)"
    string public constant override description =
        "2021-08-06 MakerDAO Executive Spell | Hash: TODO";

    // Turn off office hours
    function officeHours() public override returns (bool) {
        return false;
    }
    // Many of the settings that change weekly rely on the rate accumulator
    // described at https://docs.makerdao.com/smart-contract-modules/rates-module
    // To check this yourself, use the following rate calculation (example 8%):
    //
    // $ bc -l <<< 'scale=27; e( l(1.08)/(60 * 60 * 24 * 365) )'
    //
    // A table of rates can be found at
    //    https://ipfs.io/ipfs/QmefQMseb3AiTapiAKKexdKHig8wroKuZbmLtPLv4u2YwW
    //
    uint256 constant SIX_PCT            = 1000000001847694957439350562;
    // TODO: add more pcts needed for this spell

    // Math
    uint256 constant THOUSAND = 10 ** 3;
    uint256 constant MILLION  = 10 ** 6;
    uint256 constant WAD      = 10 ** 18;
    uint256 constant RAY      = 10 ** 27;
    uint256 constant RAD      = 10 ** 45;

    address public constant MAKER_CHANGELOG = 0xdA0Ab1e0017DEbCd72Be8599041a2aa3bA7e740F;

    // Based on https://github.com/makerdao/vote-delegate/blob/master/README.md
    address public constant VOTE_DELEGATE_PROXY_FACTORY = 0xD897F108670903D1d6070fcf818f9db3615AF272;

    function actions() public override {

        // Core Unit Budget Payouts - August
        // TODO: add poll link, e.g https://vote.makerdao.com/polling/QmRCn7Mh#poll-detail

        // ETH-B Stability Fee Decrease 6% to 5%
        // TODO: add poll link

        // LRC-A Maximum Debt Ceiling Decrease 3 million to zero.
        // TODO: add poll link

        // UNIV2ETHUSDT-A Maximum Debt Ceiling Decrease 10 million to zero.
        // TODO: add poll link

        // UNIV2DAIUSDT-A Maximum Debt Ceiling Decrease 10 million to zero.
        // TODO: add poll link

        // Increase UNIV2DAUUSDC-A Maximum Debt Ceiling
        // TODO: add poll link

        // Update RWA tokens symbols in ilk registry
        IlkRegistryAbstract ILK_REGISTRY = IlkRegistryAbstract(DssExecLib.reg());

        ILK_REGISTRY.file("RWA001-A", "symbol", "RWA001");
        ILK_REGISTRY.file("RWA002-A", "symbol", "RWA002");
        ILK_REGISTRY.file("RWA003-A", "symbol", "RWA003");
        ILK_REGISTRY.file("RWA004-A", "symbol", "RWA004");
        ILK_REGISTRY.file("RWA005-A", "symbol", "RWA005");
        ILK_REGISTRY.file("RWA006-A", "symbol", "RWA006");

        // Update early RWA tokens names in ilk registry
        ILK_REGISTRY.file("RWA001-A", "name", "RWA001-A: 6s Capital");
        ILK_REGISTRY.file("RWA002-A", "name", "RWA002-A: Centrifuge: New Silver");

        // Add vote delegate factory to changelog
        DssExecLib.setChangelogAddress("VOTE_DELEGATE_PROXY_FACTORY", VOTE_DELEGATE_PROXY_FACTORY);

        // Bump changelog version
        DssExecLib.setChangelogVersion("1.9.3");
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) public {}
}
