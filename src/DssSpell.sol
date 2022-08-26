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

pragma solidity 0.6.12;
// Enable ABIEncoderV2 when onboarding collateral through `DssExecLib.addNewCollateral()`
pragma experimental ABIEncoderV2;

import "dss-exec-lib/DssExec.sol";
import "dss-exec-lib/DssAction.sol";

// import { DssSpellCollateralAction } from "./DssSpellCollateral.sol";

import { VatAbstract } from "dss-interfaces/dss/VatAbstract.sol";
import { JugAbstract } from "dss-interfaces/dss/JugAbstract.sol";

interface RwaUrnLike {
    function draw(uint256) external;
}

interface CureLike {
    function lift(address) external;
}

interface TeleportJoinLike {
    function file(bytes32,bytes32,address) external;
    function file(bytes32,bytes32,uint256) external;
}

interface TeleportRouterLike {
    function file(bytes32,bytes32,address) external;
}

interface TeleportOracleAuthLike {
    function file(bytes32,uint256) external;
    function addSigners(address[] calldata) external;
}

interface EscrowLike {
    function approve(address,address,uint256) external;
}

contract DssSpellAction is DssAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: cast keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/f00be45def634c9185f4561a8f1549f28e704d11/governance/votes/Executive%20vote%20-%20August%2024%2C%202022.md -q -O - 2>/dev/null)"
    string public constant override description =
        "2022-08-31 MakerDAO Executive Spell | Hash: ";

    address internal constant TELEPORT_JOIN = 0xF4B72741D114a49706877366300b3053a03E7f25;
    address internal constant ORACLE_AUTH = 0xFb7b4427Fb77ad4AC24519725153CDD2C92Fc4e0;
    address internal constant ROUTER = 0x0E18ab2b7cAA7ae841bC2e0Dd819Af87A8bF8b75;
    address internal constant LINEAR_FEE = 0xE3AEA9052Aca6b8ec4CF160B5771716765f99aA5;

    bytes32 constant internal ILK = "TELEPORT-FW-A";
    bytes32 constant internal DOMAIN_ETH = "ETH-MAIN-A";

    bytes32 constant internal DOMAIN_OPT = "OPT-MAIN-A";
    address internal constant TELEPORT_GATEWAY_OPT = 0x3c27390F61058152552613a563aC0195aDc7f169;
    address internal constant ESCROW_OPT = 0x467194771dAe2967Aef3ECbEDD3Bf9a310C76C65;

    bytes32 constant internal DOMAIN_ARB = "ARB-ONE-A";
    address internal constant TELEPORT_GATEWAY_ARB = 0x39Fb4f2c0658BCE77863288d12413B23C2c2D6df;
    address internal constant ESCROW_ARB = 0xA10c7CE4b876998858b1a9E12b10092229539400;

    uint256 constant RWA009_DRAW_AMOUNT = 25_000_000 * WAD;

    // Many of the settings that change weekly rely on the rate accumulator
    // described at https://docs.makerdao.com/smart-contract-modules/rates-module
    // To check this yourself, use the following rate calculation (example 8%):
    //
    // $ bc -l <<< 'scale=27; e( l(1.08)/(60 * 60 * 24 * 365) )'
    //
    // A table of rates can be found at
    //    https://ipfs.io/ipfs/QmVp4mhhbwWGTfbh2BzwQB9eiBrQBKiqcPRZCaAxNUaar6
    //
    // --- Rates ---

    uint256 internal constant WAD = 10**18;
    uint256 internal constant RAY = 10**27;

    function actions() public override {
        // ---------------------------------------------------------------------
        // Includes changes from the DssSpellCollateralAction
        // onboardNewCollaterals();
        // offboardCollaterals();

        // ----------------------------- RWA Draws -----------------------------
        // https://vote.makerdao.com/polling/QmQMDasC#poll-detail
        // Weekly Draw for HVB
        address RWA009_A_URN = DssExecLib.getChangelogAddress("RWA009_A_URN");
        RwaUrnLike(RWA009_A_URN).draw(RWA009_DRAW_AMOUNT);

        // ------------------ Setup Teleport Fast Withdrawals -----------------
        // https://vote.makerdao.com/polling/QmahjYA2#poll-detail
        // https://forum.makerdao.com/t/layer-2-roadmap-history-and-future/17310#phase-1-l2-l1-fast-withdrawals-5

        // Setup new ilk
        VatAbstract vat = VatAbstract(DssExecLib.vat());
        JugAbstract jug = JugAbstract(DssExecLib.jug());
        CureLike cure = CureLike(DssExecLib.getChangelogAddress("MCD_CURE"));
        address dai = DssExecLib.dai();

        vat.init(ILK);
        jug.init(ILK);

        DssExecLib.increaseGlobalDebtCeiling(2_000_000);
        DssExecLib.setIlkDebtCeiling(ILK, 2_000_000);
        vat.file(ILK, "spot", RAY);

        cure.lift(TELEPORT_JOIN);

        vat.rely(TELEPORT_JOIN);

        // Configure TeleportJoin
        // Note: vow already set

        TeleportJoinLike(TELEPORT_JOIN).file("fees", DOMAIN_OPT, LINEAR_FEE);
        TeleportJoinLike(TELEPORT_JOIN).file("line", DOMAIN_OPT, 1_000_000 * WAD);

        TeleportJoinLike(TELEPORT_JOIN).file("fees", DOMAIN_ARB, LINEAR_FEE);
        TeleportJoinLike(TELEPORT_JOIN).file("line", DOMAIN_ARB, 1_000_000 * WAD);

        // Configure TeleportOracleAuth
        TeleportOracleAuthLike(ORACLE_AUTH).file("threshold", 13);
        address[] memory oracles = new address[](24);
        // All are oracle keys except the last
        oracles[0] = 0xaC8519b3495d8A3E3E44c041521cF7aC3f8F63B3;
        oracles[1] = 0x4f95d9B4D842B2E2B1d1AC3f2Cf548B93Fd77c67;
        oracles[2] = 0xE6367a7Da2b20ecB94A25Ef06F3b551baB2682e6;
        oracles[3] = 0xFbaF3a7eB4Ec2962bd1847687E56aAEE855F5D00;
        oracles[4] = 0x16655369Eb59F3e1cAFBCfAC6D3Dd4001328f747;
        oracles[5] = 0xC9508E9E3Ccf319F5333A5B8c825418ABeC688BA;
        oracles[6] = 0xA8EB82456ed9bAE55841529888cDE9152468635A;
        oracles[7] = 0x83e23C207a67a9f9cB680ce84869B91473403e7d;
        oracles[8] = 0xDA1d2961Da837891f43235FddF66BAD26f41368b;
        oracles[9] = 0x4b0E327C08e23dD08cb87Ec994915a5375619aa2;
        oracles[10] = 0xfeEd00AA3F0845AFE52Df9ECFE372549B74C69D2;
        oracles[11] = 0x8aFBD9c3D794eD8DF903b3468f4c4Ea85be953FB;
        oracles[12] = 0x8de9c5F1AC1D4d02bbfC25fD178f5DAA4D5B26dC;
        oracles[13] = 0xd94BBe83b4a68940839cD151478852d16B3eF891;
        oracles[14] = 0xa580BBCB1Cee2BCec4De2Ea870D20a12A964819e;
        oracles[15] = 0x75ef8432566A79C86BBF207A47df3963B8Cf0753;
        oracles[16] = 0xD27Fa2361bC2CfB9A591fb289244C538E190684B;
        oracles[17] = 0x60da93D9903cb7d3eD450D4F81D402f7C4F71dd9;
        oracles[18] = 0x71eCFF5261bAA115dcB1D9335c88678324b8A987;
        oracles[19] = 0x77EB6CF8d732fe4D92c427fCdd83142DB3B742f7;
        oracles[20] = 0x8ff6a38A1CD6a42cAac45F08eB0c802253f68dfD;
        oracles[21] = 0x130431b4560Cd1d74A990AE86C337a33171FF3c6;
        oracles[22] = 0x3CB645a8f10Fb7B0721eaBaE958F77a878441Cb9;
        oracles[23] = 0xd72BA9402E9f3Ff01959D6c841DDD13615FFff42;
        TeleportOracleAuthLike(ORACLE_AUTH).addSigners(oracles);

        // Configure TeleportRouter
        // Note: ETH-MAIN-A route already defined
        TeleportRouterLike(ROUTER).file("gateway", DOMAIN_OPT, TELEPORT_GATEWAY_OPT);
        TeleportRouterLike(ROUTER).file("gateway", DOMAIN_ARB, TELEPORT_GATEWAY_ARB);

        // Authorize TeleportGateways to use the escrows
        EscrowLike(ESCROW_OPT).approve(dai, TELEPORT_GATEWAY_OPT, type(uint256).max);
        EscrowLike(ESCROW_ARB).approve(dai, TELEPORT_GATEWAY_ARB, type(uint256).max);

        // Configure Chainlog
        DssExecLib.setChangelogAddress("MCD_JOIN_TELEPORT_FW_A", TELEPORT_JOIN);
        DssExecLib.setChangelogAddress("MCD_ORACLE_AUTH_TELEPORT_FW_A", ORACLE_AUTH);
        DssExecLib.setChangelogAddress("MCD_ROUTER_TELEPORT_FW_A", ROUTER);

        DssExecLib.setChangelogAddress("OPTIMISM_TELEPORT_BRIDGE", TELEPORT_GATEWAY_OPT);
        DssExecLib.setChangelogAddress("OPTIMISM_TELEPORT_FEE", LINEAR_FEE);
        DssExecLib.setChangelogAddress("ARBITRUM_TELEPORT_BRIDGE", TELEPORT_GATEWAY_ARB);
        DssExecLib.setChangelogAddress("ARBITRUM_TELEPORT_FEE", LINEAR_FEE);

        DssExecLib.setChangelogVersion("1.14.0");
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) public {}
}
