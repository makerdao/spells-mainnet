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
import "lib/dss-interfaces/src/dss/VatAbstract.sol";

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
    uint256 constant FIVE_PCT = 1000000001547125957863212448;

    // Math
    uint256 constant THOUSAND = 10 ** 3;
    uint256 constant MILLION  = 10 ** 6;
    uint256 constant WAD      = 10 ** 18;
    uint256 constant RAY      = 10 ** 27;
    uint256 constant RAD      = 10 ** 45;

    // Growth Core Unit
    address constant GRO_MULTISIG        = 0x7800C137A645c07132886539217ce192b9F0528e;
    // Ses Core Unit
    address constant SES_MULTISIG        = 0x87AcDD9208f73bFc9207e1f6F0fDE906bcA95cc6;
    // Content Production Core Unit
    address constant MKT_MULTISIG        = 0xDCAF2C84e1154c8DdD3203880e5db965bfF09B60;
    // GovAlpha Core Unit
    address constant GOV_MULTISIG        = 0x01D26f8c5cC009868A4BF66E268c17B057fF7A73;
    // Real-World Finance Core Unit
    address constant RWF_MULTISIG        = 0x9e1585d9CA64243CE43D42f7dD7333190F66Ca09;
    // Risk Core Unit
    address constant RISK_CU_EOA         = 0xd98ef20520048a35EdA9A202137847A62120d2d9;
    // Protocol Engineering
    address constant PE_MULTISIG         = 0xe2c16c308b843eD02B09156388Cb240cEd58C01c;
    // Oracles Core Unit
    address constant ORA_MULTISIG        = 0x2d09B7b95f3F312ba6dDfB77bA6971786c5b50Cf;
    // Com Core Unit (Operating)
    address constant COM_MULTISIG        = 0x1eE3ECa7aEF17D1e74eD7C447CcBA61aC76aDbA9;
    // Com Core Unit (Emergency Fund)
    address constant COM_ER_MULTISIG     = 0x99E1696A680c0D9f426Be20400E468089E7FDB0f;

    address public constant MAKER_CHANGELOG = 0xdA0Ab1e0017DEbCd72Be8599041a2aa3bA7e740F;

    // Based on https://github.com/makerdao/vote-delegate/blob/master/README.md
    address public constant VOTE_DELEGATE_PROXY_FACTORY = 0xD897F108670903D1d6070fcf818f9db3615AF272;

    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x);
    }
    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x);
    }

    function actions() public override {
        address MCD_VAT  = DssExecLib.vat();

        // -----------  Core Unit Budget Payouts - August -----------

        DssExecLib.sendPaymentFromSurplusBuffer(GRO_MULTISIG,    637_900);
        DssExecLib.sendPaymentFromSurplusBuffer(SES_MULTISIG,    0); // TODO - fill up once decided
        DssExecLib.sendPaymentFromSurplusBuffer(MKT_MULTISIG,    44_375);
        DssExecLib.sendPaymentFromSurplusBuffer(GOV_MULTISIG,    273_334);
        DssExecLib.sendPaymentFromSurplusBuffer(RWF_MULTISIG,    155_000);
        DssExecLib.sendPaymentFromSurplusBuffer(RISK_CU_EOA,     182_000);
        DssExecLib.sendPaymentFromSurplusBuffer(PE_MULTISIG,     510_000);
        DssExecLib.sendPaymentFromSurplusBuffer(ORA_MULTISIG,    419_677);
        DssExecLib.sendPaymentFromSurplusBuffer(COM_MULTISIG,    40_500);
        DssExecLib.sendPaymentFromSurplusBuffer(COM_ER_MULTISIG, 121_500);
        //                                                     _________
        //                                         TOTAL DAI:  2,384,286

        // ----------- Maker Open Market Commitee Proposal -----------
        // TODO: add poll link

        // ETH-B Stability Fee Decrease 6% to 5%
        DssExecLib.setIlkStabilityFee("ETH-B", FIVE_PCT, true);

        // Maximum Debt Ceiling Decreases to zero.
        DssExecLib.removeIlkFromAutoLine("LRC-A"); // Decrease 3 million to zero.
        (,,,uint256 lrcLine,) = VatAbstract(MCD_VAT).ilks("LRC-A");
        DssExecLib.setIlkDebtCeiling("LRC-A", 0); // -lrcLine

        DssExecLib.removeIlkFromAutoLine("UNIV2ETHUSDT-A");  // Decrease 10 million to zero.
        (,,,uint256 univ2EthUsdtLine,) = VatAbstract(MCD_VAT).ilks("UNIV2ETHUSDT-A");
        DssExecLib.setIlkDebtCeiling("UNIV2ETHUSDT-A", 0); // -univ2EthUsdtLine

        DssExecLib.removeIlkFromAutoLine("UNIV2DAIUSDT-A");  // Decrease 10 million to zero.
        (,,,uint256 univ2DaiUsdtLine,) = VatAbstract(MCD_VAT).ilks("UNIV2DAIUSDT-A");
        DssExecLib.setIlkDebtCeiling("UNIV2DAIUSDT-A", 0); // -univ2DaiUsdtLine

        uint256 reduced = add( add(lrcLine, univ2EthUsdtLine) , univ2DaiUsdtLine);

        uint256 Line = VatAbstract(MCD_VAT).Line();
        VatAbstract(MCD_VAT).file("Line", sub(Line, reduced));

        // -----------  Increase UNIV2DAUUSDC-A Maximum Debt Ceiling -----------
        // TODO: add poll link

        DssExecLib.setIlkAutoLineParameters("UNIV2DAIUSDC-A", 250 * MILLION, 10 * MILLION, 8 hours); // 50 million to 250 million.
        // TODO: should we update Line in VAT due to this autoline changes?

        // ----------- Housekeeping -----------

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
