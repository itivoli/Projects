// Esperandieu Elbon II - UCFID: 5401262
// EEL4768 Computer Architecture - Suboh Suboh - Fall 2023
// Implementing a Branch Predictor Simulator 

#include <stdlib.h>
#include <math.h>

// Global Branch History Register
typedef struct Register {
    unsigned long long int data;
    int size;
} Register;

Register *createRegister(int size);
Register *rightShft(Register *reg); 
Register *updateMSB(char outcome, Register *reg);
Register *updateRegister(char outcome, Register *reg);
Register *clearRegister(Register *reg);
Register *deleteRegister(Register *reg);

// Create a Register of the indicated size (in bits)
Register *createRegister(int size) {
    Register *reg = (Register *) malloc(sizeof(Register));
    reg->data = 0;
    reg->size = size;
    return reg;
}

// Shift the contents of the register right by 1 bit
Register *rightShft(Register *reg) {
    reg->data = reg->data >> 1;
    return reg;
}

// Update the MSB of the register based on outcome: if taken -> 1, if not taken -> 0
Register *updateMSB(char outcome, Register *reg) {
    int newMSB = 0;

    // If register size < 1, there's not actually a register so even if taken, don't update
    if (outcome == 't' && reg->size > 0) newMSB = (newMSB + 1) << reg->size - 1;
    reg->data = reg->data | newMSB;
    return reg;
}

// Update the register based on actual outcome
Register *updateRegister(char outcome, Register *reg) {
    reg = rightShft(reg);
    reg = updateMSB(outcome, reg);
    return reg;
}

// Flushes the register and sets all bits to 0
Register *clearRegister(Register *reg) {
    reg->data = (reg->data) >> (reg->size);
    return reg;
}

// De-allocate space allocated for the register
Register *deleteRegister(Register *reg) {
    free(reg);
    return NULL;
}

// Global Branch Prediction History Table
typedef struct PredTable {
    int offset;     // # of bits used to index table
    int size;       // How large the table is: 2^offset
    int *table;     
    unsigned long long int mask;    // Bit mask used to retrieve the lowest M bits from the branch address
} PredTable;

PredTable *createTable(int size);
int getEntryState(int index, PredTable *ptbl);
PredTable *updateEntryState(int index, char outcome, PredTable *ptbl);
PredTable *deleteTable(PredTable *ptbl);

// Creates a history table with the indicated offset of size 2^(offset)
PredTable *createTable(int offset) {
    PredTable *ptbl = (PredTable *) malloc(sizeof(PredTable));
    ptbl->offset = offset;

    // Compute table size
    ptbl->size = (int) pow(2,offset);

    // Initialize mask to be used in indexing  
    ptbl->mask = 1 << offset - 1;
    ptbl->mask = 2*ptbl->mask - 1;
    
    // Initialize each entry to weakly taken (2)
    ptbl-> table = (int *) malloc(ptbl->size * sizeof(int));
    for(int i = 0; i < ptbl->size; i++) ptbl->table[i] = 2;
    return ptbl;
}

// Retrieves the smith 2 bit counter state of an entry in the table at the given index
int getEntryState(int index, PredTable *ptbl) {
    return ptbl->table[index];
}

// Updates the smith 2 bit counter state of an entry in the table at the given index with respect to the indicated outcome
PredTable *updateEntryState(int index, char outcome, PredTable *ptbl) {
    if(outcome == 't' && ptbl->table[index] < 3) ptbl->table[index]++;
    else if(outcome == 'n' && ptbl->table[index] > 0) ptbl->table[index]--;
    return ptbl;
}

// De-allocate space allocated for the table
PredTable *deleteTable(PredTable *ptbl) {
    free(ptbl->table);
    free(ptbl);
    return NULL;
}

// Gshare operations
int getIndex(unsigned long long int branchAddress, Register *reg, PredTable* ptbl);
int getPrediction(int index, PredTable* ptbl);
int simulateGShare(char actualOutcome, unsigned long long int branchAddress, Register *reg, PredTable* ptbl);

// Returns the history table index of the indicated branch address
int getIndex(unsigned long long int branchAddress, Register *reg, PredTable* ptbl) {
    // M = offset of table, N = size of reg

    // Remove two LSBs (PC Offset) and take M LSBs of that
    int maskedAddress = (branchAddress >> 2) & ptbl->mask;

    // Shift GHR left by M - N bits
    int shiftedReg = (reg->data) << (ptbl->offset - reg->size);

    // XOR the above to get the index
    int index = maskedAddress ^ shiftedReg;

    // Return 
    return index;
}

// Returns the prediction stored in the table at the given index
int getPrediction(int index, PredTable* ptbl) {
    int prediction = getEntryState(index, ptbl);
    return prediction;
}

// Predicts, compares predictions, and updates table predictors based on the comparision
// Returns 1 if prediction is correct, 0 if incorrect
int simulateGShare(char actualOutcome, unsigned long long int branchAddress, Register *reg, PredTable* ptbl) {

    // Predict
    int index = getIndex(branchAddress, reg, ptbl);
    int predictedOutcome = getPrediction(index, ptbl);
    
    // Compare actuality with prediction: Incorrect = 0, Correct = 1
    int res;
    if(actualOutcome == 't' && predictedOutcome > 1) res = 1;
    else if(actualOutcome == 'n' && predictedOutcome < 2) res = 1;
    else res = 0;

    // Update prediction table and global history register based on actual outcome
    ptbl = updateEntryState(index, actualOutcome, ptbl);
    reg = updateRegister(actualOutcome, reg);

    return res;
}