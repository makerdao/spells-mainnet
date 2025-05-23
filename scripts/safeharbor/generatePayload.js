import fs from 'fs';
import { parse } from 'csv-parse/sync';
import { ethers } from 'ethers';
import fetch from 'node-fetch';

// Constants
const OWNER_ADDRESS = "0x195a7d8610edd06e0C27c006b6970319133Cb19A";
const AGREEMENT_ADDRESS = "0xA3E1b36D112a5cE365546F53Fa3af3e1310d6b5A";
const RPC_URL = "http://127.0.0.1:8545";
const CSV_URL = "https://docs.google.com/spreadsheets/d/1slHR9VbZOC3wp2ZQu7YbQEQh8N57ePfVvv0w35nz60Q/export?format=csv&gid=1121763694";

// ABI for AgreementV2
const AGREEMENT_ABI = [
    "function getDetails() view returns (tuple(string protocolName, tuple(string name, string contact)[] contactDetails, tuple(string assetRecoveryAddress, tuple(string accountAddress, uint8 childContractScope)[] accounts, uint256 id)[] chains, tuple(uint256 bountyPercentage, uint256 bountyCapUSD, bool retainable, uint8 identity, string diligenceRequirements) bountyTerms, string agreementURI))",
    "function addChains(tuple(string assetRecoveryAddress, tuple(string accountAddress, uint8 childContractScope)[] accounts, uint256 id)[] chains)",
    "function setChains(uint256[] chainIds, tuple(string assetRecoveryAddress, tuple(string accountAddress, uint8 childContractScope)[] accounts, uint256 id)[] chains)",
    "function removeChain(uint256 chainId)",
    "function addAccounts(uint256 chainId, tuple(string accountAddress, uint8 childContractScope)[] accounts)",
    "function setAccounts(uint256 chainId, uint256[] accountIds, tuple(string accountAddress, uint8 childContractScope)[] accounts)",
    "function removeAccount(uint256 chainId, uint256 accountId)"
];

// Helper function to compare arrays
export function arraysEqual(a, b) {
    if (a.length !== b.length) return false;
    return a.every((val, index) => val === b[index]);
}

// Helper function to find differences between arrays
export function findArrayDifferences(current, desired) {
    const toAdd = desired.filter(item => !current.includes(item));
    const toRemove = current.filter(item => !desired.includes(item));
    return { toAdd, toRemove };
}

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
    return records
        .filter(record => record.Status === 'ACTIVE')
        .reduce((groups, record) => {
            const chain = record.Chain;
            if (!groups[chain]) {
                groups[chain] = [];
            }
            groups[chain].push({
                accountAddress: record.Address,
                childContractScope: record.IsFactory === 'TRUE' ? 3 : 0,
                isFactory: record.IsFactory === 'TRUE'
            });
            return groups;
        }, {});
}

// Build internal representation from on-chain state
export function buildOnChainRepresentation(details) {
    return details.chains.reduce((groups, chain) => {
        const chainName = chain.id.toString() === "1" ? "ETHEREUM" : "OTHER";
        groups[chainName] = chain.accounts;
        return groups;
    }, {});
}

// Generate human-readable diffs
export function generateHumanReadableDiffs(csvState, onChainState) {
    const diffs = [];
    
    // Compare chains
    const csvChains = Object.keys(csvState);
    const onChainChains = Object.keys(onChainState);
    
    // Find chain differences
    const { toAdd: chainsToAdd, toRemove: chainsToRemove } = findArrayDifferences(onChainChains, csvChains);
    
    // Add chain diffs
    chainsToAdd.forEach(chain => {
        diffs.push(`Add chain ${chain} with ${csvState[chain].length} accounts:`);
        csvState[chain].forEach(account => {
            const factoryNote = account.isFactory ? ' (Factory)' : '';
            diffs.push(`  - Add ${account.accountAddress}${factoryNote}`);
        });
    });
    
    chainsToRemove.forEach(chain => {
        diffs.push(`Remove chain ${chain} with ${onChainState[chain].length} accounts`);
    });
    
    // Compare accounts for each common chain
    const commonChains = csvChains.filter(chain => onChainChains.includes(chain));
    commonChains.forEach(chain => {
        const csvAccounts = csvState[chain].map(acc => acc.accountAddress);
        const onChainAccounts = onChainState[chain].map(acc => acc.accountAddress);
        
        const { toAdd, toRemove } = findArrayDifferences(onChainAccounts, csvAccounts);
        
        toAdd.forEach(addr => {
            const account = csvState[chain].find(acc => acc.accountAddress === addr);
            const factoryNote = account.isFactory ? ' (Factory)' : '';
            diffs.push(`Add ${addr}${factoryNote} to ${chain}`);
        });
        
        toRemove.forEach(addr => {
            diffs.push(`Remove ${addr} from ${chain}`);
        });
    });
    
    return diffs;
}

// Data fetching and standardization
export async function fetchAgreementDetails() {
    const provider = new ethers.providers.JsonRpcProvider(RPC_URL);
    const agreement = new ethers.Contract(AGREEMENT_ADDRESS, AGREEMENT_ABI, provider);
    return await agreement.getDetails();
}

// Account difference calculation
export function calculateAccountDifferences(currentAccounts, desiredAccounts) {
    const accountDiff = findArrayDifferences(
        currentAccounts.map(account => account.accountAddress),
        desiredAccounts.map(contract => contract.accountAddress)
    );

    return {
        toAdd: accountDiff.toAdd.map(address => {
            const account = desiredAccounts.find(acc => acc.accountAddress === address);
            return {
                accountAddress: address,
                childContractScope: account.isFactory ? 3 : 0
            };
        }),
        toRemove: accountDiff.toRemove
    };
}

// Update payload generation
export function generateChainUpdates(currentChains, chainGroups) {
    const updates = [];
    const currentChainIds = currentChains.map(chain => chain.id.toString());
    const desiredChainIds = Object.entries(chainGroups).map(([chain, _]) => 
        chain === "ETHEREUM" ? "1" : "0"
    );
    const chainDiff = findArrayDifferences(currentChainIds, desiredChainIds);

    const provider = new ethers.providers.JsonRpcProvider(RPC_URL);
    const agreement = new ethers.Contract(AGREEMENT_ADDRESS, AGREEMENT_ABI, provider);

    for (const chainId of chainDiff.toRemove) {
        updates.push({
            function: "removeChain",
            args: [chainId],
            calldata: agreement.interface.encodeFunctionData("removeChain", [chainId])
        });
    }

    for (const chainId of chainDiff.toAdd) {
        const chainName = chainId === "1" ? "ETHEREUM" : "OTHER";
        const chainContracts = chainGroups[chainName] || [];
        
        const newChain = {
            assetRecoveryAddress: "0x0000000000000000000000000000000000000022",
            accounts: chainContracts,
            id: parseInt(chainId)
        };

        updates.push({
            function: "addChains",
            args: [[newChain]],
            calldata: agreement.interface.encodeFunctionData("addChains", [[newChain]])
        });
    }

    return updates;
}

export function generateAccountUpdates(currentChains, chainGroups) {
    const updates = [];
    const provider = new ethers.providers.JsonRpcProvider(RPC_URL);
    const agreement = new ethers.Contract(AGREEMENT_ADDRESS, AGREEMENT_ABI, provider);

    for (const [chainId, chain] of currentChains.entries()) {
        const chainName = chain.id.toString() === "1" ? "ETHEREUM" : "OTHER";
        const desiredAccounts = chainGroups[chainName] || [];
        const currentAccounts = chain.accounts;

        const { toAdd, toRemove } = calculateAccountDifferences(currentAccounts, desiredAccounts);
        
        // First, try to replace accounts in place
        const accountIds = [];
        const newAccounts = [];
        
        // Match removals with additions to replace in place
        const minLength = Math.min(toRemove.length, toAdd.length);
        for (let i = 0; i < minLength; i++) {
            const index = currentAccounts.findIndex(acc => acc.accountAddress === toRemove[i]);
            if (index !== -1) {
                accountIds.push(index);
                newAccounts.push(toAdd[i]);
            }
        }

        // If we have any replacements to make, do them first
        if (accountIds.length > 0) {
            updates.push({
                function: "setAccounts",
                args: [chainId, accountIds, newAccounts],
                calldata: agreement.interface.encodeFunctionData("setAccounts", [chainId, accountIds, newAccounts])
            });
        }

        // Handle remaining removals (if any)
        const remainingRemovals = toRemove.slice(minLength);
        if (remainingRemovals.length > 0) {
            const sortedIndices = remainingRemovals
                .map(addr => currentAccounts.findIndex(acc => acc.accountAddress === addr))
                .sort((a, b) => b - a);

            for (const index of sortedIndices) {
                updates.push({
                    function: "removeAccount",
                    args: [chainId, index],
                    calldata: agreement.interface.encodeFunctionData("removeAccount", [chainId, index])
                });
            }
        }

        // Handle remaining additions (if any)
        const remainingAdditions = toAdd.slice(minLength);
        if (remainingAdditions.length > 0) {
            updates.push({
                function: "addAccounts",
                args: [chainId, remainingAdditions],
                calldata: agreement.interface.encodeFunctionData("addAccounts", [chainId, remainingAdditions])
            });
        }
    }

    return updates;
}

// File I/O operations
export function saveUpdatesToFile(updates, filePath) {
    fs.writeFileSync(filePath, JSON.stringify(updates, null, 2));
}

// Main function
export async function generateUpdatePayload() {
    try {
        // 1. Download and parse CSV
        const records = await downloadAndParseCSV();
        const csvState = buildCSVRepresentation(records);
        
        // 2. Fetch on-chain state
        const currentDetails = await fetchAgreementDetails();
        const onChainState = buildOnChainRepresentation(currentDetails);
        
        // 3. Generate human-readable diffs
        const diffs = generateHumanReadableDiffs(csvState, onChainState);
        console.log("\nChanges to be made:");
        diffs.forEach(diff => console.log(diff));
        
        // 4. Generate updates
        const chainUpdates = generateChainUpdates(currentDetails.chains, csvState);
        const accountUpdates = generateAccountUpdates(currentDetails.chains, csvState);
        const updates = [...chainUpdates, ...accountUpdates];

        // 5. Save updates
        saveUpdatesToFile(updates, './agreement-updates.json');
        console.log("\nUpdates saved to agreement-updates.json");
        
        // 6. Display payload
        console.log("\nGenerated payload:");
        updates.forEach(update => {
            console.log(`\n${update.function}:`);
            console.log(update.calldata);
        });

        return updates;
    } catch (error) {
        console.error("Error generating update payload:", error);
        throw error;
    }
}

// Only run if this file is being executed directly
if (process.argv[1] === new URL(import.meta.url).pathname) {
    generateUpdatePayload();
} 
