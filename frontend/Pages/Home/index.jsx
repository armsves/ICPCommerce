import React, { useEffect, useState } from "react"
import { useAuth } from "../../auth";
import "./index.css";
import ProductCard from "../../components/ProductCard"
import Footer from '../../components/Footer';

function Home({ isLoading, profile, cartItemsCount, setCartItemsCount }) {
  const { backendActor } = useAuth();
  const [categories, setCategories] = useState(null);
  const [products, setProducts] = useState(null);

  useEffect(() => {
    getCategories()
  }, [backendActor])

  const getCategories = async () => {
    if (backendActor) {
      let response = await backendActor.getCategories();
      setCategories(response)
      //console.log("categories", response)
      let response2 = await backendActor.getAllActiveProducts();
      setProducts(response2)
      //console.log("Active Products", response2)
      //if (response2) console.log("Content", response2[0].content)
    }
  }

  /*
      {products && products.map((product, index) => (
        <div key={Number(product.id)} style={{ marginBottom: '10px', marginRight: index !== products.length - 1 ? '10px' : '0' }}>
          <ProductCard product={product} profile={profile} setCartItemsCount={setCartItemsCount} />
        </div>
  */

  return (
    <>
     <div className="bigTitle">
      <h1>Welcome to ICPCommerce!</h1>
      <h4>Your 100% on-chain e-commerce CMS</h4>
     </div>
      <div className="categories">
        <div className="category-top">
          {categories &&
            categories.sort((a, b) => Number(a.id) - Number(b.id)).map(category => (
              <div className="category-item" key={Number(category.id)}>{category.name}</div>
            ))
          }
        </div>
        <div className="products">
          {products && products.map(product => (
            <ProductCard key={Number(product.id)} product={product} profile={profile} setCartItemsCount={setCartItemsCount} />
          ))}
        </div>
      </div>
      <Footer />
    </>
  )
}

export default Home
