const { ApolloServer } = require('apollo-server');
const { ApolloGateway } = require('@apollo/gateway');
const {
  RemoteGraphQLDataSource,
} = require('@apollo/gateway/dist/datasources/RemoteGraphQLDataSource');
const GrpcGraphQLDataSource = require('./GrpcGraphQLDataSource').default;

const gateway = new ApolloGateway({
  serviceList: [
    // { name: 'accounts', url: 'http://localhost:50001/graphql' },
    // { name: 'reviews', url: 'http://localhost:50002/graphql' },
    // { name: 'products', url: 'http://localhost:50003/graphql' },
    // { name: 'inventory', url: 'http://localhost:50004/graphql' },

    { name: 'accounts', url: 'localhost:50001', type: 'grpc' },
    { name: 'reviews', url: 'localhost:50002', type: 'grpc' },
    { name: 'products', url: 'localhost:50003', type: 'grpc' },
    { name: 'inventory', url: 'localhost:50004', type: 'grpc' },
  ],
  buildService: config => {
    if (config.type === 'grpc') {
      return new GrpcGraphQLDataSource(config);
    }
    return new RemoteGraphQLDataSource(config);
  },
  debug: true,
});

(async () => {
  const { schema, executor } = await gateway.load();

  const server = new ApolloServer({ schema, executor });

  server.listen({ port: 50000 }).then(({ url }) => {
    console.log(`🚀 Server ready at ${url}`);
  });
})();
