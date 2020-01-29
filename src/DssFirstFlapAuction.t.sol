pragma solidity ^0.5.12;
pragma experimental ABIEncoderV2;

import "ds-test/test.sol";

import {Dai} from "dss/dai.sol";
import {Vat} from "dss/vat.sol";
import {Vow} from "dss/vow.sol";
import {Flapper} from "dss/flap.sol";
import {Jug} from "dss/jug.sol";

/**
 * Must be executed from the Multisig address.
 * Use ./test-first-flap-auction.sh to test
 */

contract Hevm {
    function warp(uint) public;
}

contract MkrLike {
    function totalSupply() external returns(uint256);
    function approve(address, uint256) external returns(bool);
    function allowance(address, address) external returns(uint256);
    function balanceOf(address) external returns(uint256);
    function transfer(address, uint) external returns(bool);
}

contract HasBidLike {
    struct Bid {
        uint256 bid;
        uint256 lot;
        address guy;  // high bidder
        uint48  tic;  // expiry time
        uint48  end;
    }
    function bids(uint) external returns(Bid memory);
}

contract Bidder {
    Flapper flap        = Flapper(0xdfE0fb1bE2a52CDBf8FB962D5701d7fd0902db9f);
    MkrLike gov        = MkrLike(0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2);
    uint256  constant ONE = 1.00E18;

    constructor() public {}

    function doFlapApprove() public {
        gov.approve(address(flap), uint(-1));
    }

    function doTend(uint id) public {
        (uint256 bid, uint256 lot,,,) = flap.bids(id);
        flap.tend(id, lot, bid + ONE);
    }
}

contract DssFirstFlapAuction is DSTest {
    Hevm hevm;

    Dai dai            = Dai(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    Vat vat            = Vat(0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B);
    Vow vow            = Vow(0xA950524441892A31ebddF91d3cEEFa04Bf454466);
    Jug jug            = Jug(0x19c0976f590D67707E62397C87829d896Dc0f1F1);
    Flapper flap        = Flapper(0xdfE0fb1bE2a52CDBf8FB962D5701d7fd0902db9f);
    MkrLike gov        = MkrLike(0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2);

    // ProxyLike deployer = ProxyLike(0xdDb108893104dE4E1C6d0E47c42237dB4E617ACc);
    // DeployerActions deployerActions;

    uint256  constant RAD = 10 ** 45;
    uint256  constant ONE = 1.00E18;

    function setUp() public {
        hevm = Hevm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
        hevm.warp(now);
    }

    // function setupFlap() private returns(uint) {
    //     uint256 surplus = vat.dai(address(vow));
    //     uint256 debt = vat.sin(address(vow)) - vow.Sin() - vow.Ash();
    //     uint256 bump = vow.bump();
    //     uint256 hump = vow.hump();
    //     // vat.suck(address(this), address(vow), surplus + debt + bump + hump);
    //     // vow.heal(debt);
    //     return vow.flap();
    // }

    // function bidFlap(uint256 id) private {
    //     // gov.approve(address(flap), uint256(-1));
    //     uint256 lot = vow.bump();
    //     uint256 bid = 1;
    //     flap.tend(id, lot, bid);
    // }

    function testDssFirstFlap() public {
        uint256 debt = vat.sin(address(vow)) - vow.Sin() - vow.Ash();
        uint256 bump = vow.bump();
        uint256 hump = vow.hump();

        // clear out the debt
        vow.heal(debt);

        // check that we are able to start a Flap with enough surplus
        uint256 newDebt = vat.sin(address(vow)) - vow.Sin() - vow.Ash();
        uint256 newSurplus = vat.dai(address(vow));

        assertEq(newDebt, 0);
        assertTrue(newSurplus < bump + hump);

        // jump forward in time and increase surplus
        hevm.warp(now + 2 days);
        jug.drip("ETH-A");
        jug.drip("BAT-A");

        // check that we can now start a Flap auction
        uint256 futureSurplus = vat.dai(address(vow));
        assertTrue(newSurplus < futureSurplus);
        assertTrue(futureSurplus >= bump + hump);

        // start the auction and check it has desired effects
        uint256 flapId = vow.flap();

        uint256 flappedSurplus = vat.dai(address(vow));
        assertTrue(futureSurplus - flappedSurplus == bump);

        (uint256 bid, uint256 lot, address guy, uint48 tic, uint48 end) = flap.bids(flapId);
        assertEq(bid, 0);
        assertEq(lot, bump);
        assertEq(vat.dai(address(flap)), lot);
        assertEq(guy, address(vow));
        assertTrue(tic == 0);
        assertTrue(end == now + flap.tau());
    }

    function testDssFlapAuction() public {
        //setup the flap
        hevm.warp(now + 2 days);

        jug.drip("ETH-A");
        jug.drip("BAT-A");
        vow.heal(vat.sin(address(vow)) - vow.Sin() - vow.Ash());
        uint256 flapId = vow.flap();

        // setup up the bidder and fund with ONE MKR
        Bidder bidder = new Bidder();
        gov.transfer(address(bidder), ONE);
        bidder.doFlapApprove();

        assertEq(gov.balanceOf(address(bidder)), ONE);
        assertEq(gov.balanceOf(address(flap))   , 0);
        assertEq(gov.allowance(address(bidder), address(flap)), uint(-1));

        // Bid on the auction and check results
        bidder.doTend(flapId);

        // Bidder's MKR should be transferred to Flap
        assertEq(gov.balanceOf(address(bidder)), 0);
        assertEq(gov.balanceOf(address(flap))   , ONE);

        // Bid should be updated with correct values
        HasBidLike.Bid memory bid = HasBidLike(address(flap)).bids(flapId);
        assertEq(bid.bid, ONE);
        assertEq(bid.lot, vow.bump());
        assertEq(bid.guy, address(bidder));
        assertTrue(bid.tic == now + flap.ttl());
        assertTrue(bid.end == now + flap.tau());

        // check our pre-balances
        uint256 preMkrSupply = gov.totalSupply();
        uint256 preFlapDai = vat.dai(address(flap));
        assertEq(preFlapDai, bid.lot);
        uint256 preBidderDai = vat.dai(address(bidder));
        assertEq(preBidderDai, 0);

        // fast forward to end the auction
        hevm.warp(now + bid.end + 1);
        flap.deal(flapId);

        // check our post-balances
        uint256 postMkrSupply = gov.totalSupply();
        assertEq(preMkrSupply - postMkrSupply, bid.bid);
        uint256 postFlapDai = vat.dai(address(flap));
        assertEq(postFlapDai, 0);
        uint256 postBidderDai = vat.dai(address(bidder));
        assertEq(postBidderDai, bid.lot);

        // check that the auction got cleaned up
        HasBidLike.Bid memory bid_ = HasBidLike(address(flap)).bids(flapId);
        assertEq(bid_.bid, 0);
        assertEq(bid_.lot, 0);
        assertEq(bid_.guy, address(0));
        assertTrue(bid_.tic == 0);
        assertTrue(bid_.end == 0);
    }
}
