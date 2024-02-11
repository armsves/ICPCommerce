import React from 'react';
import "./index.css";

const Footer = () => {
  return (
    <div className="pageFooter">
      <div className="centeredContainer">
        <img src="icpcommerce.jpg" width="25px" height="25px" alt="logo" />
        <span>2024 ICPcommerce</span>
      </div>
      <div className="centeredContainer">
        <span>English</span>
        <img src="english.png" width="40px" height="20px" alt="english" />
      </div>
    </div>
  );
};


export default Footer;