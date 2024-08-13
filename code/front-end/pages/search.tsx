//@ts-nocheck
// Gotta demo this tomorrow, we'll fix it later
import axios from "axios";

import { useEffect, useState } from "react";
import Card from "@mui/material/Card";

import MDBox from "@/components/MDBox";
import MDTypography from "@/components/MDTypography";

import DashboardLayout from "@/components/DashboardLayout";
import DashboardNavbar from "@/components/DashboardNavbar";
import DataTable from "@/components/search/datatable";

import { useSession, signIn } from "next-auth/react";

function DataTables() {
  const [data, setData] = useState(null);
  const [noResults, setNoResults] = useState(false);

  const { data: _session, status } = useSession();

  useEffect(() => {
    if (status === "authenticated") {
      const fetchData = async () => {
        try {
          const response = await axios.get("/api/get_opensearch_data");

          if (response.data.statusCode === 204) {
            setData(null);
            setNoResults(true);
          } else {
            const transformedData = {
              columns: [
                { Header: "Document Name", accessor: "document_name" },
                { Header: "Company", accessor: "company" },
                { Header: "Year", accessor: "year" },
                { Header: "Tags", accessor: "tags" },
                { Header: "Sector", accessor: "sector" },
                { Header: "Document Path", accessor: "document_s3_path" },
              ],
              rows: response.data.body.matched_documents,
            };

            setData(transformedData);
            setNoResults(false);
          }
        } catch (error) {
          console.error(error);
        }
      };

      fetchData();
    }
  }, [status]);

  if (status === "loading") {
    return <p>Hang on there...</p>;
  }

  if (status === "unauthenticated") {
    signIn("azure-ad");
  }

  return (
    <DashboardLayout>
      <DashboardNavbar absolute={true} />
      <MDBox pt={6} pb={3}>
        <MDBox mb={3}>
          <Card sx={{ height: "25%" }}>
            <MDBox p={3} lineHeight={1}>
              <MDTypography variant="h5" fontWeight="medium">
                Search Database
              </MDTypography>
              <MDTypography variant="button" color="text">
                Search through all the AB cloud documents bank.
              </MDTypography>
            </MDBox>
            {noResults ? (
              <MDTypography variant="h5" fontWeight="medium">
                No matching documents were found.
              </MDTypography>
            ) : (
              data && <DataTable table={data} canSearch />
            )}
          </Card>
        </MDBox>
      </MDBox>
    </DashboardLayout>
  );
}

export default DataTables;
