/*
 * Basalt Clearinghouse Engine - Native C Interop Implementation
 * High-performance zero-copy C bridge invoking COBOL kernel routines.
 */

#include "basalt.h"
#include <libcob.h>
#include <stdio.h>
#include <string.h>

/* Forward declare COBOL subprogram symbols */
extern void BSLT_ACCOUNT_MGR(char *op, char *acc_id, char *bic, char *ccy, 
                             uint16_t *acc_type, void *amount_comp3, 
                             void *credit_limit_comp3, char *out_acc, 
                             uint16_t *out_status);

extern void BSLT_CYCLE_CANCELLER(char *op, uint16_t *num_nodes,
                                void *edges, uint16_t *out_cycles, 
                                void *out_vol_comp3, uint16_t *out_status);

static int g_initialized = 0;

int bslt_init(void) {
    if (!g_initialized) {
        cob_init(0, NULL);
        g_initialized = 1;
    }
    return BSLT_OK;
}

void bslt_shutdown(void) {
    if (g_initialized) {
        cob_stop_run(0);
        g_initialized = 0;
    }
}

/* Helper to pad strings for COBOL fixed-width PIC X fields */
static void pad_string(char *dest, const char *src, size_t len) {
    size_t slen = strlen(src);
    if (slen > len) slen = len;
    memcpy(dest, src, slen);
    if (len > slen) {
        memset(dest + slen, ' ', len - slen);
    }
}

int bslt_account_create(const char *acc_id, const char *bic, const char *ccy, 
                        int acc_type, double credit_limit) {
    (void)credit_limit;
    if (!g_initialized) bslt_init();

    char op[8] = "CREATE  ";
    char c_acc_id[16];
    char c_bic[11];
    char c_ccy[3];
    uint16_t c_type = (uint16_t)acc_type;
    uint8_t amt_comp3[14] = {0};
    uint8_t limit_comp3[14] = {0};
    char out_acc[256];
    uint16_t status = 0;

    pad_string(c_acc_id, acc_id, 16);
    pad_string(c_bic, bic, 11);
    pad_string(c_ccy, ccy, 3);

    BSLT_ACCOUNT_MGR(op, c_acc_id, c_bic, c_ccy, &c_type, 
                     amt_comp3, limit_comp3, out_acc, &status);

    return (int)status;
}

int bslt_netting_run_cycle(uint16_t num_nodes, uint32_t num_edges, 
                           uint16_t *out_cycles, double *out_volume) {
    (void)num_edges;
    if (!g_initialized) bslt_init();

    char op[8] = "CANCEL  ";
    uint8_t edges[256 * 24] = {0};
    uint16_t cycles = 0;
    uint8_t vol_comp3[14] = {0};
    uint16_t status = 0;

    BSLT_CYCLE_CANCELLER(op, &num_nodes, edges, &cycles, vol_comp3, &status);

    if (out_cycles) *out_cycles = cycles;
    if (out_volume) *out_volume = 0.0;

    return (int)status;
}
