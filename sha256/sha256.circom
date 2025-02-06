pragma circom 2.1.5;

include "./node_modules/circomlib/circuits/sha256/sha256.circom";

component main = Sha256(512);
