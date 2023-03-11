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

// import "dss-exec-lib/DssExec.sol";
import "dss-exec-lib/DssAction.sol";
import "dss-interfaces/dss/VatAbstract.sol";

interface PauseAbstract {
    function delay() external view returns (uint256);
    function plot(address, bytes32, bytes calldata, uint256) external;
    function exec(address, bytes32, bytes calldata, uint256) external returns (bytes memory);
}

interface Changelog {
    function getAddress(bytes32) external view returns (address);
}

interface SpellAction {
    function officeHours() external view returns (bool);
    function description() external view returns (string memory);
    function nextCastTime(uint256) external view returns (uint256);
}

interface DirectDepositMomAbstract {
    function disable(address) external;
}

contract DssExec {

    Changelog      constant public log   = Changelog(0xdA0Ab1e0017DEbCd72Be8599041a2aa3bA7e740F);
    uint256                 public eta;
    bytes                   public sig;
    bool                    public done;
    bytes32       immutable public tag;
    address       immutable public action;
    uint256       immutable public expiration;
    PauseAbstract immutable public pause;

    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: seth keccak -- "$(wget https://<executive-vote-canonical-post> -q -O - 2>/dev/null)"
    function description() external view returns (string memory) {
        return SpellAction(action).description();
    }

    function officeHours() external view returns (bool) {
        return SpellAction(action).officeHours();
    }

    function nextCastTime() external view returns (uint256 castTime) {
        return SpellAction(action).nextCastTime(eta);
    }

    // @param _description  A string description of the spell
    // @param _expiration   The timestamp this spell will expire. (Ex. block.timestamp + 30 days)
    // @param _spellAction  The address of the spell action
    constructor(uint256 _expiration, address _spellAction) {
        pause       = PauseAbstract(log.getAddress("MCD_PAUSE"));
        expiration  = _expiration;
        action      = _spellAction;

        sig = abi.encodeWithSignature("execute()");
        bytes32 _tag;                    // Required for assembly access
        address _action = _spellAction;  // Required for assembly access
        assembly { _tag := extcodehash(_action) }
        tag = _tag;
    }

    function schedule() public {
        require(block.timestamp <= expiration, "This contract has expired");
        require(eta == 0, "This spell has already been scheduled");
        eta = block.timestamp + PauseAbstract(pause).delay();
        pause.plot(action, tag, sig, eta);

        DirectDepositMomAbstract(log.getAddress("DIRECT_MOM")).disable(
            log.getAddress("DIRECT_COMPV2_DAI_PLAN")
        );

        DirectDepositMomAbstract(log.getAddress("DIRECT_MOM")).disable(
            log.getAddress("DIRECT_AAVEV2_DAI_PLAN")
        );
    }

    function cast() public {
        require(!done, "spell-already-cast");
        done = true;
        pause.exec(action, tag, sig, eta);
    }
}

contract DssSpellAction is DssAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: cast keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/TODO/governance/votes/Executive%TODO.md -q -O - 2>/dev/null)"
    string public constant override description =
        "2023-03-11 MakerDAO Executive Spell | Hash: TODO";

    // Turn office hours off
    function officeHours() public pure override returns (bool) {
        return false;
    }

    // Many of the settings that change weekly rely on the rate accumulator
    // described at https://docs.makerdao.com/smart-contract-modules/rates-module
    // To check this yourself, use the following rate calculation (example 8%):
    //
    // $ bc -l <<< 'scale=27; e( l(1.08)/(60 * 60 * 24 * 365) )'
    //
    // A table of rates can be found at
    //    https://ipfs.io/ipfs/QmVp4mhhbwWGTfbh2BzwQB9eiBrQBKiqcPRZCaAxNUaar6
    //
    // uint256 internal constant X_PCT_RATE      = ;

    uint256 internal constant MILLION = 10 ** 6;
    uint256 internal constant BILLION = 10 ** 9;

    uint256 internal constant WAD     = 10 ** 18;

    uint256 internal constant PSM_HUNDRED_BASIS_POINTS = 100 * WAD / 10000;

    address internal immutable MCD_PSM_USDC_A = DssExecLib.getChangelogAddress("MCD_PSM_USDC_A");
    address internal immutable MCD_PSM_PAX_A  = DssExecLib.getChangelogAddress("MCD_PSM_PAX_A");

    function actions() public override {
        // Reduce UNIV2USDCETH-A, UNIV2DAIUSDC-A, GUNIV3DAIUSDC1-A and GUNIV3DAIUSDC2-A Debt Ceilings to 0
        uint256 totalLineReduction;
        uint256 line;
        VatAbstract vat = VatAbstract(DssExecLib.vat());

        (,,,line,) = vat.ilks("UNIV2USDCETH-A");
        totalLineReduction = totalLineReduction + line;
        DssExecLib.removeIlkFromAutoLine("UNIV2USDCETH-A");
        DssExecLib.setIlkDebtCeiling("UNIV2USDCETH-A", 0);

        (,,,line,) = vat.ilks("UNIV2DAIUSDC-A");
        totalLineReduction = totalLineReduction + line;
        DssExecLib.removeIlkFromAutoLine("UNIV2DAIUSDC-A");
        DssExecLib.setIlkDebtCeiling("UNIV2DAIUSDC-A", 0);

        (,,,line,) = vat.ilks("GUNIV3DAIUSDC1-A");
        totalLineReduction = totalLineReduction + line;
        DssExecLib.removeIlkFromAutoLine("GUNIV3DAIUSDC1-A");
        DssExecLib.setIlkDebtCeiling("GUNIV3DAIUSDC1-A", 0);

        (,,,line,) = vat.ilks("GUNIV3DAIUSDC2-A");
        totalLineReduction = totalLineReduction + line;
        DssExecLib.removeIlkFromAutoLine("GUNIV3DAIUSDC2-A");
        DssExecLib.setIlkDebtCeiling("GUNIV3DAIUSDC2-A", 0);

        // Decrease Global Debt Ceiling in accordance with Offboarded Ilks
        vat.file("Line", vat.Line() - totalLineReduction);

        // Set DC-IAM module for PSM-USDC-A, PSM-PAX-A and PSM-GUSD-A
        DssExecLib.setIlkAutoLineParameters("PSM-USDC-A", 10 * BILLION, 250 * MILLION, 24 hours);
        DssExecLib.setIlkAutoLineParameters("PSM-PAX-A", 1 * BILLION, 250 * MILLION, 24 hours);
        DssExecLib.setIlkAutoLineParameters("PSM-GUSD-A", 500 * MILLION, 10 * MILLION, 24 hours);

        // Increase PSM-USDC-A tin from 0% to 1%
        DssExecLib.setValue(MCD_PSM_USDC_A, "tin", PSM_HUNDRED_BASIS_POINTS);

        // Reduce PSM-USDP-A tin to 0%
        DssExecLib.setValue(MCD_PSM_PAX_A, "tin", 0);

        // Increase PSM-USDP-A tout to 1%
        DssExecLib.setValue(MCD_PSM_PAX_A, "tout", PSM_HUNDRED_BASIS_POINTS);
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) {}
}
