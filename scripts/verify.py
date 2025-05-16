#! /usr/bin/env python3

import os, sys, subprocess, time, re, json, requests
from datetime import datetime

api_key = ''
try:
    api_key = os.environ['ETHERSCAN_API_KEY']
except KeyError:
    print('''  You need an Etherscan Api Key to verify contracts.
  Create one at https://etherscan.io/myapikey\n
  Then export it with `export ETHERSCAN_API_KEY=xxxxxxxx'
''')
    exit()

if len(sys.argv) not in [3, 4]:
    print('''usage:\n
./verify.py <contractname> <address> [constructorArgs]
''')
    exit()

spell_contract_name = sys.argv[1]
spell_contract_address = sys.argv[2]
print('Attempting to verify contract {0} at address {1} ...'.format(
    spell_contract_name,
    spell_contract_address
))

if len(spell_contract_address) !=  42:
    exit('malformed address')
constructor_arguments = ''
if len(sys.argv) == 4:
    constructor_arguments = sys.argv[3]

cast_call_actions = subprocess.run(['cast', 'call', spell_contract_address, 'action()(address)'], capture_output = True, env = os.environ | {
    'ETH_GAS_PRICE': '0',
    'ETH_PRIO_FEE': '0'
})
action_contract_name = "DssSpellAction"
action_contract_address = cast_call_actions.stdout.decode('utf-8')[:-1]

print('Spell DssAction address: ' + action_contract_address)

module = 'contract'
action = 'verifysourcecode'
code_format = 'solidity-single-file'

flatten_output_path = 'out/flat.sol'
subprocess.run([
    'forge',
    'flatten',
    'src/DssSpell.sol',
    '--output',
    flatten_output_path
])

with open(flatten_output_path, 'r', encoding='utf-8') as code_file:
    code = code_file.read()

def get_block(signature, code, with_frame=False):
    block_and_tail = code[code.find(signature) :]
    start = float('inf')
    level = 0
    for i, char in enumerate(block_and_tail):
        if char == '{':
            if i < start:
                start = i + 1
            level += 1
        elif char == '}':
            level -= 1
        if i >= start and level == 0:
            if with_frame:
                return block_and_tail[: i+1]
            else:
                return block_and_tail[start : i].strip()
    raise ValueError('not found: ' + signature)

def remove_line_comments(line):
    no_inline = re.sub('//.*', '', line)
    no_block_start = re.sub('/\*.*', '', no_inline)
    no_block_end = re.sub('.*\*/', '', no_block_start)
    return no_block_end

def remove_comments(original_block):
    original_lines = original_block.split('\n')
    lines = []
    in_comment = False
    for original_line in original_lines:
        line = remove_line_comments(original_line)
        if not in_comment and line.strip() != '':
            lines.append(line)
        if '/*' in original_line:
            in_comment = True
        if '*/' in original_line:
            in_comment = False
    block = '\n'.join(lines)
    return block

lines = code.split('\n')
in_comment = False
libraries = {}

for original_line in lines:
    line = remove_line_comments(original_line)
    if not in_comment and 'library' in line:
        signature = re.sub('{.*', '', line)
        block = get_block(signature, code)
        libraries[signature] = block
    if '/*' in original_line:
        in_comment = True
    if '*/' in original_line:
        in_comment = False

def select(library_name, block, external_code):
    lines = block.split('\n')
    lines.reverse()
    for line in lines:
        if 'function' in line:
            signature = re.sub('\(.*', '', line)
            name = re.sub('function', '', signature).strip()
            full_name = library_name + '.' + name
            if (external_code.count(full_name) == 0
                and block.count(name) == block.count(signature)):
                function_block = get_block(signature, block, with_frame=True)
                block = block.replace(function_block + '\n', '')
    return block

def get_warning(library_name):
    return '''/* WARNING

The following library code acts as an interface to the actual {}
library, which can be found in its own deployed contract. Only trust the actual
library's implementation.

    */

'''.format(library_name)

def get_stubs(block):
    original_lines = block.split('\n')
    lines = []
    level = 0
    for line in original_lines:
        if level == 0:
            difference = line.count('{') - line.count('}')
            lines.append(line + '}' * difference)
        level += line.count('{')
        level -= line.count('}')
    return '\n'.join(lines)

for signature, block in libraries.items():
    external_code = remove_comments(code.replace(block, ''))
    library_name = re.sub('library ', '', signature).strip()
    no_comments = remove_comments(block)
    selected_pre = no_comments
    selected_post = select(library_name, selected_pre, external_code)
    while len(selected_post) < len(selected_pre):
        selected_pre = selected_post
        selected_post = select(library_name, selected_pre, external_code)
    stubs = get_stubs(selected_post)
    new_block = get_warning(library_name) + stubs
    code = code.replace(block, new_block)

def get_library_info():
    try:
        library_name = "DssExecLib"
        library_address = open('./DssExecLib.address').read()
        return library_name, library_address
    except FileNotFoundError:
        raise ValueError('No Makefile found')

library_name = ''
library_address = ''

try:
    library_name, library_address = get_library_info()
except ValueError as e:
    print(e)
    print('Assuming this contract uses no libraries')

print('Obtaining chain ID... ')
cast_chain_id = subprocess.run(['cast', 'chain-id'], capture_output=True)
chain_id = cast_chain_id.stdout.decode('utf-8')[:-1]
print("CHAIN_ID: " + chain_id)

def send_request(url, headers, params, data):
    print('Sending verification request...')
    verify_res = requests.post(url, headers = headers, params = params, data = data)
    verify_payload = {}
    try:
        verify_payload = json.loads(verify_res.text)
    except json.decoder.JSONDecodeError:
        print(verify_res.text)
        raise Exception('Error: Etherscan responded with invalid JSON.')
    return verify_payload

def verify(name=None, address=None, input_path=None, output_path=None):
    document = ''
    content = {}
    try:
        document = open(output_path)
    except FileNotFoundError:
        raise Exception('run forge build first')

    try:
        content = json.load(document)
    except json.decoder.JSONDecodeError:
        raise Exception('run forge build again')

    metadata = content['metadata']
    compiler_version = 'v' + metadata['compiler']['version']
    evm_version = metadata['settings']['evmVersion']
    optimizer_enabled = metadata['settings']['optimizer']['enabled']
    optimizer_runs = metadata['settings']['optimizer']['runs']
    license_name = metadata['sources'][input_path]['license']
    license_numbers = {
        'GPL-3.0-or-later': 5,
        'AGPL-3.0-or-later': 13
    }
    license_number = license_numbers[license_name]

    params = {
        'chainid': chain_id,
    }

    data = {
        'apikey': api_key,
        'module': module,
        'action': action,
        'contractaddress': address,
        'sourceCode': code,
        'codeFormat': code_format,
        'contractName': name,
        'compilerversion': compiler_version,
        'optimizationUsed': '1' if optimizer_enabled else '0',
        'runs': optimizer_runs,
        'constructorArguements': constructor_arguments,
        'evmversion': evm_version,
        'licenseType': license_number,
        'libraryname1': library_name,
        'libraryaddress1': library_address,
    }

    url = 'https://api.etherscan.io/v2/api'
    headers = {
        'User-Agent': ''
    }

    verify_response = send_request(url, headers, params, data)

    while 'locate' in verify_response['result'].lower():
        print(verify_response['result'])
        print('Waiting for 15 seconds for the network to update...')
        time.sleep(15)
        verify_response = send_request(url, headers, params, data)

    if verify_response['status'] != '1' or verify_response['message'] != 'OK':
        print('Error: ' + verify_response['result'])
        raise Exception('Failed to verify')

    print('Sent verification request with guid ' + verify_response['result'])

    guid = verify_response['result']

    check_response = {}

    while check_response == {} or 'pending' in check_response['result'].lower():

        if check_response != {}:
            print(check_response['result'])
            print('Waiting for 15 seconds for Etherscan to process the request...')
            time.sleep(15)

        check = requests.post(url, headers = headers, params = params, data = {
            'apikey': api_key,
            'module': module,
            'action': 'checkverifystatus',
            'guid': guid,
        })

        try:
            check_response = json.loads(check.text)
        except json.decoder.JSONDecodeError:
            print(check.text)
            raise Exception('Error: Etherscan responded with invalid JSON')

    if check_response['status'] != '1' or check_response['message'] != 'OK':
        print('Error: ' + check_response['result'])
        log_name = 'verify-{}.log'.format(datetime.now().timestamp())
        log = open(log_name, 'w')
        log.write(code)
        log.close()
        print('log written to {}'.format(log_name))
        raise Exception('Failed to get verification status')

etherscan_subdomains = {
    '1': '',
    '11155111': 'sepolia.'
}

verify(
    name = spell_contract_name,
    address = spell_contract_address,
    input_path = 'src/DssSpell.sol',
    output_path = 'out/DssSpell.sol/DssSpell.json',
)

print('Spell Contract verified at https://{0}etherscan.io/address/{1}#code'.format(
    etherscan_subdomains[chain_id],
    spell_contract_address
))

verify(
    name = action_contract_name,
    address = action_contract_address,
    input_path = 'src/DssSpell.sol',
    output_path = 'out/DssSpell.sol/DssSpellAction.json',
)

print('Action Contract verified at https://{0}etherscan.io/address/{1}#code'.format(
    etherscan_subdomains[chain_id],
    action_contract_address
))