pragma solidity ^0.5.12;

contract FlipMomLike {
    function rely(address) external;
    function deny(address) external;
}

contract EnableLiquidationSpell {
    address constant public MCD_FLIP_ETH_A = 0xd8a04F5412223F513DC55F839574430f5EC15531;
    address constant public MCD_FLIP_BAT_A = 0xaA745404d55f88C108A28c86abE7b5A1E7817c07;
    address constant public MCD_FLIP_USDC_A = 0xE6ed1d09a19Bd335f051d78D5d22dF3bfF2c28B1;
    address constant public FLIPPER_MOM = 0x9BdDB99625A711bf9bda237044924E34E8570f75;

    uint256 constant lifetime = 30 days;

    uint256 public exp;
    bool    public done;

    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, "overflow");
    }

    constructor() public {
        exp = add(now, lifetime);
        done = false;
    }

    function cast() public {
        require(now < exp, "expired");
        require(!done, "already-cast");
        done = true;
        FlipMomLike(FLIPPER_MOM).rely(MCD_FLIP_ETH_A);
        FlipMomLike(FLIPPER_MOM).rely(MCD_FLIP_BAT_A);
        FlipMomLike(FLIPPER_MOM).rely(MCD_FLIP_USDC_A);
    }
}
