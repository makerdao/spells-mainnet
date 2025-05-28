import {
    ETHEREUM_ASSET_RECOVERY_ADDRESS,
    BASE_ASSET_RECOVERY_ADDRESS,
    ARBITRUM_ASSET_RECOVERY_ADDRESS,
    SOLANA_ASSET_RECOVERY_ADDRESS
} from '../constants.js';

// Chain ID mapping
export const CHAIN_IDS = {
    ETHEREUM: 1,
    BASE: 8453,
    GNOSIS: 100,
    ARBITRUM: 42161,
    SOLANA: 555
};

// Reverse mapping for chain ID to name
export const CHAIN_NAMES = Object.entries(CHAIN_IDS).reduce((acc, [name, id]) => {
    acc[id] = name;
    return acc;
}, {});

// Get chain ID from chain name
export function getChainId(chain) {
    return CHAIN_IDS[chain] || 0;
}

// Get chain name from chain ID
export function getChainName(chainId) {
    return CHAIN_NAMES[chainId] || 'UNKNOWN';
}

// Get asset recovery address for a chain
export function getAssetRecoveryAddress(chain) {
    switch(chain) {
        case "ETHEREUM":
            return ETHEREUM_ASSET_RECOVERY_ADDRESS;
        case "BASE":
            return BASE_ASSET_RECOVERY_ADDRESS;
        case "ARBITRUM":
            return ARBITRUM_ASSET_RECOVERY_ADDRESS;
        case "SOLANA":
            return SOLANA_ASSET_RECOVERY_ADDRESS;
        default:
            throw new Error(`No asset recovery address defined for chain: ${chain}`);
    }
} 
