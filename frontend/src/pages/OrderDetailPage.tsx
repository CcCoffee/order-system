import { useCallback, useEffect, useState } from 'react';
import { Link, useParams } from 'react-router-dom';
import { cancelOrder, getOrder } from '../api/client';
import type { Order } from '../api/types';

export default function OrderDetailPage() {
  const { id } = useParams<{ id: string }>();
  const [order, setOrder] = useState<Order | null>(null);
  const [loading, setLoading] = useState(true);
  const [cancelling, setCancelling] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const load = useCallback(() => {
    if (!id) {
      return;
    }
    setLoading(true);
    setError(null);
    getOrder(id)
      .then(setOrder)
      .catch((e: Error) => setError(e.message))
      .finally(() => setLoading(false));
  }, [id]);

  useEffect(() => {
    load();
  }, [load]);

  const handleCancel = async () => {
    if (!id) {
      return;
    }
    setCancelling(true);
    setError(null);
    try {
      const updated = await cancelOrder(id);
      setOrder(updated);
    } catch (e) {
      setError((e as Error).message);
    } finally {
      setCancelling(false);
    }
  };

  if (loading) {
    return (
      <div className="card">
        <p className="status-loading">Loading order...</p>
      </div>
    );
  }

  if (error && !order) {
    return (
      <div className="card">
        <h1>Order not found</h1>
        <div className="error">{error}</div>
        <p>
          <Link to="/">Back to orders</Link>
        </p>
      </div>
    );
  }

  if (!order) {
    return null;
  }

  return (
    <div className="card">
      <h1>Order</h1>
      <p className="order-id">{order.id}</p>
      <p>
        <span role="status" className={`status-badge status-${order.status}`}>
          {order.status}
        </span>
      </p>
      <h2>Order Items</h2>
      <div className="table-wrap">
        <table>
          <thead>
            <tr>
              <th>Product</th>
              <th>Unit Price</th>
              <th>Qty</th>
              <th>Line Total</th>
            </tr>
          </thead>
          <tbody>
            {order.items.map((item) => (
              <tr key={item.productId}>
                <td>{item.productName}</td>
                <td>${item.unitPrice.toFixed(2)}</td>
                <td>{item.quantity}</td>
                <td>${item.lineTotal.toFixed(2)}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
      <p>
        <strong>Total: ${order.totalAmount.toFixed(2)}</strong>
      </p>
      {error && <div className="error">{error}</div>}
      {order.status === 'PENDING' && (
        <button onClick={handleCancel} disabled={cancelling}>
          {cancelling ? 'Cancelling...' : 'Cancel Order'}
        </button>
      )}
      <p>
        <Link to="/">Back</Link>
      </p>
    </div>
  );
}
