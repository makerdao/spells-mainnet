import {DssAction} from "lib/dss-exec-lib/src/DssAction.sol";

contract SpellAction is DssAction { // DssAction could be changed to a library if the lib is hardcoded and the constructor removed

    // This can be hardcoded away later or can use the chain-log
    constructor(address lib) DssAction(lib) public {}

    uint256 constant MILLION  = 10 ** 6;

    function execute() external {

        // Option 1: Use a generic library call
        libCall("setIlkDebtCeiling(bytes32,uint256)", "ETH-A", 10 * MILLION);

        // Option 2: Custom setter for ease of use.
        setGlobalDebtCeiling(1500 * MILLION);
    }
}