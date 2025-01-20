// Esperandieu Elbon II - UCFID: 5401262
// EEL4768 Computer Architecture - Suboh Suboh - Fall 2023
// Implementing a Flexible Cache Simulator 

#include <stdio.h>
#include <stdlib.h>

// Cache Block
typedef struct Block Block;
struct Block {
    int dirty;          // Dirty bit
    unsigned long long int tag;  // Tag
    Block *prev, *next; // Block links
};

// Cache Set
typedef struct Set Set;
struct Set {
    int size, capacity; // Set properties
    Block *tracker;     // Most recently accessed block
};

// Cache 
typedef struct Cache Cache;
struct Cache {
    int associativty, numberOfSets, replacementPolicy, writePolicy; // Cache properties
    Set **tagArray;  // Tag array
};

// Block Functions
Block *createBlock(unsigned long long int tag);
Block *linkBlocks(unsigned long long int tag, Block *block);
Block *unlinkBlocks(Block *block);

// Set Functions
Set *createSet(int capacity);
Set *insertBlock(int operation, int event, int writePolicy, unsigned long long int tag , Set *set);
Set *removeBlock(int writePolicy, int replacementPolicy, int event, Block *target, Set *set);
Block *searchSet(unsigned long long int tag, Set *set);
void deleteSet(Set *set);

// Cache Functions
Cache *createCache(int associativity, int numberOfSets, int replacementPoliocy, int writePolicy);
void simulateCacheAccess(char operation, unsigned long long int address, Cache *cache);
Set *updateCache_LRU(int event, char operation, int writePolicy, unsigned long long int tag, Block* block, Set *set);
Set *updateCache_FIFO(int event, char operation, int writePolicy, unsigned long long int tag, Block* block, Set *set);
void clearCache(Cache *cache);
void displayCache(Cache  *cache);

// Cache Parameters
int hits, misses, reads, writes;
#define BLOCK_SIZE 64
#define FIFO 1
#define LRU 0
#define WRITE_BACK 1
#define WRITE_THROUGH 0
#define HIT 1
#define MISS 0
#define DIRTY 1

// Statistics
void simulationStatistics ();
void printReportStats(int cacheSize, int associativity, int replacementPolicy, int writePolicy, char *traceFile);
void singleTest(int cacheSize, int associativity, int replacementPolicy, int writePolicy, char *traceFile);
void partA();
void partB();
void partC();
void partD();
void conductExperiments();

// argc # of arguments, start at 1 b/c 0 is program name 
// argv <Cache Size>, <Associativity>, <Replacement Policy>, <Write Back>, <TRACE_FILE>
// Policy: LRU = 0, FIFO = 1. Write Back: Write Through = 0, Write Back = 1
int main(int argc, char* argv[]) {

    // Create new cache with specififed parameters
    int associativity = (int) strtol(argv[2], NULL, 0), policy = (int) strtol(argv[3], NULL, 0), writeBack = (int) strtol(argv[4], NULL, 0);
    int cacheSize = (int) strtol(argv[1], NULL, 0);
    int numSets = cacheSize / (associativity * BLOCK_SIZE);
    Cache *cache = createCache(associativity, numSets, policy, writeBack);

    // Read file
    char *traceFile = argv[5];
    FILE *file = fopen(traceFile, "r");

    // Validate Path
    if(!file) {
        printf("Bad Path.\n");
        return 1;
    }

    // Begin simulation
    else {
        char operation;
        unsigned long long int address;
        int counter = 0;
        while(!feof(file)) {
            fscanf(file, "%c %llx ", &operation, &address);
            simulateCacheAccess(operation, address, cache);
        }
        simulationStatistics ();

        // Free cache memory
        clearCache(cache);
    }

    // End Simulation
    fclose(file);
    return 0;
}

// Block Function Definitons
Block *createBlock(unsigned long long int tag) {
    // New Block
   Block *newBlock = (Block *) malloc(sizeof(Block));

   // Initialize block memebers
   newBlock->dirty = 0;
   newBlock->tag = tag;
   newBlock->prev = newBlock;
   newBlock->next = newBlock;

   // Return new block
   return newBlock;
}

Block *linkBlocks(unsigned long long int tag, Block *block) {
    // Block to link with passed in block
    Block *newBlock = createBlock(tag);

    // Empty Set
    if(block == NULL) return newBlock;

    // Link Up
    newBlock->prev = block;
    newBlock->next = block->next;
    block->next->prev = newBlock;
    block->next = newBlock;

    // Return
    return newBlock;
}

Block *unlinkBlocks(Block *block) {
    // Empty set
    if(block == NULL) return NULL;
    
    // Single block set, remove only block
    else if(block == block->next || block == block->prev) {
        free(block);
        return NULL;
    }

    // Multiple blocks
    Block *newBlock = block->prev;
    block->next->prev = newBlock;
    newBlock->next = block->next;

    // Free unlinked block and return new block
    free(block);
    return newBlock;
}

// Set Function Defintions
Set *createSet(int capacity) {
    // New set
    Set *newSet = (Set *) malloc(sizeof(Set));

    // Initialize set members
    newSet->capacity = capacity;
    newSet->size = 0;
    newSet->tracker = NULL;

    // Return new set
    return newSet;
}

Set *insertBlock(int operation, int event, int writePolicy, unsigned long long int tag , Set *set) {
    // Only add to sets when not at capacity.
    if(set->size < set->capacity) {
        set->tracker = linkBlocks(tag, set->tracker);

        // Write back condiiton check, simulataneously increment size (only mark dirty blocks when set not empty)
        if(set->size++ > 0 && operation == 'W' && event == HIT && writePolicy == WRITE_BACK) set->tracker->dirty = DIRTY;
    }
    return set;
}

Set *removeBlock(int writePolicy, int replacementPolicy, int event, Block *target, Set *set) { 
    
    // Write Back if Write Hit and evicting dirty block
    int evicting = (writePolicy == WRITE_BACK) && (event == MISS);

    // FIFO Hit == unchanged set, FIFO Miss below
    if(replacementPolicy == FIFO && event == MISS) {
        // Evict FIFO always removes the head, target == NULL b/c Miss
        if(evicting && set->tracker->next->dirty == DIRTY) writes++;
        set->tracker = unlinkBlocks(set->tracker->next); 
    }
    else if(replacementPolicy == LRU) {
        if(event == HIT) {
            // Target = Head
            if(target == set->tracker->next) set->tracker = unlinkBlocks(set->tracker->next);

            // Target = Tail
            else if(target == set->tracker) set->tracker = unlinkBlocks(set->tracker);

            // Target = middle of set
            else unlinkBlocks(target);
        }
        // Evict LRU always removes the head, target == NULL b/c Miss
        else if(event == MISS) {
            if(evicting && set->tracker->next->dirty == DIRTY) writes++;
            set->tracker = unlinkBlocks(set->tracker->next);
        }
    }
    
    // Reduce set size, return
    set->size--;
    return set;
}

Block *searchSet(unsigned long long int tag, Set *set) {
    Block *currBlock = set->tracker;
    if(currBlock != NULL) {
        do {
            if(tag == currBlock->tag) return currBlock;
            else currBlock = currBlock->next;
        } while(currBlock != set->tracker);
    }
    return NULL;
}

void deleteSet(Set *set) {
    // Empty the set and then free it
    while(set->tracker != NULL) set->tracker = unlinkBlocks(set->tracker);
    free(set);
}

// Cache Function Definitions 
Cache *createCache(int associativity, int numberOfSets, int replacementPolicy, int writePolicy) {
    // Create new cache
    Cache *newCache = (Cache *) malloc(sizeof(Cache));

    // Initialize the tag array (array of set pointers)
    newCache->tagArray = (Set **) malloc(numberOfSets * sizeof(Set *));
    for(int i = 0; i <numberOfSets; i++) newCache->tagArray[i] = createSet(associativity);
    
    // Initialize the rest of the cache members
    newCache->associativty = associativity;
    newCache->numberOfSets = numberOfSets;
    newCache->replacementPolicy = replacementPolicy;
    newCache->writePolicy = writePolicy;

    // Return new cache
    return newCache;
}

void simulateCacheAccess(char operation, unsigned long long int address, Cache *cache) {
    // Calculate the set number/cache index and tag of the indicated address
    unsigned long long int tag = address / BLOCK_SIZE;
    int setNumber = (address / BLOCK_SIZE) % cache->numberOfSets;

    // Search for address
    Set *targetSet = cache->tagArray[setNumber];
    Block *targetBlock = searchSet(tag, targetSet);
    //printf("target set = %d -> ", setNumber);
    // Hit
    if(targetBlock !=  NULL) {
        //printf("%c HIT -> ", operation);
        // Increment hit counter. Increment writes on write hit and write throuh
        if(operation == 'W' && cache->writePolicy == WRITE_THROUGH) writes++;
        hits++;

        // Update Cache Block in both Write Through and Write Back
        if(cache->replacementPolicy == FIFO) targetSet = updateCache_FIFO(HIT, operation, cache->writePolicy, tag, targetBlock, targetSet); 
        else if(cache->replacementPolicy == LRU) targetSet = updateCache_LRU(HIT, operation, cache->writePolicy, tag, targetBlock, targetSet);
    }
    // Miss
    else {
        //printf("%c MISS -> ", operation);
        // Increment misses
        misses++;

        // Write miss. Write to memory.
        // Assuming from tests and sample input: a mixed Write allocate/no allocate policy
        // This means that we write to main memeory first then
        // We load the block into memory via a read
        if(operation == 'W') {
            writes++;
            reads++;
        }

        // Read miss, fetch from memory
        else if(operation == 'R') reads++;

        // Update cache block
        if(cache->replacementPolicy == FIFO) targetSet = updateCache_FIFO(MISS, operation, cache->writePolicy, tag, targetBlock, targetSet);
        else if(cache->replacementPolicy == LRU) targetSet = updateCache_LRU(MISS, operation, cache->writePolicy, tag, targetBlock, targetSet);
    }
}

Set *updateCache_LRU(int event, char operation, int writePolicy, unsigned long long int tag, Block* block, Set *set) {
    
    if(event == HIT) {
        // Remove tag and re add to move it up the stack IF not alr at the top
        set = removeBlock(writePolicy, LRU, event, block, set);
        set = insertBlock(operation, event, writePolicy, tag, set);
    }
    else {
        // Cold miss
        if(set->size < set->capacity) set = insertBlock(operation, event, writePolicy, tag, set);
        
        // Capacity Miss: Evict
        else if(set->size == set->capacity) {
            set = removeBlock(writePolicy, LRU, event, block, set);
            set = insertBlock(operation, event, writePolicy, tag, set);
        }
    }

    // Return the updated set
    return set;
}

Set *updateCache_FIFO(int event, char operation, int writePolicy, unsigned long long int tag, Block* block, Set *set) {
    
    if(event == HIT){
        // Mark block as dirty if Write and Write Back
        if(operation == 'W' && writePolicy == WRITE_BACK) block->dirty = DIRTY;
    } 
    else {
        // Cold miss
        if(set->size < set->capacity) set = insertBlock(operation, event, writePolicy, tag, set);
        
        // Capacity Miss: Evict
        else if(set->size == set->capacity) {
            set = removeBlock(writePolicy, FIFO, event, block, set);
            set = insertBlock(operation, event, writePolicy, tag, set);
        }      
    }

    // Return the updated set
    return set;
}

void clearCache(Cache *cache) {
    // Empty the tag array, free it, free the cache
    for(int i = 0; i < cache->numberOfSets; i++) deleteSet(cache->tagArray[i]);
    free(cache->tagArray);
    free(cache);
}

void displayCache(Cache *cache) {
    for(int i = 0; i < cache->numberOfSets; i++) {
        Set *currSet = cache->tagArray[i];

        if(currSet == NULL) {
            printf("Null set\n");
            return;
        }
        if(currSet->tracker == NULL) {
            printf("\t[Set #: %d. Size: 0. Tracker: NULL] \t | ", i);
            for(int j = 0; j < currSet->capacity; j++) {
                printf(" -\t");  
            }
            printf("| Tail -> NULL\n");
            continue;
        }
    
        Block *currBlock = currSet->tracker->next;
        Block *end = currBlock;

        printf("\t[Set #: %d. Size %d. Tracker: %llx] \tHead -> %llx | ", i, currSet->size, currSet->tracker->tag, currBlock->tag);
        for(int i = 0; i < currSet->capacity - currSet->size; i++) printf("- ");
        do { 
            printf("%llx ", currBlock->tag);
            currBlock = currBlock->next;
        } while (currBlock != end);
        printf("| Tail -> %llx\n", currBlock->prev->tag);
    }
}

void printReportStats(int cacheSize, int associativity, int replacementPolicy, int writePolicy, char *traceFile) {
    // Output desired simualtion stats
    printf("\t%d %d %d %d %s:\t", cacheSize, associativity, replacementPolicy, writePolicy, traceFile);
    printf("%.6f", (double) misses / (double) (hits + misses));
    printf("\t%d", writes);
    printf("\t%d\n", reads);
    hits = 0; misses = 0; reads = 0; writes = 0;
}

void singleTest(int cacheSize, int associativity, int replacementPolicy, int writePolicy, char *traceFile) {
    FILE *file = fopen(traceFile, "r");
    if(!file) printf("Bad Path.\n");
    else {
        fseek(file, 0, SEEK_SET);
        int numSets = cacheSize / (associativity * BLOCK_SIZE);
        Cache *cache = createCache(associativity, numSets, replacementPolicy, writePolicy);
        char operation;
        unsigned long long int address;
        while(!feof(file)) {
            fscanf(file, "%c %llx ", &operation, &address);
            simulateCacheAccess(operation, address, cache);
        }
        printReportStats(cacheSize, associativity, replacementPolicy, writePolicy, traceFile);
        clearCache(cache);
    }
    fclose(file);
}

void conductExperiments() {
    partA();
    partB();
    partC();
    partD();
}

void partA() {
    printf("================================= PART A =================================\n"); 
    printf("XSBENCH.t\n") ;
    singleTest(8192, 4, LRU, WRITE_BACK, "TRACES/XSBENCH.t");
    singleTest(16384, 4, LRU, WRITE_BACK, "TRACES/XSBENCH.t");
    singleTest(32768, 4, LRU, WRITE_BACK, "TRACES/XSBENCH.t");
    singleTest(65536, 4, LRU, WRITE_BACK, "TRACES/XSBENCH.t");
    singleTest(131072, 4, LRU, WRITE_BACK, "TRACES/XSBENCH.t");
    printf("MINIFE.t\n") ;
    singleTest(8192, 4, LRU, WRITE_BACK, "TRACES/MINIFE.t");
    singleTest(16384, 4, LRU, WRITE_BACK, "TRACES/MINIFE.t");
    singleTest(32768, 4, LRU, WRITE_BACK, "TRACES/MINIFE.t");
    singleTest(65536, 4, LRU, WRITE_BACK, "TRACES/MINIFE.t");
    singleTest(131072, 4, LRU, WRITE_BACK, "TRACES/MINIFE.t");
    printf("\n");
}

void partB() {
    printf("================================= PART B =================================\n");
    printf("XSBENCH.t\n") ;
    singleTest(8192, 4, LRU, WRITE_THROUGH, "TRACES/XSBENCH.t");
    singleTest(16384, 4, LRU, WRITE_THROUGH, "TRACES/XSBENCH.t");
    singleTest(32768, 4, LRU, WRITE_THROUGH, "TRACES/XSBENCH.t");
    singleTest(65536, 4, LRU, WRITE_THROUGH, "TRACES/XSBENCH.t");
    singleTest(131072, 4, LRU, WRITE_THROUGH, "TRACES/XSBENCH.t");
    printf("MINIFE.t\n") ;
    singleTest(8192, 4, LRU, WRITE_THROUGH, "TRACES/MINIFE.t");
    singleTest(16384, 4, LRU, WRITE_THROUGH, "TRACES/MINIFE.t");
    singleTest(32768, 4, LRU, WRITE_THROUGH, "TRACES/MINIFE.t");
    singleTest(65536, 4, LRU, WRITE_THROUGH, "TRACES/MINIFE.t");
    singleTest(131072, 4, LRU, WRITE_THROUGH, "TRACES/MINIFE.t");
    printf("\n");
}

void partC() {
    printf("================================= PART C =================================\n"); 
    printf("XSBENCH.t\n") ;
    singleTest(32768, 1, LRU, WRITE_BACK, "TRACES/XSBENCH.t");
    singleTest(32768, 2, LRU, WRITE_BACK, "TRACES/XSBENCH.t");
    singleTest(32768, 4, LRU, WRITE_BACK, "TRACES/XSBENCH.t");
    singleTest(32768, 8, LRU, WRITE_BACK, "TRACES/XSBENCH.t");
    singleTest(32768, 16, LRU, WRITE_BACK, "TRACES/XSBENCH.t");
    singleTest(32768, 32, LRU, WRITE_BACK, "TRACES/XSBENCH.t");
    singleTest(32768, 64, LRU, WRITE_BACK, "TRACES/XSBENCH.t");
    printf("MINIFE.t\n") ;
    singleTest(32768, 1, LRU, WRITE_BACK, "TRACES/MINIFE.t");
    singleTest(32768, 2, LRU, WRITE_BACK, "TRACES/MINIFE.t");
    singleTest(32768, 4, LRU, WRITE_BACK, "TRACES/MINIFE.t");
    singleTest(32768, 8, LRU, WRITE_BACK, "TRACES/MINIFE.t");
    singleTest(32768, 16, LRU, WRITE_BACK, "TRACES/MINIFE.t");
    singleTest(32768, 32, LRU, WRITE_BACK, "TRACES/MINIFE.t");
    singleTest(32768, 64, LRU, WRITE_BACK, "TRACES/MINIFE.t");
    printf("\n");
}

void partD() {
    printf("================================= PART D =================================\n"); 
    printf("XSBENCH.t\n") ;
    singleTest(8192, 4, FIFO, WRITE_BACK, "TRACES/XSBENCH.t");
    singleTest(16384, 4, FIFO, WRITE_BACK, "TRACES/XSBENCH.t");
    singleTest(32768, 4, FIFO, WRITE_BACK, "TRACES/XSBENCH.t");
    singleTest(65536, 4, FIFO, WRITE_BACK, "TRACES/XSBENCH.t");
    singleTest(131072, 4, FIFO, WRITE_BACK, "TRACES/XSBENCH.t");
    printf("MINIFE.t\n") ;
    singleTest(8192, 4, FIFO, WRITE_BACK, "TRACES/MINIFE.t");
    singleTest(16384, 4, FIFO, WRITE_BACK, "TRACES/MINIFE.t");
    singleTest(32768, 4, FIFO, WRITE_BACK, "TRACES/MINIFE.t");
    singleTest(65536, 4, FIFO, WRITE_BACK, "TRACES/MINIFE.t");
    singleTest(131072, 4, FIFO, WRITE_BACK, "TRACES/MINIFE.t");
    printf("\n");
}

void simulationStatistics () {
    // Outpute desired simualtion stats
    printf("Miss Ratio: \t%.6f\n", (double) misses / (double) (hits + misses));
    printf("Writes: \t%d\n", writes);
    printf("Reads: \t\t%d\n", reads);
}
