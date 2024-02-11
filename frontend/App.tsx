import React, { useEffect, useState, } from "react"
/* Connect2ic provides essential utilities for IC app development
import "@connect2ic/core/style.css"
/* Import canister definitions like this: */
/* Some examples to get you started */
import TopBar from "./components/TopBar"
import Home from "./Pages/Home";
import User from "./Pages/User";
import Cart from "./Pages/Cart";
import FileLoader from "./components/FileLoader";
//import Modal from "./components/Modal";
import Admin from "./Pages/Admin";
//import FAQ from "./Pages/FAQ";
import "./index.css"
import { BrowserRouter as Router, Routes, Route, } from "react-router-dom"
import { useAuth } from "./auth"

function AppPage() {
  //const [modal, setModal] = useState(false)
  //const [modalMsg, setModalMsg] = useState("")
  const [fileloader, setFileLoader] = useState({
    isOpen: false,
    currentIndex: 0,
    totalChunks: 0,
  })

  const [visibility, setVisibility] = useState([true, true, true])
  const { isAuthenticated, identity, login, backendActor, logout } = useAuth()
  const [isLoading, setIsLoading] = useState(true)
  const [profile, setProfile] = useState(null)
  const [caller, setCaller] = useState(null)
  const [icpBalance, setBalance] = useState(null)
  const [priceBTC, setPriceBTC] = useState(null)
  const [priceETH, setPriceETH] = useState(null)
  const [priceICP, setPriceICP] = useState(null)
  const [cartItemsCount, setCartItemsCount] = useState(null)


  useEffect(() => {
    if (isAuthenticated) {
      // getIsReady()
      //console.log("is auth", identity)
      setIsLoading(false)
      getIsReady()
    } else {
      //console.log("not auth", identity)
      //getIsReady()
      //setProfile(null)
      setCaller(null)
      // setIsLoading(false)
    }
  }, [isAuthenticated, identity])

  const getIsReady = async () => {
    const caller = await backendActor.caller()
    const profile = await backendActor.getProfile()
    //console.log("caller",caller)
    //console.log("profile", profile)
    setCaller(caller)
    //setProfile(profile)
  }

  const verifyConnectionAndAgent = async () => {
    const connected = await window.ic.plug.isConnected();
    if (!connected) window.ic.plug.requestConnect("bkyz2-fmaaa-aaaaa-qaaaq-cai");
    if (connected && !window.ic.plug.agent) {
      window.ic.plug.createAgent("bkyz2-fmaaa-aaaaa-qaaaq-cai")
    }
  };

  useEffect(() => {
    verifyConnectionAndAgent();
    fetchCryptoData();
  }, []);

  useEffect(() => { }, [
    //modal, 
    fileloader])

  const [countdown, setCountdown] = useState(10)
  const updateCountdown = () => {
    let tempcount = countdown - 1;
    setCountdown(tempcount);
    if (tempcount === 0) {
      setCountdown(10);
      fetchCryptoData();
      //console.log("Data fetched")
    }
  };
  const fetchCryptoData = () => {
    const apiUrl = 'https://openapi.bitrue.com/api/v1/ticker/price?symbol=';
    fetch(apiUrl + "BTCUSDT", {}).then(response => response.json()).then(data => { setPriceBTC(data.price); }).catch(error => { console.log('Error fetching crypto data:', error); });
    fetch(apiUrl + "ETHUSDT", {}).then(response => response.json()).then(data => { setPriceETH(data.price); }).catch(error => { console.log('Error fetching crypto data:', error); });
    fetch(apiUrl + "ICPUSDT", {}).then(response => response.json()).then(data => { setPriceICP(data.price); }).catch(error => { console.log('Error fetching crypto data:', error); });
  };

  useEffect(() => {
    const intervalId = setInterval(updateCountdown, 1000);
    return () => clearInterval(intervalId);
  }, [countdown]);
//<Modal isOpen={modal} message={modalMsg} onClose={setModal} />
  return (
    <>
      
      <FileLoader isOpen={fileloader.isOpen} currentIndex={fileloader.currentIndex} totalChunks={fileloader.totalChunks}
        className="my-custom-loader" />
      <div style={{ display: "flex", flexDirection: "column", alignItems: "center", }}>
        <Router>
          <TopBar
            setCaller={setCaller} icpBalance={icpBalance === null ? 0 : icpBalance} profile={profile} setProfile={setProfile}
            setIsLoading={setIsLoading} loading={isLoading} priceICP={priceICP} priceBTC={priceBTC} priceETH={priceETH}
            cartItemsCount={cartItemsCount}
          />
          <Routes>
            <Route path="" element={
              <Home isLoading={isLoading} profile={profile} cartItemsCount={cartItemsCount} setCartItemsCount={setCartItemsCount} />} />
            <Route path="/user" element={
              <User setFileLoader={setFileLoader} caller={caller}
                setIsLoading={setIsLoading} profile={profile} isLoading={isLoading} reLoad={getIsReady} />} />
            <Route
              path="/admin"
              element={
                <Admin setFileLoader={setFileLoader} caller={caller}
                  setIsLoading={setIsLoading} profile={profile} isLoading={isLoading} reLoad={getIsReady} />} />
            <Route path="/cart" element={
            <Cart profile={profile} priceICP={priceICP} priceBTC={priceBTC} priceETH={priceETH} setCartItemsCount={setCartItemsCount} />
            } />
          </Routes>
        </Router>
      </div>
    </>
  )
}

export default AppPage
