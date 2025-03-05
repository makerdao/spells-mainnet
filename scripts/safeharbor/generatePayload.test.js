import { jest, describe, test, expect } from '@jest/globals';
import { ethers } from 'ethers';
import {
    findArrayDifferences,
    calculateAccountDifferences,
    standardizeChainData,
    generateChainUpdates,
    generateAccountUpdates
} from './generatePayload.js';

// Mock ethers provider and contract
jest.mock('ethers', () => ({
    ethers: {
        providers: {
            JsonRpcProvider: jest.fn(),
        },
        Contract: jest.fn(),
    },
}));

describe('Array Difference Functions', () => {
    test('findArrayDifferences should correctly identify additions and removals', () => {
        const current = ['a', 'b', 'c'];
        const desired = ['b', 'c', 'd'];
        
        const result = findArrayDifferences(current, desired);
        
        expect(result.toAdd).toEqual(['d']);
        expect(result.toRemove).toEqual(['a']);
    });

    test('findArrayDifferences should handle empty arrays', () => {
        const current = [];
        const desired = ['a', 'b'];
        
        const result = findArrayDifferences(current, desired);
        
        expect(result.toAdd).toEqual(['a', 'b']);
        expect(result.toRemove).toEqual([]);
    });
});

describe('Account Difference Calculation', () => {
    test('calculateAccountDifferences should correctly format account differences', () => {
        const currentAccounts = [
            { accountAddress: '0x1', childContractScope: 0 },
            { accountAddress: '0x2', childContractScope: 0 }
        ];
        
        const desiredAccounts = [
            { Address: '0x2' },
            { Address: '0x3' }
        ];
        
        const result = calculateAccountDifferences(currentAccounts, desiredAccounts);
        
        expect(result.toAdd).toEqual([
            { accountAddress: '0x3', childContractScope: 0 }
        ]);
        expect(result.toRemove).toEqual(['0x1']);
    });
});

describe('Chain Data Standardization', () => {
    test('standardizeChainData should correctly group records by chain', () => {
        const records = [
            { Chain: 'ETHEREUM', Status: 'ACTIVE', Address: '0x1' },
            { Chain: 'ETHEREUM', Status: 'ACTIVE', Address: '0x2' },
            { Chain: 'OTHER', Status: 'ACTIVE', Address: '0x3' },
            { Chain: 'ETHEREUM', Status: 'INACTIVE', Address: '0x4' }
        ];
        
        const result = standardizeChainData(records);
        
        expect(result.ETHEREUM).toHaveLength(2);
        expect(result.OTHER).toHaveLength(1);
        expect(result.ETHEREUM[0].Address).toBe('0x1');
        expect(result.ETHEREUM[1].Address).toBe('0x2');
        expect(result.OTHER[0].Address).toBe('0x3');
    });
});

describe('Chain Updates Generation', () => {
    test('generateChainUpdates should create correct chain updates', () => {
        const currentChains = [
            { id: '1', accounts: [] },
            { id: '2', accounts: [] }
        ];
        
        const chainGroups = {
            ETHEREUM: [{ Address: '0x1' }]
        };
        
        // Mock the contract interface
        const mockInterface = {
            encodeFunctionData: jest.fn().mockImplementation((fn, args) => `encoded_${fn}_${args.join('_')}`)
        };
        
        const mockContract = {
            interface: mockInterface
        };
        
        ethers.Contract.mockImplementation(() => mockContract);
        
        const updates = generateChainUpdates(currentChains, chainGroups);
        
        // We expect one update to remove chain 2 and no other updates since chain 1 (ETHEREUM) already exists
        expect(updates).toHaveLength(1);
        expect(updates[0].function).toBe('removeChain');
        expect(updates[0].args[0]).toBe('2');
    });
});

describe('Account Updates Generation', () => {
    test('generateAccountUpdates should replace accounts in place when possible', () => {
        const currentChains = [
            {
                id: '1',
                accounts: [
                    { accountAddress: '0x1', childContractScope: 0 },
                    { accountAddress: '0x2', childContractScope: 0 }
                ]
            }
        ];
        
        const chainGroups = {
            ETHEREUM: [
                { Address: '0x2' },
                { Address: '0x3' }
            ]
        };
        
        // Mock the contract interface
        const mockInterface = {
            encodeFunctionData: jest.fn().mockImplementation((fn, args) => `encoded_${fn}_${args.join('_')}`)
        };
        
        const mockContract = {
            interface: mockInterface
        };
        
        ethers.Contract.mockImplementation(() => mockContract);
        
        const updates = generateAccountUpdates(currentChains, chainGroups);
        
        // We expect one update to replace 0x1 with 0x3 using setAccounts
        expect(updates).toHaveLength(1);
        expect(updates[0].function).toBe('setAccounts');
        expect(updates[0].args[0]).toBe(0); // chainId
        expect(updates[0].args[1]).toEqual([0]); // accountIds
        expect(updates[0].args[2]).toEqual([{ accountAddress: { accountAddress: '0x3', childContractScope: 0 }, childContractScope: 0 }]); // newAccounts
    });

    test('generateAccountUpdates should handle more removals than additions', () => {
        const currentChains = [
            {
                id: '1',
                accounts: [
                    { accountAddress: '0x1', childContractScope: 0 },
                    { accountAddress: '0x2', childContractScope: 0 },
                    { accountAddress: '0x3', childContractScope: 0 }
                ]
            }
        ];
        
        const chainGroups = {
            ETHEREUM: [
                { Address: '0x4' }
            ]
        };
        
        const mockInterface = {
            encodeFunctionData: jest.fn().mockImplementation((fn, args) => `encoded_${fn}_${args.join('_')}`)
        };
        
        const mockContract = {
            interface: mockInterface
        };
        
        ethers.Contract.mockImplementation(() => mockContract);
        
        const updates = generateAccountUpdates(currentChains, chainGroups);
        
        // We expect three updates:
        // 1. Replace 0x1 with 0x4 using setAccounts
        // 2. Remove 0x2 and 0x3
        expect(updates).toHaveLength(3);
        expect(updates[0].function).toBe('setAccounts');
        expect(updates[0].args[0]).toBe(0);
        expect(updates[0].args[1]).toEqual([0]);
        expect(updates[0].args[2]).toEqual([{ accountAddress: { accountAddress: '0x4', childContractScope: 0 }, childContractScope: 0 }]);
        
        expect(updates[1].function).toBe('removeAccount');
        expect(updates[2].function).toBe('removeAccount');
    });

    test('generateAccountUpdates should handle more additions than removals', () => {
        const currentChains = [
            {
                id: '1',
                accounts: [
                    { accountAddress: '0x1', childContractScope: 0 }
                ]
            }
        ];
        
        const chainGroups = {
            ETHEREUM: [
                { Address: '0x2' },
                { Address: '0x3' },
                { Address: '0x4' }
            ]
        };
        
        const mockInterface = {
            encodeFunctionData: jest.fn().mockImplementation((fn, args) => `encoded_${fn}_${args.join('_')}`)
        };
        
        const mockContract = {
            interface: mockInterface
        };
        
        ethers.Contract.mockImplementation(() => mockContract);
        
        const updates = generateAccountUpdates(currentChains, chainGroups);
        
        // We expect two updates:
        // 1. Replace 0x1 with 0x2 using setAccounts
        // 2. Add 0x3 and 0x4
        expect(updates).toHaveLength(2);
        expect(updates[0].function).toBe('setAccounts');
        expect(updates[0].args[0]).toBe(0);
        expect(updates[0].args[1]).toEqual([0]);
        expect(updates[0].args[2]).toEqual([{ accountAddress: { accountAddress: '0x2', childContractScope: 0 }, childContractScope: 0 }]);
        
        expect(updates[1].function).toBe('addAccounts');
        expect(updates[1].args[1]).toEqual([
            { accountAddress: { accountAddress: '0x3', childContractScope: 0 }, childContractScope: 0 },
            { accountAddress: { accountAddress: '0x4', childContractScope: 0 }, childContractScope: 0 }
        ]);
    });

    test('generateAccountUpdates should handle no changes needed', () => {
        const currentChains = [
            {
                id: '1',
                accounts: [
                    { accountAddress: '0x1', childContractScope: 0 },
                    { accountAddress: '0x2', childContractScope: 0 }
                ]
            }
        ];
        
        const chainGroups = {
            ETHEREUM: [
                { Address: '0x1' },
                { Address: '0x2' }
            ]
        };
        
        const mockInterface = {
            encodeFunctionData: jest.fn().mockImplementation((fn, args) => `encoded_${fn}_${args.join('_')}`)
        };
        
        const mockContract = {
            interface: mockInterface
        };
        
        ethers.Contract.mockImplementation(() => mockContract);
        
        const updates = generateAccountUpdates(currentChains, chainGroups);
        
        // No updates should be generated
        expect(updates).toHaveLength(0);
    });
}); 
