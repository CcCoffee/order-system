package com.example.orderservice.api;

import com.example.orderservice.application.OrderApplicationService;
import com.example.orderservice.application.ProductResponse;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/products")
public class ProductController {

    private final OrderApplicationService orderService;

    public ProductController(OrderApplicationService orderService) {
        this.orderService = orderService;
    }

    @GetMapping
    public List<ProductResponse> list() {
        return orderService.listProducts();
    }
}
