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
import { MCD, DssInstance } from "dss-test/MCD.sol";

import { UsdsInit } from "./dependencies/01-usds/UsdsInit.sol";
import { UsdsInstance } from "./dependencies/01-usds/UsdsInstance.sol";

import { SUsdsInit, SUsdsConfig } from "./dependencies/02-susds/SUsdsInit.sol";
import { SUsdsInstance } from "./dependencies/02-susds/SUsdsInstance.sol";

import { SkyInit } from "./dependencies/03-sky/SkyInit.sol";
import { SkyInstance } from "./dependencies/03-sky/SkyInstance.sol";

import { UniV2PoolMigratorInit } from "./dependencies/04-univ2-pool-migrator/UniV2PoolMigratorInit.sol";

interface PauseLike {
    function delay() external view returns (uint256);
    function plot(address, bytes32, bytes calldata, uint256) external;
    function exec(address, bytes32, bytes calldata, uint256) external returns (bytes memory);
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
    ChainlogLike  constant public chainlog = ChainlogLike(0xdA0Ab1e0017DEbCd72Be8599041a2aa3bA7e740F);
    uint256                public eta;
    bytes                  public sig;
    bool                   public done;
    bytes32      immutable public tag;
    address      immutable public action;
    uint256      immutable public expiration;
    PauseLike    immutable public pause;

    uint256 constant public MIN_ETA = 1726574400; // 2024-09-17T12:00:00Z

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
        // Even if the spell gathers enough support too fast, we do not allow it to be executed before MIN_ETA.
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
    // Hash: cast keccak -- "$(wget 'https://raw.githubusercontent.com/makerdao/community/3c1ea8b373f3fc30885619ddcc8ee7aa2be0030a/governance/votes/Executive%20vote%20-%20September%205%2C%202024.md' -q -O - 2>/dev/null)"
    string public constant override description =
        "2024-09-17 MakerDAO Executive Spell | Hash: TODO";

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
    uint256 internal constant SIX_PT_TWO_FIVE_PCT_RATE = 1000000001922394148741344865;

    // ---------- Phase 1b Addresses ----------

    address internal constant USDS          = 0xdC035D45d973E3EC169d2276DDab16f1e407384F;
    address internal constant USDS_IMP      = 0x1923DfeE706A8E78157416C29cBCCFDe7cdF4102;
    address internal constant USDS_JOIN     = 0x3C0f895007CA717Aa01c8693e59DF1e8C3777FEB;
    address internal constant DAI_USDS      = 0x3225737a9Bbb6473CB4a45b7244ACa2BeFdB276A;

    address internal constant SUSDS         = 0xa3931d71877C0E7a3148CB7Eb4463524FEc27fbD;
    address internal constant SUSDS_IMP     = 0x4e7991e5C547ce825BdEb665EE14a3274f9F61e0;

    address internal constant SKY           = 0x56072C95FAA701256059aa122697B133aDEd9279;
    address internal constant MKR_SKY       = 0xBDcFCA946b6CDd965f99a839e4435Bcdc1bc470B;

    address internal constant PAIR_DAI_MKR  = 0x517F9dD285e75b599234F7221227339478d0FcC8;
    address internal constant PAIR_USDS_SKY = 0x2621CC0B3F3c079c1Db0E80794AA24976F0b9e3c;

    function actions() public override {

        // Note: load the MCD contracts depencencies
        DssInstance memory dss = MCD.loadFromChainlog(DssExecLib.LOG);

        // ---------- New Tokens Init ----------
        // Forum: TODO
        // Poll: TODO
        // MIP: TODO

        // Init USDS by calling UsdsInit.init with the following parameters:
        // Init USDS with usds parameter being 0xdC035D45d973E3EC169d2276DDab16f1e407384F
        // Init USDS with usdsImp parameter being 0x1923DfeE706A8E78157416C29cBCCFDe7cdF4102
        // Init USDS with UsdsJoin parameter being 0x3C0f895007CA717Aa01c8693e59DF1e8C3777FEB
        // Init USDS with DaiUsds parameter being 0x3225737a9Bbb6473CB4a45b7244ACa2BeFdB276A
        UsdsInit.init(
            dss,
            UsdsInstance({
                usds: USDS,
                usdsImp: USDS_IMP,
                usdsJoin: USDS_JOIN,
                daiUsds: DAI_USDS
            })
        );

        // Init sUSDS by calling SUsdsInit.init with the following parameters:
        // Init sUSDS with sUsds parameter being 0xa3931d71877C0E7a3148CB7Eb4463524FEc27fbD
        // Init sUSDS with sUsdsImp parameter being 0x4e7991e5C547ce825BdEb665EE14a3274f9F61e0
        // Init sUSDS with usdsJoin parameter being 0x3C0f895007CA717Aa01c8693e59DF1e8C3777FEB
        // Init sUSDS with usds parameter being 0xdC035D45d973E3EC169d2276DDab16f1e407384F
        // Init sUSDS with ssr parameter being 6.25%
        SUsdsInit.init(
            dss,
            SUsdsInstance({
                sUsds: SUSDS,
                sUsdsImp: SUSDS_IMP
            }),
            SUsdsConfig({
                usdsJoin: USDS_JOIN,
                usds: USDS,
                ssr: SIX_PT_TWO_FIVE_PCT_RATE
            })
        );

        // Init SKY by calling SkyInit.init with the following parameters:
        // Init SKY with sky parameter being 0x56072C95FAA701256059aa122697B133aDEd9279
        // Init SKY with mkrSky parameter being 0xBDcFCA946b6CDd965f99a839e4435Bcdc1bc470B
        // Init SKY with rate parameter being 24,000
        SkyInit.init(
            dss,
            SkyInstance({
                sky: SKY,
                mkrSky: MKR_SKY
            }),
            24_000
        );

        // ---------- Pool Migration and Flapper Init ----------

        // Migrate liquidity to the new pool by calling UniV2PoolMigratorInit.init with the following parameters:
        // Migrate liquidity to the new pool with pairDaiMkr parameter being 0x517F9dD285e75b599234F7221227339478d0FcC8
        // Migrate liquidity to the new pool with pairUsdsSky parameter being 0x2621CC0B3F3c079c1Db0E80794AA24976F0b9e3c
        UniV2PoolMigratorInit.init(
            dss,
            PAIR_DAI_MKR,
            PAIR_USDS_SKY
        );
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) {}
}
