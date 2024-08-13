/*
Copyright 2020 Adobe
All Rights Reserved.

NOTICE: Adobe permits you to use, modify, and distribute this file in
accordance with the terms of the Adobe license agreement accompanying
it. If you have received this file from a source other than Adobe,
then your use, modification, or distribution of it requires the prior
written permission of Adobe.
*/

class ViewSDKClient {
  constructor() {
    this.readyPromise = new Promise((resolve) => {
      if (window.AdobeDC) {
        resolve();
      } else {
        document.addEventListener("adobe_dc_view_sdk.ready", () => {
          resolve();
        });
      }
    });
  }

  ready() {
    return this.readyPromise;
  }

  previewFile(divId, viewerConfig, adobeApiKey) {
    const config = {
      clientId: adobeApiKey ? adobeApiKey : "d85fbaa89009461fba745be7affb3150",
    };

    if (divId) {
      config.divId = divId;
    }

    this.adobeDcloudew = new window.AdobeDC.View(config);

    const previewFilePromise = this.adobeDcloudew.previewFile(
      {
        content: viewerConfig.content,
        metaData: {
          fileName: "Document.pdf",
          id: "6d07d124-ac85-43b3-a867-36930f502ac6",
        },
      },
      viewerConfig
    );

    return previewFilePromise;
  }
}

export default ViewSDKClient;
