import colors from "/assets/theme-dark/base/colors";

import rgba from "/assets/theme-dark/functions/rgba";

const { white } = colors;

const flatpickr = {
  ".flatpickr-day:hover, .flatpickr-day:focus, .flatpickr-day.nextMonthDay:hover, .flatpickr-day.nextMonthDay:focus":
    {
      background: rgba(white.main, 0.28),
      border: "none",
    },

  ".flatpickr-day.today": {
    background: white.main,
    color: white.main,
    border: "none",

    "&:hover, &:focus": {
      background: `${white.focus} !important`,
    },
  },

  ".flatpickr-day.selected, .flatpickr-day.selected:hover, .flatpickr-day.nextMonthDay.selected, .flatpickr-day.nextMonthDay.selected:hover, .flatpickr-day.nextMonthDay.selected:focus":
    {
      background: `${white.main} !important`,
      color: white.main,
      border: "none",
    },

  ".flatpickr-months .flatpickr-next-month:hover svg, .flatpickr-months .flatpickr-prev-month:hover svg":
    {
      color: `${white.main} !important`,
      fill: `${white.main} !important`,
    },
};

export default flatpickr;
