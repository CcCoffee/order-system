import { Link, Route, Routes } from 'react-router-dom';
import CreateOrderPage from './pages/CreateOrderPage';
import OrderDetailPage from './pages/OrderDetailPage';

export default function App() {
  return (
    <div className="app">
      <header className="app-header">
        <Link to="/" className="brand">
          Order System
        </Link>
      </header>
      <main className="app-main">
        <Routes>
          <Route path="/" element={<CreateOrderPage />} />
          <Route path="/orders/:id" element={<OrderDetailPage />} />
        </Routes>
      </main>
    </div>
  );
}
