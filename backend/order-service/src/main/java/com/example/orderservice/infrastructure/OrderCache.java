package com.example.orderservice.infrastructure;

import com.example.orderservice.application.OrderResponse;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.dao.DataAccessException;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.data.redis.core.script.DefaultRedisScript;
import org.springframework.stereotype.Component;

import java.time.Duration;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * Redis-backed cache for order lookups, an idempotency store, and a
 * coordination lock for order creation.
 *
 * <p>Redis is used for three meaningful concerns:
 * <ul>
 *   <li><b>Short-lived order caching</b>: order responses are cached for a few
 *       minutes to reduce database load on frequent order retrievals, and are
 *       evicted whenever the order state changes.</li>
 *   <li><b>Order creation idempotency</b>: a client-supplied Idempotency-Key is
 *       mapped to the created order, so a retried request returns the original
 *       order instead of creating a duplicate.</li>
 *   <li><b>Coordination lock</b>: a short-lived lock serializes concurrent
 *       create requests for the same key.</li>
 * </ul>
 *
 * <p>Every operation is best-effort. If Redis is unavailable, reads degrade to
 * empty and writes become no-ops, so order creation still behaves
 * deterministically and the database unique index remains the correctness
 * authority.
 */
@Component
public class OrderCache {

    private static final Logger LOG = LoggerFactory.getLogger(OrderCache.class);

    private static final Duration ORDER_TTL = Duration.ofMinutes(5);
    private static final Duration IDEMPOTENCY_TTL = Duration.ofHours(24);
    private static final Duration LOCK_TTL = Duration.ofSeconds(15);

    private static final String ORDER_KEY_PREFIX = "orders:";
    private static final String IDEMPOTENCY_KEY_PREFIX = "idempotency:";
    private static final String LOCK_KEY_PREFIX = "idempotency:lock:";

    /** Lua script that deletes a lock only when its value still equals the token. */
    private static final DefaultRedisScript<Long> RELEASE_LOCK_SCRIPT = new DefaultRedisScript<>(
            "if redis.call('get', KEYS[1]) == ARGV[1] then "
                    + "return redis.call('del', KEYS[1]) else return 0 end",
            Long.class);

    private final RedisTemplate<String, String> redisTemplate;
    private final ObjectMapper objectMapper;

    public OrderCache(@Qualifier("redisTemplate") RedisTemplate<String, String> redisTemplate,
                      ObjectMapper objectMapper) {
        this.redisTemplate = redisTemplate;
        this.objectMapper = objectMapper;
    }

    /** Outcome of attempting to acquire the idempotency coordination lock. */
    public enum LockResult {
        /** The lock was acquired by this caller. */
        ACQUIRED,
        /** The lock is already held by another caller. */
        BUSY,
        /** Redis was unavailable, so the lock could not be tried. */
        UNAVAILABLE
    }

    public void cache(UUID orderId, OrderResponse response) {
        try {
            String json = objectMapper.writeValueAsString(response);
            redisTemplate.opsForValue().set(ORDER_KEY_PREFIX + orderId, json, ORDER_TTL);
        } catch (JsonProcessingException e) {
            throw new IllegalStateException("Failed to serialize order response", e);
        } catch (DataAccessException e) {
            warnUnavailable("cache order " + orderId, e);
        }
    }

    public Optional<OrderResponse> get(UUID orderId) {
        try {
            String json = redisTemplate.opsForValue().get(ORDER_KEY_PREFIX + orderId);
            if (json == null) {
                return Optional.empty();
            }
            try {
                return Optional.of(objectMapper.readValue(json, OrderResponse.class));
            } catch (JsonProcessingException e) {
                throw new IllegalStateException("Failed to deserialize order response", e);
            }
        } catch (DataAccessException e) {
            warnUnavailable("get order " + orderId, e);
            return Optional.empty();
        }
    }

    public void evict(UUID orderId) {
        try {
            redisTemplate.delete(ORDER_KEY_PREFIX + orderId);
        } catch (DataAccessException e) {
            warnUnavailable("evict order " + orderId, e);
        }
    }

    public void putIdempotency(String key, UUID orderId) {
        try {
            redisTemplate.opsForValue()
                    .set(IDEMPOTENCY_KEY_PREFIX + key, orderId.toString(), IDEMPOTENCY_TTL);
        } catch (DataAccessException e) {
            warnUnavailable("put idempotency " + key, e);
        }
    }

    public Optional<UUID> getIdempotency(String key) {
        try {
            String value = redisTemplate.opsForValue().get(IDEMPOTENCY_KEY_PREFIX + key);
            if (value == null) {
                return Optional.empty();
            }
            return Optional.of(UUID.fromString(value));
        } catch (DataAccessException e) {
            warnUnavailable("get idempotency " + key, e);
            return Optional.empty();
        }
    }

    public LockResult tryAcquireIdempotencyLock(String key, String token) {
        try {
            Boolean acquired =
                    redisTemplate.opsForValue().setIfAbsent(LOCK_KEY_PREFIX + key, token, LOCK_TTL);
            return Boolean.TRUE.equals(acquired) ? LockResult.ACQUIRED : LockResult.BUSY;
        } catch (DataAccessException e) {
            warnUnavailable("acquire idempotency lock " + key, e);
            return LockResult.UNAVAILABLE;
        }
    }

    public void releaseIdempotencyLock(String key, String token) {
        try {
            redisTemplate.execute(RELEASE_LOCK_SCRIPT, List.of(LOCK_KEY_PREFIX + key), token);
        } catch (DataAccessException e) {
            warnUnavailable("release idempotency lock " + key, e);
        }
    }

    private void warnUnavailable(String operation, DataAccessException e) {
        LOG.warn("Redis unavailable, degrading {}: {}", operation, e.getMessage());
    }
}
