from web3 import Web3

# Connecting using Https
w3 = Web3(Web3.HTTPProvider("https://mainnet.infura.io/v3/478b9333f6874304a7a8cce656f1a374"))
connected = w3.isConnected()
# To test the connection status
print(connected)