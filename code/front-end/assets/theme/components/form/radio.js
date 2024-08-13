import borders from "/assets/theme/base/borders";
import colors from "/assets/theme/base/colors";

import pxToRem from "/assets/theme/functions/pxToRem";
import linearGradient from "/assets/theme/functions/linearGradient";

const { borderWidth, borderColor } = borders;
const { transparent, dark } = colors;

const radio = {
  styleOverrides: {
    root: {
      "& .MuiSvgIcon-root": {
        width: pxToRem(20),
        height: pxToRem(20),
        color: transparent.main,
        border: `${borderWidth[1]} solid ${borderColor}`,
        borderRadius: "50%",
      },

      "&:after": {
        transition: "opacity 250ms ease-in-out",
        content: `""`,
        position: "absolute",
        width: pxToRem(14),
        height: pxToRem(14),
        borderRadius: "50%",
        backgroundImage: linearGradient(dark.main, dark.main),
        opacity: 0,
        left: 0,
        right: 0,
        top: 0,
        bottom: 0,
        margin: "auto",
      },

      "&:hover": {
        backgroundColor: transparent.main,
      },

      "&.Mui-focusVisible": {
        border: `${borderWidth[2]} solid ${dark.main} !important`,
      },
    },

    colorPrimary: {
      color: borderColor,

      "&.Mui-checked": {
        color: dark.main,

        "& .MuiSvgIcon-root": {
          borderColor: dark.main,
        },

        "&:after": {
          opacity: 1,
        },
      },
    },

    colorSecondary: {
      color: borderColor,

      "&.Mui-checked": {
        color: dark.main,

        "& .MuiSvgIcon-root": {
          borderColor: dark.main,
        },

        "&:after": {
          opacity: 1,
        },
      },
    },
  },
};

export default radio;
