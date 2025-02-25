pragma circom 2.1.8;

include "circomlib/circuits/bitify.circom";
include "circomlib/circuits/poseidon.circom";
include "gpc-util.circom";

/**
 * Module deriving virtual entry data from PODs' cryptographic
 * data. At the moment, virtual entries are objects' content IDs and
 * signers' public keys.
 * 
 * This module's functionality is always enabled.
 */
template VirtualEntryModule (
    // Max number of PODs from which we derive virtual entries
    MAX_OBJECTS
) {
    // Number of virtual entries.
    var MAX_VIRTUAL_ENTRIES = 2 * MAX_OBJECTS;
    
    // Boolean flags for virtual entry behaviour.
    signal input isValueHashRevealed /*MAX_VIRTUAL_ENTRIES packed bits*/;
    
    // Signals forming virtual entries.
    signal input objectContentID[MAX_OBJECTS];
    signal input objectSignerPubkeyAx[MAX_OBJECTS];
    signal input objectSignerPubkeyAy[MAX_OBJECTS];

    // Virtual entry value hashes deduced from cryptographic data.
    signal output valueHashes[MAX_VIRTUAL_ENTRIES];

    for (var i = 0; i < MAX_OBJECTS; i++) {
            valueHashes[2*i]
                <== Poseidon(1)([objectContentID[i]]);
            
            valueHashes[2*i + 1]
                <== Poseidon(2)(
                    [
                        objectSignerPubkeyAx[i],
                        objectSignerPubkeyAy[i]
                     ]
                                );
    }
    
    signal isValueHashRevealedBits[MAX_VIRTUAL_ENTRIES]
        <== Num2Bits(MAX_VIRTUAL_ENTRIES)(isValueHashRevealed);

    // Virtual entry value is optionally revealed, or set to -1 if
    // not.
    signal output revealedValueHash[MAX_VIRTUAL_ENTRIES];
    
    for (var i = 0; i < MAX_VIRTUAL_ENTRIES; i++) {
        revealedValueHash[i]
            <== ValueOrNegativeOne()(
                valueHashes[i],
                isValueHashRevealedBits[i]);
    }
}
