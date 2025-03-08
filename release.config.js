module.exports = {
  plugins: [
    [
      '@semantic-release/commit-analyzer',
      {
        preset: 'angular',
        releaseRules: [{ type: 'chore', release: 'patch' }],
      },
    ],
    '@semantic-release/release-notes-generator',
    '@semantic-release/changelog',
    [
      'semantic-release-rubygem',
      {
        updateGemfileLock: 'bundle install',
        gemPublish: false,
      },
    ],
    [
      '@semantic-release/git',
      {
        assets: [
          'CHANGELOG.md',
          'gemfiles/*.lock',
          'Gemfile.lock',
          'lib/apollo-federation/version.rb',
        ],
      },
    ],
    '@semantic-release/github',
  ],
  branches: ['main'],
};
