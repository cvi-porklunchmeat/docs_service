import axios from "axios";

import { getToken } from "next-auth/jwt";

export default async function handler(req, res) {
  const sessionToken = await getToken({ req });

  if (req.method === "GET") {
    let documentPath = req.query.document_path;

    // Investigate what's going on here
    documentPath = documentPath.replace("s3:/", "s3://");

    try {
      const response = await axios.get(
        `${process.env.API_URL}/generate_document_url?document_path=${documentPath}`,
        {
          headers: {
            Authorization: `Bearer ${sessionToken?.accessToken}`,
            "Content-Type": "application/json",
            Accept: "*/*",
            "Accept-Encoding": "gzip, deflate, br",
            Connection: "keep-alive",
          },
        }
      );

      res.status(200).json(response.data);
    } catch (error) {
      console.error(error);
      res.status(error.status || 500).end(error.message);
    }
  } else {
    res.setHeader("Allow", ["POST"]);
    res.status(405).end(`Method ${req.method} Not Allowed`);
  }
}
