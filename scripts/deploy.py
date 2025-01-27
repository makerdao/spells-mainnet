#! /usr/bin/env python3
import re, os, sys, subprocess

# Define static variables
CHAIN_ID            = '1'
OPTIMIZER_ENABLED   = 'false'
OPTIMIZER_RUNS      = '200'
PATH_TO_SPELL       = 'src/DssSpell.sol'
SPELL_CONTRACT_NAME = 'DssSpell'
PATH_TO_EXEC_LIB    = './DssExecLib.address'
SOLIDITY_USE        = 'solc:0.8.16'
PATH_TO_CONFIG      = 'src/test/config.sol'

# Read DssExecLib address
with open(PATH_TO_EXEC_LIB, 'r') as f:
    EXEC_LIB_ADDRESS = f.read().strip()
if not EXEC_LIB_ADDRESS:
    sys.exit(f'"{PATH_TO_EXEC_LIB}" file is empty or not found')

# Check for uncommitted changes
git_status = subprocess.run(['git', 'status', '--porcelain'], stdout=subprocess.PIPE, text=True, check=True).stdout.strip()
if git_status:
    sys.exit('There are uncommitted changes in the repository. Please commit or stash them before running this script')

# Check env ETH_RPC_URL is set
ETH_RPC_URL = os.environ.get('ETH_RPC_URL')
if not ETH_RPC_URL:
    sys.exit('Please set ETH_RPC_URL environment variable with RPC url')

# Check ETH_RPC_URL is correct
cast_chain_id = subprocess.run(['cast', 'chain-id'], stdout=subprocess.PIPE, text=True, check=True).stdout.strip()
if cast_chain_id != CHAIN_ID:
    sys.exit(f'Please provide correct ETH_RPC_URL. Currently set to chain id "{cast_chain_id}", expected "{CHAIN_ID}"')
print(f'Using chain id {cast_chain_id}')

# Check env ETHERSCAN_API_KEY is set
ETHERSCAN_API_KEY = os.environ.get('ETHERSCAN_API_KEY')
if not ETHERSCAN_API_KEY:
    sys.exit('Please set ETHERSCAN_API_KEY environment variable')

# Check env ETH_KEYSTORE is set
ETH_KEYSTORE = os.environ.get('ETH_KEYSTORE')
if not ETH_KEYSTORE:
    # Use `cast wallet import --interactive "keystore_name"`
    sys.exit('Please set ETH_KEYSTORE environment variable with path to the keystore')

# Deploy the spell
print('Deploying a spell...')
deploy_logs = subprocess.run([
    'forge', 'create',
    '--no-cache',
    '--broadcast',
    '--optimize', OPTIMIZER_ENABLED,
    '--optimizer-runs', OPTIMIZER_RUNS,
    '--use', SOLIDITY_USE,
    '--libraries', f'lib/dss-exec-lib/src/DssExecLib.sol:DssExecLib:{EXEC_LIB_ADDRESS}',
    '--keystore', ETH_KEYSTORE,
    f'{PATH_TO_SPELL}:{SPELL_CONTRACT_NAME}',
], stdout=subprocess.PIPE, text=True, check=True).stdout
print(deploy_logs)

# Get spell address
spell_address = re.search(r'Deployed to: (0x[a-f0-9]{40})', deploy_logs, re.IGNORECASE).group(1)
if not spell_address:
    sys.exit('Could not find address of the deployed spell in the output')
print(f'Extracted spell address: {spell_address}')

# Get spell transaction
tx_hash = re.search(r'Transaction hash: (0x[a-f0-9]{64})', deploy_logs, re.IGNORECASE).group(1)
if not tx_hash:
    sys.exit('Could not find transaction hash in the output')
print(f'Extracted transaction hash: {tx_hash}')

# Get deployed contract block number
tx_info = subprocess.run(['cast', 'tx', tx_hash], stdout=subprocess.PIPE, text=True, check=True).stdout.strip()
tx_block = re.search(r'blockNumber\s+([0-9]+)', tx_info, re.IGNORECASE).group(1)
print(f'Fetched transaction block: {tx_block}')

# Get deployed contract timestamp
block_info = subprocess.run(['cast', 'block', tx_block], stdout=subprocess.PIPE, text=True, check=True).stdout.strip()
tx_timestamp = re.search(r'timestamp\s+([0-9]+)', block_info, re.IGNORECASE).group(1)
print(f'Fetched transaction timestamp: {tx_timestamp}')

# Read config
with open(PATH_TO_CONFIG, 'r') as f:
    config_content = f.read()

# Edit config
print(f'Editing config file "{PATH_TO_CONFIG}"...')
config_content = re.sub(r'(\s*deployed_spell:\s*).*(,)', r'\g<1>address(' + spell_address + r')\g<2>', config_content)
config_content = re.sub(r'(\s*deployed_spell_block:\s*).*(,)', r'\g<1>' + tx_block + r'\g<2>', config_content)
config_content = re.sub(r'(\s*deployed_spell_created:\s*).*(,)', r'\g<1>' + tx_timestamp + r'\g<2>', config_content)

# Write back to config
with open(PATH_TO_CONFIG, 'w') as f:
    f.write(config_content)

# Verify the contract
subprocess.run([
    'make', 'verify',
    f'addr={spell_address}',
], check=True)

# Re-run the tests
print(f'Re-running the tests...')
test_logs = subprocess.run([
    'make', 'test',
    f'block="{tx_block}"',
], capture_output=True, text=True)
print(test_logs.stdout)

if test_logs.returncode != 0:
    print(test_logs.stdout)
    print('Ensure Tests PASS before commiting the `config.sol` changes!')
    exit(test_logs.returncode)

# Commit the changes
print('Commiting changes to the `config.sol`...')
subprocess.run([
    'git', 'commit',
    '-m', "add deployed spell info",
    '--', PATH_TO_CONFIG,
], check=True)
