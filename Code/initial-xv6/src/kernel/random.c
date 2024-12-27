// kernel/random.c
#ifdef LBS
// unsigned long random_seed = 1;

// // Simple Linear Congruential Generator (LCG)
// unsigned long rand_num(void){
//     random_seed = (random_seed * 1103515245 + 12345) & 0x7fffffff;
//     return random_seed;
// }

unsigned long rand_num(void) {
    static unsigned long random_seed = 1; // Static to retain value between calls
    random_seed = (random_seed * 1103515245 + 12345) & 0x7fffffff;
    return random_seed;
}

#endif