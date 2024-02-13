import React, { useEffect, useState } from "react"
import { useAuth } from "../../auth";
import ProductCard from "../../components/ProductCard"
import Footer from '../../components/Footer';
import "./index.css";

function Home({ isLoading, profile, setCartItemsCount }) {
  const { backendActor } = useAuth();
  const [products, setProducts] = useState(null);

  useEffect(() => { getProducts() }, [backendActor])

  const getProducts = async () => {
    if (backendActor) {
      let response = await backendActor.getAllActiveProducts();
      setProducts(response)
    }
  }

  return (
    <>
      <div className="bigTitle">
        <h1>Welcome to ICPCommerce!</h1>
        <h4>Your 100% on-chain e-commerce CMS</h4>
        <h4>Project Submission for <a href="https://www.encode.club/" target="_blank">Encode Club's</a> ICP Zero to Dapp Hackaton</h4>
      </div>
      <div className="categories">
        <div className="products">
          {products && products.length > 0 ? (
            products.map(product => (
              <ProductCard key={Number(product.id)} product={product} profile={profile} setCartItemsCount={setCartItemsCount} />
            ))
          ) : (
            <p>No products found.</p>
          )}
        </div>
      </div>
      <Footer />
    </>
  )
}

export default Home
