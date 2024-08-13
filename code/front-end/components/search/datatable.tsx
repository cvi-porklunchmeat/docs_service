//@ts-nocheck
// Gotta demo this tomorrow, we'll fix it later

import axios from "axios";

import { useMemo, useEffect, useState } from "react";

import PropTypes from "prop-types";

import { styled } from "@mui/material/styles";

import {
  useTable,
  usePagination,
  useGlobalFilter,
  useAsyncDebounce,
  useSortBy,
} from "react-table";

import "regenerator-runtime/runtime.js";

import Table from "@mui/material/Table";
import TableBody from "@mui/material/TableBody";
import TableContainer from "@mui/material/TableContainer";
import TableRow from "@mui/material/TableRow";
import Icon from "@mui/material/Icon";
import Autocomplete from "@mui/material/Autocomplete";

import MDBox from "@/components/MDBox";
import MDTypography from "@/components/MDTypography";
import MDInput from "@/components/MDInput";
import MDInputSearch from "@/components/MDInputSearch";
import MDPagination from "@/components/MDPagination";

import DataTableHeadCell from "@/components/DataTable/DataTableHeadCell";
import DataTableBodyCell from "@/components/DataTable/DataTableBodyCell";

import NotificationItem from "@/components/NotificationItem";

import CircularProgress from "@mui/material/CircularProgress";

import Adobe from "@/components/PDFViewer";

function DataTable({
  entriesPerPage,
  canSearch,
  showTotalEntries,
  table,
  pagination,
  isSorted,
  noEndBorder,
}) {
  const defaultValue = entriesPerPage.defaultValue
    ? entriesPerPage.defaultValue
    : 10;
  const entries = entriesPerPage.entries
    ? entriesPerPage.entries.map((el) => el.toString())
    : ["5", "10", "15", "20", "25"];

  const columns = useMemo(() => table.columns, [table]);
  const [data, setData] = useState([]);
  const [isLoading, setIsLoading] = useState(false);

  const setLoadingStatus = (status: boolean) => {
    setIsLoading(status);
  };

  const tableInstance = useTable(
    { columns, data, initialState: { pageIndex: 0 } },
    useGlobalFilter,
    useSortBy,
    usePagination
  );

  const {
    getTableProps,
    getTableBodyProps,
    headerGroups,
    prepareRow,
    rows,
    page,
    pageOptions,
    canPreviousPage,
    canNextPage,
    gotoPage,
    nextPage,
    previousPage,
    setPageSize,
    setGlobalFilter,
    state: { pageIndex, pageSize, globalFilter },
  } = tableInstance;

  useEffect(() => setPageSize(defaultValue || 10), [defaultValue, setPageSize]);

  const setEntriesPerPage = (value) => setPageSize(value);

  const renderPagination = pageOptions.map((option) => (
    <MDPagination
      item
      key={option}
      onClick={() => gotoPage(Number(option))}
      active={pageIndex === option}
    >
      {option + 1}
    </MDPagination>
  ));

  const handleInputPagination = ({ target: { value } }) =>
    value > pageOptions.length || value < 0
      ? gotoPage(0)
      : gotoPage(Number(value));

  const customizedPageOptions = pageOptions.map((option) => option + 1);

  const handleInputPaginationValue = ({ target: value }) =>
    gotoPage(Number(value.value - 1));

  const [search, setSearch] = useState(globalFilter);

  const onSearchChange = useAsyncDebounce((value) => {
    setGlobalFilter(value || undefined);
  }, 100);

  const [noResults, setNoResults] = useState(false);
  const [errorMessage, setErrorMessage] = useState("");

  const setSortedValue = (column) => {
    let sortedValue;

    if (isSorted && column.isSorted) {
      sortedValue = column.isSortedDesc ? "desc" : "asce";
    } else if (isSorted) {
      sortedValue = "none";
    } else {
      sortedValue = false;
    }

    return sortedValue;
  };

  const entriesStart =
    pageIndex === 0 ? pageIndex + 1 : pageIndex * pageSize + 1;

  const StyledTableRow = styled(TableRow)(({ theme }) => ({
    "&:nth-of-type(odd)": {
      backgroundColor: "#f1f2f5",
    },
  }));

  const fetchData = async (searchTerm) => {
    setNoResults(false);
    setIsLoading(true);

    const response = await axios.get(
      `/api/get_opensearch_data?search_term=${searchTerm}`
    );

    if (response.data.statusCode === 204) {
      setNoResults(true);
      setErrorMessage(response.data.body.message);
    } else {
      const transformedData = response.data.body.matched_documents;
      setData(transformedData);
    }
    setIsLoading(false);
  };

  let entriesEnd;

  if (pageIndex === 0) {
    entriesEnd = pageSize;
  } else if (pageIndex === pageOptions.length - 1) {
    entriesEnd = rows.length;
  } else {
    entriesEnd = pageSize * (pageIndex + 1);
  }

  return (
    <TableContainer sx={{ boxShadow: "none" }}>
      {isLoading ? (
        <MDBox
          display="flex"
          justifyContent="center"
          alignItems="center"
          height="100%"
        >
          <CircularProgress color="info" />
        </MDBox>
      ) : null}

      {noResults ? (
        <NotificationItem
          pt={2}
          pb={5}
          px={3}
          icon={<Icon fontSize="small">reportproblem</Icon>}
          title={errorMessage}
          onClick={() => setNoResults(false)}
        />
      ) : null}

      {canSearch ? (
        <MDBox pt={2} pb={5} px={3}>
          {canSearch && (
            <MDBox>
              <MDInputSearch
                placeholder="Search..."
                value={search || ""}
                size="small"
                fullWidth
                onChange={({ currentTarget }) => {
                  setSearch(currentTarget.value);
                }}
                onKeyPress={(event) => {
                  if (event.key === "Enter") {
                    fetchData(search, true);
                  }
                }}
              />
            </MDBox>
          )}
        </MDBox>
      ) : null}
      {table.rows.length > 0 ? (
        <>
          <Table {...getTableProps()}>
            <MDBox component="thead">
              {headerGroups.map((headerGroup, key) => (
                <TableRow key={key} {...headerGroup.getHeaderGroupProps()}>
                  {headerGroup.headers.map((column, key) => (
                    <DataTableHeadCell
                      key={key}
                      {...column.getHeaderProps(
                        isSorted && column.getSortByToggleProps()
                      )}
                      width={column.width ? column.width : "auto"}
                      align={column.align ? column.align : "left"}
                      sorted={setSortedValue(column)}
                    >
                      {column.render("Header")}
                    </DataTableHeadCell>
                  ))}
                </TableRow>
              ))}
            </MDBox>
            <TableBody {...getTableBodyProps()}>
              {page.map((row, key) => {
                prepareRow(row);
                return (
                  <StyledTableRow hover key={key} {...row.getRowProps()}>
                    {row.cells.map((cell, cellKey) => (
                      <DataTableBodyCell
                        key={cellKey}
                        noBorder={noEndBorder && rows.length - 1 === key}
                        align={cell.column.align ? cell.column.align : "left"}
                        {...cell.getCellProps()}
                      >
                        {cellKey === row.cells.length - 1 ? (
                          <div
                            onClick={() => {
                              setIsLoading(true);

                              new Adobe(
                                cell.value,
                                search,
                                setLoadingStatus
                              ).showFile();
                            }}
                          >
                            <a style={{ cursor: "pointer", color: "#1E9BD7" }}>
                              Open Document
                            </a>
                          </div>
                        ) : (
                          cell.render("Cell")
                        )}
                      </DataTableBodyCell>
                    ))}
                  </StyledTableRow>
                );
              })}
            </TableBody>
          </Table>

          <MDBox
            display="flex"
            flexDirection={{ xs: "column", sm: "row" }}
            justifyContent="space-between"
            alignItems={{ xs: "flex-start", sm: "center" }}
            p={!showTotalEntries && pageOptions.length === 1 ? 0 : 3}
          >
            {showTotalEntries && (
              <MDBox mb={{ xs: 3, sm: 0 }}>
                <MDTypography
                  variant="button"
                  color="secondary"
                  fontWeight="regular"
                >
                  Showing {entriesStart} to {entriesEnd} of {rows.length}{" "}
                  entries
                </MDTypography>
              </MDBox>
            )}

            {entriesPerPage && (
              <MDBox display="flex" alignItems="center">
                <Autocomplete
                  disableClearable
                  value={pageSize.toString()}
                  options={entries}
                  onChange={(event, newValue) => {
                    setEntriesPerPage(parseInt(newValue, 10));
                  }}
                  size="small"
                  sx={{ width: "5rem" }}
                  renderInput={(params) => <MDInput {...params} />}
                />
                <MDTypography variant="caption" color="secondary">
                  &nbsp;&nbsp;entries per page
                </MDTypography>
              </MDBox>
            )}

            {pageOptions.length > 1 && (
              <MDPagination
                variant={pagination.variant ? pagination.variant : "gradient"}
                color={pagination.color ? pagination.color : "dark"}
                size="small"
              >
                {canPreviousPage && (
                  <MDPagination item onClick={() => previousPage()}>
                    <Icon sx={{ fontWeight: "bold" }}>chevron_left</Icon>
                  </MDPagination>
                )}
                {renderPagination.length > 6 ? (
                  <MDBox width="5rem" mx={1}>
                    <MDInput
                      inputProps={{
                        type: "number",
                        min: 1,
                        max: customizedPageOptions.length,
                      }}
                      value={customizedPageOptions[pageIndex]}
                      onChange={
                        (handleInputPagination, handleInputPaginationValue)
                      }
                    />
                  </MDBox>
                ) : (
                  renderPagination
                )}
                {canNextPage && (
                  <MDPagination item onClick={() => nextPage()}>
                    <Icon sx={{ fontWeight: "bold" }}>chevron_right</Icon>
                  </MDPagination>
                )}
              </MDPagination>
            )}
          </MDBox>
        </>
      ) : null}
    </TableContainer>
  );
}

DataTable.defaultProps = {
  entriesPerPage: { defaultValue: 10, entries: [5, 10, 15, 20, 25] },
  canSearch: false,
  showTotalEntries: true,
  pagination: { variant: "gradient", color: "dark" },
  isSorted: true,
  noEndBorder: false,
};

DataTable.propTypes = {
  entriesPerPage: PropTypes.oneOfType([
    PropTypes.shape({
      defaultValue: PropTypes.number,
      entries: PropTypes.arrayOf(PropTypes.number),
    }),
    PropTypes.bool,
  ]),
  canSearch: PropTypes.bool,
  showTotalEntries: PropTypes.bool,
  table: PropTypes.objectOf(PropTypes.array).isRequired,
  pagination: PropTypes.shape({
    variant: PropTypes.oneOf(["contained", "gradient"]),
    color: PropTypes.oneOf([
      "primary",
      "secondary",
      "info",
      "success",
      "warning",
      "error",
      "dark",
      "light",
    ]),
  }),
  isSorted: PropTypes.bool,
  noEndBorder: PropTypes.bool,
};

export default DataTable;
