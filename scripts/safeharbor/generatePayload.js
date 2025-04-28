import fs from 'fs';
import { parse } from 'csv-parse/sync';
import { ethers } from 'ethers';

// Constants
const OWNER_ADDRESS = "0x195a7d8610edd06e0C27c006b6970319133Cb19A";
const AGREEMENT_ADDRESS = "0xA3E1b36D112a5cE365546F53Fa3af3e1310d6b5A";
const RPC_URL = "http://127.0.0.1:8545";

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

// Data fetching and standardization
export async function fetchAgreementDetails() {
    const provider = new ethers.providers.JsonRpcProvider(RPC_URL);
    const agreement = new ethers.Contract(AGREEMENT_ADDRESS, AGREEMENT_ABI, provider);
    return await agreement.getDetails();
}

export function readAndParseCSV(filePath) {
    const fileContent = fs.readFileSync(filePath, 'utf-8');
    return parse(fileContent, {
        columns: true,
        skip_empty_lines: true
    });
}

export function standardizeChainData(records) {
    return records
        .filter(record => record.Status === 'ACTIVE')
        .reduce((groups, record) => {
            const chain = record.Chain;
            if (!groups[chain]) {
                groups[chain] = [];
            }
            groups[chain].push(record);
            return groups;
        }, {});
}

// Account difference calculation
export function calculateAccountDifferences(currentAccounts, desiredAccounts) {
    const accountDiff = findArrayDifferences(
        currentAccounts.map(account => account.accountAddress),
        desiredAccounts.map(contract => contract.Address)
    );

    return {
        toAdd: accountDiff.toAdd.map(address => ({
            accountAddress: address,
            childContractScope: 0
        })),
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
            accounts: chainContracts.map(contract => ({
                accountAddress: contract.Address,
                childContractScope: 0
            })),
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
                newAccounts.push({
                    accountAddress: toAdd[i],
                    childContractScope: 0
                });
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
                args: [chainId, remainingAdditions.map(addr => ({
                    accountAddress: addr,
                    childContractScope: 0
                }))],
                calldata: agreement.interface.encodeFunctionData("addAccounts", [chainId, remainingAdditions.map(addr => ({
                    accountAddress: addr,
                    childContractScope: 0
                }))])
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
        // 1. Fetch and standardize data
        const currentDetails = await fetchAgreementDetails();
        const records = readAndParseCSV('./active-contracts.csv');
        const chainGroups = standardizeChainData(records);

        // 2. Generate updates
        const chainUpdates = generateChainUpdates(currentDetails.chains, chainGroups);
        const accountUpdates = generateAccountUpdates(currentDetails.chains, chainGroups);
        const updates = [...chainUpdates, ...accountUpdates];

        // 3. Save updates
        saveUpdatesToFile(updates, './agreement-updates.json');
        console.log("Updates saved to agreement-updates.json");

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
