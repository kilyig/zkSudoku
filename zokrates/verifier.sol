// This file is MIT Licensed.
//
// Copyright 2017 Christian Reitwiessner
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
pragma solidity ^0.8.0;
library Pairing {
    struct G1Point {
        uint X;
        uint Y;
    }
    // Encoding of field elements is: X[0] * z + X[1]
    struct G2Point {
        uint[2] X;
        uint[2] Y;
    }
    /// @return the generator of G1
    function P1() pure internal returns (G1Point memory) {
        return G1Point(1, 2);
    }
    /// @return the generator of G2
    function P2() pure internal returns (G2Point memory) {
        return G2Point(
            [10857046999023057135944570762232829481370756359578518086990519993285655852781,
             11559732032986387107991004021392285783925812861821192530917403151452391805634],
            [8495653923123431417604973247489272438418190587263600148770280649306958101930,
             4082367875863433681332203403145435568316851327593401208105741076214120093531]
        );
    }
    /// @return the negation of p, i.e. p.addition(p.negate()) should be zero.
    function negate(G1Point memory p) pure internal returns (G1Point memory) {
        // The prime q in the base field F_q for G1
        uint q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
        if (p.X == 0 && p.Y == 0)
            return G1Point(0, 0);
        return G1Point(p.X, q - (p.Y % q));
    }
    /// @return r the sum of two points of G1
    function addition(G1Point memory p1, G1Point memory p2) internal view returns (G1Point memory r) {
        uint[4] memory input;
        input[0] = p1.X;
        input[1] = p1.Y;
        input[2] = p2.X;
        input[3] = p2.Y;
        bool success;
        assembly {
            success := staticcall(sub(gas(), 2000), 6, input, 0xc0, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require(success);
    }


    /// @return r the product of a point on G1 and a scalar, i.e.
    /// p == p.scalar_mul(1) and p.addition(p) == p.scalar_mul(2) for all points p.
    function scalar_mul(G1Point memory p, uint s) internal view returns (G1Point memory r) {
        uint[3] memory input;
        input[0] = p.X;
        input[1] = p.Y;
        input[2] = s;
        bool success;
        assembly {
            success := staticcall(sub(gas(), 2000), 7, input, 0x80, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require (success);
    }
    /// @return the result of computing the pairing check
    /// e(p1[0], p2[0]) *  .... * e(p1[n], p2[n]) == 1
    /// For example pairing([P1(), P1().negate()], [P2(), P2()]) should
    /// return true.
    function pairing(G1Point[] memory p1, G2Point[] memory p2) internal view returns (bool) {
        require(p1.length == p2.length);
        uint elements = p1.length;
        uint inputSize = elements * 6;
        uint[] memory input = new uint[](inputSize);
        for (uint i = 0; i < elements; i++)
        {
            input[i * 6 + 0] = p1[i].X;
            input[i * 6 + 1] = p1[i].Y;
            input[i * 6 + 2] = p2[i].X[1];
            input[i * 6 + 3] = p2[i].X[0];
            input[i * 6 + 4] = p2[i].Y[1];
            input[i * 6 + 5] = p2[i].Y[0];
        }
        uint[1] memory out;
        bool success;
        assembly {
            success := staticcall(sub(gas(), 2000), 8, add(input, 0x20), mul(inputSize, 0x20), out, 0x20)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require(success);
        return out[0] != 0;
    }
    /// Convenience method for a pairing check for two pairs.
    function pairingProd2(G1Point memory a1, G2Point memory a2, G1Point memory b1, G2Point memory b2) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](2);
        G2Point[] memory p2 = new G2Point[](2);
        p1[0] = a1;
        p1[1] = b1;
        p2[0] = a2;
        p2[1] = b2;
        return pairing(p1, p2);
    }
    /// Convenience method for a pairing check for three pairs.
    function pairingProd3(
            G1Point memory a1, G2Point memory a2,
            G1Point memory b1, G2Point memory b2,
            G1Point memory c1, G2Point memory c2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](3);
        G2Point[] memory p2 = new G2Point[](3);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        return pairing(p1, p2);
    }
    /// Convenience method for a pairing check for four pairs.
    function pairingProd4(
            G1Point memory a1, G2Point memory a2,
            G1Point memory b1, G2Point memory b2,
            G1Point memory c1, G2Point memory c2,
            G1Point memory d1, G2Point memory d2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](4);
        G2Point[] memory p2 = new G2Point[](4);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p1[3] = d1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        p2[3] = d2;
        return pairing(p1, p2);
    }
}

contract Verifier {
    using Pairing for *;
    struct VerifyingKey {
        Pairing.G1Point alpha;
        Pairing.G2Point beta;
        Pairing.G2Point gamma;
        Pairing.G2Point delta;
        Pairing.G1Point[] gamma_abc;
    }
    struct Proof {
        Pairing.G1Point a;
        Pairing.G2Point b;
        Pairing.G1Point c;
    }
    function verifyingKey() pure internal returns (VerifyingKey memory vk) {
        vk.alpha = Pairing.G1Point(uint256(0x109ac73f594565484d105d5a071143073de57b497f948d6d1f6afb128971ce12), uint256(0x01cdaf23aed02e077cd9177f053ff95ac311593667ba08ceca7891bff7a3687b));
        vk.beta = Pairing.G2Point([uint256(0x1aa0cdf7d4c8f563d213f400375c2f54248e812d54dbd398ecb3b8fc206ea2c2), uint256(0x107bdf1bb60e5672333889f510f1370613c35d4947831b01abcdb98a7fad727f)], [uint256(0x029fd856d8ea8c1dd8367bca4abba0cec38673f6bf424c211c0756d924ed8425), uint256(0x299371a48d960067710c9bda0eeaf5e0ac04d801c5b9b9d5c648f506629222e8)]);
        vk.gamma = Pairing.G2Point([uint256(0x247b35b198a8d6c1500aade0dc4dc6fd944e8d217cac375c8bcf5668f7bf706d), uint256(0x14c878d852f9e3c612afa5a8cc70631d48384269ff1ac1a08af1a9ee6bd5cf57)], [uint256(0x12e870d200311bd164d52b6d31250dbe8414e269b75507b8283dba3afa64ae2f), uint256(0x08044323a930b22b6cca42b9e1c58d6d8ab6a7ebfa2fe523052ba0315f7e3c93)]);
        vk.delta = Pairing.G2Point([uint256(0x2caf8639a4ce7930b53afb425a66b6f439ed31e344fe8cd6bb0363d50847bd41), uint256(0x170886fa92eeb74881fcf88d3ddad88eb7369dbb3834407acde367f74d0f60c6)], [uint256(0x2fb609770a99ec699dd72b52f3bb72dde2d61eef8c7ff731d9c7bedfc9ae1870), uint256(0x1dd8dd9dbfe94b8bf5dc33c82f3d000c1050b5df0c55faea72394511f652ec3a)]);
        vk.gamma_abc = new Pairing.G1Point[](8);
        vk.gamma_abc[0] = Pairing.G1Point(uint256(0x2eaa16e541c04bc27e6e159ad3af6589d8415356f78e2e0f4680a3eb1553405b), uint256(0x21c56b0fca43f38c840d448226fbdb0f8ec5b47117270314d1db2383d6f19ed8));
        vk.gamma_abc[1] = Pairing.G1Point(uint256(0x258b2f8cf4a355d3310a61e2e1af0f8337bd8dc7fbee5f6d8aa1c521aa7ccd02), uint256(0x2225bbb0d145216f5cf7ffab84b07bdeb00961db628c8b276910143654157ec3));
        vk.gamma_abc[2] = Pairing.G1Point(uint256(0x0c3f356762af62ac62396a25b1af95a92e97f4dd4b5caaa4d0eac3830675f8b5), uint256(0x16e75a282520a4d638b2124e362a4a582bd725d6c98e55c579cb8dba9b052fc1));
        vk.gamma_abc[3] = Pairing.G1Point(uint256(0x0c201c5bd83934f2209f5e3925c82c6bbb2f6f8de464ce3464f6560df206d6a1), uint256(0x1183a190bfa8347a2832157642bbb5b0e63b934606f5b0418ee9fef53b449757));
        vk.gamma_abc[4] = Pairing.G1Point(uint256(0x0e2afe4e2a9126469a0ab54be39baf7d6e505b3a9b5b7e05a0855bc4bc40d1af), uint256(0x1bde244f0e1c0d2e4a92d4eda4b9ea28a723b6117c06d5dbfca25a479a63c0e8));
        vk.gamma_abc[5] = Pairing.G1Point(uint256(0x1bc0b966f7debc480ec2cee7fb8240bc448757760ae1dc94248a8671c39a0814), uint256(0x28c696b6b7ad171333b7950e249ccb6999429c8cdc1a5c5d852d76c02c519060));
        vk.gamma_abc[6] = Pairing.G1Point(uint256(0x0c72fc1fa2fcfcc3eafbe9e5f193a750b8732079ae67dab4b401dc09ee63837f), uint256(0x17bf1edc410b75b28e74f11a09bcba8098bc21b163b041c54187d40e70646586));
        vk.gamma_abc[7] = Pairing.G1Point(uint256(0x05ac1d8cfa690a9c399568e056746dbaeb017a6a1d8a7a5655f6b9f2b44220ec), uint256(0x205b362ad0efb096c9f72ed254b090f4d6226aeab1d75bac3e03864396667deb));
    }
    function verify(uint[] memory input, Proof memory proof) internal view returns (uint) {
        uint256 snark_scalar_field = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
        VerifyingKey memory vk = verifyingKey();
        require(input.length + 1 == vk.gamma_abc.length);
        // Compute the linear combination vk_x
        Pairing.G1Point memory vk_x = Pairing.G1Point(0, 0);
        for (uint i = 0; i < input.length; i++) {
            require(input[i] < snark_scalar_field);
            vk_x = Pairing.addition(vk_x, Pairing.scalar_mul(vk.gamma_abc[i + 1], input[i]));
        }
        vk_x = Pairing.addition(vk_x, vk.gamma_abc[0]);
        if(!Pairing.pairingProd4(
             proof.a, proof.b,
             Pairing.negate(vk_x), vk.gamma,
             Pairing.negate(proof.c), vk.delta,
             Pairing.negate(vk.alpha), vk.beta)) return 1;
        return 0;
    }
    function verifyTx(
            Proof memory proof, uint[7] memory input
        ) public view returns (bool r) {
        uint[] memory inputValues = new uint[](7);
        
        for(uint i = 0; i < input.length; i++){
            inputValues[i] = input[i];
        }
        if (verify(inputValues, proof) == 0) {
            return true;
        } else {
            return false;
        }
    }
}
