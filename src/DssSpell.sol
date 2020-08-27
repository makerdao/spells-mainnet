// Copyright (C) 2020 Maker Ecosystem Growth Holdings, INC.
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

pragma solidity 0.5.12;

import "lib/dss-interfaces/src/dapp/DSPauseAbstract.sol";
import "lib/dss-interfaces/src/dss/VatAbstract.sol";
import "lib/dss-interfaces/src/dss/CatAbstract.sol";
import "lib/dss-interfaces/src/dss/EndAbstract.sol";
import "lib/dss-interfaces/src/dss/FlipAbstract.sol";
import "lib/dss-interfaces/src/dss/FlipperMomAbstract.sol";
import "lib/dss-interfaces/src/dss/VowAbstract.sol";

contract SpellAction {

    // MAINNET ADDRESSES
    //
    // The contracts in this list should correspond to MCD core contracts, verify
    // against the current release list at:
    //     https://changelog.makerdao.com/releases/mainnet/1.1.0/contracts.json

    // TODO: Deploy new flips, cat, flipper mom and update

    address constant MCD_VAT             = 0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B;
    address constant MCD_VOW             = 0xA950524441892A31ebddF91d3cEEFa04Bf454466;
    address constant MCD_ADM             = 0x9eF05f7F6deB616fd37aC3c959a2dDD25A54E4F5;
    address constant MCD_END             = 0xaB14d3CE3F733CACB76eC2AbE7d2fcb00c99F3d5;
    address constant FLIPPER_MOM         = 0x0;
    address constant MCD_CAT             = 0x0;
    address constant MCD_CAT_OLD         = 0x78F2c2AF65126834c51822F56Be0d7469D7A523E;

    address constant MCD_FLIP_ETH_A      = 0x0;
    address constant MCD_FLIP_ETH_A_OLD  = 0x0F398a2DaAa134621e4b687FCcfeE4CE47599Cc1;

    address constant MCD_FLIP_BAT_A      = 0x0;
    address constant MCD_FLIP_BAT_A_OLD  = 0x5EdF770FC81E7b8C2c89f71F30f211226a4d7495;

    address constant MCD_FLIP_USDC_A     = 0x0;
    address constant MCD_FLIP_USDC_A_OLD = 0x545521e0105C5698f75D6b3C3050CfCC62FB0C12;

    address constant MCD_FLIP_USDC_B     = 0x0;
    address constant MCD_FLIP_USDC_B_OLD = 0x6002d3B769D64A9909b0B26fC00361091786fe48;

    address constant MCD_FLIP_WBTC_A     = 0x0;
    address constant MCD_FLIP_WBTC_A_OLD = 0xF70590Fa4AaBe12d3613f5069D02B8702e058569;

    address constant MCD_FLIP_ZRX_A      = 0x0;
    address constant MCD_FLIP_ZRX_A_OLD  = 0x92645a34d07696395b6e5b8330b000D0436A9aAD;

    address constant MCD_FLIP_KNC_A      = 0x0;
    address constant MCD_FLIP_KNC_A_OLD  = 0xAD4a0B5F3c6Deb13ADE106Ba6E80Ca6566538eE6;

    address constant MCD_FLIP_TUSD_A     = 0x0;
    address constant MCD_FLIP_TUSD_A_OLD = 0x04C42fAC3e29Fd27118609a5c36fD0b3Cb8090b3;

    address constant MCD_FLIP_MANA_A     = 0x0;
    address constant MCD_FLIP_MANA_A_OLD = 0x4bf9D2EBC4c57B9B783C12D30076507660B58b3a;

    // Decimals & precision
    uint256 constant THOUSAND = 10 ** 3;
    uint256 constant MILLION  = 10 ** 6;
    uint256 constant WAD      = 10 ** 18;
    uint256 constant RAY      = 10 ** 27;
    uint256 constant RAD      = 10 ** 45;

    function execute() external {
        require(CatAbstract(MCD_CAT_OLD).vat() == MCD_VAT,          "non-matching-vat");
        require(CatAbstract(MCD_CAT_OLD).vow() == MCD_VOW,          "non-matching-vow");

        require(CatAbstract(MCD_CAT).vat() == MCD_VAT,              "non-matching-vat");
        require(CatAbstract(MCD_CAT).live() == 1,                   "cat-not-live");

        require(FlipperMomAbstract(FLIPPER_MOM).cat() == MCD_CAT,   "non-matching-cat");

        /*** Update Cat ***/
        CatAbstract(MCD_CAT).file("vow", MCD_VOW);
        VatAbstract(MCD_VAT).rely(MCD_CAT);
        VatAbstract(MCD_VAT).deny(MCD_CAT_OLD);
        VowAbstract(MCD_VOW).rely(MCD_CAT);
        VowAbstract(MCD_VOW).deny(MCD_CAT_OLD);
        EndAbstract(MCD_END).file("cat", MCD_CAT);
        CatAbstract(MCD_CAT).rely(MCD_END);

        // TODO: get final value from risk
        CatAbstract(MCD_CAT).file("box", 30 * MILLION * RAD);

        /*** Set Auth in Flipper Mom ***/
        FlipperMomAbstract(FLIPPER_MOM).setAuthority(MCD_ADM);

        /*** ETH-A Flip ***/
        _changeFlip(FlipAbstract(MCD_FLIP_ETH_A), FlipAbstract(MCD_FLIP_ETH_A_OLD));

        /*** BAT-A Flip ***/
        _changeFlip(FlipAbstract(MCD_FLIP_BAT_A), FlipAbstract(MCD_FLIP_BAT_A_OLD));

        /*** USDC-A Flip ***/
        _changeFlip(FlipAbstract(MCD_FLIP_USDC_A), FlipAbstract(MCD_FLIP_USDC_A_OLD));
        FlipperMomAbstract(FLIPPER_MOM).deny(MCD_FLIP_USDC_A); // Auctions disabled

        /*** USDC-B Flip ***/
        _changeFlip(FlipAbstract(MCD_FLIP_USDC_B), FlipAbstract(MCD_FLIP_USDC_B_OLD));
        FlipperMomAbstract(FLIPPER_MOM).deny(MCD_FLIP_USDC_B); // Auctions disabled

        /*** WBTC-A Flip ***/
        _changeFlip(FlipAbstract(MCD_FLIP_WBTC_A), FlipAbstract(MCD_FLIP_WBTC_A_OLD));

        /*** TUSD-A Flip ***/
        _changeFlip(FlipAbstract(MCD_FLIP_TUSD_A), FlipAbstract(MCD_FLIP_TUSD_A_OLD));
        FlipperMomAbstract(FLIPPER_MOM).deny(MCD_FLIP_TUSD_A); // Auctions disabled

        /*** ZRX-A Flip ***/
        _changeFlip(FlipAbstract(MCD_FLIP_ZRX_A), FlipAbstract(MCD_FLIP_ZRX_A_OLD));

        /*** KNC-A Flip ***/
        _changeFlip(FlipAbstract(MCD_FLIP_KNC_A), FlipAbstract(MCD_FLIP_KNC_A_OLD));

        /*** MANA-A Flip ***/
        _changeFlip(FlipAbstract(MCD_FLIP_MANA_A), FlipAbstract(MCD_FLIP_MANA_A_OLD));

    }

    function _changeFlip(FlipAbstract newFlip, FlipAbstract oldFlip) internal {
        bytes32 ilk = newFlip.ilk();
        require(ilk == oldFlip.ilk(), "non-matching-ilk");
        require(newFlip.vat() == oldFlip.vat(), "non-matching-vat");
        require(newFlip.cat() == MCD_CAT, "non-matching-cat");
        require(newFlip.vat() == MCD_VAT, "non-matching-vat");

        CatAbstract(MCD_CAT).file(ilk, "flip", address(newFlip));
        (, uint oldChop,) = CatAbstract(MCD_CAT_OLD).ilks(ilk);
        CatAbstract(MCD_CAT).file(ilk, "chop", oldChop / 10 ** 9);

        // TODO: get correct value from risk
        CatAbstract(MCD_CAT).file(ilk, "dunk", 33 * THOUSAND * RAD);
        CatAbstract(MCD_CAT).rely(address(newFlip));

        newFlip.rely(MCD_CAT);
        newFlip.rely(MCD_END);
        newFlip.rely(FLIPPER_MOM);
        newFlip.file("beg", oldFlip.beg());
        newFlip.file("ttl", oldFlip.ttl());
        newFlip.file("tau", oldFlip.tau());
    }
}

contract DssSpell {
    DSPauseAbstract public pause =
        DSPauseAbstract(0xbE286431454714F511008713973d3B053A2d38f3);
    address         public action;
    bytes32         public tag;
    uint256         public eta;
    bytes           public sig;
    uint256         public expiration;
    bool            public done;

    // TODO: Update this with new hash/date
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/77f94a877eaeeff7eccee0bfdf45cb377ff0a25c/governance/votes/Executive%20vote%20-%20August%2021%2C%202020.md -q -O - 2>/dev/null)"
    string constant public description =
        "2020-08-28 MakerDAO Executive Spell | Hash: 0x0";

    constructor() public {
        sig = abi.encodeWithSignature("execute()");
        action = address(new SpellAction());
        bytes32 _tag;
        address _action = action;
        assembly { _tag := extcodehash(_action) }
        tag = _tag;
        expiration = now + 30 days;
    }

    modifier officeHours {
        uint day = (now / 1 days + 3) % 7;
        require(day < 5, "Can only be cast on a weekday");
        uint hour = now / 1 hours % 24;
        require(hour >= 14 && hour < 21, "Outside office hours");
        _;
    }

    function schedule() public {
        require(now <= expiration, "This contract has expired");
        require(eta == 0, "This spell has already been scheduled");
        eta = now + DSPauseAbstract(pause).delay();
        pause.plot(action, tag, sig, eta);
    }

    function cast() public officeHours {
        require(!done, "spell-already-cast");
        done = true;
        pause.exec(action, tag, sig, eta);
    }
}
