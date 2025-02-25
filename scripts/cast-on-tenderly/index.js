import 'dotenv/config';
import axios from 'axios';
import { Contract, ethers, utils } from 'ethers';
import { randomUUID } from 'crypto';

const NETWORK_ID = '1';
const CHAINLOG_ADDRESS = '0xdA0Ab1e0017DEbCd72Be8599041a2aa3bA7e740F';
const CHIEF_HAT_SLOT = 12;
const DEFAULT_TRANSACTION_PARAMETERS = { gasLimit: 1_000_000_000 };

// check env vars
const REQUIRED_ENV_VARS = ['ETH_RPC_URL', 'TENDERLY_USER', 'TENDERLY_PROJECT', 'TENDERLY_ACCESS_KEY'];
if (REQUIRED_ENV_VARS.some(varName => !process.env[varName])) {
    throw new Error(`Please provide all required env variables: ${REQUIRED_ENV_VARS.join(', ')}`);
}

// check process arguments
const SPELL_ADDRESS = process.argv[2];
if (!SPELL_ADDRESS) {
    throw new Error('Please provide address of the spell, e.g.: `node index.js 0x...`');
}

const getSpellName = async function (spellAddress) {
    const provider = new ethers.providers.JsonRpcProvider(process.env.ETH_RPC_URL);
    const spell = new Contract(
        spellAddress,
        ['function description() external view returns (string memory)'],
        provider
    );
    const description = await spell.description();
    return description.split('|')[0].trim();
};

const makeTenderlyApiRequest = async function ({ method, path, body }) {
    const API_BASE = `https://api.tenderly.co/api/v1/account/${process.env.TENDERLY_USER}/project/${process.env.TENDERLY_PROJECT}`;
    try {
        return await axios[method](`${API_BASE}${path}`, body, {
            headers: {
                'content-type': 'application/json',
                accept: 'application/json, text/plain, */*',
                'X-Access-Key': process.env.TENDERLY_ACCESS_KEY,
            },
        });
    } catch (error) {
        console.error('makeTenderlyApiRequest error', error.response);
        throw new Error(`tenderly request failed with: ${error.code}`);
    }
};

const createTenderlyTestnet = async function (spellName) {
    const slug = `${spellName.replace(/\s+/g, '-').toLowerCase()}-${randomUUID()}`;
    const response = await makeTenderlyApiRequest({
        method: 'post',
        path: '/testnet/container',
        body: {
            slug,
            displayName: spellName,
            description: spellName,
            networkConfig: {
                networkId: NETWORK_ID,
                blockNumber: 'latest',
                baseFeePerGas: '1',
                chainConfig: {
                    chainId: NETWORK_ID,
                },
            },
            explorerPage: 'DISABLED',
            syncState: true,
        },
    });
    const testnetId = response.data.container.id;
    const rpcEndpointPrivate = response.data.container.connectivityConfig.endpoints.find(
        endpoint => endpoint.private === true
    );
    console.info(`tenderly testnet "${testnetId}" is created`);
    return {
        testnetId,
        rpcUrlPrivate: rpcEndpointPrivate.uri,
    };
};

const publishTenderlyTestnet = async function (testnetId) {
    console.info(`making tenderly testnet "${testnetId}" public...`);
    const response = await makeTenderlyApiRequest({
        method: 'put',
        path: `/testnet/container/${testnetId}`,
        body: {
            explorerConfig: {
                enabled: true,
            },
        },
    });
    if (response.data?.container?.explorer_page !== 'ENABLED') {
        throw new Error('failed to publish testnet');
    }
    console.info(`tenderly testnet is now public and discoverable`);
    const rpcEndpointPublic = response.data.container.connectivityConfig.endpoints.find(
        endpoint => endpoint.private === false
    );
    const explorerUrlPublic = `https://dashboard.tenderly.co/explorer/vnet/${rpcEndpointPublic.id}`;
    console.info(`public explorer url: ${explorerUrlPublic}`);
    return { rpcUrlPrivate: rpcEndpointPublic.uri, explorerUrlPublic };
};

const giveTheHatToSpell = async function (spellAddress, provider) {
    console.info('fetching the chief address from chainlog...');
    const chainlog = new Contract(
        CHAINLOG_ADDRESS,
        ['function getAddress(bytes32) external view returns (address)'],
        provider.getSigner()
    );
    const chiefAddress = await chainlog.getAddress(ethers.utils.formatBytes32String('MCD_ADM'));

    console.info('overwriting the hat...');
    await provider.send('tenderly_setStorageAt', [
        chiefAddress,
        ethers.utils.hexZeroPad(ethers.utils.hexValue(CHIEF_HAT_SLOT), 32),
        ethers.utils.hexZeroPad(spellAddress, 32),
    ]);

    console.info('checking the hat...');
    const chief = new Contract(chiefAddress, ['function hat() external view returns (address)'], provider.getSigner());
    const hatAddress = await chief.hat();
    if (hatAddress !== spellAddress) {
        throw new Error('spell does not have the hat');
    }
    console.info('spell have the hat...');
};

const sheduleWarpAndCastSpell = async function (spellAddress, provider) {
    const spell = new Contract(
        spellAddress,
        [
            'function schedule() external',
            'function cast() external',
            'function nextCastTime() external view returns (uint256)',
        ],
        provider.getSigner()
    );

    console.info('scheduling the spell...');
    try {
        const scheduleTx = await spell.schedule(DEFAULT_TRANSACTION_PARAMETERS);
        await scheduleTx.wait();
    } catch (error) {
        console.warn('scheduling failed', error);
    }

    console.info('fetching timestamp when the spell will be castable...');
    const nextCastTime = await spell.nextCastTime();
    console.info(`nextCastTime is "${nextCastTime}"`, new Date(nextCastTime.toNumber() * 1000));

    console.info(`warping the time to "${nextCastTime}"...`);
    await provider.send('evm_setNextBlockTimestamp', [ethers.utils.hexValue(nextCastTime)]);

    console.info('casting spell...');
    try {
        const castTx = await spell.cast(DEFAULT_TRANSACTION_PARAMETERS);
        await castTx.wait();
        console.info('successfully casted');
    } catch (error) {
        console.error('casting failed', error);
    }
};

const castOnTenderly = async function (spellAddress) {
    const spellName = await getSpellName(spellAddress);
    console.info(`preparing to cast spell "${spellAddress}" with name "${spellName}"...`);

    const { testnetId, rpcUrlPrivate } = await createTenderlyTestnet(spellName);

    const provider = new ethers.providers.JsonRpcProvider(rpcUrlPrivate);

    await giveTheHatToSpell(spellAddress, provider);

    await sheduleWarpAndCastSpell(spellAddress, provider);

    await publishTenderlyTestnet(testnetId);
};

castOnTenderly(utils.getAddress(SPELL_ADDRESS));
