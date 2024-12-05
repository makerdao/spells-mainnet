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

contract Config {

    struct SpellValues {
        address   deployed_spell;
        uint256   deployed_spell_created;
        uint256   deployed_spell_block;
        address[] previous_spells;
        bool      office_hours_enabled;
        uint256   expiration_threshold;
    }

    struct SystemValues {
        uint256 line_offset;
        uint256 pot_dsr;
        uint256 susds_ssr;
        uint256 pause_delay;
        uint256 vow_wait;
        uint256 vow_dump;
        uint256 vow_sump;
        uint256 vow_bump;
        uint256 vow_hump_min;
        uint256 vow_hump_max;
        uint256 split_hop;
        uint256 split_burn;
        bytes32 split_farm;
        uint256 flap_want;
        uint256 dog_Hole;
        uint256 esm_min;
        bytes32 pause_authority;
        bytes32 osm_mom_authority;
        bytes32 clipper_mom_authority;
        bytes32 d3m_mom_authority;
        bytes32 line_mom_authority;
        bytes32 lite_psm_mom_authority;
        bytes32 splitter_mom_authority;
        uint256 vest_dai_cap;
        uint256 vest_mkr_cap;
        uint256 vest_sky_cap;
        uint256 sky_mkr_rate;
        uint256 ilk_count;
        string  chainlog_version;
        mapping (bytes32 => CollateralValues) collaterals;
    }

    struct CollateralValues {
        bool aL_enabled;
        uint256 aL_line;
        uint256 aL_gap;
        uint256 aL_ttl;
        uint256 line;
        uint256 dust;
        uint256 pct;
        uint256 mat;
        bytes32 liqType;
        bool    liqOn;
        uint256 chop;
        uint256 dog_hole;
        uint256 clip_buf;
        uint256 clip_tail;
        uint256 clip_cusp;
        uint256 clip_chip;
        uint256 clip_tip;
        uint256 clipper_mom;
        uint256 cm_tolerance;
        uint256 calc_tau;
        uint256 calc_step;
        uint256 calc_cut;
        bool    offboarding;
    }

    uint256 constant private THOUSAND = 10 ** 3;
    uint256 constant private MILLION  = 10 ** 6;
    uint256 constant private BILLION  = 10 ** 9;
    uint256 constant private WAD      = 10 ** 18;

    SpellValues  spellValues;
    SystemValues afterSpell;

    function setValues() public {
        // Add spells if there is a need to test prior to their cast() functions
        // being called on-chain. They will be executed in order from index 0.
        address[] memory prevSpells = new address[](0);
        // prevSpells[0] = address(0);

        //
        // Values for spell-specific parameters
        //
        spellValues = SpellValues({
            deployed_spell:         address(0x329Feb1E300d6bf54d4969Df5089ff7bC79694B6), // populate with deployed spell if deployed
            deployed_spell_created: 1733412695, // use `make deploy-info tx=<deployment-tx>` to obtain the timestamp
            deployed_spell_block:   21337207,   // use `make deploy-info tx=<deployment-tx>` to obtain the block number
            previous_spells:        prevSpells, // older spells to ensure are executed first
            office_hours_enabled:   false,       // true if officehours is expected to be enabled in the spell
            expiration_threshold:   30 days     // Amount of time before spell expires
        });

        //
        // Values for all system configuration changes
        //
        afterSpell.line_offset            = 680 * MILLION;                  // Offset between the global line against the sum of local lines
        afterSpell.pot_dsr                = 11_50;                          // In basis points
        afterSpell.susds_ssr              = 12_50;                          // In basis points
        afterSpell.pause_delay            = 30 hours;                       // In seconds
        afterSpell.vow_wait               = 156 hours;                      // In seconds
        afterSpell.vow_dump               = 250;                            // In whole Dai units
        afterSpell.vow_sump               = 50 * THOUSAND;                  // In whole Dai units
        afterSpell.vow_bump               = 25 * THOUSAND;                  // In whole Dai units
        afterSpell.vow_hump_min           = 120 * MILLION;                   // In whole Dai units
        afterSpell.vow_hump_max           = 120 * MILLION;                   // In whole Dai units
        afterSpell.split_hop              = 15_649 seconds;                 // In seconds
        afterSpell.split_burn             = 70_00;                          // In basis points
        afterSpell.split_farm             = "REWARDS_LSMKR_USDS";           // Farm chainlog key
        afterSpell.flap_want              = 9800;                           // In basis points
        afterSpell.dog_Hole               = 150 * MILLION;                  // In whole Dai units
        afterSpell.esm_min                = 500 * THOUSAND;                 // In whole MKR units
        afterSpell.pause_authority        = "MCD_ADM";                      // Pause authority
        afterSpell.osm_mom_authority      = "MCD_ADM";                      // OsmMom authority
        afterSpell.clipper_mom_authority  = "MCD_ADM";                      // ClipperMom authority
        afterSpell.d3m_mom_authority      = "MCD_ADM";                      // D3MMom authority
        afterSpell.line_mom_authority     = "MCD_ADM";                      // LineMom authority
        afterSpell.lite_psm_mom_authority = "MCD_ADM";                      // LitePsmMom authority
        afterSpell.splitter_mom_authority = "MCD_ADM";                      // SplitterMom authority
        afterSpell.vest_dai_cap           = 1 * MILLION * WAD / 30 days;    // In WAD Dai per second
        afterSpell.vest_mkr_cap           = 2_220 * WAD / 365 days;         // In WAD MKR per second
        afterSpell.vest_sky_cap           = 800 * MILLION * WAD / 365 days; // In WAD SKY per second
        afterSpell.sky_mkr_rate           = 24_000;                         // In whole SKY/MKR units
        afterSpell.ilk_count              = 69;                             // Num expected in system
        afterSpell.chainlog_version       = "1.19.4";                       // String expected in system

        //
        // Values for all collateral
        // Update when adding or modifying Collateral Values
        //
        afterSpell.collaterals["ETH-A"] = CollateralValues({
            aL_enabled:   true,            // DssAutoLine is enabled?
            aL_line:      15 * BILLION,    // In whole Dai units
            aL_gap:       150 * MILLION,   // In whole Dai units
            aL_ttl:       6 hours,         // In seconds
            line:         0,               // In whole Dai units  // Not checked here as there is auto line
            dust:         7_500,           // In whole Dai units
            pct:          12_75,           // In basis points
            mat:          14500,           // In basis points
            liqType:      "clip",          // "" or "flip" or "clip"
            liqOn:        true,            // If liquidations are enabled
            chop:         1300,            // In basis points
            dog_hole:     40 * MILLION,    // In whole Dai units
            clip_buf:     110_00,          // In basis points
            clip_tail:    7_200,           // In seconds, do not use the 'seconds' keyword
            clip_cusp:    45_00,           // In basis points
            clip_chip:    10,              // In basis points
            clip_tip:     250,             // In whole Dai units
            clipper_mom:  1,               // 1 if circuit breaker enabled
            cm_tolerance: 5000,            // In basis points
            calc_tau:     0,               // In seconds
            calc_step:    90,              // In seconds
            calc_cut:     9900,            // In basis points
            offboarding:  false            // If mat is being offboarded
        });
        afterSpell.collaterals["ETH-B"] = CollateralValues({
            aL_enabled:   true,
            aL_line:      250 * MILLION,
            aL_gap:       20 * MILLION,
            aL_ttl:       6 hours,
            line:         0,
            dust:         25 * THOUSAND,
            pct:          13_25,
            mat:          13000,
            liqType:      "clip",
            liqOn:        true,
            chop:         1300,
            dog_hole:     15 * MILLION,
            clip_buf:     110_00,
            clip_tail:    4_800,
            clip_cusp:    45_00,
            clip_chip:    10,
            clip_tip:     250,
            clipper_mom:  1,
            cm_tolerance: 5000,
            calc_tau:     0,
            calc_step:    60,
            calc_cut:     9900,
            offboarding:  false
        });
        afterSpell.collaterals["ETH-C"] = CollateralValues({
            aL_enabled:   true,
            aL_line:      2 * BILLION,
            aL_gap:       100 * MILLION,
            aL_ttl:       8 hours,
            line:         0,
            dust:         3_500,
            pct:          12_50,
            mat:          17000,
            liqType:      "clip",
            liqOn:        true,
            chop:         1300,
            dog_hole:     35 * MILLION,
            clip_buf:     110_00,
            clip_tail:    7_200,
            clip_cusp:    45_00,
            clip_chip:    10,
            clip_tip:     250,
            clipper_mom:  1,
            cm_tolerance: 5000,
            calc_tau:     0,
            calc_step:    90,
            calc_cut:     9900,
            offboarding:  false
        });
        afterSpell.collaterals["BAT-A"] = CollateralValues({
            aL_enabled:   false,
            aL_line:      0,
            aL_gap:       0,
            aL_ttl:       0,
            line:         0,
            dust:         10 * THOUSAND,
            pct:          400,
            mat:          1120000,
            liqType:      "clip",
            liqOn:        true,
            chop:         0,
            dog_hole:     1 * MILLION + 500 * THOUSAND,
            clip_buf:     13000,
            clip_tail:    140 minutes,
            clip_cusp:    4000,
            clip_chip:    10,
            clip_tip:     300,
            clipper_mom:  1,
            cm_tolerance: 5000,
            calc_tau:     0,
            calc_step:    90,
            calc_cut:     9900,
            offboarding:  true
        });
        afterSpell.collaterals["USDC-A"] = CollateralValues({
            aL_enabled:   false,
            aL_line:      0,
            aL_gap:       0,
            aL_ttl:       0,
            line:         0,
            dust:         15 * THOUSAND,
            pct:          0,
            mat:          150000,
            liqType:      "clip",
            liqOn:        true,
            chop:         0,
            dog_hole:     20_000_000,
            clip_buf:     100_00,
            clip_tail:    720 minutes,
            clip_cusp:    99_00,
            clip_chip:    0,
            clip_tip:     0,
            clipper_mom:  1,
            cm_tolerance: 9500,
            calc_tau:     4_320_000,
            calc_step:    0,
            calc_cut:     0,
            offboarding:  true
        });
        afterSpell.collaterals["USDC-B"] = CollateralValues({
            aL_enabled:   false,
            aL_line:      0,
            aL_gap:       0,
            aL_ttl:       0,
            line:         0,
            dust:         10 * THOUSAND,
            pct:          5000,
            mat:          12000,
            liqType:      "clip",
            liqOn:        false,
            chop:         1300,
            dog_hole:     0,
            clip_buf:     10500,
            clip_tail:    220 minutes,
            clip_cusp:    9000,
            clip_chip:    10,
            clip_tip:     300,
            clipper_mom:  0,
            cm_tolerance: 9500,
            calc_tau:     0,
            calc_step:    120,
            calc_cut:     9990,
            offboarding:  false
        });
        afterSpell.collaterals["WBTC-A"] = CollateralValues({
            aL_enabled:   false,
            aL_line:      0,
            aL_gap:       0,
            aL_ttl:       0,
            line:         0,
            dust:         7_500,
            pct:          16_25,
            mat:          15000,
            liqType:      "clip",
            liqOn:        true,
            chop:         0,
            dog_hole:     10 * MILLION,
            clip_buf:     110_00,
            clip_tail:    7_200,
            clip_cusp:    45_00,
            clip_chip:    10,
            clip_tip:     250,
            clipper_mom:  1,
            cm_tolerance: 5000,
            calc_tau:     0,
            calc_step:    90,
            calc_cut:     9900,
            offboarding:  false
        });
        afterSpell.collaterals["WBTC-B"] = CollateralValues({
            aL_enabled:   false,
            aL_line:      0,
            aL_gap:       0,
            aL_ttl:       0,
            line:         0,
            dust:         25 * THOUSAND,
            pct:          16_75,
            mat:          15000,
            liqType:      "clip",
            liqOn:        true,
            chop:         0,
            dog_hole:     5 * MILLION,
            clip_buf:     110_00,
            clip_tail:    4_800,
            clip_cusp:    45_00,
            clip_chip:    10,
            clip_tip:     250,
            clipper_mom:  1,
            cm_tolerance: 5000,
            calc_tau:     0,
            calc_step:    60,
            calc_cut:     9900,
            offboarding:  false
        });
        afterSpell.collaterals["WBTC-C"] = CollateralValues({
            aL_enabled:   false,
            aL_line:      0,
            aL_gap:       0,
            aL_ttl:       0,
            line:         0,
            dust:         3_500,
            pct:          16_00,
            mat:          17500,
            liqType:      "clip",
            liqOn:        true,
            chop:         0,
            dog_hole:     10 * MILLION,
            clip_buf:     110_00,
            clip_tail:    7_200,
            clip_cusp:    45_00,
            clip_chip:    10,
            clip_tip:     250,
            clipper_mom:  1,
            cm_tolerance: 5000,
            calc_tau:     0,
            calc_step:    90,
            calc_cut:     9900,
            offboarding:  false
        });
        afterSpell.collaterals["TUSD-A"] = CollateralValues({
            aL_enabled:   false,
            aL_line:      0,
            aL_gap:       0,
            aL_ttl:       0,
            line:         0,
            dust:         15 * THOUSAND,
            pct:          0,
            mat:          15000,
            liqType:      "clip",
            liqOn:        true,
            chop:         0,
            dog_hole:     5 * MILLION,
            clip_buf:     10000,
            clip_tail:    120 hours,
            clip_cusp:    9800,
            clip_chip:    0,
            clip_tip:     0,
            clipper_mom:  1,
            cm_tolerance: 9500,
            calc_tau:     250 days,
            calc_step:    0,
            calc_cut:     0,
            offboarding:  false
        });
        afterSpell.collaterals["KNC-A"] = CollateralValues({
            aL_enabled:   false,
            aL_line:      0,
            aL_gap:       0,
            aL_ttl:       0,
            line:         0,
            dust:         10 * THOUSAND,
            pct:          500,
            mat:          500000,
            liqType:      "clip",
            liqOn:        true,
            chop:         0,
            dog_hole:     500 * THOUSAND,
            clip_buf:     13000,
            clip_tail:    140 minutes,
            clip_cusp:    4000,
            clip_chip:    10,
            clip_tip:     300,
            clipper_mom:  1,
            cm_tolerance: 5000,
            calc_tau:     0,
            calc_step:    90,
            calc_cut:     9900,
            offboarding:  true
        });
        afterSpell.collaterals["ZRX-A"] = CollateralValues({
            aL_enabled:   false,
            aL_line:      0,
            aL_gap:       0,
            aL_ttl:       0,
            line:         0,
            dust:         10 * THOUSAND,
            pct:          400,
            mat:          550000,
            liqType:      "clip",
            liqOn:        true,
            chop:         0,
            dog_hole:     1 * MILLION,
            clip_buf:     13000,
            clip_tail:    140 minutes,
            clip_cusp:    4000,
            clip_chip:    10,
            clip_tip:     300,
            clipper_mom:  1,
            cm_tolerance: 5000,
            calc_tau:     0,
            calc_step:    90,
            calc_cut:     9900,
            offboarding:  true
        });
        afterSpell.collaterals["MANA-A"] = CollateralValues({
            aL_enabled:   false,
            aL_line:      0,
            aL_gap:       0,
            aL_ttl:       0,
            line:         0,
            dust:         15 * THOUSAND,
            pct:          5000,
            mat:          17500,
            liqType:      "clip",
            liqOn:        true,
            chop:         3000,
            dog_hole:     1 * MILLION,
            clip_buf:     120_00,
            clip_tail:    140 minutes,
            clip_cusp:    40_00,
            clip_chip:    10,
            clip_tip:     250,
            clipper_mom:  1,
            cm_tolerance: 5000,
            calc_tau:     0,
            calc_step:    90,
            calc_cut:     9900,
            offboarding:  false
        });
        afterSpell.collaterals["USDT-A"] = CollateralValues({
            aL_enabled:   false,
            aL_line:      0,
            aL_gap:       0,
            aL_ttl:       0,
            line:         0,
            dust:         10 * THOUSAND,
            pct:          800,
            mat:          30000,
            liqType:      "clip",
            liqOn:        true,
            chop:         0,
            dog_hole:     15_000,
            clip_buf:     10500,
            clip_tail:    220 minutes,
            clip_cusp:    9000,
            clip_chip:    10,
            clip_tip:     300,
            clipper_mom:  1,
            cm_tolerance: 9500,
            calc_tau:     0,
            calc_step:    120,
            calc_cut:     9990,
            offboarding:  false
        });
        afterSpell.collaterals["PAXUSD-A"] = CollateralValues({
            aL_enabled:   false,
            aL_line:      0,
            aL_gap:       0,
            aL_ttl:       0,
            line:         0,
            dust:         15 * THOUSAND,
            pct:          0,
            mat:          150000,
            liqType:      "clip",
            liqOn:        true,
            chop:         0,
            dog_hole:     3_000_000,
            clip_buf:     100_00,
            clip_tail:    720 minutes,
            clip_cusp:    99_00,
            clip_chip:    0,
            clip_tip:     0,
            clipper_mom:  1,
            cm_tolerance: 9500,
            calc_tau:     4_320_000,
            calc_step:    0,
            calc_cut:     0,
            offboarding:  true
        });
        afterSpell.collaterals["COMP-A"] = CollateralValues({
            aL_enabled:   false,
            aL_line:      0,
            aL_gap:       0,
            aL_ttl:       0,
            line:         0,
            dust:         10 * THOUSAND,
            pct:          100,
            mat:          200000,
            liqType:      "clip",
            liqOn:        true,
            chop:         0,
            dog_hole:     2 * MILLION,
            clip_buf:     13000,
            clip_tail:    140 minutes,
            clip_cusp:    4000,
            clip_chip:    10,
            clip_tip:     300,
            clipper_mom:  1,
            cm_tolerance: 5000,
            calc_tau:     0,
            calc_step:    90,
            calc_cut:     9900,
            offboarding:  true
        });
        afterSpell.collaterals["LRC-A"] = CollateralValues({
            aL_enabled:   false,
            aL_line:      0,
            aL_gap:       0,
            aL_ttl:       0,
            line:         0,
            dust:         10 * THOUSAND,
            pct:          400,
            mat:          2430000,
            liqType:      "clip",
            liqOn:        true,
            chop:         0,
            dog_hole:     500 * THOUSAND,
            clip_buf:     13000,
            clip_tail:    140 minutes,
            clip_cusp:    4000,
            clip_chip:    10,
            clip_tip:     300,
            clipper_mom:  1,
            cm_tolerance: 5000,
            calc_tau:     0,
            calc_step:    90,
            calc_cut:     9900,
            offboarding:  true
        });
        afterSpell.collaterals["LINK-A"] = CollateralValues({
            aL_enabled:   false,
            aL_line:      0,
            aL_gap:       0,
            aL_ttl:       0,
            line:         0,
            dust:         15 * THOUSAND,
            pct:          250,
            mat:          10000_00,
            liqType:      "clip",
            liqOn:        true,
            chop:         0,
            dog_hole:     3 * MILLION,
            clip_buf:     120_00,
            clip_tail:    140 minutes,
            clip_cusp:    40_00,
            clip_chip:    0,
            clip_tip:     0,
            clipper_mom:  1,
            cm_tolerance: 5000,
            calc_tau:     0,
            calc_step:    90,
            calc_cut:     9900,
            offboarding:  true
        });
        afterSpell.collaterals["BAL-A"] = CollateralValues({
            aL_enabled:   false,
            aL_line:      0,
            aL_gap:       0,
            aL_ttl:       0,
            line:         0,
            dust:         10 * THOUSAND,
            pct:          100,
            mat:          230000,
            liqType:      "clip",
            liqOn:        true,
            chop:         0,
            dog_hole:     3 * MILLION,
            clip_buf:     13000,
            clip_tail:    140 minutes,
            clip_cusp:    4000,
            clip_chip:    10,
            clip_tip:     300,
            clipper_mom:  1,
            cm_tolerance: 5000,
            calc_tau:     0,
            calc_step:    90,
            calc_cut:     9900,
            offboarding:  true
        });
        afterSpell.collaterals["YFI-A"] = CollateralValues({
            aL_enabled:   false,
            aL_line:      0,
            aL_gap:       0,
            aL_ttl:       0,
            line:         0,
            dust:         15 * THOUSAND,
            pct:          150,
            mat:          10000_00,
            liqType:      "clip",
            liqOn:        true,
            chop:         0,
            dog_hole:     1 * MILLION,
            clip_buf:     130_00,
            clip_tail:    140 minutes,
            clip_cusp:    40_00,
            clip_chip:    0,
            clip_tip:     0,
            clipper_mom:  1,
            cm_tolerance: 5000,
            calc_tau:     0,
            calc_step:    90,
            calc_cut:     9900,
            offboarding:  true
        });
        afterSpell.collaterals["GUSD-A"] = CollateralValues({
            aL_enabled:   false,
            aL_line:      0,
            aL_gap:       0,
            aL_ttl:       0,
            line:         0,
            dust:         15 * THOUSAND,
            pct:          100,
            mat:          150000,
            liqType:      "clip",
            liqOn:        true,
            chop:         0,
            dog_hole:     300_000,
            clip_buf:     100_00,
            clip_tail:    720 minutes,
            clip_cusp:    99_00,
            clip_chip:    0,
            clip_tip:     0,
            clipper_mom:  1,
            cm_tolerance: 9500,
            calc_tau:     4_320_000,
            calc_step:    0,
            calc_cut:     0,
            offboarding:  true
        });
        afterSpell.collaterals["UNI-A"] = CollateralValues({
            aL_enabled:   false,
            aL_line:      0,
            aL_gap:       0,
            aL_ttl:       0,
            line:         0,
            dust:         15 * THOUSAND,
            pct:          300,
            mat:          1300_00,
            liqType:      "clip",
            liqOn:        true,
            chop:         0,
            dog_hole:     5 * MILLION,
            clip_buf:     13000,
            clip_tail:    140 minutes,
            clip_cusp:    4000,
            clip_chip:    10,
            clip_tip:     0,
            clipper_mom:  1,
            cm_tolerance: 5000,
            calc_tau:     0,
            calc_step:    90,
            calc_cut:     9900,
            offboarding:  true
        });
        afterSpell.collaterals["RENBTC-A"] = CollateralValues({
            aL_enabled:   false,
            aL_line:      0,
            aL_gap:       0,
            aL_ttl:       0,
            line:         0,
            dust:         15 * THOUSAND,
            pct:          225,
            mat:          5000_00,
            liqType:      "clip",
            liqOn:        true,
            chop:         0,
            dog_hole:     350 * THOUSAND,
            clip_buf:     120_00,
            clip_tail:    140 minutes,
            clip_cusp:    40_00,
            clip_chip:    10,
            clip_tip:     0,
            clipper_mom:  1,
            cm_tolerance: 5000,
            calc_tau:     0,
            calc_step:    90,
            calc_cut:     9900,
            offboarding:  true
        });
        afterSpell.collaterals["AAVE-A"] = CollateralValues({
            aL_enabled:   false,
            aL_line:      0,
            aL_gap:       0,
            aL_ttl:       0,
            line:         0,
            dust:         10 * THOUSAND,
            pct:          100,
            mat:          210000,
            liqType:      "clip",
            liqOn:        true,
            chop:         0,
            dog_hole:     5 * MILLION,
            clip_buf:     13000,
            clip_tail:    140 minutes,
            clip_cusp:    4000,
            clip_chip:    10,
            clip_tip:     300,
            clipper_mom:  1,
            cm_tolerance: 5000,
            calc_tau:     0,
            calc_step:    90,
            calc_cut:     9900,
            offboarding:  true
        });
        afterSpell.collaterals["UNIV2DAIETH-A"] = CollateralValues({
            aL_enabled:   false,
            aL_line:      0,
            aL_gap:       0,
            aL_ttl:       0,
            line:         0,
            dust:         60 * THOUSAND,
            pct:          100,
            mat:          2000_00,
            liqType:      "clip",
            liqOn:        true,
            chop:         0,
            dog_hole:     5 * MILLION,
            clip_buf:     11500,
            clip_tail:    215 minutes,
            clip_cusp:    6000,
            clip_chip:    10,
            clip_tip:     0,
            clipper_mom:  1,
            cm_tolerance: 7000,
            calc_tau:     0,
            calc_step:    125,
            calc_cut:     9950,
            offboarding:  true
        });
        afterSpell.collaterals["PSM-USDC-A"] = CollateralValues({
            aL_enabled:   false,
            aL_line:      0,
            aL_gap:       0,
            aL_ttl:       0,
            line:         0,
            dust:         0,
            pct:          0,
            mat:          10000,
            liqType:      "clip",
            liqOn:        false,
            chop:         1300,
            dog_hole:     0,
            clip_buf:     10500,
            clip_tail:    220 minutes,
            clip_cusp:    9000,
            clip_chip:    10,
            clip_tip:     300,
            clipper_mom:  0,
            cm_tolerance: 9500,
            calc_tau:     0,
            calc_step:    120,
            calc_cut:     9990,
            offboarding:  false
        });
        afterSpell.collaterals["LITE-PSM-USDC-A"] = CollateralValues({
            aL_enabled:   true,
            aL_line:      10 * BILLION,
            aL_gap:       400 * MILLION,
            aL_ttl:       12 hours,
            line:         0,
            dust:         0,
            pct:          0,
            mat:          100_00,
            liqType:      "",
            liqOn:        false,
            chop:         0,
            dog_hole:     0,
            clip_buf:     0,
            clip_tail:    0,
            clip_cusp:    0,
            clip_chip:    0,
            clip_tip:     0,
            clipper_mom:  0,
            cm_tolerance: 0,
            calc_tau:     0,
            calc_step:    0,
            calc_cut:     0,
            offboarding:  false
        });
        afterSpell.collaterals["UNIV2WBTCETH-A"] = CollateralValues({
            aL_enabled:   false,
            aL_line:      0,
            aL_gap:       0,
            aL_ttl:       0,
            line:         0,
            dust:         25 * THOUSAND,
            pct:          200,
            mat:          2400_00,
            liqType:      "clip",
            liqOn:        true,
            chop:         0,
            dog_hole:     5 * MILLION,
            clip_buf:     13000,
            clip_tail:    200 minutes,
            clip_cusp:    4000,
            clip_chip:    10,
            clip_tip:     0,
            clipper_mom:  1,
            cm_tolerance: 5000,
            calc_tau:     0,
            calc_step:    130,
            calc_cut:     9900,
            offboarding:  true
        });
        afterSpell.collaterals["UNIV2USDCETH-A"] = CollateralValues({
            aL_enabled:   false,
            aL_line:      0,
            aL_gap:       0,
            aL_ttl:       0,
            line:         0,
            dust:         60 * THOUSAND,
            pct:          150,
            mat:          10000_00,
            liqType:      "clip",
            liqOn:        true,
            chop:         0,
            dog_hole:     5 * MILLION,
            clip_buf:     11500,
            clip_tail:    215 minutes,
            clip_cusp:    6000,
            clip_chip:    0,
            clip_tip:     0,
            clipper_mom:  1,
            cm_tolerance: 7000,
            calc_tau:     0,
            calc_step:    125,
            calc_cut:     9950,
            offboarding:  true
        });
        afterSpell.collaterals["UNIV2DAIUSDC-A"] = CollateralValues({
            aL_enabled:   false,
            aL_line:      0,
            aL_gap:       0,
            aL_ttl:       0,
            line:         0,
            dust:         15 * THOUSAND,
            pct:          2,
            mat:          10200,
            liqType:      "clip",
            liqOn:        false,
            chop:         1300,
            dog_hole:     0,
            clip_buf:     10500,
            clip_tail:    220 minutes,
            clip_cusp:    9000,
            clip_chip:    10,
            clip_tip:     300,
            clipper_mom:  0,
            cm_tolerance: 9500,
            calc_tau:     0,
            calc_step:    120,
            calc_cut:     9990,
            offboarding:  false
        });
        afterSpell.collaterals["UNIV2ETHUSDT-A"] = CollateralValues({
            aL_enabled:   false,
            aL_line:      0,
            aL_gap:       0,
            aL_ttl:       0,
            line:         0,
            dust:         10 * THOUSAND,
            pct:          200,
            mat:          14000,
            liqType:      "clip",
            liqOn:        true,
            chop:         1300,
            dog_hole:     5 * MILLION,
            clip_buf:     11500,
            clip_tail:    215 minutes,
            clip_cusp:    6000,
            clip_chip:    10,
            clip_tip:     300,
            clipper_mom:  1,
            cm_tolerance: 7000,
            calc_tau:     0,
            calc_step:    125,
            calc_cut:     9950,
            offboarding:  false
        });
        afterSpell.collaterals["UNIV2LINKETH-A"] = CollateralValues({
            aL_enabled:   false,
            aL_line:      0,
            aL_gap:       0,
            aL_ttl:       0,
            line:         0,
            dust:         10 * THOUSAND,
            pct:          300,
            mat:          160000,
            liqType:      "clip",
            liqOn:        true,
            chop:         0,
            dog_hole:     3 * MILLION,
            clip_buf:     13000,
            clip_tail:    200 minutes,
            clip_cusp:    4000,
            clip_chip:    10,
            clip_tip:     300,
            clipper_mom:  1,
            cm_tolerance: 5000,
            calc_tau:     0,
            calc_step:    130,
            calc_cut:     9900,
            offboarding:  true
        });
        afterSpell.collaterals["UNIV2UNIETH-A"] = CollateralValues({
            aL_enabled:   false,
            aL_line:      0,
            aL_gap:       0,
            aL_ttl:       0,
            line:         0,
            dust:         25 * THOUSAND,
            pct:          400,
            mat:          16000,
            liqType:      "clip",
            liqOn:        true,
            chop:         0,
            dog_hole:     3 * MILLION,
            clip_buf:     13000,
            clip_tail:    200 minutes,
            clip_cusp:    4000,
            clip_chip:    10,
            clip_tip:     0,
            clipper_mom:  1,
            cm_tolerance: 5000,
            calc_tau:     0,
            calc_step:    130,
            calc_cut:     9900,
            offboarding:  false
        });
        afterSpell.collaterals["UNIV2WBTCDAI-A"] = CollateralValues({
            aL_enabled:   false,
            aL_line:      0,
            aL_gap:       0,
            aL_ttl:       0,
            line:         0,
            dust:         60 * THOUSAND,
            pct:          0,
            mat:          800_00,
            liqType:      "clip",
            liqOn:        true,
            chop:         0,
            dog_hole:     5 * MILLION,
            clip_buf:     11500,
            clip_tail:    215 minutes,
            clip_cusp:    6000,
            clip_chip:    10,
            clip_tip:     0,
            clipper_mom:  1,
            cm_tolerance: 7000,
            calc_tau:     0,
            calc_step:    125,
            calc_cut:     9950,
            offboarding:  true
        });
        afterSpell.collaterals["UNIV2AAVEETH-A"] = CollateralValues({
            aL_enabled:   false,
            aL_line:      0,
            aL_gap:       0,
            aL_ttl:       0,
            line:         0,
            dust:         10 * THOUSAND,
            pct:          300,
            mat:          40000,
            liqType:      "clip",
            liqOn:        true,
            chop:         0,
            dog_hole:     3 * MILLION,
            clip_buf:     13000,
            clip_tail:    200 minutes,
            clip_cusp:    4000,
            clip_chip:    10,
            clip_tip:     300,
            clipper_mom:  1,
            cm_tolerance: 5000,
            calc_tau:     0,
            calc_step:    130,
            calc_cut:     9900,
            offboarding:  true
        });
        afterSpell.collaterals["UNIV2DAIUSDT-A"] = CollateralValues({
            aL_enabled:   false,
            aL_line:      0,
            aL_gap:       0,
            aL_ttl:       0,
            line:         0,
            dust:         10 * THOUSAND,
            pct:          200,
            mat:          12500,
            liqType:      "clip",
            liqOn:        true,
            chop:         1300,
            dog_hole:     5 * MILLION,
            clip_buf:     10500,
            clip_tail:    220 minutes,
            clip_cusp:    9000,
            clip_chip:    10,
            clip_tip:     300,
            clipper_mom:  1,
            cm_tolerance: 9500,
            calc_tau:     0,
            calc_step:    120,
            calc_cut:     9990,
            offboarding:  false
        });
        afterSpell.collaterals["RWA001-A"] = CollateralValues({
            aL_enabled:   false,
            aL_line:      0,
            aL_gap:       0,
            aL_ttl:       0,
            line:         15 * MILLION,
            dust:         0,
            pct:          900,
            mat:          10000,
            liqType:      "",
            liqOn:        false,
            chop:         0,
            dog_hole:     0,
            clip_buf:     0,
            clip_tail:    0,
            clip_cusp:    0,
            clip_chip:    0,
            clip_tip:     0,
            clipper_mom:  0,
            cm_tolerance: 0,
            calc_tau:     0,
            calc_step:    0,
            calc_cut:     0,
            offboarding:  false
        });
        afterSpell.collaterals["RWA002-A"] = CollateralValues({
            aL_enabled:   false,
            aL_line:      0,
            aL_gap:       0,
            aL_ttl:       0,
            line:         50 * MILLION,
            dust:         0,
            pct:          7_00,
            mat:          100_00,
            liqType:      "",
            liqOn:        false,
            chop:         0,
            dog_hole:     0,
            clip_buf:     0,
            clip_tail:    0,
            clip_cusp:    0,
            clip_chip:    0,
            clip_tip:     0,
            clipper_mom:  0,
            cm_tolerance: 0,
            calc_tau:     0,
            calc_step:    0,
            calc_cut:     0,
            offboarding:  false
        });
        afterSpell.collaterals["RWA003-A"] = CollateralValues({
            aL_enabled:   false,
            aL_line:      0 * MILLION,
            aL_gap:       0 * MILLION,
            aL_ttl:       0,
            line:         0,
            dust:         0,
            pct:          600,
            mat:          10500,
            liqType:      "",
            liqOn:        false,
            chop:         0,
            dog_hole:     0,
            clip_buf:     0,
            clip_tail:    0,
            clip_cusp:    0,
            clip_chip:    0,
            clip_tip:     0,
            clipper_mom:  0,
            cm_tolerance: 0,
            calc_tau:     0,
            calc_step:    0,
            calc_cut:     0,
            offboarding:  false
        });
        afterSpell.collaterals["RWA004-A"] = CollateralValues({
            aL_enabled:   false,
            aL_line:      0 * MILLION,
            aL_gap:       0 * MILLION,
            aL_ttl:       0,
            line:         0,
            dust:         0,
            pct:          700,
            mat:          11000,
            liqType:      "",
            liqOn:        false,
            chop:         0,
            dog_hole:     0,
            clip_buf:     0,
            clip_tail:    0,
            clip_cusp:    0,
            clip_chip:    0,
            clip_tip:     0,
            clipper_mom:  0,
            cm_tolerance: 0,
            calc_tau:     0,
            calc_step:    0,
            calc_cut:     0,
            offboarding:  false
        });
        afterSpell.collaterals["RWA005-A"] = CollateralValues({
            aL_enabled:   false,
            aL_line:      0 * MILLION,
            aL_gap:       0 * MILLION,
            aL_ttl:       0,
            line:         0,
            dust:         0,
            pct:          450,
            mat:          10500,
            liqType:      "",
            liqOn:        false,
            chop:         0,
            dog_hole:     0,
            clip_buf:     0,
            clip_tail:    0,
            clip_cusp:    0,
            clip_chip:    0,
            clip_tip:     0,
            clipper_mom:  0,
            cm_tolerance: 0,
            calc_tau:     0,
            calc_step:    0,
            calc_cut:     0,
            offboarding:  false
        });
        afterSpell.collaterals["RWA006-A"] = CollateralValues({
            aL_enabled:   false,
            aL_line:      0 * MILLION,
            aL_gap:       0 * MILLION,
            aL_ttl:       0,
            line:         0 * MILLION,
            dust:         0,
            pct:          200,
            mat:          10000,
            liqType:      "",
            liqOn:        false,
            chop:         0,
            dog_hole:     0,
            clip_buf:     0,
            clip_tail:    0,
            clip_cusp:    0,
            clip_chip:    0,
            clip_tip:     0,
            clipper_mom:  0,
            cm_tolerance: 0,
            calc_tau:     0,
            calc_step:    0,
            calc_cut:     0,
            offboarding:  false
        });
        afterSpell.collaterals["RWA007-A"] = CollateralValues({
            aL_enabled:   false,
            aL_line:      0,
            aL_gap:       0,
            aL_ttl:       0,
            line:         0,
            dust:         0,
            pct:          0,
            mat:          10000,
            liqType:      "",
            liqOn:        false,
            chop:         0,
            dog_hole:     0,
            clip_buf:     0,
            clip_tail:    0,
            clip_cusp:    0,
            clip_chip:    0,
            clip_tip:     0,
            clipper_mom:  0,
            cm_tolerance: 0,
            calc_tau:     0,
            calc_step:    0,
            calc_cut:     0,
            offboarding:  false
        });
        afterSpell.collaterals["RWA008-A"] = CollateralValues({
            aL_enabled:   false,
            aL_line:      0,
            aL_gap:       0,
            aL_ttl:       0,
            line:         0,
            dust:         0,
            pct:          5,
            mat:          10000,
            liqType:      "",
            liqOn:        false,
            chop:         0,
            dog_hole:     0,
            clip_buf:     0,
            clip_tail:    0,
            clip_cusp:    0,
            clip_chip:    0,
            clip_tip:     0,
            clipper_mom:  0,
            cm_tolerance: 0,
            calc_tau:     0,
            calc_step:    0,
            calc_cut:     0,
            offboarding:  false
        });
        afterSpell.collaterals["RWA009-A"] = CollateralValues({
            aL_enabled:   false,
            aL_line:      0,
            aL_gap:       0,
            aL_ttl:       0,
            line:         100_000_000,
            dust:         0,
            pct:          0,
            mat:          10000,
            liqType:      "",
            liqOn:        false,
            chop:         0,
            dog_hole:     0,
            clip_buf:     0,
            clip_tail:    0,
            clip_cusp:    0,
            clip_chip:    0,
            clip_tip:     0,
            clipper_mom:  0,
            cm_tolerance: 0,
            calc_tau:     0,
            calc_step:    0,
            calc_cut:     0,
            offboarding:  false
        });
        afterSpell.collaterals["RWA010-A"] = CollateralValues({
            aL_enabled:   false,
            aL_line:      0,
            aL_gap:       0,
            aL_ttl:       0,
            line:         0,
            dust:         0,
            pct:          4_00,
            mat:          100_00,
            liqType:      "",
            liqOn:        false,
            chop:         0,
            dog_hole:     0,
            clip_buf:     0,
            clip_tail:    0,
            clip_cusp:    0,
            clip_chip:    0,
            clip_tip:     0,
            clipper_mom:  0,
            cm_tolerance: 0,
            calc_tau:     0,
            calc_step:    0,
            calc_cut:     0,
            offboarding:  false
        });
        afterSpell.collaterals["RWA011-A"] = CollateralValues({
            aL_enabled:   false,
            aL_line:      0,
            aL_gap:       0,
            aL_ttl:       0,
            line:         0,
            dust:         0,
            pct:          4_00,
            mat:          100_00,
            liqType:      "",
            liqOn:        false,
            chop:         0,
            dog_hole:     0,
            clip_buf:     0,
            clip_tail:    0,
            clip_cusp:    0,
            clip_chip:    0,
            clip_tip:     0,
            clipper_mom:  0,
            cm_tolerance: 0,
            calc_tau:     0,
            calc_step:    0,
            calc_cut:     0,
            offboarding:  false
        });
        afterSpell.collaterals["RWA012-A"] = CollateralValues({
            aL_enabled:   false,
            aL_line:      0,
            aL_gap:       0,
            aL_ttl:       0,
            line:         80_000_000,
            dust:         0,
            pct:          4_00,
            mat:          100_00,
            liqType:      "",
            liqOn:        false,
            chop:         0,
            dog_hole:     0,
            clip_buf:     0,
            clip_tail:    0,
            clip_cusp:    0,
            clip_chip:    0,
            clip_tip:     0,
            clipper_mom:  0,
            cm_tolerance: 0,
            calc_tau:     0,
            calc_step:    0,
            calc_cut:     0,
            offboarding:  false
        });
        afterSpell.collaterals["RWA013-A"] = CollateralValues({
            aL_enabled:   false,
            aL_line:      0,
            aL_gap:       0,
            aL_ttl:       0,
            line:         70_000_000,
            dust:         0,
            pct:          4_00,
            mat:          100_00,
            liqType:      "",
            liqOn:        false,
            chop:         0,
            dog_hole:     0,
            clip_buf:     0,
            clip_tail:    0,
            clip_cusp:    0,
            clip_chip:    0,
            clip_tip:     0,
            clipper_mom:  0,
            cm_tolerance: 0,
            calc_tau:     0,
            calc_step:    0,
            calc_cut:     0,
            offboarding:  false
        });
        afterSpell.collaterals["RWA014-A"] = CollateralValues({
            aL_enabled:   false,
            aL_line:      0,
            aL_gap:       0,
            aL_ttl:       0,
            line:         0,
            dust:         0,
            pct:          0,
            mat:          100_00,
            liqType:      "",
            liqOn:        false,
            chop:         0,
            dog_hole:     0,
            clip_buf:     0,
            clip_tail:    0,
            clip_cusp:    0,
            clip_chip:    0,
            clip_tip:     0,
            clipper_mom:  0,
            cm_tolerance: 0,
            calc_tau:     0,
            calc_step:    0,
            calc_cut:     0,
            offboarding:  false
        });
        afterSpell.collaterals["RWA015-A"] = CollateralValues({
            aL_enabled:   true,
            aL_line:      3_000_000_000,
            aL_gap:       50_000_000,
            aL_ttl:       24 hours,
            line:         0,
            dust:         0,
            pct:          0,
            mat:          100_00,
            liqType:      "",
            liqOn:        false,
            chop:         0,
            dog_hole:     0,
            clip_buf:     0,
            clip_tail:    0,
            clip_cusp:    0,
            clip_chip:    0,
            clip_tip:     0,
            clipper_mom:  0,
            cm_tolerance: 0,
            calc_tau:     0,
            calc_step:    0,
            calc_cut:     0,
            offboarding:  false
        });
        afterSpell.collaterals["MATIC-A"] = CollateralValues({
            aL_enabled:   false,
            aL_line:      0,
            aL_gap:       0,
            aL_ttl:       0,
            line:         0,
            dust:         15 * THOUSAND,
            pct:          300,
            mat:          10000_00,
            liqType:      "clip",
            liqOn:        true,
            chop:         0,
            dog_hole:     3 * MILLION,
            clip_buf:     120_00,
            clip_tail:    140 minutes,
            clip_cusp:    40_00,
            clip_chip:    0,
            clip_tip:     0,
            clipper_mom:  1,
            cm_tolerance: 5000,
            calc_tau:     0,
            calc_step:    90,
            calc_cut:     9900,
            offboarding:  true
        });
        afterSpell.collaterals["PSM-PAX-A"] = CollateralValues({
            aL_enabled:   false,
            aL_line:      0,
            aL_gap:       0,
            aL_ttl:       0,
            line:         0,
            dust:         0,
            pct:          0,
            mat:          10000,
            liqType:      "clip",
            liqOn:        false,
            chop:         1300,
            dog_hole:     0,
            clip_buf:     10500,
            clip_tail:    220 minutes,
            clip_cusp:    9000,
            clip_chip:    10,
            clip_tip:     300,
            clipper_mom:  0,
            cm_tolerance: 9500,
            calc_tau:     0,
            calc_step:    120,
            calc_cut:     9990,
            offboarding:  true
        });
        afterSpell.collaterals["GUNIV3DAIUSDC1-A"] = CollateralValues({
            aL_enabled:   false,
            aL_line:      0,
            aL_gap:       0,
            aL_ttl:       0,
            line:         0,
            dust:         15 * THOUSAND,
            pct:          2,
            mat:          10200,
            liqType:      "clip",
            liqOn:        false,
            chop:         1300,
            dog_hole:     5 * MILLION,
            clip_buf:     10500,
            clip_tail:    220 minutes,
            clip_cusp:    9000,
            clip_chip:    10,
            clip_tip:     300,
            clipper_mom:  0,
            cm_tolerance: 9500,
            calc_tau:     0,
            calc_step:    120,
            calc_cut:     9990,
            offboarding:  false
        });
        afterSpell.collaterals["WSTETH-A"] = CollateralValues({
            aL_enabled:   true,
            aL_line:      750 * MILLION,
            aL_gap:       30 * MILLION,
            aL_ttl:       12 hours,
            line:         0,
            dust:         7_500,
            pct:          13_75,
            mat:          150_00,
            liqType:      "clip",
            liqOn:        true,
            chop:         1300,
            dog_hole:     30 * MILLION,
            clip_buf:     110_00,
            clip_tail:    7_200,
            clip_cusp:    45_00,
            clip_chip:    10,
            clip_tip:     250,
            clipper_mom:  1,
            cm_tolerance: 5000,
            calc_tau:     0,
            calc_step:    90,
            calc_cut:     9900,
            offboarding:  false
        });
        afterSpell.collaterals["WSTETH-B"] = CollateralValues({
            aL_enabled:   true,
            aL_line:      1 * BILLION,
            aL_gap:       45 * MILLION,
            aL_ttl:       12 hours,
            line:         0,
            dust:         3_500,
            pct:          13_50,
            mat:          175_00,
            liqType:      "clip",
            liqOn:        true,
            chop:         1300,
            dog_hole:     20 * MILLION,
            clip_buf:     110_00,
            clip_tail:    7_200,
            clip_cusp:    45_00,
            clip_chip:    10,
            clip_tip:     250,
            clipper_mom:  1,
            cm_tolerance: 5000,
            calc_tau:     0,
            calc_step:    90,
            calc_cut:     9900,
            offboarding:  false
        });
        afterSpell.collaterals["DIRECT-SPK-AAVE-LIDO-USDS"] = CollateralValues({
            aL_enabled:   true,
            aL_line:      200 * MILLION,
            aL_gap:       50 * MILLION,
            aL_ttl:       24 hours,
            line:         0,
            dust:         0,
            pct:          0,
            mat:          10000,
            liqType:      "",
            liqOn:        false,
            chop:         0,
            dog_hole:     0,
            clip_buf:     0,
            clip_tail:    0,
            clip_cusp:    0,
            clip_chip:    0,
            clip_tip:     0,
            clipper_mom:  0,
            cm_tolerance: 0,
            calc_tau:     0,
            calc_step:    0,
            calc_cut:     0,
            offboarding:  false
        });
        afterSpell.collaterals["DIRECT-AAVEV2-DAI"] = CollateralValues({
            aL_enabled:   false,
            aL_line:      0,
            aL_gap:       0,
            aL_ttl:       0,
            line:         0,
            dust:         0,
            pct:          0,
            mat:          10000,
            liqType:      "",
            liqOn:        false,
            chop:         0,
            dog_hole:     0,
            clip_buf:     0,
            clip_tail:    0,
            clip_cusp:    0,
            clip_chip:    0,
            clip_tip:     0,
            clipper_mom:  0,
            cm_tolerance: 0,
            calc_tau:     0,
            calc_step:    0,
            calc_cut:     0,
            offboarding:  false
        });
        afterSpell.collaterals["DIRECT-COMPV2-DAI"] = CollateralValues({
            aL_enabled:   false,
            aL_line:      0,
            aL_gap:       0,
            aL_ttl:       0,
            line:         0,
            dust:         0,
            pct:          0,
            mat:          10000,
            liqType:      "",
            liqOn:        false,
            chop:         0,
            dog_hole:     0,
            clip_buf:     0,
            clip_tail:    0,
            clip_cusp:    0,
            clip_chip:    0,
            clip_tip:     0,
            clipper_mom:  0,
            cm_tolerance: 0,
            calc_tau:     0,
            calc_step:    0,
            calc_cut:     0,
            offboarding:  false
        });
        afterSpell.collaterals["PSM-GUSD-A"] = CollateralValues({
            aL_enabled:   false,
            aL_line:      0,
            aL_gap:       0,
            aL_ttl:       0,
            line:         0,
            dust:         0,
            pct:          0,
            mat:          10000,
            liqType:      "clip",
            liqOn:        false,
            chop:         1300,
            dog_hole:     0,
            clip_buf:     10500,
            clip_tail:    220 minutes,
            clip_cusp:    9000,
            clip_chip:    10,
            clip_tip:     300,
            clipper_mom:  0,
            cm_tolerance: 9500,
            calc_tau:     0,
            calc_step:    120,
            calc_cut:     9990,
            offboarding:  false
        });
        afterSpell.collaterals["GUNIV3DAIUSDC2-A"] = CollateralValues({
            aL_enabled:   false,
            aL_line:      0,
            aL_gap:       0,
            aL_ttl:       0,
            line:         0,
            dust:         15 * THOUSAND,
            pct:          6,
            mat:          10200,
            liqType:      "clip",
            liqOn:        false,
            chop:         1300,
            dog_hole:     5 * MILLION,
            clip_buf:     10500,
            clip_tail:    220 minutes,
            clip_cusp:    9000,
            clip_chip:    10,
            clip_tip:     300,
            clipper_mom:  0,
            cm_tolerance: 9500,
            calc_tau:     0,
            calc_step:    120,
            calc_cut:     9990,
            offboarding:  false
        });
        afterSpell.collaterals["CRVV1ETHSTETH-A"] = CollateralValues({
            aL_enabled:   false,
            aL_line:      0,
            aL_gap:       0,
            aL_ttl:       0,
            line:         0,
            dust:         25 * THOUSAND,
            pct:          4_24,
            mat:          10000_00,
            liqType:      "clip",
            liqOn:        true,
            chop:         0,
            dog_hole:     5 * MILLION,
            clip_buf:     110_00,
            clip_tail:    120 minutes,
            clip_cusp:    45_00,
            clip_chip:    0,
            clip_tip:     0,
            clipper_mom:  1,
            cm_tolerance: 5000,
            calc_tau:     0,
            calc_step:    90,
            calc_cut:     9900,
            offboarding:  true
        });
        afterSpell.collaterals["TELEPORT-FW-A"] = CollateralValues({
            aL_enabled:   false,
            aL_line:      0,
            aL_gap:       0,
            aL_ttl:       0,
            line:         2_100_000,
            dust:         0,
            pct:          0,
            mat:          0,
            liqType:      "",
            liqOn:        false,
            chop:         0,
            dog_hole:     0,
            clip_buf:     0,
            clip_tail:    0,
            clip_cusp:    0,
            clip_chip:    0,
            clip_tip:     0,
            clipper_mom:  0,
            cm_tolerance: 0,
            calc_tau:     0,
            calc_step:    0,
            calc_cut:     0,
            offboarding:  false
        });
        afterSpell.collaterals["RETH-A"] = CollateralValues({
            aL_enabled:   false,
            aL_line:      0,
            aL_gap:       0,
            aL_ttl:       0,
            line:         0,
            dust:         7_500,
            pct:          5_25,
            mat:          10000_00,
            liqType:      "clip",
            liqOn:        true,
            chop:         0,
            dog_hole:     2 * MILLION,
            clip_buf:     110_00,
            clip_tail:    120 minutes,
            clip_cusp:    45_00,
            clip_chip:    0,
            clip_tip:     0,
            clipper_mom:  1,
            cm_tolerance: 50_00,
            calc_tau:     0,
            calc_step:    90,
            calc_cut:     99_00,
            offboarding:  true
        });
        afterSpell.collaterals["GNO-A"] = CollateralValues({
            aL_enabled:   false,
            aL_line:      0,
            aL_gap:       0,
            aL_ttl:       0,
            line:         0,
            dust:         100 * THOUSAND,
            pct:          4_90,
            mat:          350_00,
            liqType:      "clip",
            liqOn:        true,
            chop:         13_00,
            dog_hole:     2 * MILLION,
            clip_buf:     120_00,
            clip_tail:    140 minutes,
            clip_cusp:    25_00,
            clip_chip:    10,
            clip_tip:     250,
            clipper_mom:  1,
            cm_tolerance: 50_00,
            calc_tau:     0,
            calc_step:    60,
            calc_cut:     99_00,
            offboarding:  false
        });
        afterSpell.collaterals["DIRECT-SPARK-DAI"] = CollateralValues({
            aL_enabled:   true,
            aL_line:      2500 * MILLION,
            aL_gap:       40 * MILLION,
            aL_ttl:       24 hours,
            line:         0,
            dust:         0,
            pct:          0,
            mat:          10000,
            liqType:      "",
            liqOn:        false,
            chop:         0,
            dog_hole:     0,
            clip_buf:     0,
            clip_tail:    0,
            clip_cusp:    0,
            clip_chip:    0,
            clip_tip:     0,
            clipper_mom:  0,
            cm_tolerance: 0,
            calc_tau:     0,
            calc_step:    0,
            calc_cut:     0,
            offboarding:  false
        });
        afterSpell.collaterals["DIRECT-SPARK-MORPHO-DAI"] = CollateralValues({
            aL_enabled:   true,
            aL_line:      1 * BILLION,
            aL_gap:       100 * MILLION,
            aL_ttl:       24 hours,
            line:         0,
            dust:         0,
            pct:          0,
            mat:          10000,
            liqType:      "",
            liqOn:        false,
            chop:         0,
            dog_hole:     0,
            clip_buf:     0,
            clip_tail:    0,
            clip_cusp:    0,
            clip_chip:    0,
            clip_tip:     0,
            clipper_mom:  0,
            cm_tolerance: 0,
            calc_tau:     0,
            calc_step:    0,
            calc_cut:     0,
            offboarding:  false
        });
        afterSpell.collaterals["LSE-MKR-A"] = CollateralValues({
            aL_enabled:   true,
            aL_line:      20_000_000,
            aL_gap:       5_000_000,
            aL_ttl:       16 hours,
            line:         0,
            dust:         30_000,
            pct:          12_00,
            mat:          200_00,
            liqType:      "clip",
            liqOn:        true,
            chop:         8_00,
            dog_hole:     3 * MILLION,
            clip_buf:     120_00,
            clip_tail:    100 minutes,
            clip_cusp:    40_00,
            clip_chip:    10,
            clip_tip:     300,
            clipper_mom:  1,
            cm_tolerance: 50_00,
            calc_tau:     0,
            calc_step:    60,
            calc_cut:     99_00,
            offboarding:  false
        });
        afterSpell.collaterals["ALLOCATOR-SPARK-A"] = CollateralValues({
            aL_enabled:   true,
            aL_line:      100 * MILLION,
            aL_gap:       100 * MILLION,
            aL_ttl:       24 hours,
            line:         0,
            dust:         0,
            pct:          12_25,
            mat:          100_00,
            liqType:      "",
            liqOn:        false,
            chop:         0,
            dog_hole:     0,
            clip_buf:     0,
            clip_tail:    0,
            clip_cusp:    0,
            clip_chip:    0,
            clip_tip:     0,
            clipper_mom:  0,
            cm_tolerance: 0,
            calc_tau:     0,
            calc_step:    0,
            calc_cut:     0,
            offboarding:  false
        });
    }
}
