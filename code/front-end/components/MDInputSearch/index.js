import { forwardRef } from "react";

import PropTypes from "prop-types";

import MDInputRoot from "/components/MDInput/MDInputRoot";
import InputAdornment from "@mui/material/InputAdornment";
import Search from "@mui/icons-material/Search";

const MDInputSearch = forwardRef(
  ({ error, success, disabled, ...rest }, ref) => {
    return (
      <MDInputRoot
        {...rest}
        ref={ref}
        InputProps={{
          startAdornment: (
            <InputAdornment position="start">
              <Search />
            </InputAdornment>
          ),
        }}
        ownerState={{ error, success, disabled }}
      />
    );
  }
);

MDInputSearch.defaultProps = {
  error: false,
  success: false,
  disabled: false,
};

MDInputSearch.propTypes = {
  error: PropTypes.bool,
  success: PropTypes.bool,
  disabled: PropTypes.bool,
};

MDInputSearch.displayName = "MDInputSearch";
export default MDInputSearch;
