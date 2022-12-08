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

contract Addresses {

    mapping (bytes32 => address) public addr;

    constructor() public {
        addr["CHANGELOG"]                       = 0xdA0Ab1e0017DEbCd72Be8599041a2aa3bA7e740F;
        addr["MULTICALL"]                       = 0x5e227AD1969Ea493B43F840cfF78d08a6fc17796;
        addr["FAUCET"]                          = 0x0000000000000000000000000000000000000000;
        addr["MCD_DEPLOY"]                      = 0xbaa65281c2FA2baAcb2cb550BA051525A480D3F4;
        addr["JOIN_FAB"]                        = 0xf1738d22140783707Ca71CB3746e0dc7Bf2b0264;
        addr["FLIP_FAB"]                        = 0x4ACdbe9dd0d00b36eC2050E805012b8Fc9974f2b;
        addr["CLIP_FAB"]                        = 0x0716F25fBaAae9b63803917b6125c10c313dF663;
        addr["CALC_FAB"]                        = 0xE1820A2780193d74939CcA104087CADd6c1aA13A;
        addr["LERP_FAB"]                        = 0x9175561733D138326FDeA86CdFdF53e92b588276;
        addr["MCD_GOV"]                         = 0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2;
        addr["GOV_GUARD"]                       = 0x6eEB68B2C7A918f36B78E2DB80dcF279236DDFb8;
        addr["MCD_ADM"]                         = 0x0a3f6849f78076aefaDf113F5BED87720274dDC0;
        addr["VOTE_PROXY_FACTORY"]              = 0x6FCD258af181B3221073A96dD90D1f7AE7eEc408;
        addr["VOTE_DELEGATE_PROXY_FACTORY"]     = 0xD897F108670903D1d6070fcf818f9db3615AF272;
        addr["MCD_VAT"]                         = 0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B;
        addr["MCD_JUG"]                         = 0x19c0976f590D67707E62397C87829d896Dc0f1F1;
        addr["MCD_CAT"]                         = 0xa5679C04fc3d9d8b0AaB1F0ab83555b301cA70Ea;
        addr["MCD_DOG"]                         = 0x135954d155898D42C90D2a57824C690e0c7BEf1B;
        addr["MCD_VOW"]                         = 0xA950524441892A31ebddF91d3cEEFa04Bf454466;
        addr["MCD_JOIN_DAI"]                    = 0x9759A6Ac90977b93B58547b4A71c78317f391A28;
        addr["MCD_FLAP"]                        = 0xa4f79bC4a5612bdDA35904FDF55Fc4Cb53D1BFf6;
        addr["MCD_FLOP"]                        = 0xA41B6EF151E06da0e34B009B86E828308986736D;
        addr["MCD_PAUSE"]                       = 0xbE286431454714F511008713973d3B053A2d38f3;
        addr["MCD_PAUSE_PROXY"]                 = 0xBE8E3e3618f7474F8cB1d074A26afFef007E98FB;
        addr["MCD_GOV_ACTIONS"]                 = 0x4F5f0933158569c026d617337614d00Ee6589B6E;
        addr["MCD_DAI"]                         = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
        addr["MCD_SPOT"]                        = 0x65C79fcB50Ca1594B025960e539eD7A9a6D434A3;
        addr["MCD_POT"]                         = 0x197E90f9FAD81970bA7976f33CbD77088E5D7cf7;
        addr["MCD_END"]                         = 0x0e2e8F1D1326A4B9633D96222Ce399c708B19c28;
        addr["MCD_CURE"]                        = 0x0085c9feAb2335447E1F4DC9bf3593a8e28bdfc7;
        addr["MCD_ESM"]                         = 0x09e05fF6142F2f9de8B6B65855A1d56B6cfE4c58;
        addr["PROXY_ACTIONS"]                   = 0x82ecD135Dce65Fbc6DbdD0e4237E0AF93FFD5038;
        addr["PROXY_ACTIONS_END"]               = 0x7AfF9FC9faD225e3c88cDA06BC56d8Aca774bC57;
        addr["PROXY_ACTIONS_DSR"]               = 0x07ee93aEEa0a36FfF2A9B95dd22Bd6049EE54f26;
        addr["CDP_MANAGER"]                     = 0x5ef30b9986345249bc32d8928B7ee64DE9435E39;
        addr["DSR_MANAGER"]                     = 0x373238337Bfe1146fb49989fc222523f83081dDb;
        addr["GET_CDPS"]                        = 0x36a724Bd100c39f0Ea4D3A20F7097eE01A8Ff573;
        addr["ILK_REGISTRY"]                    = 0x5a464C28D19848f44199D003BeF5ecc87d090F87;
        addr["OSM_MOM"]                         = 0x76416A4d5190d071bfed309861527431304aA14f;
        addr["FLIPPER_MOM"]                     = 0xc4bE7F74Ee3743bDEd8E0fA218ee5cf06397f472;
        addr["CLIPPER_MOM"]                     = 0x79FBDF16b366DFb14F66cE4Ac2815Ca7296405A0;
        addr["DIRECT_MOM"]                      = 0x99A219f3dD2DeEC02c6324df5009aaa60bA36d38;
        addr["PROXY_FACTORY"]                   = 0xA26e15C895EFc0616177B7c1e7270A4C7D51C997;
        addr["PROXY_REGISTRY"]                  = 0x4678f0a6958e4D2Bc4F1BAF7Bc52E8F3564f3fE4;
        addr["MCD_VEST_DAI"]                    = 0xa4c22f0e25C6630B2017979AcF1f865e94695C4b;
        addr["MCD_VEST_DAI_LEGACY"]             = 0x2Cc583c0AaCDaC9e23CB601fDA8F1A0c56Cdcb71;
        addr["MCD_VEST_MKR"]                    = 0x0fC8D4f2151453ca0cA56f07359049c8f07997Bd;
        addr["MCD_VEST_MKR_TREASURY"]           = 0x6D635c8d08a1eA2F1687a5E46b666949c977B7dd;
        addr["MCD_FLASH"]                       = 0x60744434d6339a6B27d73d9Eda62b6F66a0a04FA;
        addr["MCD_FLASH_LEGACY"]                = 0x1EB4CF3A948E7D72A198fe073cCb8C7a948cD853;
        addr["FLASH_KILLER"]                    = 0x07a4BaAEFA236A649880009B5a2B862097D9a1cD;
        addr["PROXY_ACTIONS_CROPPER"]           = 0xa2f69F8B9B341CFE9BfBb3aaB5fe116C89C95bAF;
        addr["PROXY_ACTIONS_END_CROPPER"]       = 0x38f7C166B5B22906f04D8471E241151BA45d97Af;
        addr["CDP_REGISTRY"]                    = 0xBe0274664Ca7A68d6b5dF826FB3CcB7c620bADF3;
        addr["MCD_CROPPER"]                     = 0x8377CD01a5834a6EaD3b7efb482f678f2092b77e;
        addr["MCD_CROPPER_IMP"]                 = 0xaFB21A0e9669cdbA539a4c91Bf6B94c5F013c0DE;
        addr["ETH"]                             = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        addr["PIP_ETH"]                         = 0x81FE72B5A8d1A857d176C3E7d5Bd2679A9B85763;
        addr["MCD_JOIN_ETH_A"]                  = 0x2F0b23f53734252Bda2277357e97e1517d6B042A;
        addr["MCD_FLIP_ETH_A"]                  = 0xF32836B9E1f47a0515c6Ec431592D5EbC276407f;
        addr["MCD_CLIP_ETH_A"]                  = 0xc67963a226eddd77B91aD8c421630A1b0AdFF270;
        addr["MCD_CLIP_CALC_ETH_A"]             = 0x7d9f92DAa9254Bbd1f479DBE5058f74C2381A898;
        addr["MCD_JOIN_ETH_B"]                  = 0x08638eF1A205bE6762A8b935F5da9b700Cf7322c;
        addr["MCD_FLIP_ETH_B"]                  = 0xD499d71bE9e9E5D236A07ac562F7B6CeacCa624c;
        addr["MCD_CLIP_ETH_B"]                  = 0x71eb894330e8a4b96b8d6056962e7F116F50e06F;
        addr["MCD_CLIP_CALC_ETH_B"]             = 0x19E26067c4a69B9534adf97ED8f986c49179dE18;
        addr["MCD_JOIN_ETH_C"]                  = 0xF04a5cC80B1E94C69B48f5ee68a08CD2F09A7c3E;
        addr["MCD_FLIP_ETH_C"]                  = 0x7A67901A68243241EBf66beEB0e7b5395582BF17;
        addr["MCD_CLIP_ETH_C"]                  = 0xc2b12567523e3f3CBd9931492b91fe65b240bc47;
        addr["MCD_CLIP_CALC_ETH_C"]             = 0x1c4fC274D12b2e1BBDF97795193D3148fCDa6108;
        addr["BAT"]                             = 0x0D8775F648430679A709E98d2b0Cb6250d2887EF;
        addr["PIP_BAT"]                         = 0xB4eb54AF9Cc7882DF0121d26c5b97E802915ABe6;
        addr["MCD_JOIN_BAT_A"]                  = 0x3D0B1912B66114d4096F48A8CEe3A56C231772cA;
        addr["MCD_FLIP_BAT_A"]                  = 0xF7C569B2B271354179AaCC9fF1e42390983110BA;
        addr["MCD_CLIP_BAT_A"]                  = 0x3D22e6f643e2F4c563fD9db22b229Cbb0Cd570fb;
        addr["MCD_CLIP_CALC_BAT_A"]             = 0x2e118153D304a0d9C5838D5FCb70CEfCbEc81DC2;
        addr["USDC"]                            = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
        addr["PIP_USDC"]                        = 0x77b68899b99b686F415d074278a9a16b336085A0;
        addr["MCD_JOIN_USDC_A"]                 = 0xA191e578a6736167326d05c119CE0c90849E84B7;
        addr["MCD_FLIP_USDC_A"]                 = 0xbe359e53038E41a1ffA47DAE39645756C80e557a;
        addr["MCD_CLIP_USDC_A"]                 = 0x046b1A5718da6A226D912cFd306BA19980772908;
        addr["MCD_CLIP_CALC_USDC_A"]            = 0x0FCa4ba0B80123b5d22dD3C8BF595F3E561d594D;
        addr["MCD_JOIN_USDC_B"]                 = 0x2600004fd1585f7270756DDc88aD9cfA10dD0428;
        addr["MCD_FLIP_USDC_B"]                 = 0x77282aD36aADAfC16bCA42c865c674F108c4a616;
        addr["MCD_CLIP_USDC_B"]                 = 0x5590F23358Fe17361d7E4E4f91219145D8cCfCb3;
        addr["MCD_CLIP_CALC_USDC_B"]            = 0xD6FE411284b92d309F79e502Dd905D7A3b02F561;
        addr["MCD_JOIN_PSM_USDC_A"]             = 0x0A59649758aa4d66E25f08Dd01271e891fe52199;
        addr["MCD_FLIP_PSM_USDC_A"]             = 0x507420100393b1Dc2e8b4C8d0F8A13B56268AC99;
        addr["MCD_CLIP_PSM_USDC_A"]             = 0x66609b4799fd7cE12BA799AD01094aBD13d5014D;
        addr["MCD_CLIP_CALC_PSM_USDC_A"]        = 0xbeE028b5Fa9eb0aDAC5eeF7E5B13383172b91A4E;
        addr["MCD_PSM_USDC_A"]                  = 0x89B78CfA322F6C5dE0aBcEecab66Aee45393cC5A;
        addr["WBTC"]                            = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
        addr["PIP_WBTC"]                        = 0xf185d0682d50819263941e5f4EacC763CC5C6C42;
        addr["MCD_JOIN_WBTC_A"]                 = 0xBF72Da2Bd84c5170618Fbe5914B0ECA9638d5eb5;
        addr["MCD_FLIP_WBTC_A"]                 = 0x58CD24ac7322890382eE45A3E4F903a5B22Ee930;
        addr["MCD_CLIP_WBTC_A"]                 = 0x0227b54AdbFAEec5f1eD1dFa11f54dcff9076e2C;
        addr["MCD_CLIP_CALC_WBTC_A"]            = 0x5f4CEa97ca1030C6Bd38429c8a0De7Cd4981C70A;
        addr["MCD_JOIN_WBTC_B"]                 = 0xfA8c996e158B80D77FbD0082BB437556A65B96E0;
        addr["MCD_CLIP_WBTC_B"]                 = 0xe30663C6f83A06eDeE6273d72274AE24f1084a22;
        addr["MCD_CLIP_CALC_WBTC_B"]            = 0xeb911E99D7ADD1350DC39d84D60835BA9B287D96;
        addr["MCD_JOIN_WBTC_C"]                 = 0x7f62f9592b823331E012D3c5DdF2A7714CfB9de2;
        addr["MCD_CLIP_WBTC_C"]                 = 0x39F29773Dcb94A32529d0612C6706C49622161D1;
        addr["MCD_CLIP_CALC_WBTC_C"]            = 0x4fa2A328E7f69D023fE83454133c273bF5ACD435;
        addr["TUSD"]                            = 0x0000000000085d4780B73119b644AE5ecd22b376;
        addr["PIP_TUSD"]                        = 0xeE13831ca96d191B688A670D47173694ba98f1e5;
        addr["MCD_JOIN_TUSD_A"]                 = 0x4454aF7C8bb9463203b66C816220D41ED7837f44;
        addr["MCD_FLIP_TUSD_A"]                 = 0x9E4b213C4defbce7564F2Ac20B6E3bF40954C440;
        addr["MCD_CLIP_TUSD_A"]                 = 0x0F6f88f8A4b918584E3539182793a0C276097f44;
        addr["MCD_CLIP_CALC_TUSD_A"]            = 0x9B207AfAAAD1ae300Ea659e71306a7Bd6D81C160;
        addr["ZRX"]                             = 0xE41d2489571d322189246DaFA5ebDe1F4699F498;
        addr["PIP_ZRX"]                         = 0x7382c066801E7Acb2299aC8562847B9883f5CD3c;
        addr["MCD_JOIN_ZRX_A"]                  = 0xc7e8Cd72BDEe38865b4F5615956eF47ce1a7e5D0;
        addr["MCD_FLIP_ZRX_A"]                  = 0xa4341cAf9F9F098ecb20fb2CeE2a0b8C78A18118;
        addr["MCD_CLIP_ZRX_A"]                  = 0xdc90d461E148552387f3aB3EBEE0Bdc58Aa16375;
        addr["MCD_CLIP_CALC_ZRX_A"]             = 0xebe5e9D77b9DBBA8907A197f4c2aB00A81fb0C4e;
        addr["KNC"]                             = 0xdd974D5C2e2928deA5F71b9825b8b646686BD200;
        addr["PIP_KNC"]                         = 0xf36B79BD4C0904A5F350F1e4f776B81208c13069;
        addr["MCD_JOIN_KNC_A"]                  = 0x475F1a89C1ED844A08E8f6C50A00228b5E59E4A9;
        addr["MCD_FLIP_KNC_A"]                  = 0x57B01F1B3C59e2C0bdfF3EC9563B71EEc99a3f2f;
        addr["MCD_CLIP_KNC_A"]                  = 0x006Aa3eB5E666D8E006aa647D4afAB212555Ddea;
        addr["MCD_CLIP_CALC_KNC_A"]             = 0x82c41e2ADE28C066a5D3A1E3f5B444a4075C1584;
        addr["MANA"]                            = 0x0F5D2fB29fb7d3CFeE444a200298f468908cC942;
        addr["PIP_MANA"]                        = 0x8067259EA630601f319FccE477977E55C6078C13;
        addr["MCD_JOIN_MANA_A"]                 = 0xA6EA3b9C04b8a38Ff5e224E7c3D6937ca44C0ef9;
        addr["MCD_FLIP_MANA_A"]                 = 0x0a1D75B4f49BA80724a214599574080CD6B68357;
        addr["MCD_CLIP_MANA_A"]                 = 0xF5C8176E1eB0915359E46DEd16E52C071Bb435c0;
        addr["MCD_CLIP_CALC_MANA_A"]            = 0xABbCd14FeDbb2D39038327055D9e615e178Fd64D;
        addr["USDT"]                            = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
        addr["PIP_USDT"]                        = 0x7a5918670B0C390aD25f7beE908c1ACc2d314A3C;
        addr["MCD_JOIN_USDT_A"]                 = 0x0Ac6A1D74E84C2dF9063bDDc31699FF2a2BB22A2;
        addr["MCD_FLIP_USDT_A"]                 = 0x667F41d0fDcE1945eE0f56A79dd6c142E37fCC26;
        addr["MCD_CLIP_USDT_A"]                 = 0xFC9D6Dd08BEE324A5A8B557d2854B9c36c2AeC5d;
        addr["MCD_CLIP_CALC_USDT_A"]            = 0x1Cf3DE6D570291CDB88229E70037d1705d5be748;
        addr["PAXUSD"]                          = 0x8E870D67F660D95d5be530380D0eC0bd388289E1;
        addr["PAX"]                             = 0x8E870D67F660D95d5be530380D0eC0bd388289E1;
        addr["PIP_PAXUSD"]                      = 0x043B963E1B2214eC90046167Ea29C2c8bDD7c0eC;
        addr["PIP_PAX"]                         = 0x043B963E1B2214eC90046167Ea29C2c8bDD7c0eC;
        addr["MCD_JOIN_PAXUSD_A"]               = 0x7e62B7E279DFC78DEB656E34D6a435cC08a44666;
        addr["MCD_FLIP_PAXUSD_A"]               = 0x52D5D1C05CC79Fc24A629Cb24cB06C5BE5d766E7;
        addr["MCD_CLIP_PAXUSD_A"]               = 0xBCb396Cd139D1116BD89562B49b9D1d6c25378B0;
        addr["MCD_CLIP_CALC_PAXUSD_A"]          = 0xAB98De83840b8367046383D2Adef9959E130923e;
        addr["MCD_JOIN_PSM_PAX_A"]              = 0x7bbd8cA5e413bCa521C2c80D8d1908616894Cf21;
        addr["MCD_CLIP_PSM_PAX_A"]              = 0x5322a3551bc6a1b39d5D142e5e38Dc5B4bc5B3d2;
        addr["MCD_CLIP_CALC_PSM_PAX_A"]         = 0xC19eAc21A4FccdD30812F5fF5FebFbD6817b7593;
        addr["MCD_PSM_PAX_A"]                   = 0x961Ae24a1Ceba861D1FDf723794f6024Dc5485Cf;
        addr["COMP"]                            = 0xc00e94Cb662C3520282E6f5717214004A7f26888;
        addr["PIP_COMP"]                        = 0xBED0879953E633135a48a157718Aa791AC0108E4;
        addr["MCD_JOIN_COMP_A"]                 = 0xBEa7cDfB4b49EC154Ae1c0D731E4DC773A3265aA;
        addr["MCD_FLIP_COMP_A"]                 = 0x524826F84cB3A19B6593370a5889A58c00554739;
        addr["MCD_CLIP_COMP_A"]                 = 0x2Bb690931407DCA7ecE84753EA931ffd304f0F38;
        addr["MCD_CLIP_CALC_COMP_A"]            = 0x1f546560EAa70985d962f1562B65D4B182341a63;
        addr["LRC"]                             = 0xBBbbCA6A901c926F240b89EacB641d8Aec7AEafD;
        addr["PIP_LRC"]                         = 0x9eb923339c24c40Bef2f4AF4961742AA7C23EF3a;
        addr["MCD_JOIN_LRC_A"]                  = 0x6C186404A7A238D3d6027C0299D1822c1cf5d8f1;
        addr["MCD_FLIP_LRC_A"]                  = 0x7FdDc36dcdC435D8F54FDCB3748adcbBF70f3dAC;
        addr["MCD_CLIP_LRC_A"]                  = 0x81C5CDf4817DBf75C7F08B8A1cdaB05c9B3f70F7;
        addr["MCD_CLIP_CALC_LRC_A"]             = 0x6856CCA4c881CAf29B6563bA046C7Bb73121fb9d;
        addr["LINK"]                            = 0x514910771AF9Ca656af840dff83E8264EcF986CA;
        addr["PIP_LINK"]                        = 0x9B0C694C6939b5EA9584e9b61C7815E8d97D9cC7;
        addr["MCD_JOIN_LINK_A"]                 = 0xdFccAf8fDbD2F4805C174f856a317765B49E4a50;
        addr["MCD_FLIP_LINK_A"]                 = 0xB907EEdD63a30A3381E6D898e5815Ee8c9fd2c85;
        addr["MCD_CLIP_LINK_A"]                 = 0x832Dd5f17B30078a5E46Fdb8130A68cBc4a74dC0;
        addr["MCD_CLIP_CALC_LINK_A"]            = 0x7B1696677107E48B152e9Bf400293e98B7D86Eb1;
        addr["BAL"]                             = 0xba100000625a3754423978a60c9317c58a424e3D;
        addr["PIP_BAL"]                         = 0x3ff860c0F28D69F392543A16A397D0dAe85D16dE;
        addr["MCD_JOIN_BAL_A"]                  = 0x4a03Aa7fb3973d8f0221B466EefB53D0aC195f55;
        addr["MCD_FLIP_BAL_A"]                  = 0xb2b9bd446eE5e58036D2876fce62b7Ab7334583e;
        addr["MCD_CLIP_BAL_A"]                  = 0x6AAc067bb903E633A422dE7BE9355E62B3CE0378;
        addr["MCD_CLIP_CALC_BAL_A"]             = 0x79564a41508DA86721eDaDac07A590b5A51B2c01;
        addr["YFI"]                             = 0x0bc529c00C6401aEF6D220BE8C6Ea1667F6Ad93e;
        addr["PIP_YFI"]                         = 0x5F122465bCf86F45922036970Be6DD7F58820214;
        addr["MCD_JOIN_YFI_A"]                  = 0x3ff33d9162aD47660083D7DC4bC02Fb231c81677;
        addr["MCD_FLIP_YFI_A"]                  = 0xEe4C9C36257afB8098059a4763A374a4ECFE28A7;
        addr["MCD_CLIP_YFI_A"]                  = 0x9daCc11dcD0aa13386D295eAeeBBd38130897E6f;
        addr["MCD_CLIP_CALC_YFI_A"]             = 0x1f206d7916Fd3B1b5B0Ce53d5Cab11FCebc124DA;
        addr["GUSD"]                            = 0x056Fd409E1d7A124BD7017459dFEa2F387b6d5Cd;
        addr["PIP_GUSD"]                        = 0xf45Ae69CcA1b9B043dAE2C83A5B65Bc605BEc5F5;
        addr["MCD_JOIN_GUSD_A"]                 = 0xe29A14bcDeA40d83675aa43B72dF07f649738C8b;
        addr["MCD_FLIP_GUSD_A"]                 = 0xCAa8D152A8b98229fB77A213BE16b234cA4f612f;
        addr["MCD_CLIP_GUSD_A"]                 = 0xa47D68b9dB0A0361284fA04BA40623fcBd1a263E;
        addr["MCD_CLIP_CALC_GUSD_A"]            = 0xF7e80359Cb9C4E6D178E6689eD8A6A6f91060747;
        addr["MCD_JOIN_PSM_GUSD_A"]             = 0x79A0FA989fb7ADf1F8e80C93ee605Ebb94F7c6A5;
        addr["MCD_CLIP_PSM_GUSD_A"]             = 0xf93CC3a50f450ED245e003BFecc8A6Ec1732b0b2;
        addr["MCD_CLIP_CALC_PSM_GUSD_A"]        = 0x7f67a68a0ED74Ea89A82eD9F243C159ed43a502a;
        addr["MCD_PSM_GUSD_A"]                  = 0x204659B2Fd2aD5723975c362Ce2230Fba11d3900;
        addr["UNI"]                             = 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984;
        addr["PIP_UNI"]                         = 0xf363c7e351C96b910b92b45d34190650df4aE8e7;
        addr["MCD_JOIN_UNI_A"]                  = 0x3BC3A58b4FC1CbE7e98bB4aB7c99535e8bA9b8F1;
        addr["MCD_FLIP_UNI_A"]                  = 0xF5b8cD9dB5a0EC031304A7B815010aa7761BD426;
        addr["MCD_CLIP_UNI_A"]                  = 0x3713F83Ee6D138Ce191294C131148176015bC29a;
        addr["MCD_CLIP_CALC_UNI_A"]             = 0xeA7FE6610e6708E2AFFA202948cA19ace3F580AE;
        addr["RENBTC"]                          = 0xEB4C2781e4ebA804CE9a9803C67d0893436bB27D;
        addr["PIP_RENBTC"]                      = 0xf185d0682d50819263941e5f4EacC763CC5C6C42;
        addr["MCD_JOIN_RENBTC_A"]               = 0xFD5608515A47C37afbA68960c1916b79af9491D0;
        addr["MCD_FLIP_RENBTC_A"]               = 0x30BC6eBC27372e50606880a36B279240c0bA0758;
        addr["MCD_CLIP_RENBTC_A"]               = 0x834719BEa8da68c46484E001143bDDe29370a6A3;
        addr["MCD_CLIP_CALC_RENBTC_A"]          = 0xcC89F368aad8D424d3e759c1525065e56019a0F4;
        addr["AAVE"]                            = 0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9;
        addr["PIP_AAVE"]                        = 0x8Df8f06DC2dE0434db40dcBb32a82A104218754c;
        addr["MCD_JOIN_AAVE_A"]                 = 0x24e459F61cEAa7b1cE70Dbaea938940A7c5aD46e;
        addr["MCD_FLIP_AAVE_A"]                 = 0x16e1b844094c885a37509a8f76c533B5fbFED13a;
        addr["MCD_CLIP_AAVE_A"]                 = 0x8723b74F598DE2ea49747de5896f9034CC09349e;
        addr["MCD_CLIP_CALC_AAVE_A"]            = 0x76024a8EfFCFE270e089964a562Ece6ea5f3a14C;
        addr["MATIC"]                           = 0x7D1AfA7B718fb893dB30A3aBc0Cfc608AaCfeBB0;
        addr["PIP_MATIC"]                       = 0x8874964279302e6d4e523Fb1789981C39a1034Ba;
        addr["MCD_JOIN_MATIC_A"]                = 0x885f16e177d45fC9e7C87e1DA9fd47A9cfcE8E13;
        addr["MCD_CLIP_MATIC_A"]                = 0x29342F530ed6120BDB219D602DaFD584676293d1;
        addr["MCD_CLIP_CALC_MATIC_A"]           = 0xdF8C347B06a31c6ED11f8213C2366348BFea68dB;
        addr["STETH"]                           = 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;
        addr["WSTETH"]                          = 0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0;
        addr["PIP_WSTETH"]                      = 0xFe7a2aC0B945f12089aEEB6eCebf4F384D9f043F;
        addr["MCD_JOIN_WSTETH_A"]               = 0x10CD5fbe1b404B7E19Ef964B63939907bdaf42E2;
        addr["MCD_CLIP_WSTETH_A"]               = 0x49A33A28C4C7D9576ab28898F4C9ac7e52EA457A;
        addr["MCD_CLIP_CALC_WSTETH_A"]          = 0x15282b886675cc1Ce04590148f456428E87eaf13;
        addr["MCD_JOIN_WSTETH_B"]               = 0x248cCBf4864221fC0E840F29BB042ad5bFC89B5c;
        addr["MCD_CLIP_WSTETH_B"]               = 0x3ea60191b7d5990a3544B6Ef79983fD67e85494A;
        addr["MCD_CLIP_CALC_WSTETH_B"]          = 0x95098b29F579dbEb5c198Db6F30E28F7f3955Fbb;
        addr["UNIV2DAIETH"]                     = 0xA478c2975Ab1Ea89e8196811F51A7B7Ade33eB11;
        addr["PIP_UNIV2DAIETH"]                 = 0xFc8137E1a45BAF0030563EC4F0F851bd36a85b7D;
        addr["MCD_JOIN_UNIV2DAIETH_A"]          = 0x2502F65D77cA13f183850b5f9272270454094A08;
        addr["MCD_FLIP_UNIV2DAIETH_A"]          = 0x57dfd99f45747DD55C1c432Db4aEa07FBd5d2B5c;
        addr["MCD_CLIP_UNIV2DAIETH_A"]          = 0x9F6981bA5c77211A34B76c6385c0f6FA10414035;
        addr["MCD_CLIP_CALC_UNIV2DAIETH_A"]     = 0xf738C272D648Cc4565EaFb43c0C5B35BbA3bf29d;
        addr["MCD_IAM_AUTO_LINE"]               = 0xC7Bdd1F2B16447dcf3dE045C4a039A60EC2f0ba3;
        addr["PROXY_PAUSE_ACTIONS"]             = 0x6bda13D43B7EDd6CAfE1f70fB98b5d40f61A1370;
        addr["PROXY_DEPLOYER"]                  = 0x1b93556AB8dcCEF01Cd7823C617a6d340f53Fb58;
        addr["UNIV2WBTCETH"]                    = 0xBb2b8038a1640196FbE3e38816F3e67Cba72D940;
        addr["MCD_JOIN_UNIV2WBTCETH_A"]         = 0xDc26C9b7a8fe4F5dF648E314eC3E6Dc3694e6Dd2;
        addr["MCD_FLIP_UNIV2WBTCETH_A"]         = 0xbc95e8904d879F371Ac6B749727a0EAfDCd2ACB6;
        addr["MCD_CLIP_UNIV2WBTCETH_A"]         = 0xb15afaB996904170f87a64Fe42db0b64a6F75d24;
        addr["MCD_CLIP_CALC_UNIV2WBTCETH_A"]    = 0xC94ee71e909DbE08d63aA9e6EFbc9976751601B4;
        addr["PIP_UNIV2WBTCETH"]                = 0x8400D2EDb8B97f780356Ef602b1BdBc082c2aD07;
        addr["UNIV2USDCETH"]                    = 0xB4e16d0168e52d35CaCD2c6185b44281Ec28C9Dc;
        addr["MCD_JOIN_UNIV2USDCETH_A"]         = 0x03Ae53B33FeeAc1222C3f372f32D37Ba95f0F099;
        addr["MCD_FLIP_UNIV2USDCETH_A"]         = 0x48d2C08b93E57701C8ae8974Fc4ADd725222B0BB;
        addr["MCD_CLIP_UNIV2USDCETH_A"]         = 0x93AE03815BAF1F19d7F18D9116E4b637cc32A131;
        addr["MCD_CLIP_CALC_UNIV2USDCETH_A"]    = 0x022ff40643e8b94C43f0a1E54f51EF6D070AcbC4;
        addr["PIP_UNIV2USDCETH"]                = 0xf751f24DD9cfAd885984D1bA68860F558D21E52A;
        addr["UNIV2DAIUSDC"]                    = 0xAE461cA67B15dc8dc81CE7615e0320dA1A9aB8D5;
        addr["MCD_JOIN_UNIV2DAIUSDC_A"]         = 0xA81598667AC561986b70ae11bBE2dd5348ed4327;
        addr["MCD_FLIP_UNIV2DAIUSDC_A"]         = 0x4a613f79a250D522DdB53904D87b8f442EA94496;
        addr["MCD_CLIP_UNIV2DAIUSDC_A"]         = 0x9B3310708af333f6F379FA42a5d09CBAA10ab309;
        addr["MCD_CLIP_CALC_UNIV2DAIUSDC_A"]    = 0xbEF2ab2aA5CC780A03bccf22AD3320c8CF35af6A;
        addr["PIP_UNIV2DAIUSDC"]                = 0x25D03C2C928ADE19ff9f4FFECc07d991d0df054B;
        addr["UNIV2ETHUSDT"]                    = 0x0d4a11d5EEaaC28EC3F61d100daF4d40471f1852;
        addr["MCD_JOIN_UNIV2ETHUSDT_A"]         = 0x4aAD139a88D2dd5e7410b408593208523a3a891d;
        addr["MCD_FLIP_UNIV2ETHUSDT_A"]         = 0x118d5051e70F9EaF3B4a6a11F765185A2Ca0802E;
        addr["MCD_CLIP_UNIV2ETHUSDT_A"]         = 0x2aC4C9b49051275AcB4C43Ec973082388D015D48;
        addr["MCD_CLIP_CALC_UNIV2ETHUSDT_A"]    = 0xA475582E3D6Ec35091EaE81da3b423C1B27fa029;
        addr["PIP_UNIV2ETHUSDT"]                = 0x5f6dD5B421B8d92c59dC6D907C9271b1DBFE3016;
        addr["UNIV2LINKETH"]                    = 0xa2107FA5B38d9bbd2C461D6EDf11B11A50F6b974;
        addr["MCD_JOIN_UNIV2LINKETH_A"]         = 0xDae88bDe1FB38cF39B6A02b595930A3449e593A6;
        addr["MCD_FLIP_UNIV2LINKETH_A"]         = 0xb79f818E3c73FCA387845f892356224CA75eac4b;
        addr["MCD_CLIP_UNIV2LINKETH_A"]         = 0x6aa0520354d1b84e1C6ABFE64a708939529b619e;
        addr["MCD_CLIP_CALC_UNIV2LINKETH_A"]    = 0x8aCeC2d937a4A4cAF42565aFbbb05ac242134F14;
        addr["PIP_UNIV2LINKETH"]                = 0xd7d31e62AE5bfC3bfaa24Eda33e8c32D31a1746F;
        addr["UNIV2UNIETH"]                     = 0xd3d2E2692501A5c9Ca623199D38826e513033a17;
        addr["MCD_JOIN_UNIV2UNIETH_A"]          = 0xf11a98339FE1CdE648e8D1463310CE3ccC3d7cC1;
        addr["MCD_FLIP_UNIV2UNIETH_A"]          = 0xe5ED7da0483e291485011D5372F3BF46235EB277;
        addr["MCD_CLIP_UNIV2UNIETH_A"]          = 0xb0ece6F5542A4577E2f1Be491A937Ccbbec8479e;
        addr["MCD_CLIP_CALC_UNIV2UNIETH_A"]     = 0xad609Ed16157014EF955C94553E40e94A09049f0;
        addr["PIP_UNIV2UNIETH"]                 = 0x8462A88f50122782Cc96108F476deDB12248f931;
        addr["UNIV2WBTCDAI"]                    = 0x231B7589426Ffe1b75405526fC32aC09D44364c4;
        addr["MCD_JOIN_UNIV2WBTCDAI_A"]         = 0xD40798267795Cbf3aeEA8E9F8DCbdBA9b5281fcC;
        addr["MCD_FLIP_UNIV2WBTCDAI_A"]         = 0x172200d12D09C2698Dd918d347155fE6692f5662;
        addr["MCD_CLIP_UNIV2WBTCDAI_A"]         = 0x4fC53a57262B87ABDa61d6d0DB2bE7E9BE68F6b8;
        addr["MCD_CLIP_CALC_UNIV2WBTCDAI_A"]    = 0x863AEa7D2c4BF2B5Aa191B057240b6Dc29F532eB;
        addr["PIP_UNIV2WBTCDAI"]                = 0x5bB72127a196392cf4aC00Cf57aB278394d24e55;
        addr["UNIV2AAVEETH"]                    = 0xDFC14d2Af169B0D36C4EFF567Ada9b2E0CAE044f;
        addr["MCD_JOIN_UNIV2AAVEETH_A"]         = 0x42AFd448Df7d96291551f1eFE1A590101afB1DfF;
        addr["MCD_FLIP_UNIV2AAVEETH_A"]         = 0x20D298ca96bf8c2000203B911908DbDc1a8Bac58;
        addr["MCD_CLIP_UNIV2AAVEETH_A"]         = 0x854b252BA15eaFA4d1609D3B98e00cc10084Ec55;
        addr["MCD_CLIP_CALC_UNIV2AAVEETH_A"]    = 0x5396e541E1F648EC03faf338389045F1D7691960;
        addr["PIP_UNIV2AAVEETH"]                = 0x32d8416e8538Ac36272c44b0cd962cD7E0198489;
        addr["UNIV2DAIUSDT"]                    = 0xB20bd5D04BE54f870D5C0d3cA85d82b34B836405;
        addr["MCD_JOIN_UNIV2DAIUSDT_A"]         = 0xAf034D882169328CAf43b823a4083dABC7EEE0F4;
        addr["MCD_FLIP_UNIV2DAIUSDT_A"]         = 0xD32f8B8aDbE331eC0CfADa9cfDbc537619622cFe;
        addr["MCD_CLIP_UNIV2DAIUSDT_A"]         = 0xe4B82Be84391b9e7c56a1fC821f47569B364dd4a;
        addr["MCD_CLIP_CALC_UNIV2DAIUSDT_A"]    = 0x4E88cE740F6bEa31C2b14134F6C5eB2a63104fcF;
        addr["PIP_UNIV2DAIUSDT"]                = 0x9A1CD705dc7ac64B50777BcEcA3529E58B1292F1;
        addr["MIP21_LIQUIDATION_ORACLE"]        = 0x88f88Bb9E66241B73B84f3A6E197FbBa487b1E30;
        addr["RWA_TOKEN_FAB"]                   = 0x2B3a4c18705e99bC29b22222dA7E10b643658552;
        addr["RWA001"]                          = 0x10b2aA5D77Aa6484886d8e244f0686aB319a270d;
        addr["PIP_RWA001"]                      = 0x76A9f30B45F4ebFD60Ce8a1c6e963b1605f7cB6d;
        addr["MCD_JOIN_RWA001_A"]               = 0x476b81c12Dc71EDfad1F64B9E07CaA60F4b156E2;
        addr["RWA001_A_URN"]                    = 0xa3342059BcDcFA57a13b12a35eD4BBE59B873005;
        addr["RWA001_A_INPUT_CONDUIT"]          = 0x486C85e2bb9801d14f6A8fdb78F5108a0fd932f2;
        addr["RWA001_A_OUTPUT_CONDUIT"]         = 0xb3eFb912e1cbC0B26FC17388Dd433Cecd2206C3d;
        addr["RWA002"]                          = 0xAAA760c2027817169D7C8DB0DC61A2fb4c19AC23;
        addr["PIP_RWA002"]                      = 0xd2473237E20Bd52F8E7cE0FD79403A6a82fbAEC8;
        addr["MCD_JOIN_RWA002_A"]               = 0xe72C7e90bc26c11d45dBeE736F0acf57fC5B7152;
        addr["RWA002_A_URN"]                    = 0x225B3da5BE762Ee52B182157E67BeA0b31968163;
        addr["RWA002_A_INPUT_CONDUIT"]          = 0x2474F297214E5d96Ba4C81986A9F0e5C260f445D;
        addr["RWA002_A_OUTPUT_CONDUIT"]         = 0x2474F297214E5d96Ba4C81986A9F0e5C260f445D;
        addr["RWA003"]                          = 0x07F0A80aD7AeB7BfB7f139EA71B3C8f7E17156B9;
        addr["PIP_RWA003"]                      = 0xDeF7E88447F7D129420FC881B2a854ABB52B73B8;
        addr["MCD_JOIN_RWA003_A"]               = 0x1Fe789BBac5b141bdD795A3Bc5E12Af29dDB4b86;
        addr["RWA003_A_URN"]                    = 0x7bF825718e7C388c3be16CFe9982539A7455540F;
        addr["RWA003_A_INPUT_CONDUIT"]          = 0x2A9798c6F165B6D60Cfb923Fe5BFD6f338695D9B;
        addr["RWA003_A_OUTPUT_CONDUIT"]         = 0x2A9798c6F165B6D60Cfb923Fe5BFD6f338695D9B;
        addr["RWA004"]                          = 0x873F2101047A62F84456E3B2B13df2287925D3F9;
        addr["PIP_RWA004"]                      = 0x5eEE1F3d14850332A75324514CcbD2DBC8Bbc566;
        addr["MCD_JOIN_RWA004_A"]               = 0xD50a8e9369140539D1c2D113c4dC1e659c6242eB;
        addr["RWA004_A_URN"]                    = 0xeF1699548717aa4Cf47aD738316280b56814C821;
        addr["RWA004_A_INPUT_CONDUIT"]          = 0xe1ed3F588A98bF8a3744f4BF74Fd8540e81AdE3f;
        addr["RWA004_A_OUTPUT_CONDUIT"]         = 0xe1ed3F588A98bF8a3744f4BF74Fd8540e81AdE3f;
        addr["RWA005"]                          = 0x6DB236515E90fC831D146f5829407746EDdc5296;
        addr["PIP_RWA005"]                      = 0x8E6039C558738eb136833aB50271ae065c700d2B;
        addr["MCD_JOIN_RWA005_A"]               = 0xA4fD373b93aD8e054970A3d6cd4Fd4C31D08192e;
        addr["RWA005_A_URN"]                    = 0xc40907545C57dB30F01a1c2acB242C7c7ACB2B90;
        addr["RWA005_A_INPUT_CONDUIT"]          = 0x5b702e1fEF3F556cbe219eE697D7f170A236cc66;
        addr["RWA005_A_OUTPUT_CONDUIT"]         = 0x5b702e1fEF3F556cbe219eE697D7f170A236cc66;
        addr["RWA006"]                          = 0x4EE03cfBF6E784c462839f5954d60f7C2B60b113;
        addr["PIP_RWA006"]                      = 0xB8AeCF04Fdf22Ef6C0c6b6536896e1F2870C41D3;
        addr["MCD_JOIN_RWA006_A"]               = 0x5E11E34b6745FeBa9449Ae53c185413d6EdC66BE;
        addr["RWA006_A_URN"]                    = 0x0C185bf5388DdfDB288F4D875265d456D18FD9Cb;
        addr["RWA006_A_INPUT_CONDUIT"]          = 0x8Fe38D1E4293181273E2e323e4c16e0D1d4861e3;
        addr["RWA006_A_OUTPUT_CONDUIT"]         = 0x8Fe38D1E4293181273E2e323e4c16e0D1d4861e3;
        addr["RWA007"]                          = 0x078fb926b041a816FaccEd3614Cf1E4bc3C723bD;
        addr["PIP_RWA007"]                      = 0x7bb4BcA758c4006998a2769776D9E4E6D86e0Dab;
        addr["MCD_JOIN_RWA007_A"]               = 0x476aaD14F42469989EFad0b7A31f07b795FF0621;
        addr["RWA007_A_URN"]                    = 0x481bA2d2e86a1c41427893899B5B0cEae41c6726;
        addr["RWA007_A_JAR"]                    = 0xef1B095F700BE471981aae025f92B03091c3AD47;
        addr["RWA007_A_INPUT_CONDUIT"]          = 0x58f5e979eF74b60a9e5F955553ab8e0e65ba89c9;
        addr["RWA007_A_JAR_INPUT_CONDUIT"]      = 0xc8bb4e2B249703640e89265e2Ae7c9D5eA2aF742;
        addr["RWA007_A_OUTPUT_CONDUIT"]         = 0x701C3a384c613157bf473152844f368F2d6EF191;
        addr["RWA007_A_OPERATOR"]               = 0x94cfBF071f8be325A5821bFeAe00eEbE9CE7c279;
        addr["RWA007_A_COINBASE_CUSTODY"]       = 0xC3acf3B96E46Aa35dBD2aA3BD12D23c11295E774;
        addr["RWA008"]                          = 0xb9737098b50d7c536b6416dAeB32879444F59fCA;
        addr["PIP_RWA008"]                      = 0x2623dE50D8A6FdC2f0D583327142210b8b464bfd;
        addr["MCD_JOIN_RWA008_A"]               = 0x56eDD5067d89D4E65Bf956c49eAF054e6Ff0b262;
        addr["RWA008_A_URN"]                    = 0x495215cabc630830071F80263a908E8826a66121;
        addr["RWA008_A_INPUT_CONDUIT"]          = 0xa397a23dDA051186F202C67148c90683c413383C;
        addr["RWA008_A_OUTPUT_CONDUIT"]         = 0x21CF5Ad1311788D762f9035829f81B9f54610F0C;
        addr["RWA009"]                          = 0x8b9734bbaA628bFC0c9f323ba08Ed184e5b88Da2;
        addr["PIP_RWA009"]                      = 0xdc7D370A089797Fe9556A2b0400496eBb3a61E44;
        addr["MCD_JOIN_RWA009_A"]               = 0xEe0FC514280f09083a32AE906cCbD2FAc4c680FA;
        addr["RWA009_A_URN"]                    = 0x1818EE501cd28e01E058E7C283E178E9e04a1e79;
        addr["RWA009_A_JAR"]                    = 0x6C6d4Be2223B5d202263515351034861dD9aFdb6;
        addr["RWA009_A_OUTPUT_CONDUIT"]         = 0x508D982e13263Fc8e1b5A4E6bf59b335202e36b4;
        addr["GUNIV3DAIUSDC1"]                  = 0xAbDDAfB225e10B90D798bB8A886238Fb835e2053;
        addr["PIP_GUNIV3DAIUSDC1"]              = 0x7F6d78CC0040c87943a0e0c140De3F77a273bd58;
        addr["MCD_JOIN_GUNIV3DAIUSDC1_A"]       = 0xbFD445A97e7459b0eBb34cfbd3245750Dba4d7a4;
        addr["MCD_CLIP_GUNIV3DAIUSDC1_A"]       = 0x5048c5Cd3102026472f8914557A1FD35c8Dc6c9e;
        addr["MCD_CLIP_CALC_GUNIV3DAIUSDC1_A"]  = 0x25B17065b94e3fDcD97d94A2DA29E7F77105aDd7;
        addr["MCD_JOIN_TELEPORT_FW_A"]          = 0x41Ca7a7Aa2Be78Cf7CB80C0F4a9bdfBC96e81815;
        addr["MCD_ROUTER_TELEPORT_FW_A"]        = 0xeEf8B35eD538b6Ef7DbA82236377aDE4204e5115;
        addr["MCD_ORACLE_AUTH_TELEPORT_FW_A"]   = 0x324a895625E7AE38Fc7A6ae91a71e7E937Caa7e6;
        addr["STARKNET_TELEPORT_BRIDGE"]        = 0x95D8367B74ef8C5d014ff19C212109E243748e28;
        addr["STARKNET_TELEPORT_FEE"]           = 0x2123159d2178f07E3899d9d22aad2Fb177B59C48;
        addr["STARKNET_DAI_BRIDGE"]             = 0x9F96fE0633eE838D0298E8b8980E6716bE81388d;
        addr["STARKNET_DAI_BRIDGE_LEGACY"]      = 0x659a00c33263d9254Fed382dE81349426C795BB6;
        addr["STARKNET_ESCROW"]                 = 0x0437465dfb5B79726e35F08559B0cBea55bb585C;
        addr["STARKNET_ESCROW_MOM"]             = 0xc238E3D63DfD677Fa0FA9985576f0945C581A266;
        addr["STARKNET_GOV_RELAY"]              = 0x9eed6763BA8D89574af1478748a7FDF8C5236fE0;
        addr["STARKNET_CORE"]                   = 0xc662c410C0ECf747543f5bA90660f6ABeBD9C8c4;
        addr["OPTIMISM_TELEPORT_BRIDGE"]        = 0x920347f49a9dbe50865EB6161C3B2774AC046A7F;
        addr["OPTIMISM_TELEPORT_FEE"]           = 0xA7C088AAD64512Eff242901E33a516f2381b8823;
        addr["OPTIMISM_DAI_BRIDGE"]             = 0x10E6593CDda8c58a1d0f14C5164B376352a55f2F;
        addr["OPTIMISM_ESCROW"]                 = 0x467194771dAe2967Aef3ECbEDD3Bf9a310C76C65;
        addr["OPTIMISM_GOV_RELAY"]              = 0x09B354CDA89203BB7B3131CC728dFa06ab09Ae2F;
        addr["ARBITRUM_TELEPORT_BRIDGE"]        = 0x22218359E78bC34E532B653198894B639AC3ed72;
        addr["ARBITRUM_TELEPORT_FEE"]           = 0xA7C088AAD64512Eff242901E33a516f2381b8823;
        addr["ARBITRUM_DAI_BRIDGE"]             = 0xD3B5b60020504bc3489D6949d545893982BA3011;
        addr["ARBITRUM_ESCROW"]                 = 0xA10c7CE4b876998858b1a9E12b10092229539400;
        addr["ARBITRUM_GOV_RELAY"]              = 0x9ba25c289e351779E0D481Ba37489317c34A899d;
        addr["ADAI"]                            = 0x028171bCA77440897B824Ca71D1c56caC55b68A3;
        addr["PIP_ADAI"]                        = 0x6A858592fC4cBdf432Fc9A1Bc8A0422B99330bdF;
        addr["MCD_JOIN_DIRECT_AAVEV2_DAI"]      = 0xa13C0c8eB109F5A13c6c90FC26AFb23bEB3Fb04a;
        addr["MCD_CLIP_DIRECT_AAVEV2_DAI"]      = 0xa93b98e57dDe14A3E301f20933d59DC19BF8212E;
        addr["MCD_CLIP_CALC_DIRECT_AAVEV2_DAI"] = 0x786DC9b69abeA503fd101a2A9fa95bcE82C20d0A;
        addr["GUNIV3DAIUSDC2"]                  = 0x50379f632ca68D36E50cfBC8F78fe16bd1499d1e;
        addr["PIP_GUNIV3DAIUSDC2"]              = 0xcCBa43231aC6eceBd1278B90c3a44711a00F4e93;
        addr["MCD_JOIN_GUNIV3DAIUSDC2_A"]       = 0xA7e4dDde3cBcEf122851A7C8F7A55f23c0Daf335;
        addr["MCD_CLIP_GUNIV3DAIUSDC2_A"]       = 0xB55da3d3100C4eBF9De755b6DdC24BF209f6cc06;
        addr["MCD_CLIP_CALC_GUNIV3DAIUSDC2_A"]  = 0xef051Ca2A2d809ba47ee0FC8caaEd06E3D832225;
        addr["CRVV1ETHSTETH"]                   = 0x06325440D014e39736583c165C2963BA99fAf14E;
        addr["PIP_CRVV1ETHSTETH"]               = 0xEa508F82728927454bd3ce853171b0e2705880D4;
        addr["MCD_JOIN_CRVV1ETHSTETH_A"]        = 0x82D8bfDB61404C796385f251654F6d7e92092b5D;
        addr["MCD_CLIP_CRVV1ETHSTETH_A"]        = 0x1926862F899410BfC19FeFb8A3C69C7Aed22463a;
        addr["MCD_CLIP_CALC_CRVV1ETHSTETH_A"]   = 0x8a4780acABadcae1a297b2eAe5DeEbd7d50DEeB8;
        addr["RETH"]                            = 0xae78736Cd615f374D3085123A210448E74Fc6393;
        addr["PIP_RETH"]                        = 0xeE7F0b350aA119b3d05DC733a4621a81972f7D47;
        addr["MCD_JOIN_RETH_A"]                 = 0xC6424e862f1462281B0a5FAc078e4b63006bDEBF;
        addr["MCD_CLIP_RETH_A"]                 = 0x27CA5E525ea473eD52Ea9423CD08cCc081d96a98;
        addr["MCD_CLIP_CALC_RETH_A"]            = 0xc59B62AFC96cf9737F717B5e5815070C0f154396;
    }
}
