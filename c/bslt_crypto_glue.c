/*
 * Basalt Clearinghouse Engine - High Performance Cryptographic Primitives
 * Standard-conformant SHA-256 compression and CRC32 verification
 */

#include "bslt_crypto_glue.h"
#include <string.h>

static inline uint32_t ror(uint32_t x, uint32_t n) {
    return (x >> n) | (x << (32 - n));
}

uint32_t bslt_rotr32(uint32_t x, uint32_t n) {
    return ror(x, n);
}

uint32_t bslt_rotl32(uint32_t x, uint32_t n) {
    return (x << n) | (x >> (32 - n));
}

uint32_t bslt_bswap32(uint32_t x) {
    return ((x & 0x000000FFU) << 24) |
           ((x & 0x0000FF00U) << 8)  |
           ((x & 0x00FF0000U) >> 8)  |
           ((x & 0xFF000000U) >> 24);
}

static const uint32_t K256[64] = {
    0x428a2f98U, 0x71374491U, 0xb5c0fbcfU, 0xe9b5dba5U,
    0x3956c25bU, 0x59f111f1U, 0x923f82a4U, 0xab1c5ed5U,
    0xd807aa98U, 0x12835b01U, 0x243185beU, 0x550c7dc3U,
    0x72be5d74U, 0x80deb1feU, 0x9bdc06a7U, 0xc19bf174U,
    0xe49b69c1U, 0xefbe4786U, 0x0fc19dc6U, 0x240ca1ccU,
    0x2de92c6fU, 0x4a7484aaU, 0x5cb0a9dcU, 0x76f988daU,
    0x983e5152U, 0xa831c66dU, 0xb00327c8U, 0xbf597fc7U,
    0xc6e00bf3U, 0xd5a79147U, 0x06ca6351U, 0x14292967U,
    0x27b70a85U, 0x2e1b2138U, 0x4d2c6dfcU, 0x53380d13U,
    0x650a7354U, 0x766a0abbU, 0x81c2c92eU, 0x92722c85U,
    0xa2bfe8a1U, 0xa81a664bU, 0xc24b8b70U, 0xc76c51a3U,
    0xd192e819U, 0xd6990624U, 0xf40e3585U, 0x106aa070U,
    0x19a4c116U, 0x1e376c08U, 0x2748774cU, 0x34b0bcb5U,
    0x391c0cb3U, 0x4ed8aa4aU, 0x5b9cca4fU, 0x682e6ff3U,
    0x748f82eeU, 0x78a5636fU, 0x84c87814U, 0x8cc70208U,
    0x90befffaU, 0xa4506cebU, 0xbef9a3f7U, 0xc67178f2U
};

#define CH(x, y, z)  (((x) & (y)) ^ (~(x) & (z)))
#define MAJ(x, y, z) (((x) & (y)) ^ ((x) & (z)) ^ ((y) & (z)))
#define EP0(x)       (ror(x, 2) ^ ror(x, 13) ^ ror(x, 22))
#define EP1(x)       (ror(x, 6) ^ ror(x, 11) ^ ror(x, 25))
#define SIG0(x)      (ror(x, 7) ^ ror(x, 18) ^ ((x) >> 3))
#define SIG1(x)      (ror(x, 17) ^ ror(x, 19) ^ ((x) >> 10))

void bslt_sha256_transform(uint32_t state[8], const uint8_t block[64]) {
    uint32_t w[64];
    uint32_t a, b, c, d, e, f, g, h;
    int i;

    for (i = 0; i < 16; ++i) {
        w[i] = ((uint32_t)block[i * 4] << 24) |
               ((uint32_t)block[i * 4 + 1] << 16) |
               ((uint32_t)block[i * 4 + 2] << 8) |
               ((uint32_t)block[i * 4 + 3]);
    }
    for (i = 16; i < 64; ++i) {
        w[i] = SIG1(w[i - 2]) + w[i - 7] + SIG0(w[i - 15]) + w[i - 16];
    }

    a = state[0];
    b = state[1];
    c = state[2];
    d = state[3];
    e = state[4];
    f = state[5];
    g = state[6];
    h = state[7];

    for (i = 0; i < 64; ++i) {
        uint32_t t1 = h + EP1(e) + CH(e, f, g) + K256[i] + w[i];
        uint32_t t2 = EP0(a) + MAJ(a, b, c);
        h = g;
        g = f;
        f = e;
        e = d + t1;
        d = c;
        c = b;
        b = a;
        a = t1 + t2;
    }

    state[0] += a;
    state[1] += b;
    state[2] += c;
    state[3] += d;
    state[4] += e;
    state[5] += f;
    state[6] += g;
    state[7] += h;
}

void bslt_sha256_full(const uint8_t *data, size_t len, uint8_t digest[32]) {
    uint32_t state[8] = {
        0x6a09e667U, 0xbb67ae85U, 0x3c6ef372U, 0xa54ff53aU,
        0x510e527fU, 0x9b05688cU, 0x1f83d9abU, 0x5be0cd19U
    };
    uint8_t buffer[64];
    size_t rem = len;
    const uint8_t *ptr = data;
    uint64_t total_bits = (uint64_t)len * 8ULL;
    size_t i;

    while (rem >= 64) {
        bslt_sha256_transform(state, ptr);
        ptr += 64;
        rem -= 64;
    }

    memset(buffer, 0, 64);
    memcpy(buffer, ptr, rem);
    buffer[rem] = 0x80;

    if (rem >= 56) {
        bslt_sha256_transform(state, buffer);
        memset(buffer, 0, 64);
    }

    for (i = 0; i < 8; ++i) {
        buffer[63 - i] = (uint8_t)(total_bits >> (i * 8));
    }
    bslt_sha256_transform(state, buffer);

    for (i = 0; i < 8; ++i) {
        digest[i * 4]     = (uint8_t)(state[i] >> 24);
        digest[i * 4 + 1] = (uint8_t)(state[i] >> 16);
        digest[i * 4 + 2] = (uint8_t)(state[i] >> 8);
        digest[i * 4 + 3] = (uint8_t)(state[i]);
    }
}

uint32_t bslt_crc32(const uint8_t *buf, size_t len) {
    uint32_t crc = 0xFFFFFFFFU;
    size_t i, j;
    for (i = 0; i < len; ++i) {
        crc ^= (uint32_t)buf[i];
        for (j = 0; j < 8; ++j) {
            if (crc & 1) {
                crc = (crc >> 1) ^ 0xEDB88320U;
            } else {
                crc >>= 1;
            }
        }
    }
    return ~crc;
}
