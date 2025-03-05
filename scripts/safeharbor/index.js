import fs from 'fs';
import { parse } from 'csv-parse/sync';
import { ethers } from 'ethers';

// Constants to be filled later
const PROTOCOL_NAME = "Sky";
const CONTACT_DETAILS = [{
    name: "Contact Name",
    contact: "Contact@Info"
}];
const BOUNTY_TERMS = {
    bountyCapUSD: "10000000",
    bountyPercentage: "10",
    diligenceRequirements: "KYC and Sanctions Screening. Sky and Stars require all eligible whitehats to undergo Know Your Customer (KYC) verification and be screened against global sanctions lists, including OFAC, UK, and EU regulations. This ensures that bounty recipients meet legal and regulatory standards before qualifying for payment. The verification process shall be conducted by a trusted third-party provider at Sky and Stars discretion, and all data is deleted, if successful, within 30 days post-verification.",
    identity: "2",
    retainable: false
};
const AGREEMENT_URI = "Agreement URI";
const ASSET_RECOVERY_ADDRESS = "0x0000000000000000000000000000000000000022";

// Create interface from ABI
const iface = new ethers.utils.Interface([{
    "type": "function",
    "name": "adoptSafeHarbor",
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
                        { "name": "assetRecoveryAddress", "type": "address" },
                        {
                            "name": "accounts",
                            "type": "tuple[]",
                            "components": [
                                { "name": "accountAddress", "type": "address" },
                                { "name": "childContractScope", "type": "uint8" },
                                { "name": "signature", "type": "bytes" }
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
        }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
}]);

function loadAndProcessContracts() {
    // Read and parse CSV
    const fileContent = fs.readFileSync('./active-contracts.csv', 'utf-8');
    const records = parse(fileContent, {
        columns: true,
        skip_empty_lines: true
    });

    // Filter active contracts and group by chain
    const chainGroups = records
        .filter(record => record.Status === 'ACTIVE')
        .reduce((groups, record) => {
            const chain = record.Chain;
            if (!groups[chain]) {
                groups[chain] = [];
            }
            groups[chain].push(record);
            return groups;
        }, {});

    // Create payload for each chain
    Object.entries(chainGroups).forEach(([chain, contracts]) => {
        // Ignore SOLANA for now
        if (chain == "SOLANA") {
            return;
        }
        const payload = {
            protocolName: PROTOCOL_NAME,
            contactDetails: CONTACT_DETAILS,
            chains: [{
                assetRecoveryAddress: ASSET_RECOVERY_ADDRESS,
                accounts: contracts.map(contract => ({
                    accountAddress: contract.Address,
                    childContractScope: 0,
                    signature: "0x"
                })),
                id: chain === "ETHEREUM" ? 1 : 0
            }],
            bountyTerms: BOUNTY_TERMS,
            agreementURI: AGREEMENT_URI
        };

        // Encode the function call
        const calldata = iface.encodeFunctionData("adoptSafeHarbor", [payload]);
        
        console.log(`\nCalldata for ${chain}:`);
        console.log(calldata);
    });
}

// Convert string values to numbers
const BOUNTY_TERMS_NUMERIC = {
    ...BOUNTY_TERMS,
    bountyCapUSD: Number(BOUNTY_TERMS.bountyCapUSD),
    bountyPercentage: Number(BOUNTY_TERMS.bountyPercentage),
    identity: Number(BOUNTY_TERMS.identity)
};

// New function to output JSON format for verification
function exportJsonForVerification() {
    // Read and parse CSV
    const fileContent = fs.readFileSync('./active-contracts.csv', 'utf-8');
    const records = parse(fileContent, {
        columns: true,
        skip_empty_lines: true
    });

    // Filter active contracts and group by chain
    const chainGroups = records
        .filter(record => record.Status === 'ACTIVE')
        .reduce((groups, record) => {
            const chain = record.Chain;
            if (!groups[chain]) {
                groups[chain] = [];
            }
            groups[chain].push(record);
            return groups;
        }, {});

    // Create JSON output for each chain
    Object.entries(chainGroups).forEach(([chain, contracts]) => {
        // Ignore SOLANA for now
        if (chain == "SOLANA") {
            return;
        }

        const jsonOutput = {
            agreementURI: AGREEMENT_URI,
            bountyTerms: {
                bountyCapUSD: BOUNTY_TERMS_NUMERIC.bountyCapUSD,
                bountyPercentage: BOUNTY_TERMS_NUMERIC.bountyPercentage,
                diligenceRequirements: BOUNTY_TERMS_NUMERIC.diligenceRequirements,
                identity: BOUNTY_TERMS_NUMERIC.identity,
                retainable: BOUNTY_TERMS_NUMERIC.retainable
            },
            chains: [{
                accounts: contracts.map(contract => ({
                    accountAddress: contract.Address,
                    childContractScope: 0,
                    signature: "0x"
                })),
                assetRecoveryAddress: ASSET_RECOVERY_ADDRESS,
                id: chain === "ETHEREUM" ? 1 : 0
            }],
            contactDetails: CONTACT_DETAILS,
            protocolName: PROTOCOL_NAME
        };

        // Write to JSON file
        fs.writeFileSync(`./verification-${chain.toLowerCase()}.json`, JSON.stringify(jsonOutput, null, 2));
        console.log(`\nJSON verification file created for ${chain}: verification-${chain.toLowerCase()}.json`);
    });
}

// Execute the function
loadAndProcessContracts();
exportJsonForVerification();
