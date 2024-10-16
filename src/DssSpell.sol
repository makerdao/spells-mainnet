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

import { DssInstance, MCD } from "dss-test/MCD.sol";
import { VatAbstract } from "dss-interfaces/dss/VatAbstract.sol";

// Note: source code matches https://github.com/makerdao/dss-flappers/blob/95431f3d4da66babf81c6e1138bd05f5ddc5e516/deploy/FlapperInit.sol
import { FlapperInit, FarmConfig } from "src/dependencies/dss-flappers/FlapperInit.sol";

// Note: source code matches https://github.com/makerdao/lockstake/blob/7c71318623f5d6732457fd0c247a1f1760960011/deploy/LockstakeInit.sol
import { LockstakeInit, LockstakeConfig } from "src/dependencies/lockstake/LockstakeInit.sol";
// Note: source code matches https://github.com/makerdao/lockstake/blob/7c71318623f5d6732457fd0c247a1f1760960011/deploy/LockstakeInstance.sol
import { LockstakeInstance } from "src/dependencies/lockstake/LockstakeInstance.sol";

interface SkyLike {
    function mint(address to, uint256 value) external;
}

interface RwaLiquidationOracleLike {
    function cull(bytes32 ilk, address urn) external;
    function tell(bytes32 ilk) external;
}

interface ProxyLike {
    function exec(address target, bytes calldata args) external payable returns (bytes memory out);
}

contract DssSpellAction is DssAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: cast keccak -- "$(wget 'https://raw.githubusercontent.com/makerdao/community/20b4c0ed4bb2771483a0861747cf34a25080ad21/governance/votes/Executive%20vote%20-%20October%2017%2C%202024.md' -q -O - 2>/dev/null)"
    string public constant override description =
        "2024-10-17 MakerDAO Executive Spell | Hash: 0xcbbb4fa0c3bce6e8d97c46e0d4a7aba50d42b184a6f58c0f1b1cf2e0da849858";

    // Set office hours according to the summary
    function officeHours() public pure override returns (bool) {
        return true;
    }

    // Note: by the previous convention it should be a comma-separated list of DAO resolutions IPFS hashes
    string public constant dao_resolutions = "QmYJUvw5xbAJmJknG2xUKDLe424JSTWQQhbJCnucRRjUv7";

    // ---------- Math ----------
    uint256 internal constant MILLION = 10 ** 6;
    uint256 internal constant WAD     = 10 ** 18;
    uint256 internal constant RAY     = 10 ** 27;
    uint256 internal constant RAD     = 10 ** 45;

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
    uint256 internal constant TWELVE_PCT_RATE = 1000000003593629043335673582;

    // ---------- Contracts ----------
    address internal immutable MCD_VAT                     = DssExecLib.vat();
    address internal immutable MIP21_LIQUIDATION_ORACLE    = DssExecLib.getChangelogAddress("MIP21_LIQUIDATION_ORACLE");
    address internal immutable RWA007_A_URN                = DssExecLib.getChangelogAddress("RWA007_A_URN");
    address internal immutable RWA014_A_URN                = DssExecLib.getChangelogAddress("RWA014_A_URN");
    address internal immutable PIP_MKR                     = DssExecLib.getChangelogAddress("PIP_MKR");
    address internal immutable VOTE_DELEGATE_PROXY_FACTORY = DssExecLib.getChangelogAddress("VOTE_DELEGATE_PROXY_FACTORY");
    address internal immutable MCD_SPLIT                   = DssExecLib.getChangelogAddress("MCD_SPLIT");
    address internal immutable MCD_VOW                     = DssExecLib.getChangelogAddress("MCD_VOW");
    address internal immutable USDS_JOIN                   = DssExecLib.getChangelogAddress("USDS_JOIN");
    address internal immutable USDS                        = DssExecLib.getChangelogAddress("USDS");
    address internal immutable MCD_GOV                     = DssExecLib.getChangelogAddress("MCD_GOV");
    address internal immutable MKR_SKY                     = DssExecLib.getChangelogAddress("MKR_SKY");
    address internal immutable SKY                         = DssExecLib.getChangelogAddress("SKY");
    address internal constant NEW_PIP_MKR                  = 0x4F94e33D0D74CfF5Ca0D3a66F1A650628551C56b;
    address internal constant VOTE_DELEGATE_FACTORY        = 0xC3D809E87A2C9da4F6d98fECea9135d834d6F5A0;
    address internal constant REWARDS_LSMKR_USDS           = 0x92282235a39bE957fF1f37619fD22A9aE5507CB1;
    address internal constant LOCKSTAKE_MKR                = 0xb4e0e45e142101dC3Ed768bac219fC35EDBED295;
    address internal constant LOCKSTAKE_ENGINE             = 0x2b16C07D5fD5cC701a0a871eae2aad6DA5fc8f12;
    address internal constant LOCKSTAKE_CLIP               = 0xA85621D35cAf9Cf5C146D2376Ce553D7B78A6239;
    address internal constant LOCKSTAKE_CLIP_CALC          = 0xf13cF3b39823CcfaE6C2354dA56416C80768474e;

    // ---------- Wallets ----------
    address internal constant AAVE_V3_TREASURY   = 0x464C71f6c2F760DdA6093dCB91C24c39e5d6e18c;
    address internal constant EARLY_BIRD_REWARDS = 0x14D98650d46BF7679BBD05D4f615A1547C87Bf68;

    // ---------- Spark Proxy Spell ----------
    // Spark Proxy: https://github.com/marsfoundation/sparklend-deployments/blob/bba4c57d54deb6a14490b897c12a949aa035a99b/script/output/1/primary-sce-latest.json#L2
    address internal constant SPARK_PROXY = 0x3300f198988e4C9C63F75dF86De36421f06af8c4;
    address internal constant SPARK_SPELL = 0xcc3B9e79261A7064A0f734Cc749A8e3762e0a187;

    function actions() public override {
        // Note: multple actions in the spell depend on DssInstance
        DssInstance memory dss = MCD.loadFromChainlog(DssExecLib.LOG);

        // ---------- Setup new MkrOsm ----------
        // Forum: https://forum.sky.money/t/atlas-weekly-cycle-edit-proposal-week-of-october-14-2024-01/25324
        // Poll: https://vote.makerdao.com/polling/QmUm8Krq

        // Whitelist MkrOsm to read from current PIP_MKR using `DssExecLib.addReaderToWhitelist` with the following parameters:
        // Set parameter address _oracle: PIP_MKR address from chainlog (0xdbbe5e9b1daa91430cf0772fcebe53f6c6f137df)
        // Set parameter address _reader: 0x4F94e33D0D74CfF5Ca0D3a66F1A650628551C56b
        DssExecLib.addReaderToWhitelist(PIP_MKR, NEW_PIP_MKR);

        // Set MkrOsm as "PIP_MKR" in the chainlog using the following parameters:
        // Set parameter bytes32 _key: "PIP_MKR"
        // Set parameter address _val:  0x4F94e33D0D74CfF5Ca0D3a66F1A650628551C56b
        DssExecLib.setChangelogAddress("PIP_MKR", NEW_PIP_MKR);

        // ---------- Setup new VoteDelegateFactory ----------
        // Forum: https://forum.sky.money/t/atlas-weekly-cycle-edit-proposal-week-of-october-14-2024-01/25324
        // Poll: https://vote.makerdao.com/polling/QmUm8Krq

        // Rename "VOTE_DELEGATE_PROXY_FACTORY" to "VOTE_DELEGATE_FACTORY_LEGACY" in chainlog:
        // Note: this is a meta instruction, actual instructions are below

        // Call DssExecLib.setChangelogAddress with the following parameters:
        // Set parameter bytes32 _key: "VOTE_DELEGATE_FACTORY_LEGACY"
        // Set parameter address _val: VOTE_DELEGATE_PROXY_FACTORY address (0xd897f108670903d1d6070fcf818f9db3615af272) from the chainlog
        DssExecLib.setChangelogAddress("VOTE_DELEGATE_FACTORY_LEGACY", VOTE_DELEGATE_PROXY_FACTORY);

        // Call CHAINLOG.removeAddress with the following parameters:
        // Set parameter bytes32 _key: "VOTE_DELEGATE_PROXY_FACTORY"
        dss.chainlog.removeAddress("VOTE_DELEGATE_PROXY_FACTORY");

        // Set "VOTE_DELEGATE_FACTORY" in the chainlog to 0xC3D809E87A2C9da4F6d98fECea9135d834d6F5A0
        DssExecLib.setChangelogAddress("VOTE_DELEGATE_FACTORY", VOTE_DELEGATE_FACTORY);

        // ---------- Setup Lockstake Engine ----------
        // Forum: https://forum.sky.money/t/atlas-weekly-cycle-edit-proposal-week-of-october-14-2024-01/25324
        // Poll: https://vote.makerdao.com/polling/QmUm8Krq

        // SBE Parameter Changes
        // Note: this is a subheading, actual instructions are below

        // Decrease splitter "burn" rate by 30% from 100% to 70% with the following parameters:
        // Decrease splitter "burn" with address _base: MCD_SPLIT from chainlog
        // Decrease splitter "burn" with bytes32 _what: "burn"
        // Decrease splitter "burn" with uint256 _amt: 70%
        DssExecLib.setValue(MCD_SPLIT, "burn", 70 * WAD / 100);

        // Increase vow.hump by 5 million DAI, from 55 million DAI to 60 million DAI
        DssExecLib.setValue(MCD_VOW, "hump", 60 * MILLION * RAD);

        // Increase splitter.hop by 4,014 seconds, from 11,635 seconds to 15,649 seconds.
        DssExecLib.setValue(MCD_SPLIT, "hop", 15_649);

        // Set Flapper farm by calling FlapperInit.setFarm with the following parameters:
        FlapperInit.setFarm(

            // Note: FlapperInit.setFarm requires DssInstance
            dss,

            // Set Flapper farm with address farm_ : 0x92282235a39bE957fF1f37619fD22A9aE5507CB1
            REWARDS_LSMKR_USDS,

            FarmConfig({
                // Set Flapper farm with address splitter: MCD_SPLIT from chainlog
                splitter:        MCD_SPLIT,

                // Set Flapper farm with address usdsJoin: USDS_JOIN from chainlog
                usdsJoin:        USDS_JOIN,

                // Set Flapper farm with uint256 hop: 15,649
                hop:             15_649 seconds,

                // Set Flapper farm with bytes32 prevChainlogKey: bytes32(0)
                prevChainlogKey: bytes32(0),

                // Set Flapper farm with chainlogKey: "REWARDS_LSMKR_USDS"
                chainlogKey:     "REWARDS_LSMKR_USDS"
            })
        );

        // "Under the hood" actions for setting flapper:
        // LsMkrUsdsFarm will be set as "farm" in MCD_SPLIT
        // MCD_SPLIT will be set as "rewardsDistribution" in LsMkrUsdsFarm
        // Provided "hop" will be set as "rewardsDuration" in LsMkrUsdsFarm
        // New chainlog key REWARDS_LSMKR_USDS will be added
        // Note: above instructions are taken inside FlapperInit.setFarm method

        // Note: prepare "farms" variable used inside Lockstake init call below
        address[] memory farms = new address[](1);
        farms[0] = REWARDS_LSMKR_USDS;

        // Init Lockstake Engine by calling LockstakeInit.initLockstake with the following parameters:
        LockstakeInit.initLockstake(

            // Note: LockstakeInit.initLockstake requires DssInstance
            dss,

            LockstakeInstance({
                // Init Lockstake Engine with address lsmkr:  0xb4e0e45e142101dC3Ed768bac219fC35EDBED295
                lsmkr:       LOCKSTAKE_MKR,

                // Init Lockstake Engine with address engine:  0x2b16C07D5fD5cC701a0a871eae2aad6DA5fc8f12
                engine:      LOCKSTAKE_ENGINE,

                // Init Lockstake Engine with address clipper:  0xA85621D35cAf9Cf5C146D2376Ce553D7B78A6239
                clipper:     LOCKSTAKE_CLIP,

                // Init Lockstake Engine with address clipperCalc:  0xf13cF3b39823CcfaE6C2354dA56416C80768474e
                clipperCalc: LOCKSTAKE_CLIP_CALC
            }),

            LockstakeConfig({
                // Init Lockstake Engine with bytes32 ilk: "LSE-MKR-A"
                ilk:                 "LSE-MKR-A",

                // Init Lockstake Engine with address voteDelegateFactory: 0xC3D809E87A2C9da4F6d98fECea9135d834d6F5A0
                voteDelegateFactory: VOTE_DELEGATE_FACTORY,

                // Init Lockstake Engine with address usdsJoin: USDS_JOIN from chainlog
                usdsJoin:            USDS_JOIN,

                // Init Lockstake Engine with address usds: USDS from chainlog
                usds:                USDS,

                // Init Lockstake Engine with address mkr: MCD_GOV from chainlog
                mkr:                 MCD_GOV,

                // Init Lockstake Engine with address mkrSky: MKR_SKY from chainlog
                mkrSky:              MKR_SKY,

                // Init Lockstake Engine with address sky: SKY from chainlog
                sky:                 SKY,

                // Init Lockstake Engine with address[] farms:  0x92282235a39bE957fF1f37619fD22A9aE5507CB1
                farms:               farms,

                // Init Lockstake Engine with uint256 fee: 5%
                fee:                 5 * WAD / 100,

                // Init Lockstake Engine with uint256 maxLine: 20 million DAI
                maxLine:             20 * MILLION * RAD,

                // Init Lockstake Engine with uint256 gap: 5 million
                gap:                 5 * MILLION * RAD,

                // Init Lockstake Engine with uint256 ttl: 16 hours
                ttl:                 16 hours,

                // Init Lockstake Engine with uint256 dust: 30,000 DAI
                dust:                30_000 * RAD,

                // Init Lockstake Engine with uint256 duty: 12%
                duty:                TWELVE_PCT_RATE,

                // Init Lockstake Engine with uint256 mat: 200%
                mat:                 200 * RAY / 100,

                // Init Lockstake Engine with uint256 buf: 1.20
                buf:                 120 * RAY / 100,

                // Init Lockstake Engine with uint256 tail: 6,000 seconds
                tail:                6_000 seconds,

                // Init Lockstake Engine with uint256 cusp: 0.40
                cusp:                40 * RAY / 100,

                // Init Lockstake Engine with uint256 chip: 0.1%
                chip:                1 * WAD / 1000,

                // Init Lockstake Engine with uint256 tip: 300 DAI
                tip:                 300 * RAD,

                // Init Lockstake Engine with uint256 stopped: 0
                stopped:             0,

                // Init Lockstake Engine with uint256 chop: 8%
                chop:                108 * WAD / 100,

                // Init Lockstake Engine with uint256 hole: 3 million DAI
                hole:                3 * MILLION * RAD,

                // Init Lockstake Engine with uint256 tau: 0
                tau:                 0,

                // Init Lockstake Engine with uint256 cut: 0.99
                cut:                 99 * RAY / 100,

                // Init Lockstake Engine with uint256 step: 60 seconds
                step:                60 seconds,

                // Init Lockstake Engine with bool lineMom: true
                lineMom:             true,

                // Init Lockstake Engine with uint256 tolerance: 0.5
                tolerance:           5 * RAY / 10,

                // Init Lockstake Engine with string name: "LockstakeMkr"
                name:                "LockstakeMkr",

                // Init Lockstake Engine with string symbol: "lsMKR"
                symbol:              "lsMKR"
            })
        );

        // "Under the hood" actions for Init Lockstake Engine:
        // New collateral type "LSE-MKR-A" will be added to "vat", "jug", "spotter", "dog" contracts
        // New collateral type "LSE-MKR-A" will be added to LINE_MOM
        // New collateral type "LSE-MKR-A" will be added to auto-line using provided maxLine, gap and ttl
        // New collateral type "LSE-MKR-A" will be added to ILK_REGISTRY with provided values ("name", "symbol") and the new ilk class 7
        // New MKR OSM will allow MCD_SPOT, CLIPPER_MOM, OSM_MOM, MCD_END and LockstakeClipper to access its price
        // PIP_MKR will be added to OSM_MOM
        // LockstakeClipper will be configured using provided values ("buf", "tail", "cusp", "chip", "tip", "stopped", "clip", "tolerance")
        // StairstepExponentialDecrease calc contract will be configured using provided values ("cut", "step")
        // The LsMkrUsdsFarm will be added to the LockstakeEngine as a first farm
        // LockstakeEngine will be authorized to access "vat"
        // LockstakeClipper will be authorized to access "vat" and LockstakeEngine
        // CLIPPER_MOM, MCD_DOG and MCD_END will be authorized to access LockstakeClipper
        // New chainlog keys LOCKSTAKE_MKR, LOCKSTAKE_ENGINE, LOCKSTAKE_CLIP and LOCKSTAKE_CLIP_CALC will be added
        // Note: above instructions are taken inside LockstakeInit.initLockstake method

        // ---------- Fund Early Bird Rewards Multisig ----------
        // Forum: https://forum.sky.money/t/atlas-weekly-cycle-edit-proposal-week-of-october-14-2024-01/25324#p-99402-early-bird-bonus-3
        // Poll: https://vote.makerdao.com/polling/QmUm8Krq

        // Mint 27,222,832.80 SKY to 0x14D98650d46BF7679BBD05D4f615A1547C87Bf68
        SkyLike(SKY).mint(EARLY_BIRD_REWARDS, 27_222_832.80 ether); // Note: ether is only a keyword helper

        // ---------- Lower Deprecated RWA Debt Ceilings ----------
        // Forum: https://forum.sky.money/t/2024-10-17-expected-executive-contents-rwa-vault-changes/25323

        // Remove RWA007-A from Debt Ceiling Instant Access Module
        DssExecLib.removeIlkFromAutoLine("RWA007-A");

        // Note: in order to decrease global debt ceiling, we need to fetch current `line`
        (,,, uint256 line1,) = VatAbstract(MCD_VAT).ilks("RWA007-A");

        // Set RWA007-A Debt Ceiling to 0
        DssExecLib.setIlkDebtCeiling("RWA007-A", 0);

        // Initiate RWA007-A soft liquidation by calling `tell()`
        RwaLiquidationOracleLike(MIP21_LIQUIDATION_ORACLE).tell("RWA007-A");

        // Write-off the debt of RWA007-A and set its oracle price to 0 by calling `cull()`
        RwaLiquidationOracleLike(MIP21_LIQUIDATION_ORACLE).cull("RWA007-A", RWA007_A_URN);

        // Note: update the spot value in vat by propagating the price
        DssExecLib.updateCollateralPrice("RWA007-A");

        // Note: in order to decrease global debt ceiling, we need to fetch current `line`
        (,,, uint256 line2,) = VatAbstract(MCD_VAT).ilks("RWA014-A");

        // Reduce RWA014-A Debt Ceiling by 1.5 billion Dai from 1.5 billion Dai to 0
        DssExecLib.setIlkDebtCeiling("RWA014-A", 0);

        // Initiate RWA014-A soft liquidation by calling `tell()`
        RwaLiquidationOracleLike(MIP21_LIQUIDATION_ORACLE).tell("RWA014-A");

        // Write-off the debt of RWA014-A and set its oracle price to 0 by calling `cull()`
        RwaLiquidationOracleLike(MIP21_LIQUIDATION_ORACLE).cull("RWA014-A", RWA014_A_URN);

        // Note: update the spot value in vat by propagating the price
        DssExecLib.updateCollateralPrice("RWA014-A");

        // Note: decrease global line
        VatAbstract(MCD_VAT).file("Line", VatAbstract(MCD_VAT).Line() - (line1 + line2));

        // ---------- Pinwheel DAO Resolution ----------
        // Forum: https://forum.sky.money/t/coinbase-web3-wallet-legal-overview/24577/3

        // Approve DAO Resolution at QmYJUvw5xbAJmJknG2xUKDLe424JSTWQQhbJCnucRRjUv7
        // Note: see `dao_resolutions` public variable declared above

        // ---------- AAVE Revenue Share Payment ----------
        // Forum: https://forum.sky.money/t/spark-aave-revenue-share-calculation-payment-5-q3-2024/25286

        // AAVE Revenue Share - 234089 DAI - 0x464C71f6c2F760DdA6093dCB91C24c39e5d6e18c
        DssExecLib.sendPaymentFromSurplusBuffer(AAVE_V3_TREASURY, 234_089);

        // ---------- Spark Spell ----------
        // Forum: https://forum.sky.money/t/oct-3-2024-proposed-changes-to-spark-for-upcoming-spell/25293
        // Poll: https://vote.makerdao.com/polling/QmbHaA2G
        // Poll: https://vote.makerdao.com/polling/QmShWccA
        // Poll: https://vote.makerdao.com/polling/QmTksxrr

        // Execute Spark Proxy Spell at 0xcc3B9e79261A7064A0f734Cc749A8e3762e0a187
        ProxyLike(SPARK_PROXY).exec(SPARK_SPELL, abi.encodeWithSignature("execute()"));

        // ---------- Chainlog bump ----------

        // Note: we have to patch chainlog version as new collateral is added
        DssExecLib.setChangelogVersion("1.19.2");
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) {}
}
