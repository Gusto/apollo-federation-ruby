const grpc = require('grpc');
const path = require('path');
const protoLoader = require('@grpc/proto-loader');

const PROTO_PATH = path.join(__dirname, '/proto/federation_api.proto');
const packageDefinition = protoLoader.loadSync(PROTO_PATH, {
  keepCase: true,
  longs: String,
  enums: String,
  defaults: true,
  oneofs: true,
});
const { FederationAPI } = grpc.loadPackageDefinition(packageDefinition).graphql;

exports.default = class GrpcGraphQLDataSource {
  constructor(config) {
    this.client = new FederationAPI(config.url, grpc.credentials.createInsecure());
  }

  async process({request}) {
    const meta = new grpc.Metadata();
    if (request.http && request.http.headers) {
      request.http.headers.forEach()
      for (let [key, value] of request.http.headers) {
        meta.add(key, value);
      }
    }

    const { http, ...graphqlRequest } = request;
    const executeRequest = {
      body: JSON.stringify(graphqlRequest),
    };

    // TODO: try/catch and throw appropriate ApolloError (see apollo-gateway's RemoteGraphQLDataSource#errorFromResponse)
    const executeResponse = await this.execute(executeRequest, meta);
    console.log(`RESPONSE: ${executeResponse.body}`);
    return JSON.parse(executeResponse.body);
  }

  execute(executeRequest, meta) {
    return new Promise((resolve, reject) => {
      this.client.execute(executeRequest, meta, (error, executeResponse) => {
        if (error) {
          reject(error);
        } else {
          resolve(executeResponse);
        }
      });
    });
  }
}
