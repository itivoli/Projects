// Esperandieu Elbon II - UCFID: 5401262
// EEL4768 Computer Architecture - Suboh Suboh - Fall 2023
// Implementing a Branch Predictor Simulator 

#include <stdio.h>
#include <stdlib.h>
#include "gsharebase.h"

// argc # of arguments, start at 1 b/c 0 is program name 
// argv <GPB> <RB> <Trace_File>
// GPB = # of bits to index history table, RB = size in bits of global register
int main(int argc, char* argv[]) {

    // Ensure valid # of arguments given
    if(argc != 4) {
        printf("Invalid number of arguments.\n");
        return 1;
    }

    // Read file
    char *traceFile = argv[3];
    FILE *file = fopen(traceFile, "r");

    // Validate Path
    if(!file) {
        printf("Bad Path.\n");
        return 1;
    }

    // Take input arguments
    int tableOffset = (int) strtol(argv[1], NULL, 0);
    int regSize = (int) strtol(argv[2], NULL, 0);

    // Begin simulation
    char outcome;
    unsigned long long int address;
    int missed = 0, predicted = 0, total = 0;
    Register *globalBranchHistoryRegister = createRegister(regSize);
    PredTable *BranchHistoryPredictionTable = createTable(tableOffset);

    while(!feof(file)) {
        fscanf(file, " %llx %c ", &address, &outcome);
        int res = simulateGShare(outcome, address, globalBranchHistoryRegister, BranchHistoryPredictionTable);
        if(res == 1) predicted++;
        else if (res == 0) missed++;
        total++;
    }

    // End Simulation
    deleteRegister(globalBranchHistoryRegister);
    deleteTable(BranchHistoryPredictionTable);
    fclose(file);
    
    // Calculate missed prediction ratio and output results
    double missRatio = (double) missed / (double) total;
    printf("%d %d %.5f", regSize, tableOffset, missRatio);

    return 0;
}