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
    identity: "2", // 2 corresponds to Named in IdentityRequirements enum
    retainable: false
};
const AGREEMENT_URI = "Agreement URI";
const ASSET_RECOVERY_ADDRESS = "0x0000000000000000000000000000000000000022";
const OWNER_ADDRESS = "0x195a7d8610edd06e0C27c006b6970319133Cb19A";

// Create interface from ABI
const iface = new ethers.utils.Interface([{
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
                    childContractScope: 0 // None in ChildContractScope enum
                })),
                id: chain === "ETHEREUM" ? 1 : 0
            }],
            bountyTerms: BOUNTY_TERMS,
            agreementURI: AGREEMENT_URI
        };

        // Encode the function call
        const calldata = iface.encodeFunctionData("create", [payload, OWNER_ADDRESS]); // Replace with actual owner address
        
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


// Execute the function
loadAndProcessContracts();
