// SPDX-License-Identifier: AGPL-3.0-or-later
//
// Copyright (C) 2021-2022 Dai Foundation
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
// Enable ABIEncoderV2 when onboarding collateral
// pragma experimental ABIEncoderV2;
import "dss-exec-lib/DssExec.sol";
import "dss-exec-lib/DssAction.sol";

import { DssSpellCollateralOnboardingAction } from "./DssSpellCollateralOnboarding.sol";

interface DssVestLike {
    function create(address, uint256, uint256, uint256, uint256, address) external returns (uint256);
    function restrict(uint256) external;
    function yank(uint256) external;
}

interface GemLike {
    function transfer(address, uint256) external returns (bool);
}

contract DssSpellAction is DssAction, DssSpellCollateralOnboardingAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/a7095d5b92ee825bef28b6f5d22baec50718d438/governance/votes/Executive%20vote%20-%20April%201%2C%202022.md -q -O - 2>/dev/null)"
    string public constant override description =
        "2022-04-01 MakerDAO Executive Spell | Hash: 0x4ac0f251ca491bf27799ebe04452ad4a6f48f2c5c8a09a5c2880a984c2f26178";

    uint256 constant WAD = 10**18;

    DssVestLike immutable MCD_VEST_DAI = DssVestLike(DssExecLib.getChangelogAddress("MCD_VEST_DAI"));
    DssVestLike immutable MCD_VEST_MKR_TREASURY = DssVestLike(DssExecLib.getChangelogAddress("MCD_VEST_MKR_TREASURY"));


    // Gov Dai Transfer, Stream and MKR vesting (41.20 MKR)
    address constant GOV_WALLET_1      = 0x01D26f8c5cC009868A4BF66E268c17B057fF7A73;
    // Gov MKR vesting (73.70 MKR) and MKR Transfer (60 MKR)
    address constant GOV_WALLET_2      = 0xC818Ae5f27B76b4902468C6B02Fd7a089F12c07b;
    // Gov MKR vesting (52.74 MKR)
    address constant GOV_WALLET_3      = 0xbfDD0E744723192f7880493b66501253C34e1241;
    // Immunifi Core Unit
    address constant ISCU_WALLET       = 0xd1F2eEf8576736C1EbA36920B957cd2aF07280F4;
    // Real World Finance Core Unit
    address constant RWF_WALLET        = 0x96d7b01Cc25B141520C717fa369844d34FF116ec;
    // Gelato Keeper Network Contract for Dai Stream
    address constant GELATO_WALLET     = 0x926c21602FeC84d6d0fA6450b40Edba595B5c6e4;

    // Start Dates - Start of Day
    uint256 constant FEB_08_2022 = 1644278400;
    uint256 constant MAR_01_2022 = 1646092800;
    uint256 constant APR_01_2022 = 1648771200;

    // End Dates - End of Day
    uint256 constant ONE_YEAR = 365 days;
    // 2022-03-01 to 2022-08-01
    uint256 constant FIVE_MONTHS = 153 days;
    // 2022-04-01 to 2022-10-01
    uint256 constant SIX_MONTHS = 183 days;
    // 2022-04-01 to 2022-12-31
    uint256 constant NINE_MONTHS = 274 days;

    // Amounts with decimals
    uint256 constant ISCU_DAI_STREAM_AMOUNT = 700_356.9 * 10 * WAD / 10;
    uint256 constant GOV_2_MKR = 73.70 * 10 * WAD / 10;
    uint256 constant GOV_3_MKR = 52.74 * 100 * WAD / 100;
    uint256 constant GOV_1_MKR = 41.20 * 10 * WAD / 10;


    function officeHours() public override returns (bool) {
        return false;
    }

    function actions() public override {
        // onboardNewCollaterals();

        // Core Unit DAI Budget Transfers
        // GOV-001 - 30,000 DAI - 0x01D26f8c5cC009868A4BF66E268c17B057fF7A73 https://forum.makerdao.com/t/mip40c3-sp59-govalpha-budget-2022-23/13144
        DssExecLib.sendPaymentFromSurplusBuffer(GOV_WALLET_1,  30_000);
        // IS-001 - 348,452.30 DAI - 0xd1F2eEf8576736C1EbA36920B957cd2aF07280F4 https://github.com/makerdao/mips/pull/463/files
        // Rounded up from 348,452.30 to 348,453
        DssExecLib.sendPaymentFromSurplusBuffer(ISCU_WALLET,  348_453);
        // RWF-001 - 2,055,000 DAI - 0x96d7b01Cc25B141520C717fa369844d34FF116ec https://mips.makerdao.com/mips/details/MIP40c3SP61#transactions
        DssExecLib.sendPaymentFromSurplusBuffer(RWF_WALLET,  2_055_000);

        // VEST.restrict( Only recipient can request funds
        //     VEST.create(
        //         Recipient of vest,
        //         Total token amount of vest over period,
        //         Start timestamp of vest,
        //         Duration of the vesting period (in seconds),
        //         Length of cliff period (in seconds),
        //         Manager address
        //     )
        // );

        // Core Unit DAI Budget Streams
        // GOV-001 | 2022-04-01 to 2023-04-01 | 1,079,793 DAI | 0x01D26f8c5cC009868A4BF66E268c17B057fF7A73 https://forum.makerdao.com/t/mip40c3-sp59-govalpha-budget-2022-23/13144
        MCD_VEST_DAI.restrict(
            MCD_VEST_DAI.create(
                GOV_WALLET_1,
                1_079_793 * WAD,
                APR_01_2022,
                ONE_YEAR,
                0,
                GOV_WALLET_1
            )
        );
        // IS-001 | 2022-03-01 to 2022-08-01 | 700,356.90 DAI | 0xd1F2eEf8576736C1EbA36920B957cd2aF07280F4 https://github.com/makerdao/mips/pull/463/files
        MCD_VEST_DAI.restrict(
            MCD_VEST_DAI.create(
                ISCU_WALLET,
                ISCU_DAI_STREAM_AMOUNT,
                MAR_01_2022,
                FIVE_MONTHS,
                0,
                ISCU_WALLET
            )
        );
        // RWF-001 | 2022-04-01 to 2022-12-31 | 6,165,000 DAI | 0x96d7b01Cc25B141520C717fa369844d34FF116ec https://mips.makerdao.com/mips/details/MIP40c3SP61#transactions
        MCD_VEST_DAI.restrict(
            MCD_VEST_DAI.create(
                RWF_WALLET,
                6_165_000 * WAD,
                APR_01_2022,
                NINE_MONTHS,
                0,
                RWF_WALLET
            )
        );
        // Remove/Revoke Stream #27 (RWF-001) on DssVestSuckable https://mips.makerdao.com/mips/details/MIP40c3SP61#transactions
        MCD_VEST_DAI.yank(27);

        // Gelato Keeper Network DAI Budget Stream
        // https://mips.makerdao.com/mips/details/MIP63c4SP3
        // Address: 0x926c21602fec84d6d0fa6450b40edba595b5c6e4
        // Amount: 1,000 DAI/day
        // Start Date: Apr 1, 2022
        // End Date: Oct 1, 2022
        MCD_VEST_DAI.restrict(
            MCD_VEST_DAI.create(
                GELATO_WALLET,
                183_000 * WAD,
                APR_01_2022,
                SIX_MONTHS,
                0,
                GELATO_WALLET
            )
        );

        // Core Unit MKR Vesting Streams (sourced from treasury)
        // GOV-001 | 2022-02-08 to 2023-02-08 | Cliff: 2023-02-08 (1 year) | 73.70 MKR | 0xC818Ae5f27B76b4902468C6B02Fd7a089F12c07b https://mips.makerdao.com/mips/details/MIP40c3SP60#list-of-budget-breakdowns
        MCD_VEST_MKR_TREASURY.restrict(
            MCD_VEST_MKR_TREASURY.create(
                GOV_WALLET_2,
                GOV_2_MKR,
                FEB_08_2022,
                ONE_YEAR,
                ONE_YEAR,
                address(0)
            )
        );
        // GOV-001 | 2022-02-08 to 2023-02-08 | Cliff: 2023-02-08 (1 year) | 52.74 MKR | 0xbfDD0E744723192f7880493b66501253C34e1241 https://mips.makerdao.com/mips/details/MIP40c3SP60#list-of-budget-breakdowns
        MCD_VEST_MKR_TREASURY.restrict(
            MCD_VEST_MKR_TREASURY.create(
                GOV_WALLET_3,
                GOV_3_MKR,
                FEB_08_2022,
                ONE_YEAR,
                ONE_YEAR,
                address(0)
            )
        );
        // GOV-001 | 2022-02-08 to 2023-02-08 | Cliff: 2023-02-08 (1 year) | 41.20 MKR | 0x01D26f8c5cC009868A4BF66E268c17B057fF7A73 https://mips.makerdao.com/mips/details/MIP40c3SP60#list-of-budget-breakdowns
        MCD_VEST_MKR_TREASURY.restrict(
            MCD_VEST_MKR_TREASURY.create(
                GOV_WALLET_1,
                GOV_1_MKR,
                FEB_08_2022,
                ONE_YEAR,
                ONE_YEAR,
                address(0)
            )
        );

        // Core Unit MKR Transfer (sourced from treasury)
        // GOV-001 - 60 MKR - 0xC818Ae5f27B76b4902468C6B02Fd7a089F12c07b https://mips.makerdao.com/mips/details/MIP40c3SP60#list-of-budget-breakdowns
        GemLike(DssExecLib.getChangelogAddress("MCD_GOV")).transfer(GOV_WALLET_2, 60 * WAD);
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) public {}
}
