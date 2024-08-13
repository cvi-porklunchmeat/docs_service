const AWS = require('aws-sdk')
const express = require('express')
const serverless = require('serverless-http')
const cors = require('cors')
const swaggerUI = require('swagger-ui-express')

var apigateway = new AWS.APIGateway({apiVersion: '2015-07-09'});

const app = express()

var corsOptions = {
  origin: process.env.ALLOWED_ORIGIN,
}

module.exports.handler = async (event, context) => {
    const apiId = event.requestContext.apiId
    const stage = event.requestContext.stage
    const domainPrefix = event.requestContext.domainPrefix

    var params = {
        exportType: 'swagger',
        restApiId: apiId,
        stageName: stage,
        accepts: 'application/json'
      };

    var getExportPromise = await apigateway.getExport(params).promise()
    var body = getExportPromise.body

    // Due to us using a private in API Gateway, the URL in the swagger.json is incorrect
    const fixedUpURL = body.replaceAll(apiId, domainPrefix);
    
    var swaggerJson = JSON.parse(fixedUpURL)

    delete swaggerJson['paths']['/api-docs/{proxy+}']
    delete swaggerJson['paths']['/api-docs']

    app.use(cors(corsOptions))
    app.use('/api-docs', swaggerUI.serve, swaggerUI.setup(swaggerJson, { explorer: true } ))
    const handler = serverless(app)
    const ret = await handler(event, context)
    return ret
 };
