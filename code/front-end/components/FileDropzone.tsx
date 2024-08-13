import React, { useState } from "react";

import { FilePond, registerPlugin } from "react-filepond";

import "filepond/dist/filepond.min.css";

import FilePondPluginImageExifOrientation from "filepond-plugin-image-exif-orientation";
import FilePondPluginImagePreview from "filepond-plugin-image-preview";
import "filepond-plugin-image-preview/dist/filepond-plugin-image-preview.css";
import FilePondPluginFileValidateType from "filepond-plugin-file-validate-type";

registerPlugin(
  FilePondPluginImageExifOrientation,
  FilePondPluginImagePreview,
  FilePondPluginFileValidateType
);

type DropzoneProps = {
  selectedGroup: {
    id: string;
  };
  companyName: string;
  preferredDocName: string;
  tags: string;
  sector: string;
  year: string;
};

const Dropzone: React.FC<DropzoneProps> = ({
  selectedGroup,
  companyName,
  preferredDocName,
  tags,
  sector,
  year,
}) => {
  const [files] = useState([]);
  return (
    <div className="container min-h-[12rem] max-h-80">
      <FilePond
        files={files}
        allowMultiple={true}
        maxFiles={5}
        server={{
          process: {
            url: "/api/upload",
            method: "POST",
            ondata: (formData) => {
              formData.append("selectedGroup", selectedGroup.id);
              formData.append("companyName", companyName);
              formData.append("preferredDocName", preferredDocName);
              formData.append("tags", tags);
              formData.append("sector", sector);
              formData.append("year", year);
              return formData;
            },
          },
        }}
        acceptedFileTypes={["application/pdf"]}
        labelFileTypeNotAllowed={"Only PDFs are allowed to be uploaded"}
        fileValidateTypeLabelExpectedTypes={"Please try again."}
        name="files"
        credits={false}
        labelIdle="Drag & drop your files here"
      />
    </div>
  );
};

export default Dropzone;
