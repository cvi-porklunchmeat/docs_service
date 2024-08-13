import Search from "@mui/icons-material/Search";
import Home from "@mui/icons-material/Home";
import QuestionAnswer from "@mui/icons-material/QuestionAnswer";
import SettingsIcon from "@mui/icons-material/Settings";

const routes = [
  {
    type: "collapse",
    name: "Home",
    key: "dashboards",
    icon: <Home style={{ color: "#000000" }} fontSize="small" />,
    route: "/",
    noCollapse: true,
  },
  {
    type: "collapse",
    name: "Search",
    key: "search",
    icon: <Search style={{ color: "#000000" }} fontSize="small" />,
    route: "/search",
    noCollapse: true,
  },
  {
    type: "collapse",
    name: "My Questions",
    key: "questions",
    icon: <QuestionAnswer style={{ color: "#000000" }} fontSize="small" />,
    route: "#",
    noCollapse: true,
  },
  {
    type: "collapse",
    name: "Settings",
    key: "settings",
    icon: <SettingsIcon style={{ color: "#000000" }} fontSize="small" />,
    route: "#",
    noCollapse: true,
  },
];

export default routes;
