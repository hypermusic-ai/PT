#include <solana_sdk.h>

// Entry point of the program
extern "C" uint64_t entrypoint(const uint8_t *input) {
    // Parse input
    SolAccountInfo ka[1];
    SolParameters params = (SolParameters) { .ka = ka };

    if (!sol_deserialize(input, &params, SOL_ARRAY_SIZE(ka))) {
        return ERROR_INVALID_ARGUMENT;
    }

    // Example logic: just return success
    sol_log("Hello, Solana from C++!");
    return SUCCESS;
}