pragma circom 2.0.0;
include "../node_modules/circomlib/circuits/comparators.circom";

template Sudoku(N) {
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
    numbersVerifier.out === 0;

    
    // verify the rows
    component rowVerifiers[N];
    for (var i = 0; i < N; i++) {
        rowVerifiers[i] = SubgroupVerifier(N);
        for (var j = 0; j < N; j++) {
            rowVerifiers[i].in[j] <== solved[i][j];
        }
        rowVerifiers[i].out === 0;
    }

    // verify the columns
    component columnVerifiers[N];
    for (var i = 0; i < N; i++) {
        columnVerifiers[i] = SubgroupVerifier(N);
        for (var j = 0; j < N; j++) {
            columnVerifiers[i].in[j] <== solved[j][i];
        }
        columnVerifiers[i].out === 0;
    }

    // verify the boxes


    // verify that solved solves unsolved
}

template SubgroupVerifier(N) {
    signal input in[N];
    signal output out;

    // verify the numbers
    component numberVerifier[N];
    for (var i = 0; i < N; i++) {
        numberVerifier[i] = NumberVerifier(N);
        numberVerifier[i].in <== in[i];
        numberVerifier[i].out === 0;
    }    

    // initialize the occurrences array
    var occurrences[N];
    //for (var i = 0; i < N; i++) {
    //    occurrences[i] = 0;
    //}

    // count the occurrences
    for (var i = 0; i < N; i++) {
        occurrences[in[i]] = 1;
    }


    // each number must occur exactly once
    // TODO: check if the <-- below is dangerous: https://docs.circom.io/circom-language/constraint-generation/
    component zeroCheckers[N];
    signal occ[N];
    for (var i = 0; i < N; i++) {
        zeroCheckers[i] = IsEqual();
        occ[i] <-- occurrences[i];
        zeroCheckers[i].in[0] <== occ[i];
        zeroCheckers[i].in[1] <== 1;
        zeroCheckers[i].out === 0;
    }

}

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

template SudokuNumberVerifier(N) {
    signal input in[N*N];
    signal output out;

    component numberVerifiers[N*N];
    for (var i = 0; i < N*N; i++) {
           numberVerifiers[i] = NumberVerifier(N);
           numberVerifiers[i].in <== in[i];
           numberVerifiers[i].out === 0;
    }

    out <== 0;
}


component main {public [unsolved]} = Sudoku(4);
