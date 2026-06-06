import { Link } from "react-router-dom";
import logo from "../Aureview.png";

export function Brand() {
  return (
    <Link className="brand" to="/">
      <img src={logo} alt="Aureview Logo" style={{ height: "40px", transform: "scale(4)", transformOrigin: "left center", marginLeft: "10px" }} />
    </Link>
  );
}

