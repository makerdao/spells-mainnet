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

interface ProxyLike {
    function exec(address target, bytes calldata args) external payable returns (bytes memory out);
}

interface PauseLike {
    function delay() external view returns (uint256);
    function exec(address, bytes32, bytes calldata, uint256) external returns (bytes memory);
    function plot(address, bytes32, bytes calldata, uint256) external;
}

interface ChainlogLike {
    function getAddress(bytes32) external view returns (address);
}

interface SpellActionLike {
    function officeHours() external view returns (bool);
    function description() external view returns (string memory);
    function nextCastTime(uint256) external view returns (uint256);
}

contract DssExec {
    ChainlogLike  constant public   chainlog = ChainlogLike(0xdA0Ab1e0017DEbCd72Be8599041a2aa3bA7e740F);
    uint256                public   eta;
    bytes                  public   sig;
    bool                   public   done;
    bytes32      immutable public   tag;
    address      immutable public   action;
    uint256      immutable public   expiration;
    PauseLike    immutable public   pause;

    // 2025-06-30T14:00:00Z
    uint256       constant internal JUN_30_2025_14_00_UTC = 1750428000;
    uint256       constant public   MIN_ETA              = JUN_30_2025_14_00_UTC;

    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: seth keccak -- "$(wget https://<executive-vote-canonical-post> -q -O - 2>/dev/null)"
    function description() external view returns (string memory) {
        return SpellActionLike(action).description();
    }

    function officeHours() external view returns (bool) {
        return SpellActionLike(action).officeHours();
    }

    function nextCastTime() external view returns (uint256 castTime) {
        return SpellActionLike(action).nextCastTime(eta);
    }

    // @param _description  A string description of the spell
    // @param _expiration   The timestamp this spell will expire. (Ex. block.timestamp + 30 days)
    // @param _spellAction  The address of the spell action
    constructor(uint256 _expiration, address _spellAction) {
        pause       = PauseLike(chainlog.getAddress("MCD_PAUSE"));
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
        // ---------- Set earliest execution date June 30, 14:00 UTC ----------
        // Forum: TODO
        // Poll: TODO
        // Note: In case the spell is scheduled later than planned, we have to switch
        //       back to the regular logic to respect GSM delay enforced by MCD_PAUSE
        eta = _max(block.timestamp + PauseLike(pause).delay(), MIN_ETA);
        pause.plot(action, tag, sig, eta);
    }

    function cast() public {
        require(!done, "spell-already-cast");
        done = true;
        pause.exec(action, tag, sig, eta);
    }

    function _max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }
}

contract DssSpellAction is DssAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: cast keccak -- "$(wget 'TODO' -q -O - 2>/dev/null)"
    string public constant override description = "2025-06-26 MakerDAO Executive Spell | Hash: TODO";

    // Set office hours according to the summary
    function officeHours() public pure override returns (bool) {
        return false;
    }

    // ---------- Execute Spark Proxy Spell ----------
    address internal constant SPARK_PROXY = 0x3300f198988e4C9C63F75dF86De36421f06af8c4;
    address internal constant SPARK_SPELL = address(0);

    function actions() public override {
        // ---------- Execute Spark Proxy Spell ----------
        // Forum: TODO
        // Poll: TODO

        // Execute Spark Proxy Spell at address TODO
        // ProxyLike(SPARK_PROXY).exec(SPARK_SPELL, abi.encodeWithSignature("execute()"));
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) {}
}
