import axios from "axios";

import { getToken } from "next-auth/jwt";

export default async function handler(req, res) {
  const sessionToken = await getToken({ req });

  if (req.method === "GET") {
    const search_term = req.query.search_term || "financial";

    try {
      const response = await axios.get(
        `${process.env.API_URL}/docs/search?search_term=${search_term}`,
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
    res.setHeader("Allow", ["GET"]);
    res.status(405).end(`Method ${req.method} Not Allowed`);
  }
}
