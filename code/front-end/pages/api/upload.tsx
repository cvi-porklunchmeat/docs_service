import formidable from "formidable";
import axios from "axios";
import fs from "fs";
import util from "util";

import { NextApiRequest, NextApiResponse } from "next";
import { JWT, getToken } from "next-auth/jwt";
import { getServerSession } from "next-auth/next";

const readFile = util.promisify(fs.readFile);

export const config = {
  api: {
    bodyParser: false,
  },
};

interface Metadata {
  selectedGroup: string;
  companyName: string;
  preferredDocName: string;
  tags: string;
  sector: string;
  year: string;
}

export default async function handler(
  req: NextApiRequest,
  res: NextApiResponse
) {
  if (req.method !== "POST") {
    return res.status(405).json({ error: "Method not allowed" });
  }

  const form = new formidable.IncomingForm();
  const session = await getServerSession(req, res, {});
  const sessionToken = await getToken({ req });
  const userEmail = session?.user?.email;
  const accessToken = sessionToken?.accessToken;

  // return res.status(200).json({ session: session, sessionToken: sessionToken });

  form.parse(req, async (err, fields, upload) => {
    try {
      if (err) {
        console.error("Error while parsing form: ", err);
        return res
          .status(500)
          .json({ message: "Something went wrong while parsing the form." });
      }

      // @ts-ignore
      const filePath = upload.files.filepath;
      const fileData = await readFile(filePath);
      // @ts-ignore
      const url = await fetchPresignedUrl(accessToken, fields, userEmail);
      // @ts-ignore
      const success = await uploadToS3(url, fileData, upload.files.mimetype);

      if (success) {
        res.status(200).json({ message: "File uploaded successfully" });
      } else {
        res.status(500).json({ message: "Failed to upload file to S3" });
      }
    } catch (error) {
      console.error("Error in form.parse: ", error);
      res.status(500).json({ message: "Internal Server Error" });
    }
  });
}

const fetchPresignedUrl = async (
  userToken: JWT | null,
  fields: Metadata,
  userEmail: string
) => {
  const [namePart, _domainPart] = userEmail.split("@");
  const userAsGroup = namePart.replace(".", "_");
  const selectedGroup =
    fields.selectedGroup === "just_me" ? userAsGroup : fields.selectedGroup;
  const res = await axios.post(
    `${process.env.API_URL}/upload/local`,
    {
      tags: fields.tags,
      user_email: userEmail,
      group: selectedGroup,
      sector: fields.sector,
      year: fields.year,
      company_name: fields.companyName,
      document_name: fields.preferredDocName,
    },
    {
      headers: {
        Authorization: `Bearer ${userToken}`,
        "Content-Type": "application/json",
        Accept: "*/*",
        "Accept-Encoding": "gzip, deflate, br",
        Connection: "keep-alive",
      },
    }
  );

  return res.data.body.url;
};

const uploadToS3 = async (url: string, file: Buffer, filetype: any) => {
  const options = {
    headers: {
      "Content-Type": filetype,
    },
  };

  let response;

  try {
    response = await axios.put(url, file, options);
  } catch (error) {
    console.error("Error uploading to S3:", error);
    throw error;
  }

  if (response.status !== 200) {
    console.error("Failed to upload file to S3:", response.statusText);
    throw new Error("Failed to upload file to S3");
  }

  return response.status === 200;
};
