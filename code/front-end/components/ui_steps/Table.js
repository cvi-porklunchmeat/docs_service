import React from "react";

const data = [
  {
    id: 1,
    company: "American Express",
    year: 2022,
    sector: "Financial",
    tag: "Legal",
    matches: 9,
  },
  {
    id: 2,
    company: "Twitter",
    year: 2027,
    sector: "Financial",
    tag: "Europe",
    matches: 2,
  },
  {
    id: 3,
    company: "Tesla",
    year: 2030,
    sector: "Technology",
    tag: "US",
    matches: 3,
  },
  {
    id: 4,
    company: "SpaceX",
    year: 2024,
    sector: "Financial",
    tag: "Tax",
    matches: 1,
  },
  {
    id: 5,
    company: "Apple",
    year: 2033,
    sector: "Technology",
    tag: "Engineering",
    matches: 7,
  },
  {
    id: 6,
    company: "Google",
    year: 2033,
    sector: "Financial",
    tag: "Engineering",
    matches: 12,
  },
  {
    id: 7,
    company: "Open AI",
    year: 2033,
    sector: "Financial",
    tag: "Engineering",
    matches: 9,
  },
  {
    id: 8,
    company: "Microsoft",
    year: 2033,
    sector: "Financial",
    tag: "Engineering",
    matches: 1,
  },
];

const TableComponent = () => (
  <table className="table-auto w-full">
    <thead>
      <tr className="leading-normal">
        <th className="py-3 px-6 text-left">ID</th>
        <th className="py-3 px-6 text-left">Company Name</th>
        <th className="py-3 px-6 text-left">Year</th>
        <th className="py-3 px-6 text-left">Tags</th>
        <th className="py-3 px-6 text-left">Sector</th>
        <th className="py-3 px-6 text-left">Matches</th>
      </tr>
    </thead>
    <tbody>
      {data.map((row, index) => (
        <tr
          key={row.id}
          className={index % 2 === 0 ? "bg-gray-100" : "bg-white"}
        >
          <td className="py-3 px-6 text-left">{row.id}</td>
          <td className="py-3 px-6 text-left">{row.company}</td>
          <td className="py-3 px-6 text-left">{row.year}</td>
          <td className="py-3 px-6 text-left">{row.tag}</td>
          <td className="py-3 px-6 text-left">{row.sector}</td>
          <td className="py-3 px-6 text-left">{row.matches}</td>
        </tr>
      ))}
    </tbody>
  </table>
);

export default TableComponent;
