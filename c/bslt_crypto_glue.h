/*
 * Basalt Clearinghouse Engine - High Performance Cryptographic Primitives
 * 32-bit bitwise rotation, endian transformation, and SHA-256 compression
 */

#ifndef BSLT_CRYPTO_GLUE_H
#define BSLT_CRYPTO_GLUE_H

#include <stdint.h>
#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

uint32_t bslt_rotr32(uint32_t x, uint32_t n);
uint32_t bslt_rotl32(uint32_t x, uint32_t n);
uint32_t bslt_bswap32(uint32_t x);

/* SHA-256 compression function over a 64-byte block */
void bslt_sha256_transform(uint32_t state[8], const uint8_t block[64]);

/* Direct full SHA-256 calculation */
void bslt_sha256_full(const uint8_t *data, uint32_t len, uint8_t digest[32]);

/* CRC32 calculation for ARIES WAL records and storage pages */
uint32_t bslt_crc32(const uint8_t *buf, uint32_t len);

#ifdef __cplusplus
}
#endif

#endif /* BSLT_CRYPTO_GLUE_H */
