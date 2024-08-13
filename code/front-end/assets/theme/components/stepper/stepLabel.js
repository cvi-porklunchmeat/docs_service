import typography from "/assets/theme/base/typography";
import colors from "/assets/theme/base/colors";

import pxToRem from "/assets/theme/functions/pxToRem";

const { size, fontWeightRegular } = typography;
const { white, grey } = colors;

const stepLabel = {
  styleOverrides: {
    label: {
      marginTop: `${pxToRem(8)} !important`,
      fontWeight: fontWeightRegular,
      fontSize: size.xs,
      color: grey[500],
      textTransform: "uppercase",

      "&.Mui-active": {
        fontWeight: `${fontWeightRegular} !important`,
        color: `${white.main} !important`,
      },

      "&.Mui-completed": {
        fontWeight: `${fontWeightRegular} !important`,
        color: `${white.main} !important`,
      },
    },
  },
};

export default stepLabel;
