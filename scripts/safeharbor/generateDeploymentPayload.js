import { ethers } from 'ethers';
import fetch from 'node-fetch';
import { parse } from 'csv-parse/sync';

// output: 0xa5c82ae35b653192d99c019a8eeaa159af0133e5
// Constants
const FACTORY_ADDRESS = "0x9d211CaC1ce390F676d1cB1D2Eb681410EC47E47";
const OWNER_ADDRESS = "0x195a7d8610edd06e0C27c006b6970319133Cb19A";
const CSV_URL = "https://docs.google.com/spreadsheets/d/1slHR9VbZOC3wp2ZQu7YbQEQh8N57ePfVvv0w35nz60Q/export?format=csv&gid=1121763694";

// ABI for the factory contract
const FACTORY_ABI = [{
    "type": "function",
    "name": "create",
    "inputs": [
        {
            "name": "details",
            "type": "tuple",
            "components": [
                { "name": "protocolName", "type": "string" },
                {
                    "name": "contactDetails",
                    "type": "tuple[]",
                    "components": [
                        { "name": "name", "type": "string" },
                        { "name": "contact", "type": "string" }
                    ]
                },
                {
                    "name": "chains",
                    "type": "tuple[]",
                    "components": [
                        { "name": "assetRecoveryAddress", "type": "string" },
                        {
                            "name": "accounts",
                            "type": "tuple[]",
                            "components": [
                                { "name": "accountAddress", "type": "string" },
                                { "name": "childContractScope", "type": "uint8" }
                            ]
                        },
                        { "name": "id", "type": "uint256" }
                    ]
                },
                {
                    "name": "bountyTerms",
                    "type": "tuple",
                    "components": [
                        { "name": "bountyPercentage", "type": "uint256" },
                        { "name": "bountyCapUSD", "type": "uint256" },
                        { "name": "retainable", "type": "bool" },
                        { "name": "identity", "type": "uint8" },
                        { "name": "diligenceRequirements", "type": "string" }
                    ]
                },
                { "name": "agreementURI", "type": "string" }
            ]
        },
        { "name": "owner", "type": "address" }
    ],
    "outputs": [{ "name": "agreementAddress", "type": "address" }],
    "stateMutability": "nonpayable"
}];

// ABI for the deployed agreement contract
const AGREEMENT_ABI = [
    "function addChains(tuple(string assetRecoveryAddress, tuple(string accountAddress, uint8 childContractScope)[] accounts, uint256 id)[] chains)"
];

// Download and parse CSV
export async function downloadAndParseCSV() {
    try {
        const response = await fetch(CSV_URL);
        if (!response.ok) {
            throw new Error(`HTTP error! status: ${response.status}`);
        }
        const csvText = await response.text();
        
        // Basic validation that we got CSV data
        if (csvText.includes('<!DOCTYPE html>')) {
            throw new Error('Received HTML instead of CSV data. Please check the URL format.');
        }
        
        return parse(csvText, {
            columns: true,
            skip_empty_lines: true,
            trim: true
        });
    } catch (error) {
        console.error("Error downloading CSV:", error.message);
        if (error.message.includes('HTML')) {
            console.error("\nThe URL might be incorrect. For Google Sheets, make sure to use the export URL format:");
            console.error("https://docs.google.com/spreadsheets/d/{SPREADSHEET_ID}/export?format=csv&gid={SHEET_ID}");
        }
        throw error;
    }
}

// Build internal representation from CSV
export function buildCSVRepresentation(records) {
    const filteredRecords = records.filter(record => record.Status === 'ACTIVE');
    const groups = filteredRecords.reduce((groups, record) => {
        const chain = record.Chain;
        if (!groups[chain]) {
            groups[chain] = [];
        }
        const isFactory = record.isFactory === 'TRUE';
        groups[chain].push({
            accountAddress: record.Address,
            childContractScope: isFactory ? 3 : 0,
            isFactory: isFactory
        });
        return groups;
    }, {});

    return groups;
}

// Helper function to encode the deployment payload
export async function generateDeploymentPayload() {
    try {
        // 1. Download and parse CSV
        const records = await downloadAndParseCSV();
        const csvState = buildCSVRepresentation(records);

        // 2. Generate empty contract creation payload
        const provider = new ethers.providers.JsonRpcProvider("http://127.0.0.1:8545");
        const factory = new ethers.Contract(FACTORY_ADDRESS, FACTORY_ABI, provider);

        // Create empty details for initial deployment
        const emptyDetails = {
            protocolName: "Sky and Stars",
            contactDetails: [
                {
                    name: "Contact Name",
                    contact: "Contact@Info"
                }
            ],
            chains: [], // Empty chains array
            bountyTerms: {
                bountyPercentage: 10000000, // 10%
                bountyCapUSD: 0,
                retainable: false,
                identity: 2,
                diligenceRequirements: "KYC and Sanctions Screening. Sky and Stars require all eligible whitehats to undergo Know Your Customer (KYC) verification and be screened against global sanctions lists, including OFAC, UK, and EU regulations. This ensures that bounty recipients meet legal and regulatory standards before qualifying for payment. The verification process shall be conducted by a trusted third-party provider at Sky and Stars discretion, and all data is deleted, if successful, within 30 days post-verification."
            },
            agreementURI: "Agreement URI"
        };

        // Encode the function call with empty chains
        const createCalldata = factory.interface.encodeFunctionData("create", [
            emptyDetails,
            OWNER_ADDRESS
        ]);

        const createPayload = {
            target: FACTORY_ADDRESS,
            calldata: createCalldata
        };

        // 3. Generate addChains payload
        const agreement = new ethers.Contract("0xa5c82ae35b653192d99c019a8eeaa159af0133e5", AGREEMENT_ABI, provider);

        // Convert CSV state to chains format
        const allChains = Object.entries(csvState).map(([chain, accounts]) => ({
            assetRecoveryAddress: "0x0000000000000000000000000000000000000022",
            accounts: accounts.map(acc => ({
                accountAddress: acc.accountAddress,
                childContractScope: acc.childContractScope
            })),
            id: chain === "ETHEREUM" ? 1 : 0
        }));

        // Generate addChains calldata for all chains
        const addChainsCalldata = agreement.interface.encodeFunctionData("addChains", [allChains]);
        const addChainsPayload = {
            target: "0xa5c82ae35b653192d99c019a8eeaa159af0133e5",
            calldata: addChainsCalldata
        };

        // 4. Log all payloads
        console.log("\n1. Initial Contract Creation Payload:");
        console.log(JSON.stringify(createPayload, null, 2));

        console.log("\n2. Add All Chains Payload:");
        console.log(JSON.stringify(addChainsPayload, null, 2));

        // 5. Log the configuration that was used
        console.log("\nConfiguration used:");
        console.log("Protocol Name:", emptyDetails.protocolName);
        console.log("\nChains and Accounts:");
        allChains.forEach(chain => {
            console.log(`\nChain ID: ${chain.id}`);
            chain.accounts.forEach(account => {
                console.log(`  - ${account.accountAddress} (Factory: ${account.childContractScope === 3})`);
            });
        });

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
