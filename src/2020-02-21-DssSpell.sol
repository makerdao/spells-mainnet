pragma solidity 0.5.12;

import "ds-math/math.sol";
import "lib/dss-interfaces/src/dapp/DSPauseAbstract.sol";
import "lib/dss-interfaces/src/dss/OsmAbstract.sol";
import "lib/dss-interfaces/src/dss/OsmMomAbstract.sol";
import "lib/dss-interfaces/src/dss/JugAbstract.sol";
import "lib/dss-interfaces/src/dss/PotAbstract.sol";
import "lib/dss-interfaces/src/dss/VatAbstract.sol";
import "lib/dss-interfaces/src/dss/FlapAbstract.sol";
import "lib/dss-interfaces/src/sai/SaiMomAbstract.sol";

contract SpellAction is DSMath {
    uint256 constant RAD = 10 ** 45;
    address constant public PAUSE = 0xbE286431454714F511008713973d3B053A2d38f3;
    address constant public CHIEF = 0x9eF05f7F6deB616fd37aC3c959a2dDD25A54E4F5;
    address constant public OSM_MOM = 0x76416A4d5190d071bfed309861527431304aA14f;
    address constant public ETH_OSM = 0x81FE72B5A8d1A857d176C3E7d5Bd2679A9B85763;
    address constant public BAT_OSM = 0xB4eb54AF9Cc7882DF0121d26c5b97E802915ABe6;
    address constant public VAT = 0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B;
    address constant public JUG = 0x19c0976f590D67707E62397C87829d896Dc0f1F1;
    address constant public POT = 0x197E90f9FAD81970bA7976f33CbD77088E5D7cf7;
    address constant public FLAP = 0xdfE0fb1bE2a52CDBf8FB962D5701d7fd0902db9f;
    uint256 constant NEW_BEG = 1.02E18; // 2%

    function execute() external {
        // drip
        PotAbstract(POT).drip();
        JugAbstract(JUG).drip("ETH-A");
        JugAbstract(JUG).drip("BAT-A");

        // set the global debt ceiling to 183,000,000
        VatAbstract(VAT).file("Line", mul(183000000, RAD));

        // set the ETH-A debt ceiling to 150,000,000
        // https://vote.makerdao.com/polling-proposal/qmsm1q1hohyctsgxpbm44fomjoukf1d5g9lmpqraikmeoc
        VatAbstract(VAT).file("ETH-A", "line", mul(150000000, RAD));

        // No Sai debt ceiling change this week.

        // set dsr to 8.0%
        // Previously ETH SF was set to 8.0%, no change this week.
        //  DSR rate was voted to a 0% spread, so we're bringing DSR up to match.
        // https://vote.makerdao.com/polling-proposal/qmss9hnszwr6egq3xn6gpx4u8bz8cajja56rgtanjev1v8
        PotAbstract(POT).file("dsr", 1000000002440418608258400030);

        // MCD Stability fee is currently at 8% and remains the same this week.
        // https://vote.makerdao.com/polling-proposal/qmzgvzjm4xpm4b1tk2hxhdc6p8f4zqyju38pwqieatmhel

        // Lower the minimum flap auction bid increase to 2%
        // https://vote.makerdao.com/polling-proposal/qmtsxrqavtczfsseytpypgqrz6z8zb613ikxwhqjv9ytzz
        FlapAbstract(FLAP).file("beg", NEW_BEG);

        // Increase the Pause to 24 Hours
        OsmAbstract(ETH_OSM).rely(OSM_MOM);
        OsmAbstract(BAT_OSM).rely(OSM_MOM);
        OsmMomAbstract(OSM_MOM).setAuthority(CHIEF);
        OsmMomAbstract(OSM_MOM).setOsm("ETH-A", ETH_OSM);
        OsmMomAbstract(OSM_MOM).setOsm("BAT-A", BAT_OSM);
        DSPauseAbstract(PAUSE).setDelay(60 * 60 * 24);
    }
}

contract DssSpell20200221 is DSMath {
    DSPauseAbstract  public pause =
        DSPauseAbstract(0xbE286431454714F511008713973d3B053A2d38f3);
    address constant public SAIMOM = 0xF2C5369cFFb8Ea6284452b0326e326DbFdCb867C;
    uint256 constant public NEW_FEE = 1000000002877801985002875644; // 9.5%
    address          public action;
    bytes32          public tag;
    uint256          public eta;
    bytes            public sig;
    bool             public done;

    constructor() public {
        sig = abi.encodeWithSignature("execute()");
        action = address(new SpellAction());
        bytes32 _tag;
        address _action = action;
        assembly { _tag := extcodehash(_action) }
        tag = _tag;
    }

    function schedule() public {
        require(eta == 0, "spell-already-scheduled");
        eta = add(now, DSPauseAbstract(pause).delay());
        pause.plot(action, tag, sig, eta);

        // NOTE: 'eta' check should mimic the old behavior of 'done', thus
        // preventing these SCD changes from being executed again.
    }

    function cast() public {
        require(!done, "spell-already-cast");
        done = true;
        pause.exec(action, tag, sig, eta);

        // Sai Stability Fee adjustment to 9.5%
        // https://vote.makerdao.com/polling-proposal/qmaj4fnjeohomnrs8m9cihrfxws4m89bwfu9eh96y8okxw
        SaiMomAbstract(SAIMOM).setFee(NEW_FEE);
    }
}
