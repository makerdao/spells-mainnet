// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.6.12;

import "./DssSpell.t.base.sol";
import "dss-interfaces/Interfaces.sol";

interface Gem6Like {
    function implementation() external view returns (address);
}

interface GemJoin6Like {
    function implementations(address) external view returns (uint256);
    function join(address, uint256) external;
    function exit(address, uint256) external;
}

interface AuthLike {
    function wards(address) external view returns (uint256);
}

contract DssSpellTest is DssSpellTestBase {

    function test_TUSDImplementation() public {
        address TUSD = addr.addr("TUSD");
        address MCD_JOIN_TUSD_A = addr.addr("MCD_JOIN_TUSD_A");
        address prevImpl = 0xffc40F39806F1400d8278BfD33823705b5a4c196;
        address nextImpl = 0xd8D59c59Ab40B880b54C969920E8d9172182Ad7b;
        address actualImpl = Gem6Like(TUSD).implementation();
        assertEq(nextImpl, actualImpl);
        assertEq(GemJoin6Like(MCD_JOIN_TUSD_A).implementations(prevImpl), 1);
        assertEq(GemJoin6Like(MCD_JOIN_TUSD_A).implementations(nextImpl), 0);

        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done(), "DssSpellTest/spell-not-done");

        assertEq(GemJoin6Like(MCD_JOIN_TUSD_A).implementations(prevImpl), 0);
        assertEq(GemJoin6Like(MCD_JOIN_TUSD_A).implementations(nextImpl), 1);
    }

    function joinAndExitTUSD() internal {
        address TUSD = addr.addr("TUSD");
        address MCD_JOIN_TUSD_A = addr.addr("MCD_JOIN_TUSD_A");

        uint256 amount = 86 * THOUSAND * WAD;
        giveTokens(GemAbstract(TUSD), amount);
        GemAbstract(TUSD).approve(MCD_JOIN_TUSD_A, amount);
        GemJoin6Like(MCD_JOIN_TUSD_A).join(address(this), amount);
        assertEq(vat.gem("TUSD-A", address(this)), amount);
        assertEq(GemAbstract(TUSD).balanceOf(address(this)), 0);
        GemJoin6Like(MCD_JOIN_TUSD_A).exit(address(this), amount);
        assertEq(vat.gem("TUSD-A", address(this)), 0);
        assertEq(GemAbstract(TUSD).balanceOf(address(this)), amount);
    }

    function testFail_joinAndExitTUSDBefore() public {
        joinAndExitTUSD();
    }

    function test_joinAndExitTUSDAfter() public {
        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done(), "DssSpellTest/spell-not-done");
        joinAndExitTUSD();
    }

    function test_ESMFlashAuth() public {
        address MCD_FLASH = addr.addr("MCD_FLASH");
        address MCD_ESM = addr.addr("MCD_ESM");

        assertEq(AuthLike(MCD_FLASH).wards(MCD_ESM), 0);

        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done(), "DssSpellTest/spell-not-done");

        assertEq(AuthLike(MCD_FLASH).wards(MCD_ESM), 1);
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

    function testPayments() private { // make public to use
        uint256 prevSin = vat.sin(address(vow));

        // Insert new payments tests here

        uint256 amount = WAD;
        address WALLET = address(123);

        uint256 prevDai = dai.balanceOf(WALLET);

        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        assertEq(vat.sin(address(vow)) - prevSin, amount * RAY);
        assertEq(dai.balanceOf(WALLET) - prevDai, amount);

    }

    function testCollateralIntegrations() private { // make public to use
        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        // Insert new collateral tests here
        checkIlkIntegration(
            "TOKEN-X",
            GemJoinAbstract(addr.addr("MCD_JOIN_TOKEN_X")),
            ClipAbstract(addr.addr("MCD_CLIP_TOKEN_X")),
            addr.addr("PIP_TOKEN"),
            true,
            true,
            false
        );
    }

    function testNewChainlogValues() private { // make public to use
        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        // Insert new chainlog values tests here
        assertEq(chainLog.getAddress("XXX"), addr.addr("XXX"));

        assertEq(chainLog.version(), "1.X.X");
    }

    function testNewIlkRegistryValues() private { // make public to use
        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        // Insert new ilk registry values tests here
        assertEq(reg.pos("XXX-A"), 48);
        assertEq(reg.join("XXX-A"), addr.addr("MCD_JOIN_XXX_A"));
        assertEq(reg.gem("XXX-A"), addr.addr("XXX"));
        assertEq(reg.dec("XXX-A"), GemAbstract(addr.addr("XXX")).decimals());
        assertEq(reg.class("XXX-A"), 1);
        assertEq(reg.pip("XXX-A"), addr.addr("PIP_XXX"));
        assertEq(reg.xlip("XXX-A"), addr.addr("MCD_CLIP_XXX_A"));
        assertEq(reg.name("XXX-A"), "xxx xxx xxx");
        assertEq(reg.symbol("XXX-A"), "xxx");
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
        address READER_ADDR = address(spotter);

        // Track OSM authorizations here
        assertEq(OsmAbstract(addr.addr("PIP_XXX")).bud(READER_ADDR), 0);

        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        assertEq(OsmAbstract(addr.addr("PIP_XXX")).bud(READER_ADDR), 1);
    }

    function test_Medianizers() private { // make public to use
        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        // Track Median authorizations here
        address PIP     = addr.addr("PIP_XXX");
        address MEDIAN  = OsmAbstract(PIP).src();
        assertEq(MedianAbstract(MEDIAN).bud(PIP), 1);
    }

    function test_auth() private { // make public to use
        checkAuth(false);
    }

    function test_auth_in_sources() private { // make public to use
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
