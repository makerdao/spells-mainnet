// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.6.12;

import "./DssSpell.t.base.sol";
import "dss-interfaces/Interfaces.sol";

contract DssSpellTest is DssSpellTestBase {

    address immutable FLIPFLOPFLAP   = wallets.addr("FLIPFLOPFLAP");
    address immutable FEEDBLACKLOOPS = wallets.addr("FEEDBLACKLOOPS");
    address immutable ULTRASCHUPPI   = wallets.addr("ULTRASCHUPPI");
    address immutable MAKERMAN       = wallets.addr("MAKERMAN");
    address immutable MONETSUPPLY    = wallets.addr("MONETSUPPLY");
    address immutable ACREINVEST     = wallets.addr("ACREINVEST");
    address immutable JUSTINCASE     = wallets.addr("JUSTINCASE");
    address immutable GFXLABS        = wallets.addr("GFXLABS");

    address immutable SNE            = wallets.addr("SNE_WALLET");
    address immutable SF             = wallets.addr("SF_WALLET");

    uint256 constant amountFlipFlop     = 12_000;
    uint256 constant amountFeedblack    = 12_000;
    uint256 constant amountSchuppi      = 12_000;
    uint256 constant amountMakerMan     =  8_620;
    uint256 constant amountMonetSupply  =  4_807;
    uint256 constant amountAcreInvest   =  3_795;
    uint256 constant amountJustinCase   =    889;
    uint256 constant amountGfxLabs      =    641;

    uint256 constant amountSNE          = 42_917;
    uint256 constant amountSF           = 82_417;

    uint256 constant MAR_01_2022        = 1646092800;
    uint256 constant JUL_31_2022        = 1659225600;

    function testPayments() public {
        uint256 prevSin              = vat.sin(address(vow));
        uint256 prevDaiFlipFlop      = dai.balanceOf(FLIPFLOPFLAP);
        uint256 prevDaiFeedblack     = dai.balanceOf(FEEDBLACKLOOPS);
        uint256 prevDaiSchuppi       = dai.balanceOf(ULTRASCHUPPI);
        uint256 prevDaiMakerMan      = dai.balanceOf(MAKERMAN);
        uint256 prevDaiMonetSupply   = dai.balanceOf(MONETSUPPLY);
        uint256 prevDaiAcreInvest    = dai.balanceOf(ACREINVEST);
        uint256 prevDaiJustinCase    = dai.balanceOf(JUSTINCASE);
        uint256 prevDaiGfxLabs       = dai.balanceOf(GFXLABS);

        uint256 prevDaiSNE              = dai.balanceOf(SNE);
        uint256 prevDaiSF               = dai.balanceOf(SF);

        uint256 amountTotal = amountFlipFlop + amountFeedblack + amountSchuppi
        + amountMakerMan + amountMonetSupply + amountAcreInvest + amountJustinCase
        + amountGfxLabs + amountSNE + amountSF;

        assertEq(amountTotal, 180_086);

        assertEq(vat.can(address(pauseProxy), address(daiJoin)), 1);

        vote(address(spell));
        spell.schedule();
        hevm.warp(spell.nextCastTime());
        spell.cast();
        assertTrue(spell.done());

        assertEq(vat.can(address(pauseProxy), address(daiJoin)), 1);

        assertEq(vat.sin(address(vow))         - prevSin,            amountTotal        * RAD);
        assertEq(dai.balanceOf(FLIPFLOPFLAP)   - prevDaiFlipFlop,    amountFlipFlop     * WAD);
        assertEq(dai.balanceOf(FEEDBLACKLOOPS) - prevDaiFeedblack,   amountFeedblack    * WAD);
        assertEq(dai.balanceOf(ULTRASCHUPPI)   - prevDaiSchuppi,     amountSchuppi      * WAD);
        assertEq(dai.balanceOf(MAKERMAN)       - prevDaiMakerMan,    amountMakerMan     * WAD);
        assertEq(dai.balanceOf(MONETSUPPLY)    - prevDaiMonetSupply, amountMonetSupply  * WAD);
        assertEq(dai.balanceOf(ACREINVEST)     - prevDaiAcreInvest,  amountAcreInvest   * WAD);
        assertEq(dai.balanceOf(JUSTINCASE)     - prevDaiJustinCase,  amountJustinCase   * WAD);
        assertEq(dai.balanceOf(GFXLABS)        - prevDaiGfxLabs,     amountGfxLabs      * WAD);
        assertEq(dai.balanceOf(SNE)            - prevDaiSNE,         amountSNE          * WAD);
        assertEq(dai.balanceOf(SF)             - prevDaiSF,          amountSF           * WAD);
    }

    function testVestDAI() public {
        VestAbstract vest = VestAbstract(addr.addr("MCD_VEST_DAI"));

        uint streams = vest.ids();

        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        assertEq(vest.cap(), 1 * MILLION * WAD / 30 days);
        assertEq(vest.ids(), streams + 2);

        // // -----
        assertEq(vest.usr(28), wallets.addr("SNE_WALLET"));
        assertEq(vest.bgn(28), MAR_01_2022, "bgn");
        assertEq(vest.clf(28), MAR_01_2022, "clf");
        assertEq(vest.fin(28), MAR_01_2022 + 152 days, "fin"); // (31+30+31+30+31)
        assertEq(vest.mgr(28), address(0));
        assertEq(vest.res(28), 1);
        assertEq(vest.tot(28), 214_583 * WAD);
        assertEq(vest.rxd(28), 0);
        // // -----
        assertEq(vest.usr(29), wallets.addr("SF_WALLET"));
        assertEq(vest.bgn(29), MAR_01_2022, "bgn");
        assertEq(vest.clf(29), MAR_01_2022, "clf");
        assertEq(vest.fin(29), MAR_01_2022 + 152 days, "fin"); // (31+30+31+30+31)
        assertEq(vest.mgr(29), address(0));
        assertEq(vest.res(29), 1);
        assertEq(vest.tot(29), 412_805 * WAD);
        assertEq(vest.rxd(29), 0);


        // // Give admin powers to Test contract address and make the vesting unrestricted for testing
        hevm.store(
            address(vest),
            keccak256(abi.encode(address(this), uint256(1))),
            bytes32(uint256(1))
        );
        vest.unrestrict(28);
        vest.unrestrict(29);
        // //

        hevm.warp(JUL_31_2022);
        uint256 prevBalanceSNE  = dai.balanceOf(wallets.addr("SNE_WALLET"));
        uint256 prevBalanceSF  = dai.balanceOf(wallets.addr("SF_WALLET"));

        uint256 vestedSNE = vest.accrued(28);
        assertEq(vestedSNE, 214583 * WAD);
        uint256 vestedSF = vest.accrued(29);
        assertEq(vestedSF, 412805 * WAD);

        vest.vest(28);
        vest.vest(29);

        assertEq(dai.balanceOf(wallets.addr("SNE_WALLET")), prevBalanceSNE + vestedSNE);
        assertEq(dai.balanceOf(wallets.addr("SF_WALLET")), prevBalanceSF + vestedSF);

    }

    function testSpellIsCast_GENERAL() public {
        string memory description = new DssSpell().description();
        assertTrue(bytes(description).length > 0, "TestError/spell-description-length");
        // DS-Test can't handle strings directly, so cast to a bytes32.
        assertEq(stringToBytes32(spell.description()),
                stringToBytes32(description), "TestError/spell-description");

        if(address(spell) != address(spellValues.deployed_spell)) {
            assertEq(spell.expiration(), block.timestamp + spellValues.expiration_threshold, "TestError/spell-expiration");
        } else {
            assertEq(spell.expiration(), spellValues.deployed_spell_created + spellValues.expiration_threshold, "TestError/spell-expiration");

            // If the spell is deployed compare the on-chain bytecode size with the generated bytecode size.
            // extcodehash doesn't match, potentially because it's address-specific, avenue for further research.
            address depl_spell = spellValues.deployed_spell;
            address code_spell = address(new DssSpell());
            assertEq(getExtcodesize(depl_spell), getExtcodesize(code_spell), "TestError/spell-codesize");
        }

        assertTrue(spell.officeHours() == spellValues.office_hours_enabled, "TestError/spell-office-hours");

        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done(), "TestError/spell-not-done");

        checkSystemValues(afterSpell);

        checkCollateralValues(afterSpell);
    }

    function testCollateralIntegrations() private { // make public to use
        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        // Insert new collateral tests here
    }

    function testLerps() private { // make public to use
        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());
    }

    function testAAVEDirectBarChange() public {
        DirectDepositLike join = DirectDepositLike(addr.addr("MCD_JOIN_DIRECT_AAVEV2_DAI"));
        assertEq(join.bar(), 3.75 * 10**27 / 100);

        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        assertEq(join.bar(), 3.5 * 10**27 / 100);
    }

    bytes32[] items;
    function testESMOffboarding() public {
        delete items; // reset array
        address _oldEsm = chainLog.getAddress("MCD_ESM");

        bytes32[] memory contractNames = chainLog.list();
        uint256 nameLen = contractNames.length;
        for(uint256 i = 0; i < nameLen; i++) {
            bytes32 _name = contractNames[i];
            if (_name == "DEPLOYER" ||
                _name == "ETH"||
                _name == "PROXY_DEPLOYER"
            ) { continue; }
            address _addr = chainLog.getAddress(_name);
            (bool ok, bytes memory val) = _addr.call(abi.encodeWithSignature("wards(address)", _oldEsm));
            log_bytes(val);
            if (ok) {
                uint256 isWard = abi.decode(val, (uint256));
                log_uint(isWard);
                if (isWard == 1) {
                    items.push(_name);
                }
            }
        }
        assertTrue(items.length >= 51);

        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done(), "TestError/spell-not-done");

        address _newEsm = chainLog.getAddress("MCD_ESM");

        uint256 itemLen = items.length;
        for(uint256 i = 0; i < itemLen; i++) {
            WardsAbstract _base = WardsAbstract(chainLog.getAddress(items[i]));
            assertEq(_base.wards(_oldEsm), 0);
            assertEq(_base.wards(_newEsm), 1);
        }
    }

    function testFireESM() public {
        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        assertTrue(esm.revokesGovernanceAccess());

        uint256 amt = 100 * THOUSAND * WAD;
        assertEq(esm.min(), amt);
        giveTokens(gov, amt);
        gov.approve(address(esm), amt);
        esm.join(amt);

        assertEq(vat.wards(address(pauseProxy)), 1);
        esm.fire();
        assertEq(vat.wards(address(pauseProxy)), 0);
        assertEq(end.live(), 0);
        assertEq(vat.live(), 0);

        ClipAbstract clipLINKA = ClipAbstract(addr.addr("MCD_CLIP_LINK_A"));
        assertEq(clipLINKA.wards(address(pauseProxy)), 1);
        ESMAbstract(address(esm)).denyProxy(address(clipLINKA));
        assertEq(clipLINKA.wards(address(pauseProxy)), 0);
    }

    function testFailFireESM() public {
        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        uint256 amt = 99 * THOUSAND * WAD;
        giveTokens(gov, amt);
        gov.approve(address(esm), amt);
        esm.join(amt);
        esm.fire();
    }

    function testNewChainlogValues() public { // make public to use
        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        // Insert new chainlog values tests here
        assertEq(chainLog.getAddress("MCD_ESM"), addr.addr("MCD_ESM"));
        assertEq(chainLog.version(), "1.10.0");
    }

    function testNewIlkRegistryValues() private { // make public to use
        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        // Insert new ilk registry values tests here
    }

    function testFailWrongDay() public {
        require(spell.officeHours() == spellValues.office_hours_enabled);
        if (spell.officeHours()) {
            vote(address(spell));
            scheduleWaitAndCastFailDay();
        } else {
            revert("Office Hours Disabled");
        }
    }

    function testFailTooEarly() public {
        require(spell.officeHours() == spellValues.office_hours_enabled);
        if (spell.officeHours()) {
            vote(address(spell));
            scheduleWaitAndCastFailEarly();
        } else {
            revert("Office Hours Disabled");
        }
    }

    function testFailTooLate() public {
        require(spell.officeHours() == spellValues.office_hours_enabled);
        if (spell.officeHours()) {
            vote(address(spell));
            scheduleWaitAndCastFailLate();
        } else {
            revert("Office Hours Disabled");
        }
    }

    function testOnTime() public {
        vote(address(spell));
        scheduleWaitAndCast(address(spell));
    }

    function testCastCost() public {
        vote(address(spell));
        spell.schedule();

        castPreviousSpell();
        hevm.warp(spell.nextCastTime());
        uint256 startGas = gasleft();
        spell.cast();
        uint256 endGas = gasleft();
        uint256 totalGas = startGas - endGas;

        assertTrue(spell.done());
        // Fail if cast is too expensive
        assertTrue(totalGas <= 10 * MILLION);
    }

    // The specific date doesn't matter that much since function is checking for difference between warps
    function test_nextCastTime() public {
        hevm.warp(1606161600); // Nov 23, 20 UTC (could be cast Nov 26)

        vote(address(spell));
        spell.schedule();

        uint256 monday_1400_UTC = 1606744800; // Nov 30, 2020
        uint256 monday_2100_UTC = 1606770000; // Nov 30, 2020

        // Day tests
        hevm.warp(monday_1400_UTC);                                    // Monday,   14:00 UTC
        assertEq(spell.nextCastTime(), monday_1400_UTC);               // Monday,   14:00 UTC

        if (spell.officeHours()) {
            hevm.warp(monday_1400_UTC - 1 days);                       // Sunday,   14:00 UTC
            assertEq(spell.nextCastTime(), monday_1400_UTC);           // Monday,   14:00 UTC

            hevm.warp(monday_1400_UTC - 2 days);                       // Saturday, 14:00 UTC
            assertEq(spell.nextCastTime(), monday_1400_UTC);           // Monday,   14:00 UTC

            hevm.warp(monday_1400_UTC - 3 days);                       // Friday,   14:00 UTC
            assertEq(spell.nextCastTime(), monday_1400_UTC - 3 days);  // Able to cast

            hevm.warp(monday_2100_UTC);                                // Monday,   21:00 UTC
            assertEq(spell.nextCastTime(), monday_1400_UTC + 1 days);  // Tuesday,  14:00 UTC

            hevm.warp(monday_2100_UTC - 1 days);                       // Sunday,   21:00 UTC
            assertEq(spell.nextCastTime(), monday_1400_UTC);           // Monday,   14:00 UTC

            hevm.warp(monday_2100_UTC - 2 days);                       // Saturday, 21:00 UTC
            assertEq(spell.nextCastTime(), monday_1400_UTC);           // Monday,   14:00 UTC

            hevm.warp(monday_2100_UTC - 3 days);                       // Friday,   21:00 UTC
            assertEq(spell.nextCastTime(), monday_1400_UTC);           // Monday,   14:00 UTC

            // Time tests
            uint256 castTime;

            for(uint256 i = 0; i < 5; i++) {
                castTime = monday_1400_UTC + i * 1 days; // Next day at 14:00 UTC
                hevm.warp(castTime - 1 seconds); // 13:59:59 UTC
                assertEq(spell.nextCastTime(), castTime);

                hevm.warp(castTime + 7 hours + 1 seconds); // 21:00:01 UTC
                if (i < 4) {
                    assertEq(spell.nextCastTime(), monday_1400_UTC + (i + 1) * 1 days); // Next day at 14:00 UTC
                } else {
                    assertEq(spell.nextCastTime(), monday_1400_UTC + 7 days); // Next monday at 14:00 UTC (friday case)
                }
            }
        }
    }

    function testFail_notScheduled() public view {
        spell.nextCastTime();
    }

    function test_use_eta() public {
        hevm.warp(1606161600); // Nov 23, 20 UTC (could be cast Nov 26)

        vote(address(spell));
        spell.schedule();

        uint256 castTime = spell.nextCastTime();
        assertEq(castTime, spell.eta());
    }

    function test_OSMs() private { // make public to use
        vote(address(spell));
        spell.schedule();
        hevm.warp(spell.nextCastTime());
        spell.cast();
        assertTrue(spell.done());

        // Track OSM authorizations here
    }

    function test_Medianizers() private { // make public to use
        vote(address(spell));
        spell.schedule();
        hevm.warp(spell.nextCastTime());
        spell.cast();
        assertTrue(spell.done());

        // Track Median authorizations here
    }

    function test_auth() public {
        checkAuth(false);
    }

    function test_auth_in_sources() public {
        checkAuth(true);
    }

    // Verifies that the bytecode of the action of the spell used for testing
    // matches what we'd expect.
    //
    // Not a complete replacement for Etherscan verification, unfortunately.
    // This is because the DssSpell bytecode is non-deterministic because it
    // deploys the action in its constructor and incorporates the action
    // address as an immutable variable--but the action address depends on the
    // address of the DssSpell which depends on the address+nonce of the
    // deploying address. If we had a way to simulate a contract creation by
    // an arbitrary address+nonce, we could verify the bytecode of the DssSpell
    // instead.
    //
    // Vacuous until the deployed_spell value is non-zero.
    function test_bytecode_matches() public {
        address expectedAction = (new DssSpell()).action();
        address actualAction   = spell.action();
        uint256 expectedBytecodeSize;
        uint256 actualBytecodeSize;
        assembly {
            expectedBytecodeSize := extcodesize(expectedAction)
            actualBytecodeSize   := extcodesize(actualAction)
        }

        uint256 metadataLength = getBytecodeMetadataLength(expectedAction);
        assertTrue(metadataLength <= expectedBytecodeSize);
        expectedBytecodeSize -= metadataLength;

        metadataLength = getBytecodeMetadataLength(actualAction);
        assertTrue(metadataLength <= actualBytecodeSize);
        actualBytecodeSize -= metadataLength;

        assertEq(actualBytecodeSize, expectedBytecodeSize);
        uint256 size = actualBytecodeSize;
        uint256 expectedHash;
        uint256 actualHash;
        assembly {
            let ptr := mload(0x40)

            extcodecopy(expectedAction, ptr, 0, size)
            expectedHash := keccak256(ptr, size)

            extcodecopy(actualAction, ptr, 0, size)
            actualHash := keccak256(ptr, size)
        }
        assertEq(expectedHash, actualHash);
    }
}
