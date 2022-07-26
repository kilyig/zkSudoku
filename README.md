# zkSudoku
Implementation of a zero-knowledge prover for Sudoku, both in ZoKrates and Circom.

## ZoKrates guide
In the `zokrates` folder, run
```
# compile
zokrates compile -i sudoku.zok

# perform the setup phase
zokrates setup

# execute the program
cat input.json | zokrates compute-witness --abi --stdin

# generate a proof of computation
zokrates generate-proof

# export a solidity verifier
zokrates export-verifier

# or verify natively
zokrates verify

```

## Circom guide
Coming soon.

### Related Work
https://github.com/akosba/xjsnark/tree/master/doc/code_previews#sudoku-9x9

