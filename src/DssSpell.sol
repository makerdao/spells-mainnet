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
    //     https://changelog.makerdao.com/releases/mainnet/1.0.9/contracts.json

    // TODO: Deploy new flips, cat, flipper mom and update

    address constant MCD_VAT             = 0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B;
    address constant MCD_VOW             = 0xA950524441892A31ebddF91d3cEEFa04Bf454466;
    address constant MCD_ADM             = 0x9eF05f7F6deB616fd37aC3c959a2dDD25A54E4F5;
    address constant MCD_END             = 0xaB14d3CE3F733CACB76eC2AbE7d2fcb00c99F3d5;

    address constant FLIPPER_MOM         = 0x50dC6120c67E456AdA2059cfADFF0601499cf681;

    address constant MCD_CAT             = 0xdDb5F7A3A5558b9a6a1f3382BD75E2268d1c6958;
    address constant MCD_CAT_OLD         = 0x0511674A67192FE51e86fE55Ed660eB4f995BDd6;

    address constant MCD_FLIP_ETH_A      = 0x750295A8db0580F32355f97de7918fF538c818F1;
    address constant MCD_FLIP_ETH_A_OLD  = 0xc78EdADA7e8bEa29aCc3a31bBA1D516339deD350;

    address constant MCD_FLIP_BAT_A      = 0x44Acf0eb2C7b9F0B55723e5289437AefE8ef7a1c;
    address constant MCD_FLIP_BAT_A_OLD  = 0xc0126c3383777bDc175E659A51020E56307dDe21;

    address constant MCD_FLIP_USDC_A     = 0x17C144eaC1B3D6777eF2C3fA1F98e3BC3c18DB4F;
    address constant MCD_FLIP_USDC_A_OLD = 0xc29Ad1913C3B415497fdA1eA15c132502B8fa372;

    address constant MCD_FLIP_USDC_B     = 0x6DCd745D91AB422e962d08Ed1a9242adB47D8d0C;
    address constant MCD_FLIP_USDC_B_OLD = 0x3c9eF711B68882d9732F60758e7891AcEae2Aa7c;

    address constant MCD_FLIP_WBTC_A     = 0x80Fb08f2EF268f491D6B58438326a3006C1a0e09;
    address constant MCD_FLIP_WBTC_A_OLD = 0x28dd4263e1FcE04A9016Bd7BF71a4f0F7aB93810;

    address constant MCD_FLIP_ZRX_A      = 0x798eB3126f1d5cb54743E3e93D3512C58f461084;
    address constant MCD_FLIP_ZRX_A_OLD  = 0xe07F1219f7d6ccD59431a6b151179A9181e3902c;

    address constant MCD_FLIP_KNC_A      = 0xF2c21882Bd14A5F7Cb46291cf3c86E53057FaD06;
    address constant MCD_FLIP_KNC_A_OLD  = 0x644699674D06cF535772D0DC19Ad5EA695000F51;

    address constant MCD_FLIP_TUSD_A     = 0x867711f695e11663eC8adCFAAD2a152eFBA56dfD;
    address constant MCD_FLIP_TUSD_A_OLD = 0xD4A145d161729A4B43B7Ab7DD683cB9A16E01a1b;

    address constant MCD_FLIP_MANA_A     = 0xb2B7430D49D2D2e7abb6a6B4699B2659c141A2a6;
    address constant MCD_FLIP_MANA_A_OLD = 0x5CB9D33A9fE5244019e6F5f45e68F18600805264;

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
        CatAbstract(MCD_CAT).file("box", 10  * THOUSAND * RAD);

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
        CatAbstract(MCD_CAT).file(ilk, "dunk", 500 * RAD);
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
        DSPauseAbstract(0x8754E6ecb4fe68DaA5132c2886aB39297a5c7189);
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
        "2020-08-21 MakerDAO Executive Spell | Hash: 0xa42625339c53b03d0d95ad99ccffc07a1f2cf8ec5f8858d9a0b5578204949609";

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