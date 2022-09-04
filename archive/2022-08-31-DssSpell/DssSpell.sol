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
// pragma experimental ABIEncoderV2;

import "dss-exec-lib/DssExec.sol";
import "dss-exec-lib/DssAction.sol";

// import { DssSpellCollateralAction } from "./DssSpellCollateral.sol";

import { VatAbstract } from "dss-interfaces/dss/VatAbstract.sol";
import { JugAbstract } from "dss-interfaces/dss/JugAbstract.sol";
import { IlkRegistryAbstract } from "dss-interfaces/dss/IlkRegistryAbstract.sol";
import { DaiAbstract } from "dss-interfaces/dss/DaiAbstract.sol";

interface RwaUrnLike {
    function draw(uint256) external;
}

interface CureLike {
    function lift(address) external;
}

interface TeleportJoinLike {
    function rely(address) external;
    function file(bytes32,address) external;
    function file(bytes32,bytes32,address) external;
    function file(bytes32,bytes32,uint256) external;
    function vat() external view returns (address);
    function daiJoin() external view returns (address);
    function ilk() external view returns (bytes32);
    function domain() external view returns (bytes32);
}

interface TeleportRouterLike {
    function rely(address) external;
    function file(bytes32,bytes32,address) external;
    function gateways(bytes32) external view returns (address);
    function domains(address) external view returns (bytes32);
    function dai() external view returns (address);
}

interface TeleportOracleAuthLike {
    function rely(address) external;
    function file(bytes32,uint256) external;
    function addSigners(address[] calldata) external;
    function teleportJoin() external view returns (address);
}

interface TeleportFeeLike {
    function fee() external view returns (uint256);
    function ttl() external view returns (uint256);
}

interface EscrowLike {
    function approve(address,address,uint256) external;
}

interface TeleportBridgeLike {
    function l1Escrow() external view returns (address);
    function l1TeleportRouter() external view returns (address);
    function l1Token() external view returns (address);
    function l2TeleportGateway() external view returns (address);
}

interface OptimismTeleportBridgeLike is TeleportBridgeLike {
    function messenger() external view returns (address);
}

interface ArbitrumTeleportBridgeLike is TeleportBridgeLike {
    function inbox() external view returns (address);
}

contract DssSpellAction is DssAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: cast keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/7ec65311cebe0d79e349300e7681cfa13583a5bb/governance/votes/Executive%20vote%20-%20August%2031%2C%202022.md -q -O - 2>/dev/null)"
    string public constant override description =
        "2022-08-31 MakerDAO Executive Spell | Hash: 0x63220529d84b7a0ab1758dfd9d14e30d37ce6bf3d3f22a17e76fc26aef76c9cb";

    address internal constant TELEPORT_JOIN = 0x41Ca7a7Aa2Be78Cf7CB80C0F4a9bdfBC96e81815;
    address internal constant ORACLE_AUTH = 0x324a895625E7AE38Fc7A6ae91a71e7E937Caa7e6;
    address internal constant ROUTER = 0xeEf8B35eD538b6Ef7DbA82236377aDE4204e5115;
    address internal constant LINEAR_FEE = 0xA7C088AAD64512Eff242901E33a516f2381b8823;

    bytes32 internal constant ILK = "TELEPORT-FW-A";
    bytes32 internal constant DOMAIN_ETH = "ETH-MAIN-A";

    bytes32 internal constant DOMAIN_OPT = "OPT-MAIN-A";
    address internal constant TELEPORT_GATEWAY_OPT = 0x920347f49a9dbe50865EB6161C3B2774AC046A7F;
    address internal constant TELEPORT_L2_GATEWAY_OPT = 0x18d2CF2296c5b29343755E6B7e37679818913f88;
    address internal constant MESSENGER_OPT = 0x25ace71c97B33Cc4729CF772ae268934F7ab5fA1;

    bytes32 internal constant DOMAIN_ARB = "ARB-ONE-A";
    address internal constant TELEPORT_GATEWAY_ARB = 0x22218359E78bC34E532B653198894B639AC3ed72;
    address internal constant TELEPORT_L2_GATEWAY_ARB = 0x5dBaf6F2bEDebd414F8d78d13499222347e59D5E;
    address internal constant INBOX_ARB = 0x4Dbd4fc535Ac27206064B68FfCf827b0A60BAB3f;

    uint256 internal constant RWA009_DRAW_AMOUNT = 25_000_000 * WAD;

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
        IlkRegistryAbstract ilkRegistry = IlkRegistryAbstract(DssExecLib.reg());
        address esm = DssExecLib.esm();
        address escrowOpt = DssExecLib.getChangelogAddress("OPTIMISM_ESCROW");
        address escrowArb = DssExecLib.getChangelogAddress("ARBITRUM_ESCROW");

        // Run sanity checks
        require(TeleportJoinLike(TELEPORT_JOIN).vat() == address(vat));
        require(TeleportJoinLike(TELEPORT_JOIN).daiJoin() ==  DssExecLib.daiJoin());
        require(TeleportJoinLike(TELEPORT_JOIN).ilk() == ILK);
        require(TeleportJoinLike(TELEPORT_JOIN).domain() == DOMAIN_ETH);
        require(TeleportOracleAuthLike(ORACLE_AUTH).teleportJoin() == TELEPORT_JOIN);
        require(TeleportRouterLike(ROUTER).dai() == dai);
        require(TeleportFeeLike(LINEAR_FEE).fee() == WAD / 10000);
        require(TeleportFeeLike(LINEAR_FEE).ttl() == 8 days);
        require(OptimismTeleportBridgeLike(TELEPORT_GATEWAY_OPT).l1Escrow() == escrowOpt);
        require(OptimismTeleportBridgeLike(TELEPORT_GATEWAY_OPT).l1TeleportRouter() == ROUTER);
        require(OptimismTeleportBridgeLike(TELEPORT_GATEWAY_OPT).l1Token() == dai);
        require(OptimismTeleportBridgeLike(TELEPORT_GATEWAY_OPT).l2TeleportGateway() == TELEPORT_L2_GATEWAY_OPT);
        require(OptimismTeleportBridgeLike(TELEPORT_GATEWAY_OPT).messenger() == MESSENGER_OPT);
        require(ArbitrumTeleportBridgeLike(TELEPORT_GATEWAY_ARB).l1Escrow() == escrowArb);
        require(ArbitrumTeleportBridgeLike(TELEPORT_GATEWAY_ARB).l1TeleportRouter() == ROUTER);
        require(ArbitrumTeleportBridgeLike(TELEPORT_GATEWAY_ARB).l1Token() == dai);
        require(ArbitrumTeleportBridgeLike(TELEPORT_GATEWAY_ARB).l2TeleportGateway() == TELEPORT_L2_GATEWAY_ARB);
        require(ArbitrumTeleportBridgeLike(TELEPORT_GATEWAY_ARB).inbox() == INBOX_ARB);

        vat.init(ILK);
        jug.init(ILK);

        DssExecLib.increaseGlobalDebtCeiling(2_000_000);
        DssExecLib.setIlkDebtCeiling(ILK, 2_000_000);
        vat.file(ILK, "spot", RAY);

        cure.lift(TELEPORT_JOIN);

        vat.rely(TELEPORT_JOIN);

        // Configure TeleportJoin
        TeleportJoinLike(TELEPORT_JOIN).rely(ORACLE_AUTH);
        TeleportJoinLike(TELEPORT_JOIN).rely(ROUTER);
        TeleportJoinLike(TELEPORT_JOIN).rely(esm);

        TeleportJoinLike(TELEPORT_JOIN).file("vow", DssExecLib.vow());

        TeleportJoinLike(TELEPORT_JOIN).file("fees", DOMAIN_OPT, LINEAR_FEE);
        TeleportJoinLike(TELEPORT_JOIN).file("line", DOMAIN_OPT, 1_000_000 * WAD);

        TeleportJoinLike(TELEPORT_JOIN).file("fees", DOMAIN_ARB, LINEAR_FEE);
        TeleportJoinLike(TELEPORT_JOIN).file("line", DOMAIN_ARB, 1_000_000 * WAD);

        // Configure TeleportOracleAuth
        TeleportOracleAuthLike(ORACLE_AUTH).rely(esm);

        TeleportOracleAuthLike(ORACLE_AUTH).file("threshold", 13);
        address[] memory oracles = new address[](24);
        // https://forum.makerdao.com/t/maker-teleport-oracle-launch-configuration/17471
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
        TeleportRouterLike(ROUTER).rely(esm);

        TeleportRouterLike(ROUTER).file("gateway", DOMAIN_ETH, TELEPORT_JOIN);
        TeleportRouterLike(ROUTER).file("gateway", DOMAIN_OPT, TELEPORT_GATEWAY_OPT);
        TeleportRouterLike(ROUTER).file("gateway", DOMAIN_ARB, TELEPORT_GATEWAY_ARB);

        // Authorize TeleportGateways to use the escrows
        EscrowLike(escrowOpt).approve(dai, TELEPORT_GATEWAY_OPT, type(uint256).max);
        EscrowLike(escrowArb).approve(dai, TELEPORT_GATEWAY_ARB, type(uint256).max);

        // Add to ilk registry
        ilkRegistry.put(
            ILK,
            TELEPORT_JOIN,
            address(0),
            0,
            4,
            address(0),
            address(0),
            "",
            ""
        );

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
