import requests
projectId = "2HDzk9ilhap5Y1wRxAP9CEdl54O"
projectSecret = "2f0f7e398d640e88653a43294eff0948"
endpoint = "https://ipfs.infura.io:5001"

files = {'file': 'C:/Users/Mahmoud/OneDrive/Desktop/test/test.txt'}


### ADD FILE TO IPFS AND SAVE THE HASH ###
### To connect to IPFS, Infura requires the Authorization HTTP header
### Authorization: Basic <base64(USERNAME:PASSWORD)>
### In this case it is: auth=(projectId, projectSecret)
response1 = requests.post(endpoint+'/api/v0/add', files=files, auth=(projectId, projectSecret))
print(response1)
hash = response1.text.split(",")[1].split(":")[1].replace('"','')
print(hash)


### READ FILE WITH HASH ###
params = {'arg': hash}

response2 = requests.post(endpoint + '/api/v0/cat', params=params, auth=(projectId, projectSecret))
print(response2)
print(response2.text)


























