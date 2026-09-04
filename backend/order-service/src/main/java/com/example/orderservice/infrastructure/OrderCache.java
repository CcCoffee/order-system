package com.example.orderservice.infrastructure;

import com.example.orderservice.application.OrderResponse;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.stereotype.Component;

import java.time.Duration;
import java.util.Optional;
import java.util.UUID;

/**
 * Redis-backed cache for order lookups and an idempotency store for order creation.
 *
 * <p>Redis is used for two meaningful concerns:
 * <ul>
 *   <li><b>Short-lived order caching</b>: order responses are cached for a few
 *       minutes to reduce database load on frequent order retrievals, and are
 *       evicted whenever the order state changes.</li>
 *   <li><b>Order creation idempotency</b>: a client-supplied Idempotency-Key is
 *       mapped to the created order, so a retried request returns the original
 *       order instead of creating a duplicate.</li>
 * </ul>
 */
@Component
public class OrderCache {

    private static final Duration ORDER_TTL = Duration.ofMinutes(5);
    private static final Duration IDEMPOTENCY_TTL = Duration.ofHours(24);
    private static final String ORDER_KEY_PREFIX = "orders:";
    private static final String IDEMPOTENCY_KEY_PREFIX = "idempotency:";

    private final RedisTemplate<String, String> redisTemplate;
    private final ObjectMapper objectMapper;

    public OrderCache(@Qualifier("redisTemplate") RedisTemplate<String, String> redisTemplate,
                      ObjectMapper objectMapper) {
        this.redisTemplate = redisTemplate;
        this.objectMapper = objectMapper;
    }

    public void cache(UUID orderId, OrderResponse response) {
        try {
            redisTemplate.opsForValue()
                    .set(ORDER_KEY_PREFIX + orderId, objectMapper.writeValueAsString(response), ORDER_TTL);
        } catch (JsonProcessingException e) {
            throw new IllegalStateException("Failed to serialize order response", e);
        }
    }

    public Optional<OrderResponse> get(UUID orderId) {
        String json = redisTemplate.opsForValue().get(ORDER_KEY_PREFIX + orderId);
        if (json == null) {
            return Optional.empty();
        }
        try {
            return Optional.of(objectMapper.readValue(json, OrderResponse.class));
        } catch (JsonProcessingException e) {
            throw new IllegalStateException("Failed to deserialize order response", e);
        }
    }

    public void evict(UUID orderId) {
        redisTemplate.delete(ORDER_KEY_PREFIX + orderId);
    }

    public void putIdempotency(String key, UUID orderId) {
        redisTemplate.opsForValue()
                .set(IDEMPOTENCY_KEY_PREFIX + key, orderId.toString(), IDEMPOTENCY_TTL);
    }

    public Optional<UUID> getIdempotency(String key) {
        String value = redisTemplate.opsForValue().get(IDEMPOTENCY_KEY_PREFIX + key);
        if (value == null) {
            return Optional.empty();
        }
        return Optional.of(UUID.fromString(value));
    }
}
