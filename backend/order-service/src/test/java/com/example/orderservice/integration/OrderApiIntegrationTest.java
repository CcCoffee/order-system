package com.example.orderservice.integration;

import com.example.orderservice.api.dto.CreateOrderItemRequest;
import com.example.orderservice.api.dto.CreateOrderRequest;
import com.example.orderservice.application.OrderResponse;
import com.example.orderservice.domain.OrderStatus;
import org.junit.jupiter.api.Tag;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;

import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

@Tag("integration")
class OrderApiIntegrationTest extends AbstractIntegrationTest {

    private static final UUID WIDGET = UUID.fromString("11111111-1111-1111-1111-111111111111");

    @Test
    void createOrderReturnsCreatedPending() {
        ResponseEntity<OrderResponse> response = postOrder(WIDGET, 2);
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.CREATED);
        assertThat(response.getBody()).isNotNull();
        assertThat(response.getBody().status()).isEqualTo(OrderStatus.PENDING);
        assertThat(response.getBody().totalAmount()).isEqualByComparingTo("20.00");
        assertThat(response.getBody().items()).hasSize(1);
        cancel(response.getBody().id());
    }

    @Test
    void getOrderReturnsOrderDetails() {
        UUID orderId = postOrder(WIDGET, 2).getBody().id();
        ResponseEntity<OrderResponse> response =
                rest.getForEntity("/api/orders/" + orderId, OrderResponse.class);
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(response.getBody()).isNotNull();
        assertThat(response.getBody().id()).isEqualTo(orderId);
        assertThat(response.getBody().status()).isEqualTo(OrderStatus.PENDING);
        assertThat(response.getBody().totalAmount()).isEqualByComparingTo("20.00");
        assertThat(response.getBody().createdAt()).isNotNull();
        cancel(orderId);
    }

    @Test
    void cancelPendingOrderTransitionsToCancelled() {
        UUID orderId = postOrder(WIDGET, 1).getBody().id();
        ResponseEntity<OrderResponse> response =
                rest.postForEntity("/api/orders/" + orderId + "/cancel", null, OrderResponse.class);
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(response.getBody()).isNotNull();
        assertThat(response.getBody().status()).isEqualTo(OrderStatus.CANCELLED);
    }

    @Test
    void cancelSecondTimeReturnsConflict() {
        UUID orderId = postOrder(WIDGET, 1).getBody().id();
        rest.postForEntity("/api/orders/" + orderId + "/cancel", null, OrderResponse.class);
        ResponseEntity<OrderResponse> second =
                rest.postForEntity("/api/orders/" + orderId + "/cancel", null, OrderResponse.class);
        assertThat(second.getStatusCode()).isEqualTo(HttpStatus.CONFLICT);
    }

    @Test
    void cancelMissingOrderReturnsNotFound() {
        ResponseEntity<OrderResponse> response =
                rest.postForEntity("/api/orders/" + UUID.randomUUID() + "/cancel", null, OrderResponse.class);
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.NOT_FOUND);
    }

    @Test
    void getMissingOrderReturnsNotFound() {
        ResponseEntity<OrderResponse> response =
                rest.getForEntity("/api/orders/" + UUID.randomUUID(), OrderResponse.class);
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.NOT_FOUND);
    }

    @Test
    void createOrderInsufficientInventoryReturnsConflict() {
        CreateOrderRequest request =
                new CreateOrderRequest(List.of(new CreateOrderItemRequest(WIDGET, 1000)));
        ResponseEntity<OrderResponse> response =
                rest.postForEntity("/api/orders", request, OrderResponse.class);
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.CONFLICT);
    }

    @Test
    void createOrderUnknownProductReturnsNotFound() {
        CreateOrderRequest request =
                new CreateOrderRequest(List.of(new CreateOrderItemRequest(UUID.randomUUID(), 1)));
        ResponseEntity<OrderResponse> response =
                rest.postForEntity("/api/orders", request, OrderResponse.class);
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.NOT_FOUND);
    }

    @Test
    void createOrderWithEmptyItemsReturnsBadRequest() {
        CreateOrderRequest request = new CreateOrderRequest(List.of());
        ResponseEntity<OrderResponse> response =
                rest.postForEntity("/api/orders", request, OrderResponse.class);
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
    }

    @Test
    void idempotencyKeyReturnsSameOrder() {
        // Use a per-run unique key: the database now uniquely constrains
        // idempotency_key, so a fixed key could collide with a prior run.
        String key = UUID.randomUUID().toString();
        CreateOrderRequest request =
                new CreateOrderRequest(List.of(new CreateOrderItemRequest(WIDGET, 1)));
        HttpHeaders headers = new HttpHeaders();
        headers.set("Idempotency-Key", key);
        HttpEntity<CreateOrderRequest> entity = new HttpEntity<>(request, headers);

        ResponseEntity<OrderResponse> first = rest.postForEntity("/api/orders", entity, OrderResponse.class);
        ResponseEntity<OrderResponse> second = rest.postForEntity("/api/orders", entity, OrderResponse.class);

        assertThat(first.getStatusCode()).isEqualTo(HttpStatus.CREATED);
        assertThat(second.getStatusCode()).isEqualTo(HttpStatus.CREATED);
        assertThat(first.getBody()).isNotNull();
        assertThat(second.getBody()).isNotNull();
        // AC-3: repeated callers observe the same logical result.
        assertThat(second.getBody().id()).isEqualTo(first.getBody().id());
        assertThat(second.getBody().status()).isEqualTo(first.getBody().status());
        assertThat(second.getBody().totalAmount()).isEqualByComparingTo(first.getBody().totalAmount());
        assertThat(second.getBody().items()).isEqualTo(first.getBody().items());
        cancel(first.getBody().id());
    }

    private ResponseEntity<OrderResponse> postOrder(UUID productId, int quantity) {
        CreateOrderRequest request =
                new CreateOrderRequest(List.of(new CreateOrderItemRequest(productId, quantity)));
        return rest.postForEntity("/api/orders", request, OrderResponse.class);
    }

    private void cancel(UUID orderId) {
        rest.postForEntity("/api/orders/" + orderId + "/cancel", null, OrderResponse.class);
    }
}
