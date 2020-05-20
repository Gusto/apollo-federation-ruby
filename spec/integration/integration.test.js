import { ApolloGateway } from '@apollo/gateway';
import { ApolloServerBase as ApolloServer } from 'apollo-server-core';
import { createTestClient } from 'apollo-server-testing';
import gql from 'graphql-tag';
import { spawn } from 'child_process';

const GEMFILE = process.env.GEMFILE || 'Gemfile';

const startService = serviceName =>
  new Promise((resolve, reject) => {
    const child = spawn('bundle', [
      'exec',
      '--gemfile',
      GEMFILE,
      'ruby',
      `./example/${serviceName}.rb`,
      '--test',
    ]);

    let ready = false;
    const readyTimeout = setTimeout(() => {
      if (!ready) {
        child.kill();
        reject(new Error(`Starting the ${serviceName} service timed out`));
      }
    }, 4000);

    child.stdout.on('data', data => {
      if (data.toString().includes('_READY_')) {
        clearTimeout(readyTimeout);
        ready = true;
        resolve(child);
      }
    });

    child.on('error', err => reject(err));

    child.on('exit', code => {
      if (code) {
        const err = new Error(`The ${serviceName} service exited unexpectedly`);
        if (ready) {
          throw err;
        } else {
          clearTimeout(readyTimeout);
          reject(err);
        }
      }
    });

    child.stderr.on('data', data => {
      if (!child.killed) {
        console.error(`Error from ${serviceName} service: ${data}`);
      }
    });
  });

let testClient;
let serviceProcesses = [];
const serviceList = [
  { name: 'accounts', url: 'http://localhost:5001/graphql' },
  { name: 'reviews', url: 'http://localhost:5002/graphql' },
  { name: 'products', url: 'http://localhost:5003/graphql' },
  { name: 'inventory', url: 'http://localhost:5004/graphql' },
];

beforeAll(async () => {
  serviceProcesses = await Promise.all(serviceList.map(({ name }) => startService(name)));

  const gateway = new ApolloGateway({ serviceList });

  const { schema, executor } = await gateway.load();

  const server = new ApolloServer({
    schema,
    executor,
  });

  testClient = createTestClient(server);
});

afterAll(() => {
  serviceProcesses.forEach(child => {
    child.kill();
  });
});

it('works with a gateway', async () => {
  const query = gql`
    {
      me {
        name
        username
        reviews {
          body
          author {
            name
          }
          product {
            upc
            price
            weight
            name
            inStock
            shippingEstimate
            reviews {
              id
            }
          }
        }
      }
    }
  `;

  const result = await testClient.query({ query });

  expect(result.errors).toBeUndefined();
  expect(result.data).toEqual({
    me: {
      name: 'Ada Lovelace',
      username: '@ada',
      reviews: [
        {
          body: 'Love it!',
          author: {
            name: 'Ada Lovelace',
          },
          product: {
            upc: '1',
            price: 899,
            weight: 100,
            name: 'Table',
            inStock: true,
            shippingEstimate: 50,
            reviews: [
              {
                id: '1',
              },
              {
                id: '4',
              },
            ],
          },
        },
        {
          body: 'Too expensive.',
          author: {
            name: 'Ada Lovelace',
          },
          product: {
            upc: '2',
            price: 1299,
            weight: 1000,
            name: 'Couch',
            inStock: false,
            shippingEstimate: 0,
            reviews: [
              {
                id: '2',
              },
            ],
          },
        },
      ],
    },
  });
});

it('works with a @requires directive', async () => {
  const query = gql`
    {
      topProducts {
        upc
        shippingEstimate
      }
    }
  `;

  const result = await testClient.query({ query });

  expect(result.errors).toBeUndefined();
  expect(result.data).toEqual({
    topProducts: [
      {
        upc: '1',
        shippingEstimate: 50,
      },
      {
        upc: '2',
        shippingEstimate: 0,
      },
      {
        upc: '3',
        shippingEstimate: 25,
      },
    ],
  });
});

it('works with a @provides directive', async () => {
  const query = gql`
    {
      topProducts {
        upc
        reviews {
          id
          author {
            username
          }
        }
      }
    }
  `;

  const result = await testClient.query({ query });

  expect(result.errors).toBeUndefined();
  expect(result.data).toEqual({
    topProducts: [
      {
        upc: '1',
        reviews: [
          {
            id: '1',
            author: {
              username: '@ada',
            },
          },
          {
            id: '4',
            author: {
              username: '@complete',
            },
          },
        ],
      },
      {
        upc: '2',
        reviews: [
          {
            id: '2',
            author: {
              username: '@ada',
            },
          },
        ],
      },
      {
        upc: '3',
        reviews: [
          {
            id: '3',
            author: {
              username: '@complete',
            },
          },
        ],
      },
    ],
  });
});
