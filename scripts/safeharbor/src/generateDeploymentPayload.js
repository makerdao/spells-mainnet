// NOTE: File required for bootstrapping the initial deployment of the AgreementV2 contract, remove after adoption.
import {
    downloadAndParseCSV,
    buildCSVRepresentation,
} from "./utils/csvUtils.js";
import {
    createEmptyDetails,
    createContractInstances,
    createProvider,
    generateCreatePayload,
    generateAddChainsPayload,
    logConfiguration,
} from "./utils/contractUtils.js";

import { CSV_URL_SHEET1 } from "./constants.js";

import { getAssetRecoveryAddress, getChainId } from "./utils/chainUtils.js";

// Helper function to encode the deployment payload
export async function generateDeploymentPayload() {
    try {
        // 1. Download and parse CSV
        const records = await downloadAndParseCSV(CSV_URL_SHEET1);

        const csvState = buildCSVRepresentation(records);

        // 2. Generate empty contract creation payload
        const provider = createProvider();
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
            assetRecoveryAddress: getAssetRecoveryAddress(chain),
            accounts: accounts.map((acc) => ({
                accountAddress: acc.accountAddress,
                childContractScope: acc.childContractScope,
            })),
            id: getChainId(chain),
        }));
        logConfiguration(emptyDetails, allChains);

        return {
            createPayload,
            addChainsPayload,
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
