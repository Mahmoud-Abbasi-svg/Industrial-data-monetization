from umbral import SecretKey, Signer

# Generate Umbral keys for Alice.
alices_secret_key = SecretKey.random()
alices_public_key = alices_secret_key.public_key()

alices_signing_key = SecretKey.random()
alices_signer = Signer(alices_signing_key)
alices_verifying_key = alices_signing_key.public_key()

# Generate Umbral keys for Bob.
bobs_secret_key = SecretKey.random()
bobs_public_key = bobs_secret_key.public_key()



from umbral import encrypt, decrypt_original

# Encrypt data with Alice's public key.
plaintext = b'Proxy Re-Encryption is cool!'
capsule, ciphertext = encrypt(alices_public_key, plaintext)

# Decrypt data with Alice's private key.
cleartext = decrypt_original(alices_secret_key, capsule, ciphertext)


from umbral import generate_kfrags

# Alice generates "M of N" re-encryption key fragments (or "KFrags") for Bob.
# In this example, 10 out of 20.
kfrags = generate_kfrags(delegating_sk=alices_secret_key,
                         receiving_pk=bobs_public_key,
                         signer=alices_signer,
                         threshold=10,
                         shares=20)



from umbral import reencrypt

# Several Ursulas perform re-encryption, and Bob collects the resulting `cfrags`.
cfrags = list()           # Bob's cfrag collection
for kfrag in kfrags[:10]:
    cfrag = reencrypt(capsule=capsule, kfrag=kfrag)
    cfrags.append(cfrag)    # Bob collects a cfrag



from umbral import decrypt_reencrypted

bob_cleartext = decrypt_reencrypted(receiving_sk=bobs_secret_key,
                                        delegating_pk=alices_public_key,
                                        capsule=capsule,
                                        verified_cfrags=cfrags,
                                        ciphertext=ciphertext)
assert bob_cleartext == plaintext





