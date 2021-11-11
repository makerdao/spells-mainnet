pragma solidity 0.6.12;

struct CentrifugeCollateralValues {
    // mip21 addresses
    address MCD_JOIN;
    address GEM;
    address OPERATOR; // MGR
    address INPUT_CONDUIT; // MGR
    address OUTPUT_CONDUIT; // MGR
    address URN;

    // changelog ids
    bytes32 gemID;
    bytes32 joinID;
    bytes32 urnID;
    bytes32 inputConduitID;
    bytes32 outputConduitID;
    bytes32 pipID;

    // misc
    bytes32 ilk;
    string ilk_string;
    string ilkRegistryName;
    uint256 RATE;
    uint256 CEIL;
    uint256 PRICE;
    uint256 MAT;
    uint48 TAU;
    string DOC;
}

struct CentrifugeCollateralTestValues {
    bytes32 ilk;
    address LIQ;
    address URN;
    address ROOT;
    address COORDINATOR;
    address DROP;
    address MEMBERLIST;
    address MGR;
}