import React, { Component } from "react";

import ViewSDKClient from "/components/PDFViewer/ViewSDKClient";

import axios from "axios";

class Adobe extends Component {
  constructor(pdfURL, searchTerm, setLoadingStatus) {
    super();
    this.pdfURL = pdfURL;
    this.searchTerm = searchTerm;
    this.setLoadingStatus = setLoadingStatus;
    this.viewSDKClient = new ViewSDKClient();
  }

  async showFile() {
    const viewSDKClient = this.viewSDKClient;
    const adobeApiKey = process.env.NEXT_PUBLIC_ADOBE_API_KEY;

    const response = await axios.get(
      `/api/get_document_url?document_path=${this.pdfURL}`
    );

    viewSDKClient.ready().then(() => {
      viewSDKClient
        .previewFile(
          "pdf-div",
          {
            embedMode: "LIGHT_BOX",
            defaultViewMode: "FIT_PAGE",
            enableSearchAPIs: true,
            content: {
              location: {
                url: response.data.message,
              },
            },
          },
          adobeApiKey
        )
        .then((adobeViewer) => {
          adobeViewer.getAPIs().then((apis) => {
            apis.search(this.searchTerm);
          });
        })
        .then(() => this.setLoadingStatus(false));
    });
  }

  render() {
    return <div id="pdf-div"></div>;
  }
}

export default Adobe;
