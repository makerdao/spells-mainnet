// NOTE: File required for bootstrapping the initial deployment of the AgreementV2 contract, remove after adoption.

import { ethers } from 'ethers';

import { 
    downloadAndParseCSV, 
    buildCSVRepresentation 
} from './utils/csvUtils.js';
import { 
    createEmptyDetails, 
    createContractInstances, 
    generateCreatePayload, 
    generateAddChainsPayload,
    logConfiguration 
} from './utils/contractUtils.js';

import { 
    CSV_URL_SHEET1,
    CSV_URL_SHEET2
} from './constants.js';

// Helper function to encode the deployment payload
export async function generateDeploymentPayload() {
    try {
        // 1. Download and parse CSV
        const records1 = await downloadAndParseCSV(CSV_URL_SHEET1);
        const records2 = await downloadAndParseCSV(CSV_URL_SHEET2);
        const records = [...records1, ...records2];
        
        const csvState = buildCSVRepresentation(records);

        // 2. Generate empty contract creation payload
        const provider = new ethers.providers.JsonRpcProvider("http://127.0.0.1:8545");
        const { factory, agreement } = createContractInstances(provider);

        // Create empty details for initial deployment
        const emptyDetails = createEmptyDetails();

        // Generate payloads
        const createPayload = generateCreatePayload(factory, emptyDetails);
        const addChainsPayload = generateAddChainsPayload(agreement, csvState);

        // Log all payloads
        console.log("\n1. Initial Contract Creation Payload:");
        console.log(JSON.stringify(createPayload, null, 2));

        console.log("\n2. Add All Chains Payload:");
        console.log(JSON.stringify(addChainsPayload, null, 2));

        // Log the configuration that was used
        const allChains = Object.entries(csvState).map(([chain, accounts]) => ({
            assetRecoveryAddress: "0x0000000000000000000000000000000000000022",
            accounts: accounts.map(acc => ({
                accountAddress: acc.accountAddress,
                childContractScope: acc.childContractScope
            })),
            id: chain === "ETHEREUM" ? 1 : 
                chain === "BASE" ? 8453 :
                chain === "GNOSIS" ? 100 :
                chain === "ARBITRUM" ? 42161 :
                chain === "SOLANA" ? 555 : 0
        }));
        logConfiguration(emptyDetails, allChains);

        return {
            createPayload,
            addChainsPayload
        };
    } catch (error) {
        console.error("Error generating deployment payload:", error);
        throw error;
    }
}

// Only run if this file is being executed directly
if (process.argv[1] === new URL(import.meta.url).pathname) {
    generateDeploymentPayload();
} 
