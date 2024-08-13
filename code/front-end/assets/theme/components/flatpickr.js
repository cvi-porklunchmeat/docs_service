import colors from "/assets/theme/base/colors";

import rgba from "/assets/theme/functions/rgba";

const { dark, white, gradients } = colors;

const flatpickr = {
  ".flatpickr-day:hover, .flatpickr-day:focus, .flatpickr-day.nextMonthDay:hover, .flatpickr-day.nextMonthDay:focus":
    {
      background: rgba(dark.main, 0.28),
      border: "none",
    },

  ".flatpickr-day.today": {
    background: dark.main,
    color: white.main,
    border: "none",

    "&:hover, &:focus": {
      background: `${dark.focus} !important`,
    },
  },

  ".flatpickr-day.selected, .flatpickr-day.selected:hover, .flatpickr-day.nextMonthDay.selected, .flatpickr-day.nextMonthDay.selected:hover, .flatpickr-day.nextMonthDay.selected:focus":
    {
      background: `${gradients.dark.state} !important`,
      color: white.main,
      border: "none",
    },

  ".flatpickr-months .flatpickr-next-month:hover svg, .flatpickr-months .flatpickr-prev-month:hover svg":
    {
      color: `${dark.main} !important`,
      fill: `${dark.main} !important`,
    },
};

export default flatpickr;
