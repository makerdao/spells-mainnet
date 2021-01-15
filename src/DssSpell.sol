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

import "dss-exec-lib/DssAction.sol";
import "lib/dss-interfaces/src/dss/OsmAbstract.sol";
import "lib/dss-interfaces/src/dss/FlapAbstract.sol";

contract SpellAction is DssAction {

    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/b902aac62c589dcc77c74eea6e6de8131c39547a/governance/votes/Executive%20vote%20-%20January%2015%2C%202021.md -q -O - 2>/dev/null)"
    string public constant description =
        "2021-01-15 MakerDAO Executive Spell | Hash: 0x2417a1d5c313f1acf1198d99d4356522cbe71e3253af1b7138b3448649c85129";

    // New flap.beg() value
    uint256 constant NEW_BEG     = 1.04E18; // 4%

    // Gnosis
    address constant GNOSIS      = 0xD5885fbCb9a8a8244746010a3BC6F1C6e0269777;

    // SET
    address constant SET_AAVE    = 0x8b1C079f8192706532cC0Bf0C02dcC4fF40d045D;
    address constant SET_LRC     = 0x1D5d9a2DDa0843eD9D8a9Bddc33F1fca9f9C64a0;
    address constant SET_YFI     = 0x1686d01Bd776a1C2A3cCF1579647cA6D39dd2465;
    address constant SET_ZRX     = 0xFF60D1650696238F81BE53D23b3F91bfAAad938f;
    address constant SET_UNI     = 0x3c3Afa479d8C95CF0E1dF70449Bb5A14A3b7Af67;


    // Many of the settings that change weekly rely on the rate accumulator
    // described at https://docs.makerdao.com/smart-contract-modules/rates-module
    // To check this yourself, use the following rate calculation (example 8%):
    //
    // $ bc -l <<< 'scale=27; e( l(1.08)/(60 * 60 * 24 * 365) )'
    //
    // A table of rates can be found at
    //    https://ipfs.io/ipfs/QmefQMseb3AiTapiAKKexdKHig8wroKuZbmLtPLv4u2YwW
    //
    uint256 constant THREE_PT_FIVE_PERCENT_RATE = 1000000001090862085746321732;
    uint256 constant FOUR_PERCENT_RATE          = 1000000001243680656318820312;
    uint256 constant FIVE_PERCENT_RATE          = 1000000001547125957863212448;
    uint256 constant SIX_PERCENT_RATE           = 1000000001847694957439350562;
    uint256 constant SIX_PT_FIVE_PERCENT_RATE   = 1000000001996917783620820123;


    /**
        @dev constructor (required)
        @param lib         address of the DssExecLib contract
        @param officeHours true if officehours enabled
    */
    constructor(address lib, bool officeHours) public DssAction(lib, officeHours) {}

    function actions() public override {

        // Adjust FLAP Auction Parameters - January 11, 2021
        // https://vote.makerdao.com/polling/QmT79sT6#poll-detail
        FlapAbstract(flap()).file("beg", NEW_BEG);
        setSurplusAuctionBidDuration(1 hours);
        // Increase the System Surplus Buffer - January 11, 2021
        // https://vote.makerdao.com/polling/QmcXtm1d#poll-detail
        setSurplusBuffer(10_000_000);

        // Rates Proposal - January 11, 2021
        // https://vote.makerdao.com/polling/QmfBQ4Bh#poll-detail
        // Increase the ETH-A Stability Fee from 2.5% to 3.5%.
        /// @dev setIlkStabilityFee will drip() the collateral
        setIlkStabilityFee("ETH-A",  THREE_PT_FIVE_PERCENT_RATE);
        // Increase the ETH-B Stability Fee from 5% to 6.5%.
        setIlkStabilityFee("ETH-B",  SIX_PT_FIVE_PERCENT_RATE);
        // Decrease the WBTC-A Stability Fee from 4.5% to 4%.
        setIlkStabilityFee("WBTC-A", FOUR_PERCENT_RATE);
        // Decrease the YFI-A Stability Fee from 9% to 6%.
        setIlkStabilityFee("YFI-A",  SIX_PERCENT_RATE);
        // Decrease the MANA-A Stability Fee from 10% to 5%.
        setIlkStabilityFee("MANA-A", FIVE_PERCENT_RATE);
        // Decrease the AAVE-A Stability Fee from 6% to 4%.
        setIlkStabilityFee("AAVE-A", FOUR_PERCENT_RATE);

        address PIP_YFI = getChangelogAddress("PIP_YFI");
        address PIP_ZRX = getChangelogAddress("PIP_ZRX");

        // Whitelist Gnosis on Multiple Oracles - January 11, 2021
        // https://vote.makerdao.com/polling/QmNwTMcB#poll-detail
        addReaderToOSMWhitelist(getChangelogAddress("PIP_WBTC"), GNOSIS);
        addReaderToOSMWhitelist(getChangelogAddress("PIP_LINK"), GNOSIS);
        addReaderToOSMWhitelist(getChangelogAddress("PIP_COMP"), GNOSIS);
        addReaderToOSMWhitelist(PIP_YFI,                         GNOSIS);
        addReaderToOSMWhitelist(PIP_ZRX,                         GNOSIS);

        // Whitelist Set Protocol on Multiple Oracles - January 11, 2021
        // https://vote.makerdao.com/polling/QmTctW6i#poll-detail
        addReaderToMedianWhitelist(OsmAbstract(getChangelogAddress("PIP_AAVE")).src(), SET_AAVE);
        addReaderToMedianWhitelist(OsmAbstract(getChangelogAddress("PIP_LRC")).src(),  SET_LRC);
        addReaderToMedianWhitelist(OsmAbstract(PIP_YFI).src(),                         SET_YFI);
        addReaderToMedianWhitelist(OsmAbstract(PIP_ZRX).src(),                         SET_ZRX);
        addReaderToMedianWhitelist(OsmAbstract(getChangelogAddress("PIP_UNI")).src(),  SET_UNI);

        // Limiting Governance Attack Surface for Stablecoins
        // https://forum.makerdao.com/t/limiting-governance-attack-surface-for-stablecoins/6057
        deauthorize(getChangelogAddress("MCD_FLIP_USDC_A"),   flipperMom());
        deauthorize(getChangelogAddress("MCD_FLIP_USDC_B"),   flipperMom());
        deauthorize(getChangelogAddress("MCD_FLIP_TUSD_A"),   flipperMom());
        deauthorize(getChangelogAddress("MCD_FLIP_PAXUSD_A"), flipperMom());
        deauthorize(getChangelogAddress("MCD_FLIP_GUSD_A"),   flipperMom());
    }
}
