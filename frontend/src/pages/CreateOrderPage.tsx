import { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { createOrder, listProducts } from '../api/client';
import type { Product } from '../api/types';

interface CartItem {
  productId: string;
  quantity: number;
}

export default function CreateOrderPage() {
  const navigate = useNavigate();
  const [products, setProducts] = useState<Product[]>([]);
  const [selectedProductId, setSelectedProductId] = useState('');
  const [quantity, setQuantity] = useState(1);
  const [cart, setCart] = useState<CartItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    listProducts()
      .then((data) => {
        setProducts(data);
        if (data.length > 0) {
          setSelectedProductId(data[0].id);
        }
      })
      .catch((e: Error) => setError(e.message))
      .finally(() => setLoading(false));
  }, []);

  const addToCart = () => {
    if (!selectedProductId || quantity < 1) {
      return;
    }
    setCart((prev) => {
      const existing = prev.find((i) => i.productId === selectedProductId);
      if (existing) {
        return prev.map((i) =>
          i.productId === selectedProductId ? { ...i, quantity: i.quantity + quantity } : i,
        );
      }
      return [...prev, { productId: selectedProductId, quantity }];
    });
    setQuantity(1);
  };

  const submit = async () => {
    if (cart.length === 0) {
      return;
    }
    setSubmitting(true);
    setError(null);
    try {
      const order = await createOrder({ items: cart });
      navigate(`/orders/${order.id}`);
    } catch (e) {
      setError((e as Error).message);
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div className="card">
      <h1>Create Order</h1>
      <p className="page-subtitle">
        Add products to your cart, then create the order to place it.
      </p>
      {error && <div className="error">{error}</div>}
      {loading ? (
        <p className="status-loading">Loading products...</p>
      ) : products.length === 0 ? (
        <p className="empty-state">No products available.</p>
      ) : (
        <>
          <section className="mt-10">
            <h2>Add Items</h2>
            <div className="row">
              <div className="field">
                <label htmlFor="product">Product</label>
                <select
                  id="product"
                  value={selectedProductId}
                  onChange={(e) => setSelectedProductId(e.target.value)}
                >
                  {products.map((p) => (
                    <option key={p.id} value={p.id}>
                      {p.name} - ${p.price.toFixed(2)}
                    </option>
                  ))}
                </select>
              </div>
              <div className="field">
                <label htmlFor="quantity">Quantity</label>
                <input
                  id="quantity"
                  type="number"
                  min={1}
                  value={quantity}
                  onChange={(e) => setQuantity(Number(e.target.value))}
                />
              </div>
              <button className="secondary" onClick={addToCart}>
                Add
              </button>
            </div>
          </section>

          {cart.length > 0 && (
            <section className="mt-10">
              <div className="table-wrap">
                <table>
                  <thead>
                    <tr>
                      <th>Item</th>
                      <th>Qty</th>
                    </tr>
                  </thead>
                  <tbody>
                    {cart.map((item) => {
                      const product = products.find((p) => p.id === item.productId);
                      return (
                        <tr key={item.productId}>
                          <td>{product?.name ?? item.productId}</td>
                          <td>{item.quantity}</td>
                        </tr>
                      );
                    })}
                  </tbody>
                </table>
              </div>
            </section>
          )}

          <div className="form-actions">
            <button onClick={submit} disabled={submitting || cart.length === 0}>
              {submitting ? 'Creating...' : 'Create Order'}
            </button>
          </div>
        </>
      )}
    </div>
  );
}
