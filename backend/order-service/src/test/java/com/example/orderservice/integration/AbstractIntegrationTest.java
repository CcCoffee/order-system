package com.example.orderservice.integration;

import com.example.orderservice.OrderServiceApplication;
import org.junit.jupiter.api.BeforeEach;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.client.TestRestTemplate;
import org.springframework.http.client.ClientHttpResponse;
import org.springframework.web.client.ResponseErrorHandler;

import java.io.IOException;

/**
 * Base test for integration tests, bootstrapping the full application against
 * the locally running (compose) PostgreSQL and Redis infrastructure.
 *
 * <p>Integration tests target the shared dev infrastructure, so tests that
 * create orders must cancel them to restore inventory and keep the run
 * repeatable.
 */
@SpringBootTest(classes = OrderServiceApplication.class,
        webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
public abstract class AbstractIntegrationTest {

    @Autowired
    protected TestRestTemplate rest;

    @BeforeEach
    void configureRestTemplate() {
        rest.getRestTemplate().setErrorHandler(new ResponseErrorHandler() {
            @Override
            public boolean hasError(ClientHttpResponse response) {
                return false;
            }

            @Override
            public void handleError(ClientHttpResponse response) throws IOException {
                // Return error responses as-is so status codes can be asserted.
            }
        });
    }
}
