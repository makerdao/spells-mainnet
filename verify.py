#! /usr/bin/env python3

import os, sys, subprocess, time, re, json, requests

api_key = ''
try:
    api_key = os.environ['ETHERSCAN_API_KEY']
except KeyError:
    print('''  You need an Etherscan Api Key to verify contracts.
  Create one at https://etherscan.io/myapikey

  Then export it with `export ETHERSCAN_API_KEY=xxxxxxxx'
''')
    exit()

document = ''
try:
    document = open('out/dapp.sol.json')
except FileNotFoundError:
    exit('run dapp build first')
content = json.load(document)

if len(sys.argv) not in [3, 4]:
    print('''usage:

./verify.py <contractname> <address> [constructorArgs]
''')
    exit()

contract_name = sys.argv[1]
contract_address = sys.argv[2]
print('Attempting to verify contract {0} at address {1} ...'.format(
    contract_name,
    contract_address
))

if len(contract_address) !=  42:
    exit('malformed address')
constructor_arguments = ''
if len(sys.argv) == 4:
    constructor_arguments = sys.argv[3]
contract_path = ''

for path in content['contracts'].keys():
    for name in content['contracts'][path].keys():
        if name == contract_name:
            contract_path = path
if contract_path == '':
    exit('contract name not found.')

print('Obtaining chain... ')
seth_chain = subprocess.run(['seth', 'chain'], capture_output=True)
chain = seth_chain.stdout.decode('ascii').replace('\n', '')
print(chain)

text_metadata = content['contracts'][contract_path][contract_name]['metadata']
metadata = json.loads(text_metadata)

compiler_version = 'v' + metadata['compiler']['version']

evm_version = metadata['settings']['evmVersion']

optimizer_enabled = metadata['settings']['optimizer']['enabled']

optimizer_runs = metadata['settings']['optimizer']['runs']

license_name = metadata['sources'][contract_path]['license']

license_numbers = {
    'GPL-3.0-or-later': 5,
    'AGPL-3.0-or-later': 13
}

license_number = license_numbers[license_name]

module = 'contract'

action = 'verifysourcecode'

code_format = 'solidity-single-file'

flatten = subprocess.run([
    'hevm',
    'flatten',
    '--source-file',
    contract_path
], capture_output=True)

code = flatten.stdout.decode('utf-8')

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
    external_code = code.replace(block, '')
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

if 'addNewCollateral' not in code:
    code = code.replace(
        'pragma experimental ABIEncoderV2;',
        '// pragma experimental ABIEncoderV2;'
    )

def get_library_info():
    try:
        makefile = open('./Makefile').read()
        libraries_flags = re.findall('DAPP_LIBRARIES=\'(.*)\'', makefile)
        if len(libraries_flags) == 0:
            raise ValueError('No library flags found in Makefile')
        libraries_flag = libraries_flags[0].strip().split(' ')
        library_flag = libraries_flag[0]
        library_components = library_flag.split(':')
        if len(library_components) != 3:
            raise ValueError('Malformed library flag: ', library_components)
        library_name = library_components[1]
        library_address = library_components[2]
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

data = {
    'apikey': api_key,
    'module': module,
    'action': action,
    'contractaddress': contract_address,
    'sourceCode': code,
    'codeFormat': code_format,
    'contractName': contract_name,
    'compilerversion': compiler_version,
    'optimizationUsed': '1' if optimizer_enabled else '0',
    'runs': optimizer_runs,
    'constructorArguements': constructor_arguments,
    'evmversion': evm_version,
    'licenseType': license_number,
    'libraryname1': library_name,
    'libraryaddress1': library_address,
}

if chain in ['mainnet', 'ethlive']:
    chain_separator = False
    chain_id = ''
else:
    chain_separator = True
    chain_id = chain

url = 'https://api{0}{1}.etherscan.io/api'.format(
    '-' if chain_separator else '',
    chain_id
)

headers = {
    'User-Agent': ''
}

def send():
    print('Sending verification request...')
    verify = requests.post(url, headers = headers, data = data)
    verify_response = {}
    try:
        verify_response = json.loads(verify.text)
    except json.decoder.JSONDecodeError:
        print(verify.text)
        exit('Error: Etherscan responded with invalid JSON.')
    return verify_response

verify_response = send()

while 'locate' in verify_response['result'].lower():
    print(verify_response['result'])
    print('Waiting for 15 seconds for the network to update...')
    time.sleep(15)
    verify_response = send()

if verify_response['status'] != '1' or verify_response['message'] != 'OK':
    print('Error: ' + verify_response['result'])
    exit()

print('Sent verification request with guid ' + verify_response['result'])

guid = verify_response['result']

check_response = {}

while check_response == {} or 'pending' in check_response['result'].lower():

    if check_response != {}:
        print(check_response['result'])
        print('Waiting for 15 seconds for Etherscan to process the request...')
        time.sleep(15)

    check = requests.post(url, headers = headers, data = {
        'apikey': api_key,
        'module': module,
        'action': 'checkverifystatus',
        'guid': guid,
    })

    try:
        check_response = json.loads(check.text)
    except json.decoder.JSONDecodeError:
        print(check.text)
        exit('Error: Etherscan responded with invalid JSON')

if check_response['status'] != '1' or check_response['message'] != 'OK':
    print('Error: ' + check_response['result'])
    exit()

print('Contract verified at https://{0}{1}etherscan.io/address/{2}#code'.format(
    chain_id,
    '.' if chain_separator else '',
    contract_address
))
