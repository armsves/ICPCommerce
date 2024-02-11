import React from 'react';
import "./index.css"
import { useAuth } from "../../auth"

const OrdersList = ({ orders, getOrders }) => {
  const { backendActor } = useAuth()

  const deleteOrder = async (orderId) => {
    let response = await backendActor.deleteOrder(Number(orderId));
    console.log("order deleted ", response);
    getOrders(); // Refresh the list
  };

  /*
  if (!contests) {
    return <div>Loading...</div>;
  }
  */

  return (
    <div className="OrdersList">
      <h2>Orders</h2>
      <div>
        {orders && orders.length > 0 ? (orders.sort((a, b) => Number(a.id) - Number(b.id)).map(order => (
          <div key={Number(order.id)} style={{ display: 'flex', justifyContent: 'space-between', margin: '10px', padding: '5px' }}>
            <div style={{ marginRight: '5px' }}>{Number(order.id)}</div>
            <div style={{ marginRight: '5px' }}>{order.customerId}</div>
            <div style={{ marginRight: '5px' }}>{Number(order.total)}</div>
            <div style={{ marginRight: '5px' }}>{order.symbol}</div>
            <div style={{ marginRight: '5px' }}>{order.paymentTx}</div>
            <div style={{ marginRight: '5px' }}>
              {(() => {
                //0 Payment Pending - 1 Payment Complete - 2 Order Processing - 3 Order Shipped - 4 order not processed
                switch (Number(order.status)) {
                  case 0: return "Payment Pending";
                  case 1: return "Payment Complete";
                  case 2: return "Order Processing";
                  case 3: return "Order Shipped";
                  case 4: return "Order not processed";
                }
              })()}
            </div>
            <div>{<button onClick={() => deleteOrder(order.id)} >Delete Order</button>}</div>
          </div>
        ))

        ) : (<p>No orders found.</p>)
        }
      </div>
    </div>
  );
};

export default OrdersList;
