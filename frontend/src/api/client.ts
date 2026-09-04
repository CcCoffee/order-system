import type { CreateOrderRequest, Order, Product } from './types';

async function handle<T>(res: Response): Promise<T> {
  if (!res.ok) {
    let message = `Request failed with status ${res.status}`;
    try {
      const body = (await res.json()) as { message?: string };
      if (body?.message) {
        message = body.message;
      }
    } catch {
      // ignore parse errors
    }
    throw new Error(message);
  }
  return (await res.json()) as T;
}

export async function listProducts(): Promise<Product[]> {
  const res = await fetch('/api/products');
  return handle<Product[]>(res);
}

export async function createOrder(request: CreateOrderRequest): Promise<Order> {
  const res = await fetch('/api/orders', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(request),
  });
  return handle<Order>(res);
}

export async function getOrder(id: string): Promise<Order> {
  const res = await fetch(`/api/orders/${id}`);
  return handle<Order>(res);
}

export async function cancelOrder(id: string): Promise<Order> {
  const res = await fetch(`/api/orders/${id}/cancel`, {
    method: 'POST',
  });
  return handle<Order>(res);
}
