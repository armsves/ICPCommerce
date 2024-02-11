import React, { useEffect, useState, Component } from "react"
import "./index.css"
import { useAuth } from "../../auth"
import { useNavigate } from "react-router-dom"
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import { faBars, faHome, faQuestionCircle, faHistory, faUser } from '@fortawesome/free-solid-svg-icons';
import PlugConnect from '@psychedelic/plug-connect';
import { toast } from 'react-toastify';

function TopBar({ setIsLoading, loading, icpBalance, setCaller, profile, setProfile, priceBTC, priceETH, priceICP, cartItemsCount }) {
  const [ImgSrc, setImgSrc] = useState(null)
  const navigate = useNavigate()
  const auth = useAuth()
  const [isMenuOpen, setIsMenuOpen] = useState(false)
  const [hamburger, setHamburger] = useState(false)
  //const [profile, setProfile] = useState(null)
  const [connected, setConnected] = useState(false)
  const { isAuthenticated, identity, login, backendActor, logout } = useAuth()

  const verifyConnectionAndAgent = async () => {
    const connected = await window.ic.plug.isConnected();
    if (!connected) window.ic.plug.requestConnect("bkyz2-fmaaa-aaaaa-qaaaq-cai");
    if (connected && !window.ic.plug.agent) {
      window.ic.plug.createAgent("bkyz2-fmaaa-aaaaa-qaaaq-cai")
    }
  };

  useEffect(() => {
    verifyConnectionAndAgent();
  }, []);

  useEffect(() => {
    if (!profile) {
      setIsLoading(true)
    }
    if (profile && profile.profilePic) {
      let image = new Uint8Array(profile.profilePic[0])
      let blob = new Blob([image])
      let reader = new FileReader()
      reader.onload = function (e) {
        setImgSrc(e.target.result)
      }
      reader.readAsDataURL(blob)
    }
  }, [profile, ImgSrc])

  return (
    <div className="TopBar">
      <div className="logo" onClick={() => navigate("/")}><img src="icpcommerce.jpg" width="100px" height="100px" alt="logo" /></div>
      <div className="ticker">{priceBTC}$<img src="ckBTC.png" width="50px" height="50px" alt="logo" /></div>
      <div className="ticker">{priceETH}$<img src="ckETH.png" width="50px" height="50px" alt="logo" /></div>
      <div className="ticker">{priceICP}$<img src="ICPblack.png" width="50px" height="50px" alt="logo" /></div>
      <div className="logo" onClick={() => navigate("/cart")}>
        <img src="cart.png" width="50px" height="50px" alt="cart" />
        {Number(cartItemsCount) > 0 && (<div className="badge">{Number(cartItemsCount)}</div>)}
      </div>

      {profile && profile.admin && (<button className="button" onClick={async () => { navigate("/admin") }}>Admin</button>)}

      <PlugConnect
        dark
        title={!connected ? "Connect Wallet" : !profile.admin ? "Wallet Connected" : "Admin Connected"}
        whitelist={['bkyz2-fmaaa-aaaaa-qaaaq-cai']}
        onConnectCallback={
          async () => {
            const balance = await window.ic?.plug?.requestBalance();
            const icpbalance = balance.find(item => item.symbol === "ICP");
            const ckBTCbalance = balance.find(item => item.symbol === "ckBTC");
            const ckETHbalance = balance.find(item => item.symbol === "ckETH");
            const icpValue = icpbalance ? icpbalance.amount : null;
            const ckBTCValue = ckBTCbalance ? ckBTCbalance.amount : null;
            const ckETHValue = ckETHbalance ? ckETHbalance.amount : null;
            //console.log("Valor de ICP:", icpValue);
            //console.log("Valor de ckBTC:", ckBTCValue);
            //console.log("Valor de ckETH:", ckETHValue);
            const principalId: String = await window.ic.plug.agent.getPrincipal();
            const admin: String = "am7jk-7ly4w-dh262-wtu6h-hmlvh-toclt-xpdqr-s32cx-44buf-hoy5c-jqe";
            if (principalId.toString() === admin.toString()) {
              console.log("Welcome admin");
              const newAdmin = {
                name: principalId.toString(),
                profilePic: null,
                admin: true
              };
              setProfile(newAdmin);
            } else { console.log("Welcome user"); }
            setConnected(true);
            toast.success("Wallet Connected!");
            //getCartItemsCount();
            //console.log(`Plug's user principal Id is ${principalId} and the admin is ${admin}`);
          }
        }
      />
    </div>
  );
}

export default TopBar
