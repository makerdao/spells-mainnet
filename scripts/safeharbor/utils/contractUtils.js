import { ethers } from 'ethers';
import { 
    FACTORY_ADDRESS, 
    OWNER_ADDRESS,
    DEFAULT_PROTOCOL_NAME,
    DEFAULT_CONTACT,
    DEFAULT_BOUNTY_TERMS,
    DEFAULT_AGREEMENT_URI,
    DEFAULT_ASSET_RECOVERY_ADDRESS
} from '../constants.js';
import { FACTORY_ABI, AGREEMENTV2_ABI as AGREEMENT_ABI } from '../abis.js';

export function createEmptyDetails() {
    return {
        protocolName: DEFAULT_PROTOCOL_NAME,
        contactDetails: [DEFAULT_CONTACT],
        chains: [], // Empty chains array
        bountyTerms: DEFAULT_BOUNTY_TERMS,
        agreementURI: DEFAULT_AGREEMENT_URI
    };
}

export function createContractInstances(provider) {
    const factory = new ethers.Contract(FACTORY_ADDRESS, FACTORY_ABI, provider);
    const agreement = new ethers.Contract("0xa5c82ae35b653192d99c019a8eeaa159af0133e5", AGREEMENT_ABI, provider);
    return { factory, agreement };
}

export function generateCreatePayload(factory, emptyDetails) {
    const createCalldata = factory.interface.encodeFunctionData("create", [
        emptyDetails,
        OWNER_ADDRESS
    ]);

    return {
        target: FACTORY_ADDRESS,
        calldata: createCalldata
    };
}

export function generateAddChainsPayload(agreement, csvState) {
    const allChains = Object.entries(csvState).map(([chain, accounts]) => ({
        assetRecoveryAddress: DEFAULT_ASSET_RECOVERY_ADDRESS,
        accounts: accounts.map(acc => ({
            accountAddress: acc.accountAddress,
            childContractScope: acc.childContractScope
        })),
        id: chain === "ETHEREUM" ? 1 : 0
    }));

    const addChainsCalldata = agreement.interface.encodeFunctionData("addChains", [allChains]);
    return {
        target: "0xa5c82ae35b653192d99c019a8eeaa159af0133e5",
        calldata: addChainsCalldata
    };
}

export function logConfiguration(emptyDetails, allChains) {
    console.log("\nConfiguration used:");
    console.log("Protocol Name:", emptyDetails.protocolName);
    console.log("\nChains and Accounts:");
    allChains.forEach(chain => {
        console.log(`\nChain ID: ${chain.id}`);
        chain.accounts.forEach(account => {
            console.log(`  - ${account.accountAddress} (Factory: ${account.childContractScope === 3})`);
        });
    });
} 
