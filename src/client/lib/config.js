var AWS = require('aws-sdk');

module.exports = {
  ENV_NAME: process.env.ENV_NAME,

  PORT: process.env.PORT || 3000,
  REGION: process.env.REGION || 'eu-central-1',

  DYNAMODB_ENDPOINT: new AWS.Endpoint(process.env.DYNAMODB_ENDPOINT || 'https://dynamodb.eu-central-1.amazonaws.com'),

  // Controls how often clients ping back and forth
  HEARTBEAT_TIMEOUT: 8000,
  HEARTBEAT_INTERVAL: 4000
};

module.exports.SELF_URL = process.env.SELF_URL || 'http://localhost:' + module.exports.PORT;
