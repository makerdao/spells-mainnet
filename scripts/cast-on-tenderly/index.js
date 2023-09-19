import 'dotenv/config';
import axios from 'axios';
import { Contract, ethers } from 'ethers';

const NETWORK_ID = 5;
const CHAINLOG_ADDRESS = '0xdA0Ab1e0017DEbCd72Be8599041a2aa3bA7e740F';
const CHIEF_HAT_SLOT = 12;
const DEFAULT_TRANSACTION_PARAMETERS = { gasLimit: 1_000_000_000 };

// check env vars
const REQUIRED_ENV_VARS = ['TENDERLY_USER', 'TENDERLY_PROJECT', 'TENDERLY_ACCESS_KEY'];
if (REQUIRED_ENV_VARS.some(varName => !process.env[varName])) {
    throw new Error(`Please provide all required env variables: ${REQUIRED_ENV_VARS.join(', ')}`);
}

// check process arguments
const SPELL_ADDRESS = process.argv[2];
if (!SPELL_ADDRESS) {
    throw new Error('Please provide address of the spell, e.g.: `node index.js 0x...`');
}

const makeTenderlyApiRequest = async function (path) {
    const API_BASE = `https://api.tenderly.co/api/v1/account/${process.env.TENDERLY_USER}/project/${process.env.TENDERLY_PROJECT}`;
    return await axios.post(
        `${API_BASE}${path}`,
        { network_id: NETWORK_ID },
        { headers: { 'X-Access-Key': process.env.TENDERLY_ACCESS_KEY } }
    );
};

const createTenderlyFork = async function () {
    const response = await makeTenderlyApiRequest('/fork');
    const forkId = response.data.simulation_fork.id;
    const rpcUrl = `https://rpc.tenderly.co/fork/${forkId}`;
    const forkUrl = `https://dashboard.tenderly.co/${process.env.TENDERLY_USER}/${process.env.TENDERLY_PROJECT}/fork/${forkId}`;
    return { forkId, forkUrl, rpcUrl };
};

const publishTenderlyTransaction = async function (forkId, transactionId) {
    await makeTenderlyApiRequest(`/fork/${forkId}/transaction/${transactionId}/share`);
    return `https://dashboard.tenderly.co/shared/fork/simulation/${transactionId}`;
};

const runSpell = async function () {
    const { forkId, forkUrl, rpcUrl } = await createTenderlyFork();
    console.info('private tenderly fork is created', forkUrl);

    const provider = new ethers.providers.JsonRpcProvider(rpcUrl);
    const signer = provider.getSigner();

    console.info('fetching the chief address from chainlog...');
    const chainlog = new Contract(
        CHAINLOG_ADDRESS,
        ['function getAddress(bytes32) external view returns (address)'],
        signer
    );
    const chiefAddress = await chainlog.getAddress(ethers.utils.formatBytes32String('MCD_ADM'));

    console.info('overwriting the hat...');
    await provider.send('tenderly_setStorageAt', [
        chiefAddress,
        ethers.utils.hexZeroPad(ethers.utils.hexValue(CHIEF_HAT_SLOT), 32),
        ethers.utils.hexZeroPad(SPELL_ADDRESS, 32),
    ]);

    console.info('checking the hat...');
    const chief = new Contract(chiefAddress, ['function hat() external view returns (address)'], signer);
    const hatAddress = await chief.hat();
    if (hatAddress !== SPELL_ADDRESS) {
        throw new Error('spell does not have the hat');
    }

    const spell = new Contract(
        SPELL_ADDRESS,
        ['function schedule() external', 'function cast() external', 'function eta() external view returns (uint256)'],
        signer
    );
    console.info('scheduling spell on a fork...');
    try {
        const scheduleTx = await spell.schedule(DEFAULT_TRANSACTION_PARAMETERS);
        await scheduleTx.wait();
    } catch (error) {
        console.warn('scheduling failed', error);
    }

    console.info('fetching timestamp when the spell will be castable...');
    const eta = await spell.eta();

    console.info(`warping the time to "${eta}"...`);
    const currentUnixTimestamp = Math.floor(Date.now() / 1000);
    if (currentUnixTimestamp < eta) {
        const timestampDifference = eta - currentUnixTimestamp + 1;
        await provider.send('evm_increaseTime', [ethers.utils.hexValue(timestampDifference)]);
    }

    console.info('casting spell on a fork...');
    try {
        const castTx = await spell.cast(DEFAULT_TRANSACTION_PARAMETERS);
        await castTx.wait();
        console.info('successfully casted');
    } catch (error) {
        console.error('casting failed', error);
    }

    const lastTransactionId = await provider.send('evm_getLatest', []);
    const publicTransactionUrl = await publishTenderlyTransaction(forkId, lastTransactionId);
    console.info('publicly sharable transaction url', publicTransactionUrl);
};

runSpell();
