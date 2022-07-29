pragma circom 2.0.0;
include "../node_modules/circomlib/circuits/comparators.circom";

template Sudoku(sqrtN, N) {
    signal input unsolved[N][N];
    signal input solved[N][N];
    signal output out;

    // check that the numbers make sense
    component numbersVerifier = SudokuNumberVerifier(N);
    for (var i = 0; i < N; i++) {
        for (var j = 0; j < N; j++) {
            numbersVerifier.in[i*N + j] <== solved[i][j];
        }
    }
    numbersVerifier.out === 1;

    
    // verify the rows
    component rowVerifiers[N];
    for (var i = 0; i < N; i++) {
        rowVerifiers[i] = SubgroupVerifier(N);
        for (var j = 0; j < N; j++) {
            rowVerifiers[i].in[j] <== solved[i][j];
        }
        rowVerifiers[i].out === 1;
    }

    // verify the columns
    component columnVerifiers[N];
    for (var i = 0; i < N; i++) {
        columnVerifiers[i] = SubgroupVerifier(N);
        for (var j = 0; j < N; j++) {
            columnVerifiers[i].in[j] <== solved[j][i];
        }
        columnVerifiers[i].out === 1;
    }

    // verify the boxes
    component boxVerifiers[N];
    // i and j iterate through the boxes
    // k and m iterate through the entries in each box
    for (var i = 0; i < sqrtN; i++) {
        for (var j = 0; j < sqrtN; j++) {
            var xTopLeftCorner = i*sqrtN;
            var yTopLeftCorner = j*sqrtN;

            // fill the verifier with the numbers in the box 
            var boxIndex = i*sqrtN + j;
            boxVerifiers[boxIndex] = SubgroupVerifier(N);
            for (var k = 0; k < sqrtN; k++) {
                for (var m = 0; m < sqrtN; m++) {
                    var x = xTopLeftCorner + k;
                    var y = yTopLeftCorner + m;
                    var indexInBox = k*sqrtN + m;
                    boxVerifiers[boxIndex].in[indexInBox] <== solved[x][y];
                }
            }

            boxVerifiers[boxIndex].out === 1;
        }
    }

    // verify that solved solves unsolved
    // NOTE: idea stolen from https://github.com/vplasencia/zkSudoku/blob/main/circuits/sudoku/sudoku.circom
    component isEquals[N][N];
    component isZeros[N][N];
    for (var i = 0; i < N; i++) {
        for (var j = 0; j < N; j++) {
            isEquals[i][j] = IsEqual();
            isEquals[i][j].in[0] <== solved[i][j];
            isEquals[i][j].in[1] <== unsolved[i][j];

            isZeros[i][j] = IsZero();
            isZeros[i][j].in <== unsolved[i][j];

            isEquals[i][j].out === 1 - isZeros[i][j].out;
        }
    }
}

// returns 1 iff the N input signals are numbers from 1 to N without any repetitions 
template SubgroupVerifier(N) {
    signal input in[N];
    signal output out;

    // verify the numbers
    component numberVerifier[N];
    for (var i = 0; i < N; i++) {
        numberVerifier[i] = NumberVerifier(N);
        numberVerifier[i].in <== in[i];
        numberVerifier[i].out === 1;
    }    

    // initialize the occurrences array
    var occurrences[N];
    for (var i = 0; i < N; i++) {
        occurrences[i] = 0;
    }

    // count the occurrences
    for (var i = 0; i < N; i++) {
        occurrences[in[i]-1] += 1;
    }

    // each number must occur exactly once
    // TODO: check if the <-- below is dangerous (I don't think so): https://docs.circom.io/circom-language/constraint-generation/
    component zeroCheckers[N];
    signal occ[N];
    for (var i = 0; i < N; i++) {
        zeroCheckers[i] = IsEqual();
        occ[i] <-- occurrences[i];
        zeroCheckers[i].in[0] <== occ[i];
        zeroCheckers[i].in[1] <== 1;
        zeroCheckers[i].out === 1;
    }

    out <== 1;
}

// returns 1 iff 1 <= in <= N
template NumberVerifier(N) {
    signal input in;
    signal output out;
    component greq1;
    component leqN;

    // should be less than or equal to N ...
    leqN = LessEqThan(32);
    leqN.in[0] <== in;
    leqN.in[1] <== N;

    // ... and greater than or equal to 1 ...
    greq1 = GreaterEqThan(32);
    greq1.in[0] <== in;
    greq1.in[1] <== 1;

    // ... at the same time.
    component equal = IsEqual();
    equal.in[0] <== leqN.out;
    equal.in[1] <== greq1.out;
    out <== equal.out;
}

// receives all numbers on a N by N sudoku board and verifies that each
// value on the board satisfies 1 <= value <= N
template SudokuNumberVerifier(N) {
    signal input in[N*N];
    signal output out;

    component numberVerifiers[N*N];
    for (var i = 0; i < N*N; i++) {
           numberVerifiers[i] = NumberVerifier(N);
           numberVerifiers[i].in <== in[i];
           numberVerifiers[i].out === 1;
    }

    out <== 1;
}


component main {public [unsolved]} = Sudoku(3, 9);
