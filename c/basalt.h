/*
 * Basalt Clearinghouse Engine - Native C Interop API
 * High-performance zero-copy C bindings for the COBOL settlement kernel.
 */

#ifndef BASALT_H
#define BASALT_H

#include <stdint.h>
#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

/* Return codes */
#define BSLT_OK                     0
#define BSLT_ERR_INSUFFICIENT_FUNDS 1001
#define BSLT_ERR_NOT_FOUND          1002
#define BSLT_ERR_INVALID_STATE      1003
#define BSLT_ERR_PAGE_FULL          1004
#define BSLT_ERR_PARSE_ERROR        1005
#define BSLT_ERR_CHECKSUM_MISMATCH  1006
#define BSLT_ERR_LOCK_TIMEOUT       1007
#define BSLT_ERR_DUPLICATE          1008
#define BSLT_ERR_INVALID_AMOUNT     1009
#define BSLT_ERR_CREDIT_LIMIT       1010

/* Initialization and shutdown */
int bslt_init(void);
void bslt_shutdown(void);

/* Ledger and Account management */
int bslt_account_create(const char *acc_id, const char *bic, const char *ccy, int acc_type, double credit_limit);
int bslt_account_credit(const char *acc_id, double amount);
int bslt_account_debit(const char *acc_id, double amount);
int bslt_account_get_balance(const char *acc_id, double *out_balance, double *out_available);

/* Multilateral Netting and Settlement */
int bslt_netting_run_cycle(uint16_t num_nodes, uint32_t num_edges, uint16_t *out_cycles, double *out_volume);

/* Risk and SPAN Margining */
int bslt_risk_span_calc(uint16_t pos_count, double *out_margin);
int bslt_risk_var_calc(double confidence, double *out_var, double *out_es);

/* Storage and Recovery */
int bslt_storage_checkpoint(uint64_t *out_checkpoint_lsn);
int bslt_storage_recover(uint64_t *out_recovered_lsn);

#ifdef __cplusplus
}
#endif

#endif /* BASALT_H */
