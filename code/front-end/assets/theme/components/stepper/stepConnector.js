import borders from "/assets/theme/base/borders";
import colors from "/assets/theme/base/colors";

const { white, grey } = colors;
const { borderWidth } = borders;

const stepConnector = {
  styleOverrides: {
    root: {
      color: grey[500],
      transition: "all 200ms linear",

      "&.Mui-active": {
        color: white.main,
      },

      "&.Mui-completed": {
        color: white.main,
      },
    },

    alternativeLabel: {
      top: "14%",
      left: "-50%",
      right: "50%",
    },

    line: {
      borderWidth: `${borderWidth[2]} !important`,
      borderColor: "currentColor",
    },
  },
};

export default stepConnector;
