import PropTypes from "prop-types";

import List from "@mui/material/List";

function SidenavList({ children }) {
  return (
    <List
      sx={{
        px: 2,
        my: 0.3,
      }}
    >
      {children}
    </List>
  );
}

SidenavList.propTypes = {
  children: PropTypes.node.isRequired,
};

export default SidenavList;
