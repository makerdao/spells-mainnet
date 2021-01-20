// SPDX-License-Identifier: GPL-3.0-or-later
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

pragma solidity 0.6.11;

import "lib/dss-interfaces/src/dapp/DSPauseAbstract.sol";
import "lib/dss-interfaces/src/dss/ChainlogAbstract.sol";
import "lib/dss-interfaces/src/dss/DaiJoinAbstract.sol";
import "lib/dss-interfaces/src/dss/IlkRegistryAbstract.sol";
import "lib/dss-interfaces/src/dss/OsmAbstract.sol";
import "lib/dss-interfaces/src/dss/VatAbstract.sol";

interface LerpFabLike {
    function newIlkLerp(address target_, bytes32 ilk_, bytes32 what_, uint256 start_, uint256 end_, uint256 duration_) external returns (address);
}

interface LerpLike {
    function init() external;
}

contract SpellAction {
    // Office hours enabled if true
    bool constant public officeHours = false;

    // MAINNET ADDRESSES
    //
    // The contracts in this list should correspond to MCD core contracts, verify
    //  against the current release list at:
    //     https://changelog.makerdao.com/releases/mainnet/active/contracts.json
    ChainlogAbstract constant CHANGELOG =
        ChainlogAbstract(0xdA0Ab1e0017DEbCd72Be8599041a2aa3bA7e740F);

    // Ilks
    bytes32 constant ILK_LINK_A         = "LINK-A";
    bytes32 constant ILK_MANA_A         = "MANA-A";
    bytes32 constant ILK_BAT_A          = "BAT-A";
    bytes32 constant ILK_TUSD_A         = "TUSD-A";
    bytes32 constant ILK_PSM_USDC_A     = "PSM-USDC-A";

    // Lerp Module
    address constant LERP_FAB = 0x9B98aF142993877BEF8FC5cA514fD8A18E8f8Ed6;

    // Oracle whitelist
    address constant ETHUSD_OSM    = 0x81FE72B5A8d1A857d176C3E7d5Bd2679A9B85763;
    address constant INSTA_DAPP    = 0x3b50336E3E1E618FE74DF351966ebaD2B12cD24a;

    // decimals & precision
    uint256 constant THOUSAND = 10 ** 3;
    uint256 constant MILLION  = 10 ** 6;
    uint256 constant WAD      = 10 ** 18;
    uint256 constant RAY      = 10 ** 27;
    uint256 constant RAD      = 10 ** 45;

    // Many of the settings that change weekly rely on the rate accumulator
    // described at https://docs.makerdao.com/smart-contract-modules/rates-module
    // To check this yourself, use the following rate calculation (example 8%):
    //
    // $ bc -l <<< 'scale=27; e( l(1.08)/(60 * 60 * 24 * 365) )'
    //
    // A table of rates can be found at
    //    https://ipfs.io/ipfs/QmefQMseb3AiTapiAKKexdKHig8wroKuZbmLtPLv4u2YwW
    //

    modifier limited {
        if (officeHours) {
            uint day = (block.timestamp / 1 days + 3) % 7;
            require(day < 5, "Can only be cast on a weekday");
            uint hour = block.timestamp / 1 hours % 24;
            require(hour >= 14 && hour < 21, "Outside office hours");
        }
        _;
    }

    function execute() external limited {
        address MCD_VAT      = CHANGELOG.getAddress("MCD_VAT");
        address MCD_VOW      = CHANGELOG.getAddress("MCD_VOW");
        address MCD_JOIN_DAI = CHANGELOG.getAddress("MCD_JOIN_DAI");
        address ILK_REGISTRY = CHANGELOG.getAddress("ILK_REGISTRY");

        // Adjust Debt Ceiling Parameters - January 18, 2021
        // https://vote.makerdao.com/polling/QmQtn7UY#poll-detail - LINK-A
        // https://vote.makerdao.com/polling/QmSCLfXN#poll-detail - MANA-A
        // https://vote.makerdao.com/polling/QmW4ei2M#poll-detail - BAT-A
        // https://vote.makerdao.com/polling/QmXTGwq4#poll-detail - TUSD-A
        // https://vote.makerdao.com/polling/QmfTU85J#poll-detail - PSM-USDC-A [ December 14, 2020 ]

        // Set the global debt ceiling
        // + 10 M for LINK-A
        // + 750 K for WBTC-A [ Note: Units ]
        // - 8 M for WBTC-A
        // - 135 M for TUSD-A
        // + 470 M for PSM-USDC-A [ Lerp End Amount ]
        // TODO: WBTC-ETH UNI LP
        // TODO: USDC-ETH UNI LP
        VatAbstract(MCD_VAT).file("Line",
            VatAbstract(MCD_VAT).Line()
            + 10 * MILLION * RAD
            + 750 * THOUSAND * RAD
            - 8 * MILLION * RAD
            - 135 * MILLION * RAD
            + 470 * MILLION * RAD
        );

        // Update the Debt Ceilings
        VatAbstract(MCD_VAT).file(ILK_LINK_A, "line", 20 * MILLION * RAD);
        VatAbstract(MCD_VAT).file(ILK_MANA_A, "line", 1 * MILLION * RAD);
        VatAbstract(MCD_VAT).file(ILK_BAT_A, "line", 2 * MILLION * RAD);
        VatAbstract(MCD_VAT).file(ILK_TUSD_A, "line", 0 * MILLION * RAD);
        // Note: PSM-USDC-A is set to 80 M in the Lerp.init()

        // Setup the Lerp module
        address lerp = LerpFabLike(LERP_FAB).newIlkLerp(MCD_VAT, ILK_PSM_USDC_A, "line", 80 * MILLION * RAD, 500 * MILLION * RAD, 12 weeks);
        VatAbstract(MCD_VAT).rely(lerp);
        LerpLike(lerp).init();

        // Set dust to 2000 DAI - January 18, 2021
        // https://vote.makerdao.com/polling/QmWPAu5z#poll-detail
        bytes32[] memory ilks = IlkRegistryAbstract(ILK_REGISTRY).list();
        for (uint256 i = 0; i < ilks.length; i++) {
            (,,,, uint256 dust) = VatAbstract(MCD_VAT).ilks(ilks[i]);
            if (dust != 0) {
                VatAbstract(MCD_VAT).file(ilks[i], "dust", 2000 * RAD);
            }
        }

        // Vault Compensation Working Group Payment - January 18, 2021
        // https://vote.makerdao.com/polling/QmQcXFeC#poll-detail
        VatAbstract(MCD_VAT).suck(MCD_VOW, address(this), 12700 * RAD);
        VatAbstract(MCD_VAT).hope(MCD_JOIN_DAI);
        
        // @makerman: 6,300 Dai for 126 hours to [0x9AC6A6B24bCd789Fa59A175c0514f33255e1e6D0]
        DaiJoinAbstract(MCD_JOIN_DAI).exit(0x9AC6A6B24bCd789Fa59A175c0514f33255e1e6D0, 6300 * WAD);
        // @monet-supply: 3,800 Dai for 76 hours to [0x8d07D225a769b7Af3A923481E1FdF49180e6A265]
        DaiJoinAbstract(MCD_JOIN_DAI).exit(0x8d07D225a769b7Af3A923481E1FdF49180e6A265, 3800 * WAD);
        // @Joshua_Pritikin: 2,000 Dai for 40 hours to [0x2235A5D7bCC37855CB91dFf66334F4DFD9C39b58]
        DaiJoinAbstract(MCD_JOIN_DAI).exit(0x2235A5D7bCC37855CB91dFf66334F4DFD9C39b58, 2000 * WAD);
        // @befitsandpiper: 400 Dai for 8 hours to [0x851fB899dA7F80c211d9B8e5f231FB3BC9eca41a]
        DaiJoinAbstract(MCD_JOIN_DAI).exit(0x851fB899dA7F80c211d9B8e5f231FB3BC9eca41a, 400 * WAD);
        // @Vault2288: 200 Dai for 4 hours to [0x92e5a14b08E5232682Eb38269A1cE661F04Ec93D]
        DaiJoinAbstract(MCD_JOIN_DAI).exit(0x92e5a14b08E5232682Eb38269A1cE661F04Ec93D, 200 * WAD);

        VatAbstract(MCD_VAT).nope(MCD_JOIN_DAI);

        // Whitelist Instadapp on ETHUSD Oracle - January 18, 2021
        // https://vote.makerdao.com/polling/QmNSb2cu#poll-detail
        OsmAbstract(ETHUSD_OSM).kiss(INSTA_DAPP);

        //
        // TODO: Onboard WBTC-ETH UNI LP
        //

        //
        // TODO: Onboard USDC-ETH UNI LP
        //

        // Update the changelog
        CHANGELOG.setAddress("LERP_FAB", LERP_FAB);
        // Bump version
        CHANGELOG.setVersion("1.2.4");
    }
}

contract DssSpell {
    ChainlogAbstract constant CHANGELOG =
        ChainlogAbstract(0xdA0Ab1e0017DEbCd72Be8599041a2aa3bA7e740F);

    DSPauseAbstract immutable public pause;
    address         immutable public action;
    bytes32         immutable public tag;
    uint256         immutable public expiration;
    uint256         public eta;
    bytes           public sig;
    bool            public done;

    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/7545776ce23113335369331dff39d71d9e767a19/governance/votes/Executive%20vote%20-%20January%2018%2C%202021.md -q -O - 2>/dev/null)"
    string constant public description =
        "2021-01-22 MakerDAO Executive Spell | Hash: 0x71eb4d0a0f678bc2d706033c2ad238e637fb7665521040a31a193ad27d89183c";

    function officeHours() external view returns (bool) {
        return SpellAction(action).officeHours();
    }

    constructor() public {
        pause = DSPauseAbstract(CHANGELOG.getAddress("MCD_PAUSE"));
        sig = abi.encodeWithSignature("execute()");
        bytes32 _tag;
        address _action = action = address(new SpellAction());
        assembly { _tag := extcodehash(_action) }
        tag = _tag;
        expiration = block.timestamp + 30 days;
    }

    function nextCastTime() external view returns (uint256 castTime) {
        require(eta != 0, "DSSSpell/spell-not-scheduled");
        castTime = block.timestamp > eta ? block.timestamp : eta; // Any day at XX:YY

        if (SpellAction(action).officeHours()) {
            uint256 day    = (castTime / 1 days + 3) % 7;
            uint256 hour   = castTime / 1 hours % 24;
            uint256 minute = castTime / 1 minutes % 60;
            uint256 second = castTime % 60;

            if (day >= 5) {
                castTime += (6 - day) * 1 days;                 // Go to Sunday XX:YY
                castTime += (24 - hour + 14) * 1 hours;         // Go to 14:YY UTC Monday
                castTime -= minute * 1 minutes + second;        // Go to 14:00 UTC
            } else {
                if (hour >= 21) {
                    if (day == 4) castTime += 2 days;           // If Friday, fast forward to Sunday XX:YY
                    castTime += (24 - hour + 14) * 1 hours;     // Go to 14:YY UTC next day
                    castTime -= minute * 1 minutes + second;    // Go to 14:00 UTC
                } else if (hour < 14) {
                    castTime += (14 - hour) * 1 hours;          // Go to 14:YY UTC same day
                    castTime -= minute * 1 minutes + second;    // Go to 14:00 UTC
                }
            }
        }
    }

    function schedule() external {
        require(block.timestamp <= expiration, "DSSSpell/spell-has-expired");
        require(eta == 0, "DSSSpell/spell-already-scheduled");
        eta = block.timestamp + DSPauseAbstract(pause).delay();
        pause.plot(action, tag, sig, eta);
    }

    function cast() external {
        require(!done, "DSSSpell/spell-already-cast");
        done = true;
        pause.exec(action, tag, sig, eta);
    }
}
