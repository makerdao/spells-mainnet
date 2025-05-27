export const FACTORY_ABI = [{
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

export const AGREEMENTV2_ABI = [
    "function getDetails() view returns (tuple(string protocolName, tuple(string name, string contact)[] contactDetails, tuple(string assetRecoveryAddress, tuple(string accountAddress, uint8 childContractScope)[] accounts, uint256 id)[] chains, tuple(uint256 bountyPercentage, uint256 bountyCapUSD, bool retainable, uint8 identity, string diligenceRequirements) bountyTerms, string agreementURI))",
    "function addChains(tuple(string assetRecoveryAddress, tuple(string accountAddress, uint8 childContractScope)[] accounts, uint256 id)[] chains)",
    "function setChains(uint256[] chainIds, tuple(string assetRecoveryAddress, tuple(string accountAddress, uint8 childContractScope)[] accounts, uint256 id)[] chains)",
    "function removeChain(uint256 chainId)",
    "function addAccounts(uint256 chainId, tuple(string accountAddress, uint8 childContractScope)[] accounts)",
    "function setAccounts(uint256 chainId, uint256[] accountIds, tuple(string accountAddress, uint8 childContractScope)[] accounts)",
    "function removeAccount(uint256 chainId, uint256 accountId)"
];
