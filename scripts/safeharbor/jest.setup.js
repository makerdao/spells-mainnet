import { jest } from '@jest/globals';

jest.mock('ethers', () => ({
    ethers: {
        providers: {
            JsonRpcProvider: jest.fn(),
        },
        Contract: jest.fn(),
    },
})); 
