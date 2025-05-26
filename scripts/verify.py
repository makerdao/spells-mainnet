#! /usr/bin/env python3

import os, sys, subprocess
import re
import json
from typing import Dict, Any, Tuple, Optional

# Constants
LIBRARY_NAME = 'DssExecLib'
LIBRARY_PATH = 'lib/dss-exec-lib/src/DssExecLib.sol'
SOURCE_FILE_PATH = 'src/DssSpell.sol'

def get_env_var(var_name: str, error_message: str) -> str:
    """
    Get environment variable with error handling.
    """
    try:
        return os.environ[var_name]
    except KeyError:
        print(f"  {error_message}", file=sys.stderr)
        sys.exit(1)

def parse_command_line_args() -> Tuple[str, str, str]:
    """
    Parse command line arguments.
    """
    if len(sys.argv) not in [3, 4]:
        print("""usage:\n
./verify.py <contractname> <address> [constructorArgs]
""", file=sys.stderr)
        sys.exit(1)

    contract_name = sys.argv[1]
    contract_address = sys.argv[2]

    if len(contract_address) != 42:
        sys.exit('Malformed address')

    constructor_args = ''
    if len(sys.argv) == 4:
        constructor_args = sys.argv[3]

    return contract_name, contract_address, constructor_args

def get_chain_id() -> str:
    """
    Get the current chain ID.
    """
    print('Obtaining chain ID... ')
    result = subprocess.run(['cast', 'chain-id'], capture_output=True)
    chain_id = result.stdout.decode('utf-8').strip()
    print(f"CHAIN_ID: {chain_id}")
    return chain_id

def get_library_address() -> str:
    """
    Find the DssExecLib address from either DssExecLib.address file or foundry.toml.
    Returns an empty string if no library address is found.
    """
    library_address = ''

    # First try to read from foundry.toml libraries
    if os.path.exists('foundry.toml'):
        try:
            with open('foundry.toml', 'r') as f:
                config = f.read()

            result = re.search(r':DssExecLib:(0x[0-9a-fA-F]{40})', config)
            if result:
                library_address = result.group(1)
                print(
                    f'Using library {LIBRARY_NAME} at address {library_address}')
                return library_address
            else:
                print('No DssExecLib configured in foundry.toml', file=sys.stderr)
        except Exception as e:
            print(f'Error reading foundry.toml: {str(e)}', file=sys.stderr)
    else:
        print('No foundry.toml found', file=sys.stderr)

    # If it cannot be found, try DssExecLib.address
    if os.path.exists('DssExecLib.address'):
        try:
            print(f'Trying to read DssExecLib.address...', file=sys.stderr)
            with open('DssExecLib.address', 'r') as f:
                library_address = f.read().strip()
            print(f'Using library {LIBRARY_NAME} at address {library_address}')
            return library_address
        except Exception as e:
            print(
                f'Error reading DssExecLib.address: {str(e)}', file=sys.stderr)

    # If we get here, no library address was found
    print('WARNING: Assuming this contract uses no libraries', file=sys.stderr)
    return ''

def get_action_address(spell_address: str) -> Optional[str]:
    """
    Get the action contract address from the spell contract.
    """
    try:
        result = subprocess.run(
            ['cast', 'call', spell_address, 'action()(address)'],
            capture_output=True,
            env=os.environ | {
                'ETH_GAS_PRICE': '0',
                'ETH_PRIO_FEE': '0'
            }
        )
        return result.stdout.decode('utf-8').strip()
    except Exception as e:
        print(f'Error getting action address: {str(e)}', file=sys.stderr)
        return None

def get_contract_metadata(output_path: str) -> Dict[str, Any]:
    """
    Extract contract metadata from the compiled output.
    """
    try:
        with open(output_path, 'r') as f:
            content = json.load(f)

        metadata = content['metadata']

        return {
            'compiler_version': 'v' + metadata['compiler']['version'],
            'evm_version': metadata['settings']['evmVersion'],
            'optimizer_enabled': metadata['settings']['optimizer']['enabled'],
            'optimizer_runs': metadata['settings']['optimizer']['runs'],
        }
    except FileNotFoundError:
        raise Exception('Run forge build first')
    except json.decoder.JSONDecodeError:
        raise Exception('Run forge build again')
    except KeyError as e:
        raise Exception(f'Missing metadata field: {e}')

def verify_contract(
    contract_name: str,
    contract_address: str,
    input_path: str,
    output_path: str,
    chain_id: str,
    library_address: str,
    verifier: str
) -> bool:
    """
    Verify a contract on Etherscan.
    """
    print(f'\nVerifying {contract_name} at {contract_address} on {verifier}...')

    # Construct contract format
    contract = input_path + ':' + contract_name

    # Construct library format
    library_option = LIBRARY_PATH + ':' + LIBRARY_NAME + ':' + library_address

    # Get contract metadata
    metadata = get_contract_metadata(output_path)
    compiler = metadata['compiler_version']
    runs = str(metadata['optimizer_runs'])

    #Verify on etherscan, this will automatically verify the contract on blocksout
    response = subprocess.run([
        'forge',
        'verify-contract',
        contract_address,
        contract,
        '--libraries', library_option,
        '--compiler-version', compiler,
        '--optimizer-runs', runs,
        '--chain', chain_id,
        '--verifier', verifier,
        '--force',
        "--json",
        '--watch'
    ])

    if response == None:
            print ("Error during verification")
            return False
    else:
        if response.returncode == 0:
            return True
        else:
            return False


def main():
    """
    Main entry point for the script.
    """
    try:
        # Get environment variables
        api_key = get_env_var(
            'ETHERSCAN_API_KEY',
            "You need an Etherscan API key to verify contracts.\n"
            "Create one at https://etherscan.io/myapikey\n"
            "Then export it with `export ETHERSCAN_API_KEY=xxxxxxxx'"
        )

        rpc_url = get_env_var(
            'ETH_RPC_URL',
            "You need a valid ETH_RPC_URL.\n"
            "Get a public one at https://chainlist.org/ or provide your own\n"
            "Then export it with `export ETH_RPC_URL=https://....'"
        )

        # Parse command line arguments
        spell_name, spell_address, constructor_args = parse_command_line_args()

        # Get chain ID
        chain_id = get_chain_id()

        # Get library address
        library_address = get_library_address()

        # Count in how many different explorers the contract was verified; min: 2/3
        num_verifications_spell = 0
        num_verifications_action = 0

        # Verify Spell contract on Etherscan
        verified = verify_contract(
            contract_name=spell_name,
            contract_address=spell_address,
            input_path=SOURCE_FILE_PATH,
            output_path=f'out/DssSpell.sol/DssSpell.json',
            chain_id=chain_id,
            library_address=library_address,
            verifier="etherscan"
            )

        if verified:
            num_verifications_spell += 1

        # Get and verify action contract on Etherscan
        action_address = get_action_address(spell_address)
        if not action_address:
            print('Could not determine action contract address', file=sys.stderr)
            return

        verify_contract(
            contract_name="DssSpellAction",
            contract_address=action_address,
            input_path=SOURCE_FILE_PATH,
            output_path=f'out/DssSpell.sol/DssSpell.json',
            chain_id=chain_id,
            library_address=library_address,
            verifier="etherscan"
        )

        if verified:
            num_verifications_action += 1

        # This is needed in order to verify the contract outside of Etherscan
        os.environ.pop("ETHERSCAN_API_KEY")

        # Verify Spell contract on Blockscout
        # verified = verify_contract(
        #     contract_name=spell_name,
        #     contract_address=spell_address,
        #     input_path=SOURCE_FILE_PATH,
        #     output_path=f'out/DssSpell.sol/DssSpell.json',
        #     chain_id=chain_id,
        #     library_address=library_address,
        #     verifier="blockscout"
        #     )

        # if verified:
        #     num_verifications_spell += 1

        # Verify action contract on Blockscout
        # verify_contract(
        #     contract_name="DssSpellAction",
        #     contract_address=action_address,
        #     input_path=SOURCE_FILE_PATH,
        #     output_path=f'out/DssSpell.sol/DssSpell.json',
        #     chain_id=chain_id,
        #     library_address=library_address,
        #     verifier="blockscout"
        # )

        # if verified:
            # num_verifications_action += 1

         # Verify Spell contract on Sourcify
        verify_contract(
            contract_name=spell_name,
            contract_address=spell_address,
            input_path=SOURCE_FILE_PATH,
            output_path=f'out/DssSpell.sol/DssSpell.json',
            chain_id=chain_id,
            library_address=library_address,
            verifier="sourcify"
        )

        if verified:
            num_verifications_spell += 1

        # Verify action contract on Sourcify
        verify_contract(
            contract_name="DssSpellAction",
            contract_address=action_address,
            input_path=SOURCE_FILE_PATH,
            output_path=f'out/DssSpell.sol/DssSpell.json',
            chain_id=chain_id,
            library_address=library_address,
            verifier="sourcify"
        )

        if verified:
            num_verifications_action += 1

        print('\Contracts verified on' + str(num_verifications_spell) + ' and ' +
              str(num_verifications_action) + ' explorers, respectively')

    except Exception as e:
        print(f'\nError: {str(e)}', file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
