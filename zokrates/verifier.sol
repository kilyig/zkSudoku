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
        vk.alpha = Pairing.G1Point(uint256(0x0fe07406ebb99b9f172e65b6213be715d587c446fd71f0c479b3200fce88efca), uint256(0x08f9bc44d54b2d6c13345d48ecf70988d0029e201f060a1dda2637de9a70a11f));
        vk.beta = Pairing.G2Point([uint256(0x2bd87453b976e1b6d6fd495af5f4a5eb18e6feb84a7e240fea6687b644234bf5), uint256(0x08985e32919303a1ca11fb3f48353de2b5b59ca940fb531331231ba046de11c9)], [uint256(0x0d734a5ed0ac3d9f8dd98ec9f3e914f38bf6f059d785c3db6c41f5cce6ede5f6), uint256(0x2114b871f35bc9b5b18edc11bdd1a8a46fd126904f5c3f82fc57e8cc225dcd79)]);
        vk.gamma = Pairing.G2Point([uint256(0x1475d1cccfb0279e494d9c7ca9d114421cf30465d4f837f5cae656c1ac2b95a2), uint256(0x2478bcf12ec0943d973f530c902a8d7b6f6e163724a8e7bc517482a6c1735fca)], [uint256(0x2df3950eb3bfa85ec2d142a24776a17893582e2c2cfe75ff1f3081bf87adf73d), uint256(0x10d72f0854c2a3ff94ba46edca94efd52c50ab2bb47bfc0752fa63006da1a989)]);
        vk.delta = Pairing.G2Point([uint256(0x023d352479b4af86eacbc3edea8f40c19039ba2a6830b83041b4db7c70f35cf7), uint256(0x1236e27ab2ad9081b04fe84f2640776e92a6ac35aa1ece285cc0bb02d1cee782)], [uint256(0x1ab6158f1811fa031fac6285730f8c7021b3b5749a46a2c822be08141811d12b), uint256(0x2d2050a99cbaacbb0688a64d649cf1fa76b998737210e9df241a8c4b8034619f)]);
        vk.gamma_abc = new Pairing.G1Point[](17);
        vk.gamma_abc[0] = Pairing.G1Point(uint256(0x112d1bc76956dbf333967234aca223a52eeada952180f05481d1e893cda42526), uint256(0x14092450a32fb52115964378278903fdef9abf8eaeda2308c998d0ad4e013c19));
        vk.gamma_abc[1] = Pairing.G1Point(uint256(0x1fb4ce0d6b78d7ea8df3d3c357821413059ea938eb3b2881b8c9cb4518901503), uint256(0x22fcc2f76bf989488e2d7eeeb29781114a35998976f475ae43e1f7d6b8231f24));
        vk.gamma_abc[2] = Pairing.G1Point(uint256(0x2e2014f13ab878318a7db9673b977e9342aa7a9074aff948bb9fa456263c34c1), uint256(0x0557c840fcffcd846842326393e1b595509cddc550dc9d05d368be175cd3368c));
        vk.gamma_abc[3] = Pairing.G1Point(uint256(0x0e9eb0de754e73ebc4c35d0634fcfb7ea424473df898b5beeb6a4825c270f7e8), uint256(0x2e4214960771fc94db0e0cf5f0fb1dfdd634bb58a65ecf0f9254c8e1a4c17917));
        vk.gamma_abc[4] = Pairing.G1Point(uint256(0x2d1ed61b9a1f2ab3b4726a49116f8f5528616d4f27e154d0a55c0fa1b64bc783), uint256(0x149172f0d7f95d1d193dc897811347079b8aca7f9d3681cd91a1bba5fa3b8861));
        vk.gamma_abc[5] = Pairing.G1Point(uint256(0x07fe6dfac19f3bddd91f8856f4e462e181bd2d63fdcc1a37681a111c0a566ab1), uint256(0x002a306df4dd39a5eaf6b702ec4b7fabae464f61b016ba8637bf5ccff912f700));
        vk.gamma_abc[6] = Pairing.G1Point(uint256(0x24ac57bc227381b1aab85ff6483ee8f6968031c056eba7c507b54c4b2ca467cd), uint256(0x1d8b4b792a39789c74e5e8928ca481d473568a518af168f38e67bd66bf368908));
        vk.gamma_abc[7] = Pairing.G1Point(uint256(0x12046a3355a60b5e1e630fbfd8cc5bacc9e601e8fa41a3985ab41e29062ef700), uint256(0x00061b298932d7bc2726d0019fad36b8dca04783236cef59cc8a19b55a3bf16c));
        vk.gamma_abc[8] = Pairing.G1Point(uint256(0x1215bfe767b4ee7b5cd409f688dddc973818f0a33fd871ec9be6c879e421637f), uint256(0x20661817ff203c86fbe3824aa1a016f43826b1736c4f45bf32645a3de819426e));
        vk.gamma_abc[9] = Pairing.G1Point(uint256(0x3032d56eb1ee325c0c95fae3b31921f1318c261e2af42d69a4ec08cc854d7f14), uint256(0x0ab143f578ab0711664ef85fd765a837d1983de060fd2872f16d4154d869a2e3));
        vk.gamma_abc[10] = Pairing.G1Point(uint256(0x1a3efc73c1051e3d0384be50e9ebcd7796d85f3dbbcaf29da4b963822c186415), uint256(0x1bccfed318758f2525ab12b0a171758af229e2cdad18809ffc93ef7b7da77252));
        vk.gamma_abc[11] = Pairing.G1Point(uint256(0x202e28c65522e9b29eaa780442010e0850a4b7d06b37031248e1d282d43eacf6), uint256(0x2925e20e24f35df3b8b9c0ad30f042cb209af744ea81f2eb69aa29ebb2455796));
        vk.gamma_abc[12] = Pairing.G1Point(uint256(0x0e11c535fec62a3fcfc70a5a82a634d93dc51f7c77f133ea0524b778eb4501f8), uint256(0x034f011a133ecbf3d300990fa308e80d9c3734b240e773ef43548222fc76d827));
        vk.gamma_abc[13] = Pairing.G1Point(uint256(0x23c006cb2e5422f329c3c78c818c33c2c8c547564db681ba38952ef798d3d7b6), uint256(0x24e49c75ca54adaa85bfd85fffdea6293fbf3cdbc2badded09bc1d63d7e6c679));
        vk.gamma_abc[14] = Pairing.G1Point(uint256(0x09672b8b446c2cbc0a0119c97e9a42fee31142d097ff73d1851bd4f9ed29ab43), uint256(0x13a34f0d5587c9b38fd31fbc4f8374b9d90d8edf7fdc585256313949eb4ab8cc));
        vk.gamma_abc[15] = Pairing.G1Point(uint256(0x07ab751c2a1823a5538c49c526ebc6ba434f2937ed4166db50de2c47eb9e9600), uint256(0x2b698a5dac34dfc644829333fd52d21c59f6b487fc56155be279284badb1cd91));
        vk.gamma_abc[16] = Pairing.G1Point(uint256(0x0363734db2df3f8992eb5202624b60d070f287b28f3a5bd59f34575a1b48ba9e), uint256(0x2a3789a98fa2f5eb1197acbe9c0a2a54be05247e9d0c0de03b0f416ed5917f97));
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
            Proof memory proof, uint[16] memory input
        ) public view returns (bool r) {
        uint[] memory inputValues = new uint[](16);
        
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
