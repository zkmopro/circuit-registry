pragma circom 2.1.6;

include "../node_modules/circomlib/circuits/comparators.circom";
include "../node_modules/circomlib/circuits/bitify.circom";

function log2(a) {
    if (a == 0) {
        return 0;
    }
    var n = 1;
    var r = 1;
    while (n<a) {
        r++;
        n *= 2;
    }
    return r;
}


/// @title SubarraySelector
/// @notice Select a subarray from `startIndex` index and size of `length`
/// @notice Output array will have same length with remaining elements set to 0
/// @notice Based on https://demo.hedgedoc.org/s/Le0R3xUhB
/// @param maxArrayLen The maximum length of the input array
/// @param maxSubArrayLen The maximum length of the output array
/// @input in The input array
/// @input startIndex The index of the first element of the subarray
/// @input length The length of the subarray
/// @output out The selected subarray, zero padded
template SubarraySelector(maxArrayLen, maxSubArrayLen) {
    var bitLength = log2(maxArrayLen);
    assert(maxArrayLen <= (1 << bitLength));
    signal input in[maxArrayLen];
    signal input startIndex;
    signal input length;

    signal output out[maxSubArrayLen];

    component n2b = Num2Bits(bitLength);
    n2b.in <== startIndex;

    signal tmp[bitLength][maxArrayLen];
    for (var j = 0; j < bitLength; j++) {
        for (var i = 0; i < maxArrayLen; i++) {
            var offset = (i + (1 << j)) % maxArrayLen;
            // Shift left by 2^j indices if bit is 1
            if (j == 0) {
                tmp[j][i] <== n2b.out[j] * (in[offset] - in[i]) + in[i];
            } else {
                tmp[j][i] <== n2b.out[j] * (tmp[j-1][offset] - tmp[j-1][i]) + tmp[j-1][i];
            }
        }
    }

    // Return last row value or 0 depending on index
    component gtLengths[maxSubArrayLen];
    for (var i = 0; i < maxSubArrayLen; i++) {
        gtLengths[i] = GreaterThan(bitLength);
        gtLengths[i].in[0] <== length;
        gtLengths[i].in[1] <== i;
        out[i] <==  gtLengths[i].out * tmp[bitLength - 1][i];
    }
}


/// @title ArraySelector
/// @notice Select an element from an array based on index
/// From MACI https://github.com/privacy-scaling-explorations/maci/blob/v1/circuits/circom/trees/incrementalQuinTree.circom#L29
/// @param maxLength The number of elements in the array
/// @param bits The number of bits required to represent the number of elements - ceil(log2 maxLength)
/// @input in The input array
/// @input index The index of the element to select
/// @output out The selected element
template ArraySelector(maxLength, bits) {
    signal input in[maxLength];
    signal input index;
    signal output out;

    // Ensure that index < maxLength
    component lessThan = LessThan(bits);
    lessThan.in[0] <== index;
    lessThan.in[1] <== maxLength;
    lessThan.out === 1;

    component calcTotal = CalculateTotal(maxLength);
    component eqs[maxLength];

    // For each item, check whether its index equals the input index.
    for (var i = 0; i < maxLength; i ++) {
        eqs[i] = IsEqual();
        eqs[i].in[0] <== i;
        eqs[i].in[1] <== index;

        // eqs[i].out is 1 if the index matches. As such, at most one input to
        // calcTotal is not 0.
        calcTotal.nums[i] <== eqs[i].out * in[i];
    }

    // Returns 0 + 0 + ... + item
    out <== calcTotal.sum;
}

/// @title CalculateTotal
/// @notice Calculate the sum of an array
/// @param n The number of elements in the array
/// @input nums The input array
/// @output sum The sum of the input array
template CalculateTotal(n) {
    signal input nums[n];
    signal output sum;

    signal sums[n];
    sums[0] <== nums[0];

    for (var i=1; i < n; i++) {
        sums[i] <== sums[i - 1] + nums[i];
    }

    sum <== sums[n - 1];
}
