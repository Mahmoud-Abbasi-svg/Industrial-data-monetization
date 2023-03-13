
####################  Connect to an Ethereum node  ##############################
####################  Compile and deploy smart contract #########################
####################  Execute some functions of smart contract ##################


import solcx
from web3 import Web3



# @desc Connecting to a local (e.g.,Ganache) or remote(e.g.,Infura) Ethereum node 
w3 = Web3(Web3.HTTPProvider("HTTP://127.0.0.1:7545"))
connected = w3.isConnected()
# @desc To test the connection status
print(connected)


# @desc chek the version
solcx.install_solc()

# @desc compile the file by using the Solidity compiler to make its abi and bytecode
compiled_sol = solcx.compile_files(["greeter.sol"],
                          output_values=["abi", "bin"],solc_version="0.8.17")


# @desc retrieve the contract interface
contract_id, contract_interface = compiled_sol.popitem()

# @desc get bytecode / bin
bytecode = contract_interface['bin']

# @desc get abi
abi = contract_interface['abi']

# @desc Creates an account object from a private key
key = "0x0ef4b3e3b59e1cfdcdaebf739e5e0f21f020d03507f2d934f79dc41166c270f1"
acct = w3.eth.account.privateKeyToAccount(key)
account_address= acct.address


# @desc Return an instance of the contract
#Greeter = w3.eth.contract(abi=abi, bytecode=bytecode)

####################  Signs and sends the given transaction  ######################

# @desc To build transaction
tx = w3.eth.send_transaction({'from': acct.address,
                              'nonce': w3.eth.getTransactionCount(acct.address),
                             'gas': 1728712,
                             'gasPrice': w3.toWei('21', 'gwei')})


# @desc To sign transaction
signed = acct.signTransaction({'from': acct.address,
                               'nonce': w3.eth.get_transaction_count(acct.address),
                               'gas': 1728712,
                               'gasPrice': w3.toWei('21', 'gwei')})

# @desc Sends a signed and serialized transaction.
# @desc returns the transaction hash as a HexBytes object.
tx_hash=w3.eth.send_raw_transaction(signed.rawTransaction)
print(tx_hash.hex())

# @desc Waits for the transaction specified by transaction_hash
# @desc to be included in a block, then returns its transaction receipt
tx_receipt = w3.eth.wait_for_transaction_receipt(tx_hash)
print("Contract Deployed At:", tx_receipt['contractAddress'])

####################  Sending Transactions to the Deployed Contract  #############

# @desc Instantiate and deploy contract
contract1  = w3.eth.contract(abi=abi, bytecode=bytecode)

# @desc Return an instance of the contract
contract_address = Web3.toChecksumAddress(tx_receipt['contractAddress']) 
contract_instance = w3.eth.contract(abi=abi, address=contract_address)


# @desc Build transaction for interacting with greet function
tx_greet = contract_instance.functions.greet("Hello all  my goody people").build_transaction({
    'from': acct.address,
    'nonce': w3.eth.get_transaction_count(account_address),
    'gas': 1728712,
    'gasPrice': w3.toWei('21', 'gwei')})

# @descGet tx receipt to get contract address
signed_tx = w3.eth.account.signTransaction(tx_greet, key)
hash= w3.eth.sendRawTransaction(signed_tx.rawTransaction)
print(hash.hex())


# @desc Reading Data from Deployed Smart Contract






















