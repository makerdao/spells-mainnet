import fs from 'fs';
import { parse } from 'csv-parse/sync';
import { ethers } from 'ethers';

// Constants
const OWNER_ADDRESS = "0x195a7d8610edd06e0C27c006b6970319133Cb19A";
const AGREEMENT_ADDRESS = "0x0000000000000000000000000000000000000000"; // Replace with actual agreement address
const RPC_URL = "https://mainnet.infura.io/v3/YOUR-API-KEY"; // Replace with your RPC URL

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

// Create provider and contract instance
const provider = new ethers.providers.JsonRpcProvider(RPC_URL);
const agreement = new ethers.Contract(AGREEMENT_ADDRESS, AGREEMENT_ABI, provider);

// Helper function to compare arrays
function arraysEqual(a, b) {
    if (a.length !== b.length) return false;
    return a.every((val, index) => val === b[index]);
}

// Helper function to find differences between arrays
function findArrayDifferences(current, desired) {
    const toAdd = desired.filter(item => !current.includes(item));
    const toRemove = current.filter(item => !desired.includes(item));
    return { toAdd, toRemove };
}

async function generateUpdatePayload() {
    try {
        // 1. Fetch current agreement details
        const currentDetails = await agreement.getDetails();
        console.log("Current agreement details fetched");

        // 2. Read and parse CSV
        const fileContent = fs.readFileSync('./active-contracts.csv', 'utf-8');
        const records = parse(fileContent, {
            columns: true,
            skip_empty_lines: true
        });

        // 3. Process CSV data
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

        // 4. Compare and generate updates
        const updates = [];

        // Compare chains
        const currentChainIds = currentDetails.chains.map(chain => chain.id.toString());
        const desiredChainIds = Object.entries(chainGroups).map(([chain, _]) => 
            chain === "ETHEREUM" ? "1" : "0"
        );

        const chainDiff = findArrayDifferences(currentChainIds, desiredChainIds);

        // Generate chain updates
        for (const chainId of chainDiff.toRemove) {
            updates.push({
                function: "removeChain",
                args: [chainId],
                calldata: agreement.interface.encodeFunctionData("removeChain", [chainId])
            });
        }

        // For chains to add, we'll create new chain objects
        for (const chainId of chainDiff.toAdd) {
            const chainName = chainId === "1" ? "ETHEREUM" : "OTHER";
            const chainContracts = chainGroups[chainName] || [];
            
            const newChain = {
                assetRecoveryAddress: "0x0000000000000000000000000000000000000022", // Replace with actual address
                accounts: chainContracts.map(contract => ({
                    accountAddress: contract.Address,
                    childContractScope: 0 // None in ChildContractScope enum
                })),
                id: parseInt(chainId)
            };

            updates.push({
                function: "addChains",
                args: [[newChain]],
                calldata: agreement.interface.encodeFunctionData("addChains", [[newChain]])
            });
        }

        // Compare accounts for each existing chain
        for (const [chainId, chain] of currentDetails.chains.entries()) {
            const chainName = chain.id === 1 ? "ETHEREUM" : "OTHER";
            const desiredAccounts = (chainGroups[chainName] || []).map(contract => contract.Address);
            const currentAccounts = chain.accounts.map(account => account.accountAddress);

            const accountDiff = findArrayDifferences(currentAccounts, desiredAccounts);

            // Calculate the net change in number of accounts
            const netChange = accountDiff.toAdd.length - accountDiff.toRemove.length;

            if (netChange === 0) {
                // If the number of accounts stays the same, use setAccounts
                const accountIds = [];
                const newAccounts = [];

                // First, handle accounts that need to be replaced
                for (const address of accountDiff.toRemove) {
                    const index = currentAccounts.indexOf(address);
                    if (index !== -1) {
                        accountIds.push(index);
                        newAccounts.push({
                            accountAddress: accountDiff.toAdd[accountIds.length - 1],
                            childContractScope: 0
                        });
                    }
                }

                if (accountIds.length > 0) {
                    updates.push({
                        function: "setAccounts",
                        args: [chainId, accountIds, newAccounts],
                        calldata: agreement.interface.encodeFunctionData("setAccounts", [chainId, accountIds, newAccounts])
                    });
                }
            } else {
                // If we need to add or remove accounts, handle that first
                if (accountDiff.toRemove.length > 0) {
                    // Remove accounts in reverse order to maintain correct indices
                    const sortedIndices = accountDiff.toRemove
                        .map(addr => currentAccounts.indexOf(addr))
                        .sort((a, b) => b - a); // Sort in descending order

                    for (const index of sortedIndices) {
                        updates.push({
                            function: "removeAccount",
                            args: [chainId, index],
                            calldata: agreement.interface.encodeFunctionData("removeAccount", [chainId, index])
                        });
                    }
                }

                if (accountDiff.toAdd.length > 0) {
                    const newAccounts = accountDiff.toAdd.map(address => ({
                        accountAddress: address,
                        childContractScope: 0
                    }));

                    updates.push({
                        function: "addAccounts",
                        args: [chainId, newAccounts],
                        calldata: agreement.interface.encodeFunctionData("addAccounts", [chainId, newAccounts])
                    });
                }
            }
        }

        // 5. Output the updates
        console.log("\nGenerated updates:");
        updates.forEach((update, index) => {
            console.log(`\nUpdate ${index + 1}:`);
            console.log(`Function: ${update.function}`);
            console.log(`Arguments: ${JSON.stringify(update.args, null, 2)}`);
            console.log(`Calldata: ${update.calldata}`);
        });

        // 6. Save updates to file
        fs.writeFileSync(
            './agreement-updates.json',
            JSON.stringify(updates, null, 2)
        );
        console.log("\nUpdates saved to agreement-updates.json");

    } catch (error) {
        console.error("Error generating update payload:", error);
    }
}

// Execute the function
generateUpdatePayload(); 
