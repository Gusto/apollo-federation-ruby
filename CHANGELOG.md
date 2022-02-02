## [2.0.3](https://github.com/Gusto/apollo-federation-ruby/compare/v2.0.2...v2.0.3) (2022-02-02)


### Bug Fixes

* Attempt to remove platform specific lock on google-protobuf ([#171](https://github.com/Gusto/apollo-federation-ruby/issues/171)) ([7898c28](https://github.com/Gusto/apollo-federation-ruby/commit/7898c2851aca06f08fa2559652375769bb98dfd8))

## [2.0.2](https://github.com/Gusto/apollo-federation-ruby/compare/v2.0.1...v2.0.2) (2022-01-31)


### Bug Fixes

* Use `bundle install` to avoid `bundle check` that changes our lockfiles ([#170](https://github.com/Gusto/apollo-federation-ruby/issues/170)) ([5c89ff1](https://github.com/Gusto/apollo-federation-ruby/commit/5c89ff1545dd1e6668fcdcf5b6fa89188cbb3ab4))

## [2.0.1](https://github.com/Gusto/apollo-federation-ruby/compare/v2.0.0...v2.0.1) (2022-01-27)


### Bug Fixes

* Update to latest Ruby 2.6 image ([#167](https://github.com/Gusto/apollo-federation-ruby/issues/167)) ([f57d523](https://github.com/Gusto/apollo-federation-ruby/commit/f57d523c36274d5f729bc724ab0f86474f7c0f73))

# [2.0.0](https://github.com/Gusto/apollo-federation-ruby/compare/v1.1.5...v2.0.0) (2022-01-27)


* Remove beta disclaimer (#165) ([29da3de](https://github.com/Gusto/apollo-federation-ruby/commit/29da3deb0163c38d5d08f084e5e8dc67d8454358)), closes [#165](https://github.com/Gusto/apollo-federation-ruby/issues/165)


### BREAKING CHANGES

* GraphQL 1.9.x support removed

## [1.1.5](https://github.com/Gusto/apollo-federation-ruby/compare/v1.1.4...v1.1.5) (2020-10-29)


### Bug Fixes

* pass context as a Hash to GraphQL::Schema.federation_sdl ([c13a94e](https://github.com/Gusto/apollo-federation-ruby/commit/c13a94e6487471b47f05907bd4f83c03fa7e6af7))

## [1.1.4](https://github.com/Gusto/apollo-federation-ruby/compare/v1.1.3...v1.1.4) (2020-09-25)


### Bug Fixes

* **tracing:** properly handle parsing and validation errors ([#102](https://github.com/Gusto/apollo-federation-ruby/issues/102)) ([a1c2a41](https://github.com/Gusto/apollo-federation-ruby/commit/a1c2a41d3d01f06364d439cdcc273f4678fed7bd)), closes [#101](https://github.com/Gusto/apollo-federation-ruby/issues/101) [#101](https://github.com/Gusto/apollo-federation-ruby/issues/101)

## [1.1.4-beta.1](https://github.com/Gusto/apollo-federation-ruby/compare/v1.1.3...v1.1.4-beta.1) (2020-09-21)


### Bug Fixes

* **tracing:** properly handle parsing and validation errors ([#101](https://github.com/Gusto/apollo-federation-ruby/issues/101)) ([6cf8202](https://github.com/Gusto/apollo-federation-ruby/commit/6cf820281dd85bd358c6bf4c176b9a73a9280d54))

## [1.1.3](https://github.com/Gusto/apollo-federation-ruby/compare/v1.1.2...v1.1.3) (2020-07-16)


### Bug Fixes

* **tracing:** Properly handle tracing fields that resolve an array of lazy values ([#87](https://github.com/Gusto/apollo-federation-ruby/issues/87)) ([a9eed77](https://github.com/Gusto/apollo-federation-ruby/commit/a9eed77bbe5859456f93be00fbcafa02142ad5ed))

## [1.1.2](https://github.com/Gusto/apollo-federation-ruby/compare/v1.1.1...v1.1.2) (2020-06-09)


### Bug Fixes

* Fix _service field type owner ([#70](https://github.com/Gusto/apollo-federation-ruby/issues/70)) ([364e54f](https://github.com/Gusto/apollo-federation-ruby/commit/364e54fbb333b7cd4fe30f04bf72733b0e18d3f4))

## [1.1.1](https://github.com/Gusto/apollo-federation-ruby/compare/v1.1.0...v1.1.1) (2020-05-29)


### Bug Fixes

* **lazy resolve:** Handle problem with sync resolve ([#58](https://github.com/Gusto/apollo-federation-ruby/issues/58)) ([e66c22b](https://github.com/Gusto/apollo-federation-ruby/commit/e66c22ba6fe51a7c282190ee77bd02dbfa514a66))

# [1.1.0](https://github.com/Gusto/apollo-federation-ruby/compare/v1.0.4...v1.1.0) (2020-05-27)


### Features

* Add support for interpreter runtime ([#65](https://github.com/Gusto/apollo-federation-ruby/issues/65)) ([1957da0](https://github.com/Gusto/apollo-federation-ruby/commit/1957da0))

## [1.0.4](https://github.com/Gusto/apollo-federation-ruby/compare/v1.0.3...v1.0.4) (2020-04-06)


### Bug Fixes

* Fix spec to account for breaking change to graphql-ruby 1.10.0 ([#62](https://github.com/Gusto/apollo-federation-ruby/issues/62)) ([a631441](https://github.com/Gusto/apollo-federation-ruby/commit/a631441))

## [1.0.3](https://github.com/Gusto/apollo-federation-ruby/compare/v1.0.2...v1.0.3) (2020-03-25)


### Bug Fixes

* Make the tracer work with the new interpreter runtime ([#59](https://github.com/Gusto/apollo-federation-ruby/issues/59)) ([de4caf0](https://github.com/Gusto/apollo-federation-ruby/commit/de4caf0))

## [1.0.2](https://github.com/Gusto/apollo-federation-ruby/compare/v1.0.1...v1.0.2) (2020-02-19)


### Bug Fixes

* service field context ([#50](https://github.com/Gusto/apollo-federation-ruby/issues/50)) ([6dd1fe7](https://github.com/Gusto/apollo-federation-ruby/commit/6dd1fe7))

## [1.0.1](https://github.com/Gusto/apollo-federation-ruby/compare/v1.0.0...v1.0.1) (2020-01-29)


### Bug Fixes

* Send context to SDL generation / don't cache ([#45](https://github.com/Gusto/apollo-federation-ruby/issues/45)) ([9a29be1](https://github.com/Gusto/apollo-federation-ruby/commit/9a29be1))

# [1.0.0](https://github.com/Gusto/apollo-federation-ruby/compare/v0.5.1...v1.0.0) (2019-12-09)


### Bug Fixes

* specify dependency versions ([#35](https://github.com/Gusto/apollo-federation-ruby/issues/35)) ([0a29bb3](https://github.com/Gusto/apollo-federation-ruby/commit/0a29bb3))


### BREAKING CHANGES

* Requires graphql ~> 1.9.8 and google-protobuf ~> 3.7

## [0.5.1](https://github.com/Gusto/apollo-federation-ruby/compare/v0.5.0...v0.5.1) (2019-10-22)


### Bug Fixes

* drop actionpack from runtime dependencies ([#34](https://github.com/Gusto/apollo-federation-ruby/issues/34)) ([64acd27](https://github.com/Gusto/apollo-federation-ruby/commit/64acd27))

# [0.5.0](https://github.com/Gusto/apollo-federation-ruby/compare/v0.4.2...v0.5.0) (2019-10-22)


### Features

* Support Interfaces ([#27](https://github.com/Gusto/apollo-federation-ruby/issues/27)) ([33d0097](https://github.com/Gusto/apollo-federation-ruby/commit/33d0097))

## [0.4.2](https://github.com/Gusto/apollo-federation-ruby/compare/v0.4.1...v0.4.2) (2019-10-21)


### Bug Fixes

* typo in exception message ([#33](https://github.com/Gusto/apollo-federation-ruby/issues/33)) ([0a337f3](https://github.com/Gusto/apollo-federation-ruby/commit/0a337f3))

## [0.4.1](https://github.com/Gusto/apollo-federation-ruby/compare/v0.4.0...v0.4.1) (2019-10-12)


### Bug Fixes

* Support lazy objects ([#17](https://github.com/Gusto/apollo-federation-ruby/issues/17)) ([68b0b9a](https://github.com/Gusto/apollo-federation-ruby/commit/68b0b9a))

# [0.4.0](https://github.com/Gusto/apollo-federation-ruby/compare/v0.3.2...v0.4.0) (2019-09-10)


### Features

* add support for federated tracing ([#16](https://github.com/Gusto/apollo-federation-ruby/issues/16)) ([57ecc5b](https://github.com/Gusto/apollo-federation-ruby/commit/57ecc5b)), closes [#14](https://github.com/Gusto/apollo-federation-ruby/issues/14)

## [0.3.2](https://github.com/Gusto/apollo-federation-ruby/compare/v0.3.1...v0.3.2) (2019-09-03)


### Bug Fixes

* run bundle-install before semantic-release ([2f60912](https://github.com/Gusto/apollo-federation-ruby/commit/2f60912))

## [0.3.1](https://github.com/Gusto/apollo-federation-ruby/compare/v0.3.0...v0.3.1) (2019-09-03)


### Bug Fixes

* push up lockfile changes ([4aaa827](https://github.com/Gusto/apollo-federation-ruby/commit/4aaa827))

# [0.3.0](https://github.com/Gusto/apollo-federation-ruby/compare/v0.2.0...v0.3.0) (2019-09-03)


### Bug Fixes

* checkout before running semantic-release ([cb67533](https://github.com/Gusto/apollo-federation-ruby/commit/cb67533))
* install before running semantic-release ([0ebb5b5](https://github.com/Gusto/apollo-federation-ruby/commit/0ebb5b5))


### Features

* switch from Travis to CircleCI ([#18](https://github.com/Gusto/apollo-federation-ruby/issues/18)) ([3af14b3](https://github.com/Gusto/apollo-federation-ruby/commit/3af14b3))

## [0.2.0](https://github.com/Gusto/apollo-federation-ruby/compare/v0.1.0...v0.2.0) (2019-08-01)


### Features

* Add a description to the `_Service` type ([b7f19b9](https://github.com/Gusto/apollo-federation-ruby/commit/b7f19b99c385e94d29bed8dd34cc06383ce01ea2))

### Bug Fixes

* Fix an issue coercing the `_Any` scalar in a Rails app ([39e9213](https://github.com/Gusto/apollo-federation-ruby/commit/39e9213d90bb18c7f218085e1dcaed8f2b6fa835))

## 0.1.0 (2019-06-21)


* First release
