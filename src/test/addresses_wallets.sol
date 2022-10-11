// SPDX-FileCopyrightText: © 2021 Dai Foundation <www.daifoundation.org>
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

contract Wallets {

    mapping (bytes32 => address) public addr;

    constructor() public {

        // Core Units
        addr["CES_WALLET"]                   = 0x25307aB59Cd5d8b4E2C01218262Ddf6a89Ff86da;
        addr["CES_OP_WALLET"]                = 0xD740882B8616B50d0B317fDFf17Ec3f4f853F44f;
        addr["COM_WALLET"]                   = 0x1eE3ECa7aEF17D1e74eD7C447CcBA61aC76aDbA9;
        addr["COM_EF_WALLET"]                = 0x99E1696A680c0D9f426Be20400E468089E7FDB0f;
        addr["DAIF_WALLET"]                  = 0x34D8d61050Ef9D2B48Ab00e6dc8A8CA6581c5d63;
        addr["DAIF_RESERVE_WALLET"]          = 0x5F5c328732c9E52DfCb81067b8bA56459b33921f;
        addr["DECO_WALLET"]                  = 0xF482D1031E5b172D42B2DAA1b6e5Cbf6519596f7;
        addr["DIN_WALLET"]                   = 0x7327Aed0Ddf75391098e8753512D8aEc8D740a1F;
        addr["DUX_WALLET"]                   = 0x5A994D8428CCEbCC153863CCdA9D2Be6352f89ad;
        addr["EVENTS_WALLET"]                = 0x3D274fbAc29C92D2F624483495C0113B44dBE7d2;
        addr["GRO_WALLET"]                   = 0x7800C137A645c07132886539217ce192b9F0528e;
        addr["IS_WALLET"]                    = 0xd1F2eEf8576736C1EbA36920B957cd2aF07280F4;
        addr["ORA_WALLET"]                   = 0x2d09B7b95f3F312ba6dDfB77bA6971786c5b50Cf;
        addr["ORA_GAS"]                      = 0x2B6180b413511ce6e3DA967Ec503b2Cc19B78Db6;
        addr["ORA_GAS_EMERGENCY"]            = 0x1A5B692029b157df517b7d21a32c8490b8692b0f;
        addr["PE_WALLET"]                    = 0xe2c16c308b843eD02B09156388Cb240cEd58C01c;
        addr["RISK_WALLET"]                  = 0xb386Bc4e8bAE87c3F67ae94Da36F385C100a370a;
        addr["RISK_WALLET_VEST"]             = 0x5d67d5B1fC7EF4bfF31967bE2D2d7b9323c1521c;
        addr["RWF_WALLET"]                   = 0x96d7b01Cc25B141520C717fa369844d34FF116ec;
        addr["SES_WALLET"]                   = 0x87AcDD9208f73bFc9207e1f6F0fDE906bcA95cc6;
        addr["SF_WALLET"]                    = 0xf737C76D2B358619f7ef696cf3F94548fEcec379;
        addr["SH_WALLET"]                    = 0x955993Df48b0458A01cfB5fd7DF5F5DCa6443550;
        addr["SH_MULTISIG"]                  = 0xc657aC882Fb2D6CcF521801da39e910F8519508d;
        addr["SNE_WALLET"]                   = 0x6D348f18c88D45243705D4fdEeB6538c6a9191F1;
        addr["TECH_WALLET"]                  = 0x2dC0420A736D1F40893B9481D8968E4D7424bC0B;
        addr["SIDESTREAM_WALLET"]            = 0xb1f950a51516a697E103aaa69E152d839182f6Fe;

        // Recognized Delegates
        addr["ACREINVEST"]                   = 0x5b9C98e8A3D9Db6cd4B4B4C1F92D0A551D06F00D;
        addr["FEEDBLACKLOOPS"]               = 0x80882f2A36d49fC46C3c654F7f9cB9a2Bf0423e1;
        addr["FIELDTECHNOLOGIES"]            = 0x0988E41C02915Fe1beFA78c556f946E5F20ffBD3;
        addr["FLIPFLOPFLAP"]                 = 0x688d508f3a6B0a377e266405A1583B3316f9A2B3;
        addr["GFXLABS"]                      = 0xa6e8772af29b29B9202a073f8E36f447689BEef6;
        addr["JUSTINCASE"]                   = 0xE070c2dCfcf6C6409202A8a210f71D51dbAe9473;
        addr["MAKERMAN"]                     = 0x9AC6A6B24bCd789Fa59A175c0514f33255e1e6D0;
        addr["ULTRASCHUPPI"]                 = 0xCCffDBc38B1463847509dCD95e0D9AAf54D1c167;
        addr["MONETSUPPLY"]                  = 0x4Bd73eeE3d0568Bb7C52DFCad7AD5d47Fff5E2CF;
        addr["DOO"]                          = 0x3B91eBDfBC4B78d778f62632a4004804AC5d2DB0;
        addr["FLIPSIDE"]                     = 0x62a43123FE71f9764f26554b3F5017627996816a;
        addr["PENNBLOCKCHAIN"]               = 0x2165D41aF0d8d5034b9c266597c1A415FA0253bd;
        addr["CHRISBLEC"]                    = 0xa3f0AbB4Ba74512b5a736C5759446e9B50FDA170;
        addr["BLOCKCHAINCOLUMBIA"]           = 0xdC1F98682F4F8a5c6d54F345F448437b83f5E432;
        addr["MHONKASALOTEEMULAU"]           = 0x97Fb39171ACd7C82c439b6158EA2F71D26ba383d;
        addr["LLAMA"]                        = 0xA519a7cE7B24333055781133B13532AEabfAC81b;
        addr["CODEKNIGHT"]                   = 0x46dFcBc2aFD5DD8789Ef0737fEdb03489D33c428;
        addr["FRONTIERRESEARCH"]             = 0xA2d55b89654079987CF3985aEff5A7Bd44DA15A8;
        addr["LBSBLOCKCHAIN"]                = 0xB83b3e9C8E3393889Afb272D354A7a3Bd1Fbcf5C;
        addr["ONESTONE"]                     = 0x4eFb12d515801eCfa3Be456B5F348D3CD68f9E8a;
        addr["PVI"]                          = 0x6ebB1A9031177208A4CA50164206BF2Fa5ff7416;
        
        


        // MIP-63 Keeper Network
        addr["GELATO_VEST_STREAMING"]        = 0x478c7Ce3e1df09130f8D65a23AD80e05b352af62;
        addr["KEEP3R_VEST_STREAMING"]        = 0x37b375e3D418fbECba6b283e704F840AB32f3b3C;
        addr["KEEP3R_VEST_STREAMING_LEGACY"] = 0xc6A048550C9553F8Ac20fbdeB06f114c27ECcabb;

        // ETH Amsterdam Event SPF
        addr["ETH_AMSTERDAM"]                = 0xF34ac684BA2734039772f0C0d77bc2545e819212;

        // Ambassador Program Pilot Multisig
        addr["AMBASSADOR_WALLET"]            = 0xF411d823a48D18B32e608274Df16a9957fE33E45;

        // Legal Domain Work
        addr["BIBTA_WALLET"]                 = 0x173d85CD1754daD73cfc673944D9C8BF11A01D3F;
        addr["MIP65_WALLET"]                 = 0x29408abeCe474C85a12ce15B05efBB6A1e8587fe;
    }
}
