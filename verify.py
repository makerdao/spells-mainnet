#! /bin/env python3

import os, sys, subprocess, time, re, json, requests

def log(r):
    print('{0} {1} {2} {3}'.format(r.method, r.url, r.headers, r.body))

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
print('Attempting to verify contract {0} at address {1}...'.format(
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

original_code = flatten.stdout.decode('utf-8')

code = original_code.replace(
    'pragma experimental ABIEncoderV2;',
    '// pragma experimental ABIEncoderV2;'
)

def get_function(signature, code):
    after_function = code[code.find(signature) :]
    in_body = False
    counter = 0
    for i, char in enumerate(after_function):
        if char == '{':
            in_body = True
            counter += 1
        elif char == '}':
            counter -= 1
        if in_body and counter == 0:
            return after_function[: i+1]
    return None

function_signature = 'function addNewCollateral'
function_body = get_function(function_signature, code)
code = code.replace(function_body, '// removed addNewCollateral function')

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

print('Sending verification request...')

verify = requests.post(url, headers = headers, data = data)

log(verify.request)

try:
    verify_response = json.loads(verify.text)
except json.decoder.JSONDecodeError:
    print(verify.text)
    exit('Error: Etherscan responded with invalid JSON.')

if verify_response['status'] != '1' or verify_response['message'] != 'OK':
    print('Error: ' + verify_response['result'])
    exit()

print('Sent verification request with guid ' + verify_response['result'])

guid = verify_response['result']

check_response = {}

while check_response == {} or 'pending' in check_response['result'].lower():

    if check_response != {}:
        print('Verification pending...')
        time.sleep(1)

    check = requests.post(url, headers = headers, data = {
        'apikey': api_key,
        'module': module,
        'action': 'checkverifystatus',
        'guid': guid,
    })

    if check_response == {}:
        log(check.request)

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
