import React from 'react';
import "./index.css";

const Footer = () => {
  return (
    <div className="pageFooter">
      <div className="centeredContainer">
        <img src="icpcommerce.jpg" width="30px" height="30px" alt="logo" />
        <span>2024 ICPcommerce</span>
      </div>

      <div className="centeredContainer">
        <a href="https://github.com/armsves/ICPCommerce" target="_blank">
          <img src="github.png" width="30px" height="30px" alt="GitHub logo" />
        </a>
      </div>

      <div className="centeredContainer">
        <a href="https://twitter.com/armsves" target="_blank">
          <img src="twitter.png" width="30px" height="30px" alt="X/Twitter logo" />
        </a>
      </div>

      <div className="centeredContainer">
        <a href="https://www.linkedin.com/in/armsves" target="_blank">
          <img src="linkedin.png" width="30px" height="30px" alt="LinkedIn logo" />
        </a>
      </div>

      <div className="centeredContainer">
        <span>English</span>
        <img src="english.png" width="40px" height="20px" alt="english" />
      </div>
    </div>
  );
};


export default Footer;