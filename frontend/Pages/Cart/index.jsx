import React, { useEffect, useState } from "react"
import { useAuth } from "../../auth";
import "./index.css";
import { getToPathname } from "@remix-run/router";
import { toast } from 'react-toastify';
import Footer from '../../components/Footer';

function Cart({ profile, priceICP, priceBTC, priceETH, setCartItemsCount }) {
    const { backendActor } = useAuth();
    const [products, setProducts] = useState(null);

    useEffect(() => { if (profile && profile.name) { getShoppingCart() } }, []);

    const getShoppingCart = async () => {
        if (backendActor) {
            let response = await backendActor.getShoppingCart(profile.name);
            setProducts(response)
            //console.log("shopping cart for ", response)
            let response2 = await backendActor.getCartItemsNumber(profile.name);
            setCartItemsCount(response2);
        }
    }

    const buyWithICP = async () => {
        const total = products.reduce((total, product) => total + (Number(product.quantity) * Number(product.price)), 0);
        let response = await backendActor.convertUSDto("ICPUSDT", total);
        const balance = await window.ic?.plug?.requestBalance();
        const tokenBalance = balance.find(item => item.symbol === "ICP");
        const tokenValue = tokenBalance ? tokenBalance.amount : null;
        if (tokenValue >= response) {
            const amount = (response * 100000000).toFixed(0);
            const requestTransferArg = {
                to: 'am7jk-7ly4w-dh262-wtu6h-hmlvh-toclt-xpdqr-s32cx-44buf-hoy5c-jqe',
                fee: 0,
                from_subaccount: [],
                created_at_time: [],
                amount: Number(amount),
            };
            await window.ic?.plug?.requestTransfer(requestTransferArg)
                .then(transfer => {
                    console.log('Transfer successful:', transfer);
                    createOrder("ICP", transfer.height);
                })
                .catch(error => {
                    if (String(error).includes("Error: The transaction was rejected.")) {
                        toast.error("The transaction was declined/rejected");
                    }
                });
        } else {
            toast.warning("You don't have enough balance!");
        }
    }

    const buyWithBTC = async () => {
        const total = products.reduce((total, product) => total + (Number(product.quantity) * Number(product.price)), 0);
        let response = await backendActor.convertUSDto("BTCUSDT", total);
        const balance = await window.ic?.plug?.requestBalance();
        const tokenBalance = balance.find(item => item.symbol === "BTC");
        const tokenValue = tokenBalance ? tokenBalance.amount : null;
        if (tokenValue >= response) {
            const amount = (response * 100000000).toFixed(0);
            const requestTransferArg = {
                to: 'am7jk-7ly4w-dh262-wtu6h-hmlvh-toclt-xpdqr-s32cx-44buf-hoy5c-jqe',
                fee: 0,
                token: {
                    token: 'mxzaz-hqaaa-aaaar-qaada-cai',
                    symbol: 'ckBTC',
                    usdValue: total,
                },
                from_subaccount: [],
                created_at_time: [],
                amount: (Number(amount)),
                //amount: (Number(1000)),
            };

            await window.ic?.plug?.requestTransfer(requestTransferArg)
                .then(transfer => {
                    console.log('Transfer successful:', transfer);
                    createOrder("ckBTC", String(transfer.height));
                })
                .catch(error => {
                    if (String(error).includes("Error: The transaction was rejected.")) {
                        toast.error("The transaction was declined/rejected");
                    }
                });
        } else {
            toast.warning("You don't have enough balance!");
        }
    }

    const buyWithETH = async () => {
        const total = products.reduce((total, product) => total + (Number(product.quantity) * Number(product.price)), 0);
        let response = await backendActor.convertUSDto("ETHUSDT", total);
        const balance = await window.ic?.plug?.requestBalance();
        const tokenBalance = balance.find(item => item.symbol === "ETH");
        const tokenValue = tokenBalance ? tokenBalance.amount : null;
        if (tokenValue >= response) {
            let amount = (response * 100000000).toFixed(0);
            const requestTransferArg = {
                to: 'am7jk-7ly4w-dh262-wtu6h-hmlvh-toclt-xpdqr-s32cx-44buf-hoy5c-jqe',
                fee: 0,
                token: {
                    token: 'ss2fx-dyaaa-aaaar-qacoq-cai',
                    symbol: 'ckETH',
                    value: priceETH,
                },
                from_subaccount: [],
                created_at_time: [],
                amount: (Number(amount)),
            };
            await window.ic?.plug?.requestTransfer(requestTransferArg)
                .then(transfer => {
                    console.log('Transfer successful:', transfer);
                    createOrder("ckETH", transfer.height);
                })
                .catch(error => {
                    if (String(error).includes("Error: The transaction was rejected.")) {
                        toast.error("The transaction was declined/rejected");
                    }
                });
        } else {
            toast.warning("You don't have enough balance!");
        }
    }

    const createOrder = async (symbol, transfer) => {
        console.log(products);
        let response = await backendActor.createOrder(profile.name, products, symbol, transfer);
        console.log("order created ", response);
        toast.success("Order Created!");
        getShoppingCart()
    };

    const deleteCartProduct = async (productId) => {
        let response = await backendActor.deleteCartProduct(Number(productId), profile.name);
        console.log("delete cart product", response);
        toast.success("Product deleted!");
        getShoppingCart()
    };

    const addQuantityCartProduct = async (productId) => {
        let response = await backendActor.addQuantityCartProduct(Number(productId), profile.name);
        console.log("add quantity cart product", response);
        getShoppingCart()
    };

    const removeQuantityCartProduct = async (productId) => {
        let response = await backendActor.removeQuantityCartProduct(Number(productId), profile.name);
        console.log("remove quantity cart product", response);
        getShoppingCart()
    };

    return (
        <>
            <div className="cartlist">
                <h2>Shopping Cart</h2>
                {profile && products && products.length > 0 ? (
                    <>
                        <div className="grid-header">
                            <div className="header-item">Product Name</div>
                            <div style={{ textAlign: 'center' }} className="header-item">Quantity</div>
                            <div className="header-item"></div>
                            <div style={{ textAlign: 'center' }} className="header-item">Subtotal</div>
                            <div className="header-item"></div>
                        </div>
                        {products.sort((a, b) => Number(a.id) - Number(b.id)).map(product => (
                            <div key={Number(product.id)} className="grid-item">
                                <div className="product-name">{product.name}</div>
                                <div style={{ textAlign: 'center' }} className="quantity">{Number(product.quantity)}</div>
                                <div className="quantity-controls">
                                    <button onClick={() => removeQuantityCartProduct(product.id)}>&#8722;</button>
                                    <button onClick={() => addQuantityCartProduct(product.id)}>&#43;</button>
                                </div>
                                <div style={{ textAlign: 'center' }} className="subtotal">${Number(product.quantity) * Number(product.price)}</div>
                                <div className="delete-button">
                                    <button onClick={() => deleteCartProduct(product.id)}>Delete Product</button>
                                </div>
                            </div>
                        ))}
                        <div className="total-container">
                            <h2 className="total-price">Total Price:
                                ${products.reduce((total, product) => total + (Number(product.quantity) * Number(product.price)), 0)}
                            </h2>
                            <div className="buyButtons">
                                <button onClick={buyWithICP} className="centered-button">
                                    <span>
                                        Buy with ICP&nbsp;
                                        {Number(products.reduce((total, product) => total + (Number(product.quantity) * Number(product.price) / priceICP), 0)).toFixed(6)}
                                        &nbsp;<img src="ICPblack.png" width="25px" height="25px" alt="logo" />
                                    </span>
                                </button>
                                <button onClick={buyWithBTC} className="centered-button">
                                    <span>
                                        Buy with ckBTC&nbsp;
                                        {Number(products.reduce((total, product) => total + (Number(product.quantity) * Number(product.price) / priceBTC), 0)).toFixed(6)}
                                        &nbsp;<img src="ckBTC.png" width="25px" height="25px" alt="logo" />
                                    </span>
                                </button>
                                <button onClick={buyWithETH} className="centered-button">
                                    <span>
                                        Buy with ckETH&nbsp;
                                        {Number(products.reduce((total, product) => total + (Number(product.quantity) * Number(product.price) / priceETH), 0)).toFixed(6)}
                                        &nbsp;<img src="ckETH.png" width="25px" height="25px" alt="logo" />
                                    </span>
                                </button>
                            </div>
                        </div>
                    </>
                ) : (
                    <p>Shopping Cart is empty.</p>
                )}
            </div>
            <Footer />
        </>
    )
}

export default Cart;
