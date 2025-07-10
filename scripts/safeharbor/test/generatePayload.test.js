import { test, describe, mock } from 'node:test';
import assert from 'node:assert';
import { 
  arraysEqual, 
  findArrayDifferences,
  calculateAccountDifferences 
} from '../src/generatePayload.js';

describe('generatePayload.js', () => {
  describe('arraysEqual', () => {
    test('should return true for two identical arrays', () => {
      assert.strictEqual(arraysEqual([1, 2, 3], [1, 2, 3]), true);
    });

    test('should return false for arrays with different lengths', () => {
      assert.strictEqual(arraysEqual([1, 2], [1, 2, 3]), false);
    });

    test('should return false for arrays with different elements', () => {
      assert.strictEqual(arraysEqual([1, 2, 3], [1, 2, 4]), false);
    });

    test('should return true for two empty arrays', () => {
      assert.strictEqual(arraysEqual([], []), true);
    });
  });

  describe('findArrayDifferences', () => {
    test('should find elements to add and remove correctly', () => {
      const current = ['a', 'b', 'c'];
      const desired = ['b', 'c', 'd'];
      const result = findArrayDifferences(current, desired);
      assert.deepStrictEqual(result.toAdd, ['d']);
      assert.deepStrictEqual(result.toRemove, ['a']);
    });

    test('should return empty arrays if no differences', () => {
      const current = ['a', 'b', 'c'];
      const desired = ['a', 'b', 'c'];
      const result = findArrayDifferences(current, desired);
      assert.deepStrictEqual(result.toAdd, []);
      assert.deepStrictEqual(result.toRemove, []);
    });
  });

  describe('findArrayDifferences', () => {
    test('should find elements to add and remove correctly', () => {
      const current = ['a', 'b', 'c'];
      const desired = ['b', 'c', 'd'];
      const result = findArrayDifferences(current, desired);
      assert.deepStrictEqual(result.toAdd, ['d']);
      assert.deepStrictEqual(result.toRemove, ['a']);
    });

    test('should return empty arrays if no differences', () => {
      const current = ['a', 'b', 'c'];
      const desired = ['a', 'b', 'c'];
      const result = findArrayDifferences(current, desired);
      assert.deepStrictEqual(result.toAdd, []);
      assert.deepStrictEqual(result.toRemove, []);
    });

    test('should handle all additions', () => {
      const current = [];
      const desired = ['a', 'b'];
      const result = findArrayDifferences(current, desired);
      assert.deepStrictEqual(result.toAdd, ['a', 'b']);
      assert.deepStrictEqual(result.toRemove, []);
    });

    test('should handle all removals', () => {
      const current = ['a', 'b'];
      const desired = [];
      const result = findArrayDifferences(current, desired);
      assert.deepStrictEqual(result.toAdd, []);
      assert.deepStrictEqual(result.toRemove, ['a', 'b']);
    });

    test('should handle empty arrays for both', () => {
      const current = [];
      const desired = [];
      const result = findArrayDifferences(current, desired);
      assert.deepStrictEqual(result.toAdd, []);
      assert.deepStrictEqual(result.toRemove, []);
    });
  });

  describe('calculateAccountDifferences', () => {
    test('should correctly identify accounts to add and remove', () => {
        const currentAccounts = [
            { accountAddress: '0xA', childContractScope: 0 },
            { accountAddress: '0xB', childContractScope: 0 },
        ];
        const desiredAccounts = [
            { accountAddress: '0xB', isFactory: false },
            { accountAddress: '0xC', isFactory: true }, // Added
        ];

        const result = calculateAccountDifferences(currentAccounts, desiredAccounts);
        assert.deepStrictEqual(result.toAdd, [{ accountAddress: '0xC', childContractScope: 3 }]);
        assert.deepStrictEqual(result.toRemove, ['0xA']);
    });

    test('should return empty arrays if no differences', () => {
        const currentAccounts = [
            { accountAddress: '0xA', childContractScope: 0 },
        ];
        const desiredAccounts = [
            { accountAddress: '0xA', isFactory: false },
        ];
        const result = calculateAccountDifferences(currentAccounts, desiredAccounts);
        assert.deepStrictEqual(result.toAdd, []);
        assert.deepStrictEqual(result.toRemove, []);
    });

    test('should handle only additions', () => {
        const currentAccounts = [];
        const desiredAccounts = [
            { accountAddress: '0xD', isFactory: false },
        ];
        const result = calculateAccountDifferences(currentAccounts, desiredAccounts);
        assert.deepStrictEqual(result.toAdd, [{ accountAddress: '0xD', childContractScope: 0 }]);
        assert.deepStrictEqual(result.toRemove, []);
    });

    test('should handle only removals', () => {
        const currentAccounts = [
            { accountAddress: '0xE', childContractScope: 0 },
        ];
        const desiredAccounts = [];
        const result = calculateAccountDifferences(currentAccounts, desiredAccounts);
        assert.deepStrictEqual(result.toAdd, []);
        assert.deepStrictEqual(result.toRemove, ['0xE']);
    });
  });
}); 
