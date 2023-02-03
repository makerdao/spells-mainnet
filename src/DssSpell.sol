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

interface OptimismGovRelayLike {
    function relay(address target, bytes calldata targetData, uint32 l2gas) external;
}

interface ArbitrumGovRelayLike {
    function relay(
        address target,
        bytes calldata targetData,
        uint256 l1CallValue,
        uint256 maxGas,
        uint256 gasPriceBid,
        uint256 maxSubmissionCost
    ) external payable;
}

interface StarknetGovRelayLike {
    function relay(uint256 spell) external payable;
}

interface StarknetEscrowLike {
    function approve(address token, address spender, uint256 value) external;
}

contract DssSpellAction is DssAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: cast keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/TODO/governance/votes/TODO.md -q -O - 2>/dev/null)"
    string public constant override description =
        "2023-02-03 MakerDAO Executive Spell | Hash: 0x0";

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

    address internal constant TECH_WALLET = 0x2dC0420A736D1F40893B9481D8968E4D7424bC0B;
    address internal constant COM_WALLET  = 0x1eE3ECa7aEF17D1e74eD7C447CcBA61aC76aDbA9;
    address internal constant SF01_WALLET = 0x4Af6f22d454581bF31B2473Ebe25F5C6F55E028D;

    address immutable internal OPTIMISM_GOV_RELAY = DssExecLib.getChangelogAddress("OPTIMISM_GOV_RELAY");
    address immutable internal ARBITRUM_GOV_RELAY = DssExecLib.getChangelogAddress("ARBITRUM_GOV_RELAY");
    address immutable internal STARKNET_GOV_RELAY = DssExecLib.getChangelogAddress("STARKNET_GOV_RELAY");

    address immutable internal DAI = DssExecLib.getChangelogAddress("MCD_DAI");
    address immutable internal STARKNET_ESCROW = DssExecLib.getChangelogAddress("STARKNET_ESCROW");
    address immutable internal STARKNET_DAI_BRIDGE_LEGACY = DssExecLib.getChangelogAddress("STARKNET_DAI_BRIDGE_LEGACY");

    address constant internal OPTIMISM_L2_SPELL = 0x9495632F53Cc16324d2FcFCdD4EB59fb88dDab12;
    address constant internal ARBITRUM_L2_SPELL = 0x852CCBB823D73b3e35f68AD6b14e29B02360FD3d;
    uint256 constant internal STARKNET_L2_SPELL = 0x4e7d83cd693f8b518f9638ce47d573fd2d642371ee266d6ed55e1276d5b43c3;

    // run ./scripts/get-opt-relay-cost.sh to help determine Optimism relay param
    uint32 public constant OPT_MAX_GAS = 100_000; // = 44582 gas (estimated L2 execution cost) + margin

    // run ./scripts/get-arb-relay-cost.sh to help determine Arbitrum relay params
    uint256 public constant ARB_MAX_GAS = 100_000; // = 38_920 gas (estimated L1 calldata + L2 execution cost) + margin (to account for surge in L1 basefee)
    uint256 public constant ARB_GAS_PRICE_BID = 1_000_000_000; // = 0.1 gwei + 0.9 gwei margin
    uint256 public constant ARB_MAX_SUBMISSION_COST = 1e15; // = ~0.7 * 10^15 (@ ~15 gwei L1 basefee) rounded up to 1*10^15
    uint256 public constant ARB_L1_CALL_VALUE = ARB_MAX_SUBMISSION_COST + ARB_MAX_GAS * ARB_GAS_PRICE_BID;

    // see: https://github.com/makerdao/starknet-spells-mainnet/blob/55401e8121f93d09f57f61c4e77dc0b6c73fb4f8/README.md#estimate-l1-l2-fee
    uint256 public constant STA_GAS_USAGE_ESTIMATION = 28460;

    // 500gwei, ~upper bound of monthly avg gas price in `21-`22,
    // ~100x max monthly median gas price in `21-`22
    // https://explorer.bitquery.io/ethereum/gas?from=2021-01-01&till=2023-01-31
    uint256 public constant STA_GAS_PRICE = 500000000000;
    uint256 public constant STA_L1_CALL_VALUE = STA_GAS_USAGE_ESTIMATION * STA_GAS_PRICE;

    function actions() public override {
        // ------------------ Pause Optimism Goerli L2DaiTeleportGateway -----------------
        // Forum: https://forum.makerdao.com/t/community-notice-pecu-to-redeploy-teleport-l2-gateways/19550
        // L2 Spell to execute via OPTIMISM_GOV_RELAY:
        // https://optimistic.etherscan.io/address/0x9495632f53cc16324d2fcfcdd4eb59fb88ddab12#code
        OptimismGovRelayLike(OPTIMISM_GOV_RELAY).relay(
            OPTIMISM_L2_SPELL,
            abi.encodeWithSignature("execute()"),
            OPT_MAX_GAS
        );

        // ------------------ Pause Arbitrum Goerli L2DaiTeleportGateway -----------------
        // Forum: https://forum.makerdao.com/t/community-notice-pecu-to-redeploy-teleport-l2-gateways/19550
        // L2 Spell to execute via ARBITRUM_GOV_RELAY:
        // https://arbiscan.io/address/0x852ccbb823d73b3e35f68ad6b14e29b02360fd3d#code
        // Note: ARBITRUM_GOV_RELAY must have been pre-funded with at least ARB_L1_CALL_VALUE worth of Ether
        ArbitrumGovRelayLike(ARBITRUM_GOV_RELAY).relay(
            ARBITRUM_L2_SPELL,
            abi.encodeWithSignature("execute()"),
            ARB_L1_CALL_VALUE,
            ARB_MAX_GAS,
            ARB_GAS_PRICE_BID,
            ARB_MAX_SUBMISSION_COST
        );

        // ------------------ Pause Starknet Goerli L2DaiTeleportGateway -----------------
        // Forum: https://forum.makerdao.com/t/community-notice-pecu-to-redeploy-teleport-l2-gateways/19550
        // L2 Spell to execute via STARKNET_GOV_RELAY:
        // src: https://github.com/makerdao/starknet-spells-mainnet/blob/55401e8121f93d09f57f61c4e77dc0b6c73fb4f8/src/spell.cairo
        // contract: https://voyager.online/contract/0x4e7d83cd693f8b518f9638ce47d573fd2d642371ee266d6ed55e1276d5b43c3#code
        StarknetGovRelayLike(STARKNET_GOV_RELAY).relay{value: STA_L1_CALL_VALUE}(STARKNET_L2_SPELL);

        // disallow legacy bridge on escrow
        // Forum: https://forum.makerdao.com/t/starknet-changes-for-executive-spell-on-the-week-of-2023-01-30/19607
        StarknetEscrowLike(STARKNET_ESCROW).approve(DAI, STARKNET_DAI_BRIDGE_LEGACY, 0);

        // Tech-Ops DAI Transfer
        // https://vote.makerdao.com/polling/QmUMnuGb
        DssExecLib.sendPaymentFromSurplusBuffer(TECH_WALLET, 138_894);

        // GovComms offboarding
        // https://vote.makerdao.com/polling/QmV9iktK
        // https://forum.makerdao.com/t/mip39c3-sp7-core-unit-offboarding-com-001/19068/65
        DssExecLib.sendPaymentFromSurplusBuffer(COM_WALLET, 131_200);
        DssExecLib.sendPaymentFromSurplusBuffer(0x50D2f29206a76aE8a9C2339922fcBCC4DfbdD7ea, 1_336);
        DssExecLib.sendPaymentFromSurplusBuffer(0xeD27986bf84Fa8E343aA9Ff90307291dAeF234d3, 1_983);
        DssExecLib.sendPaymentFromSurplusBuffer(0x3dfE26bEDA4282ECCEdCaF2a0f146712712e81EA, 715);
        DssExecLib.sendPaymentFromSurplusBuffer(0x74520D1690348ba882Af348223A30D760BCbD72a, 1_376);
        DssExecLib.sendPaymentFromSurplusBuffer(0x471C5806cadAFB297D9b95B914B65f626fDCD1a7, 583);
        DssExecLib.sendPaymentFromSurplusBuffer(0x051cCee0CfBF1Fe9BD891117E85bEbDFa42aFaA9, 1_026);
        DssExecLib.sendPaymentFromSurplusBuffer(0x1c138352C779af714b6cE328C9d962E5c82EBA07, 631);
        DssExecLib.sendPaymentFromSurplusBuffer(0x55f2E8728cFCCf260040cfcc24E14A6047fF4d31, 255);
        DssExecLib.sendPaymentFromSurplusBuffer(0xE004DAabEfe0322Ac1ab46A3CF382a2A0bA81Ab4, 1_758);
        DssExecLib.sendPaymentFromSurplusBuffer(0xC2bE81CeB685eea53c77975b5F9c5f82641deBC8, 3_013);
        DssExecLib.sendPaymentFromSurplusBuffer(0xdB7c1777b5d4502b3d1228c2449F1816EB507748, 2_683);

        // SPF Funding: Expanded SF-001 Domain Work
        // https://vote.makerdao.com/polling/QmTjgcHY
        DssExecLib.sendPaymentFromSurplusBuffer(SF01_WALLET, 209_000);
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) {}
}
