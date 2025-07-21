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

import {VestAbstract} from "dss-interfaces/dss/VestAbstract.sol";
import {DssAutoLineAbstract} from "dss-interfaces/dss/DssAutoLineAbstract.sol";
import {GemAbstract} from "dss-interfaces/ERC/GemAbstract.sol";

interface VestedRewardsDistributionLike {
    function distribute() external returns (uint256 amount);
}

interface DaiUsdsLike {
    function daiToUsds(address usr, uint256 wad) external;
}

contract DssSpellAction is DssAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: cast keccak -- "$(wget 'TODO' -q -O - 2>/dev/null)"
    string public constant override description = "2025-07-24 MakerDAO Executive Spell | Hash: TODO";

    // Set office hours according to the summary
    function officeHours() public pure override returns (bool) {
        return true;
    }

    // Note: by the previous convention it should be a comma-separated list of DAO resolutions IPFS hashes
    string public constant dao_resolutions = "bafkreidm3bqfiwv224m6w4zuabsiwqruy22sjfaxfvgx4kgcnu3wndxmva";

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
    uint256 internal constant MILLION = 10 ** 6;
    uint256 internal constant WAD     = 10 ** 18;
    uint256 internal constant RAY     = 10 ** 27;

    // ---------- Addresses ----------
    address internal immutable DAI                   = DssExecLib.dai();
    address internal immutable MCD_SPOT              = DssExecLib.spotter();
    address internal immutable MCD_VEST_SKY_TREASURY = DssExecLib.getChangelogAddress("MCD_VEST_SKY_TREASURY");
    address internal immutable REWARDS_DIST_USDS_SKY = DssExecLib.getChangelogAddress("REWARDS_DIST_USDS_SKY");
    address internal immutable MCD_IAM_AUTO_LINE     = DssExecLib.getChangelogAddress("MCD_IAM_AUTO_LINE");
    address internal immutable SKY                   = DssExecLib.getChangelogAddress("SKY");
    address internal immutable DAI_USDS              = DssExecLib.getChangelogAddress("DAI_USDS");

    // ---------- Wallets ----------
    address internal constant BLUE           = 0xb6C09680D822F162449cdFB8248a7D3FC26Ec9Bf;
    address internal constant BONAPUBLICA    = 0x167c1a762B08D7e78dbF8f24e5C3f1Ab415021D3;
    address internal constant CLOAKY_2       = 0x9244F47D70587Fa2329B89B6f503022b63Ad54A5;
    address internal constant JULIACHANG     = 0x252abAEe2F4f4b8D39E5F12b163eDFb7fac7AED7;
    address internal constant WBC            = 0xeBcE83e491947aDB1396Ee7E55d3c81414fB0D47;
    address internal constant PBG            = 0x8D4df847dB7FfE0B46AF084fE031F7691C6478c2;
    address internal constant EXCEL          = 0x0F04a22B62A26e25A29Cba5a595623038ef7AcE7;
    address internal constant CLOAKY_KOHLA_2 = 0x73dFC091Ad77c03F2809204fCF03C0b9dccf8c7a;
    address internal constant AEGIS_D        = 0x78C180CF113Fe4845C325f44648b6567BC79d6E0;

    function actions() public override {
        // ---------- MKR to SKY Upgrade Phase Three: Offboard LSE-MKR-A ----------
        // Forum: https://forum.sky.money/t/phase-3-mkr-to-sky-migration-items-july-24th-spell/26750
        // Atlas: https://sky-atlas.powerhouse.io/A.4.1.2.1.4.2.2_Offboard_Borrowing_Against_Staked_MKR/1f1f2ff0-8d73-8024-bf88-f0a17374ceea%7Cb341f4c0b83472dc1f9e1a3b

        // Increase LSE-MKR-A liquidation ratio by 9,875 percentage points, from 125% to 10,000%
        DssExecLib.setValue(MCD_SPOT, "LSE-MKR-A", "mat", 100 * RAY);

        // Reduce LSE-MKR-A chop for 8 percentage points, from 8% to 0%
        DssExecLib.setIlkLiquidationPenalty("LSE-MKR-A", 0);

        // ---------- Sky Token Rewards Rebalance ----------
        // Forum: https://forum.sky.money/t/sky-token-rewards-usds-to-sky-rewards-normalization-configuration/26638/8
        // Forum: https://forum.sky.money/t/sky-token-rewards-usds-to-sky-rewards-normalization-configuration/26638/9

        // Yank MCD_VEST_SKY_TREASURY vest with ID 4
        VestAbstract(MCD_VEST_SKY_TREASURY).yank(4);

        // VestedRewardsDistribution.distribute() on REWARDS_DIST_USDS_SKY
        VestedRewardsDistributionLike(REWARDS_DIST_USDS_SKY).distribute();

        // ---------- Create a New MCD_VEST_SKY_TREASURY Stream ----------
        // Forum: https://forum.sky.money/t/sky-token-rewards-usds-to-sky-rewards-normalization-configuration/26638/8
        // Forum: https://forum.sky.money/t/sky-token-rewards-usds-to-sky-rewards-normalization-configuration/26638/9

        // res: 1 (restricted)
        // Note: the stream is restricted below, right after being created

        // MCD_VEST_SKY_TREASURY Vest Stream  | from 'block.timestamp' to 'block.timestamp + 15,724,800 seconds' | 100,851,495 * WAD SKY | REWARDS_DIST_USDS_SKY
        uint256 vestId = VestAbstract(MCD_VEST_SKY_TREASURY).create(
            REWARDS_DIST_USDS_SKY,
            100_851_495 * WAD,
            block.timestamp,
            15_724_800 seconds,
            0,
            address(0)
        );

        // Note: restricting the stream, as instructed above
        VestAbstract(MCD_VEST_SKY_TREASURY).restrict(vestId);

        // Note: we need to increase SKY allowance for MCD_VEST_SKY_TREASURY to the sum of all streams
        GemAbstract(SKY).approve(
            MCD_VEST_SKY_TREASURY,
            VestAbstract(MCD_VEST_SKY_TREASURY).tot(1) - VestAbstract(MCD_VEST_SKY_TREASURY).rxd(1) +
            VestAbstract(MCD_VEST_SKY_TREASURY).tot(2) - VestAbstract(MCD_VEST_SKY_TREASURY).rxd(2) +
            VestAbstract(MCD_VEST_SKY_TREASURY).tot(3) - VestAbstract(MCD_VEST_SKY_TREASURY).rxd(3) +
            100_851_495 * WAD
        );

        // File the new stream ID on REWARDS_DIST_USDS_SKY
        DssExecLib.setValue(REWARDS_DIST_USDS_SKY, "vestId", vestId);

        // ---------- Delegate Compensation for June 2025 ----------
        // Forum: https://forum.sky.money/t/june-2025-aligned-delegate-compensation/26816
        // Atlas: https://sky-atlas.powerhouse.io/Budget_And_Participation_Requirements/4c698938-1a11-4486-a568-e54fc6b0ce0c%7C0db3af4e

        // BLUE - 4,000 USDS - 0xb6C09680D822F162449cdFB8248a7D3FC26Ec9Bf
        _transferUsds(BLUE, 4_000 * WAD);

        // Bonapublica - 4,000 USDS - 0x167c1a762B08D7e78dbF8f24e5C3f1Ab415021D3
        _transferUsds(BONAPUBLICA, 4_000 * WAD);

        // Cloaky - 4,000 USDS - 0x9244F47D70587Fa2329B89B6f503022b63Ad54A5
        _transferUsds(CLOAKY_2, 4_000 * WAD);

        // JuliaChang - 4,000 USDS - 0x252abAEe2F4f4b8D39E5F12b163eDFb7fac7AED7
        _transferUsds(JULIACHANG, 4_000 * WAD);

        // WBC - 3,733 USDS - 0xeBcE83e491947aDB1396Ee7E55d3c81414fB0D47
        _transferUsds(WBC, 3_733 * WAD);

        // PBG - 800 USDS - 0x8D4df847dB7FfE0B46AF084fE031F7691C6478c2
        _transferUsds(PBG, 800 * WAD);

        // Excel - 400 USDS - 0x0F04a22B62A26e25A29Cba5a595623038ef7AcE7
        _transferUsds(EXCEL, 400 * WAD);

        // AegisD - 129 USDS - 0x78C180CF113Fe4845C325f44648b6567BC79d6E0
        _transferUsds(AEGIS_D, 129 * WAD);

        // ---------- Atlas Core Development USDS Payments for July 2025 ----------
        // Forum: https://forum.sky.money/t/atlas-core-development-payment-requests-july-2025/26779
        // Forum: https://forum.sky.money/t/atlas-core-development-payment-requests-july-2025/26779/6

        // BLUE - 50,167 USDS - 0xb6C09680D822F162449cdFB8248a7D3FC26Ec9Bf
        _transferUsds(BLUE, 50_167 * WAD);

        // Cloaky - 16,417 USDS - 0x9244F47D70587Fa2329B89B6f503022b63Ad54A5
        _transferUsds(CLOAKY_2, 16_417 * WAD);

        // Kohla - 11,000 USDS - 0x73dFC091Ad77c03F2809204fCF03C0b9dccf8c7a
        _transferUsds(CLOAKY_KOHLA_2, 11_000 * WAD);

        // ---------- Atlas Core Development SKY Payments for July 2025 ----------
        // Forum: https://forum.sky.money/t/atlas-core-development-payment-requests-july-2025/26779
        // Forum: https://forum.sky.money/t/atlas-core-development-payment-requests-july-2025/26779/6

        // BLUE - 330,000 SKY - 0xb6C09680D822F162449cdFB8248a7D3FC26Ec9Bf
        GemAbstract(SKY).transfer(BLUE, 330_000 * WAD);

        // Cloaky - 288,000 SKY - 0x9244F47D70587Fa2329B89B6f503022b63Ad54A5
        GemAbstract(SKY).transfer(CLOAKY_2, 288_000 * WAD);

        // ---------- HVB DAO Resolution ----------
        // Forum: https://forum.sky.money/t/huntingdon-valley-bank-transaction-documents-on-permaweb/16264/28

        // Approve DAO Resolution with hash bafkreidm3bqfiwv224m6w4zuabsiwqruy22sjfaxfvgx4kgcnu3wndxmva
        // Note: see `dao_resolutions` public variable declared above

        // ---------- Spark <> Grove Token Transfers ----------
        // Forum: https://forum.sky.money/t/july-24-2025-proposed-changes-to-spark-for-upcoming-spell/26796
        // Poll: https://vote.sky.money/polling/Qme5qebN

        // Increase ALLOCATOR-BLOOM-A DC-IAM gap by 1.2 billion USDS from 50 million USDS to 1.25 billion USDS
        // line remains unchanged at 2.5 billion USDS
        // ttl remains unchanged at 86400 seconds
        DssExecLib.setIlkAutoLineParameters("ALLOCATOR-BLOOM-A", /* amount = */ 2_500 * MILLION, /* gap = */ 1_250 * MILLION, /* ttl = */ 86400 seconds);

        // Apply ALLOCATOR-BLOOM-A auto-line changes
        DssAutoLineAbstract(MCD_IAM_AUTO_LINE).exec("ALLOCATOR-BLOOM-A");

        // Execute Grove Proxy Spell at address TBC
        // TODO

        // Decrease ALLOCATOR-BLOOM-A gap by 1.2 billion USDS from 1.25 billion USDS to 50 million USDS
        DssExecLib.setIlkAutoLineParameters("ALLOCATOR-BLOOM-A", /* amount = */ 2_500 * MILLION, /* gap = */ 50 * MILLION, /* ttl = */ 86400 seconds);

        // ---------- Execute Spark Proxy Spell ----------

        // Execute Spark Proxy Spell at address TBC
        // TODO
    }

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
        GemAbstract(DAI).approve(DAI_USDS, wad);
        // Note: Convert Dai to USDS for `usr`.
        DaiUsdsLike(DAI_USDS).daiToUsds(usr, wad);
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) {}
}
