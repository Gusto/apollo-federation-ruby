## [3.8.1](https://github.com/Gusto/apollo-federation-ruby/compare/v3.8.0...v3.8.1) (2023-06-20)

# [3.8.0](https://github.com/Gusto/apollo-federation-ruby/compare/v3.7.1...v3.8.0) (2023-06-02)


### Features

* optionally underscore _Any keys ([#248](https://github.com/Gusto/apollo-federation-ruby/issues/248)) ([f1688e7](https://github.com/Gusto/apollo-federation-ruby/commit/f1688e793ba08195a06ddad74d84f2858dcdfcdf))

## [3.7.1](https://github.com/Gusto/apollo-federation-ruby/compare/v3.7.0...v3.7.1) (2023-06-01)


### Bug Fixes

* handle lazy `resolve_references` return values ([#250](https://github.com/Gusto/apollo-federation-ruby/issues/250)) ([e29b155](https://github.com/Gusto/apollo-federation-ruby/commit/e29b15550d48093c6ed5b73dabb8206a3e9463b0))
* handle lazy `resolve_references` return values ([#250](https://github.com/Gusto/apollo-federation-ruby/issues/250)) ([1614440](https://github.com/Gusto/apollo-federation-ruby/commit/16144402d32de3d5016023b87fc2b949364761f5))
* handle lazy resolve_references return values ([#250](https://github.com/Gusto/apollo-federation-ruby/issues/250)) ([fa72465](https://github.com/Gusto/apollo-federation-ruby/commit/fa72465bd5f1d38f3556b748b905f16f932829ac))

# [3.7.0](https://github.com/Gusto/apollo-federation-ruby/compare/v3.6.9...v3.7.0) (2023-05-26)


### Features

* support [@key](https://github.com/key) directive resolvable argument ([#249](https://github.com/Gusto/apollo-federation-ruby/issues/249)) ([6df7030](https://github.com/Gusto/apollo-federation-ruby/commit/6df70305d3e6035946c9ac35d74387014b08b28a))

## [3.6.9](https://github.com/Gusto/apollo-federation-ruby/compare/v3.6.8...v3.6.9) (2023-05-23)


### Bug Fixes

* visibility checks should handle duplicate types and fields ([#245](https://github.com/Gusto/apollo-federation-ruby/issues/245)) ([6401feb](https://github.com/Gusto/apollo-federation-ruby/commit/6401febe65743eb1fae970b3cf865b7007fb27cf))

## [3.6.8](https://github.com/Gusto/apollo-federation-ruby/compare/v3.6.7...v3.6.8) (2023-05-22)


### Bug Fixes

* include inherited types in generated _Entity union ([#247](https://github.com/Gusto/apollo-federation-ruby/issues/247)) ([c377785](https://github.com/Gusto/apollo-federation-ruby/commit/c377785466736114d17beda8b6e27c2e0a56eb75))

## [3.6.7](https://github.com/Gusto/apollo-federation-ruby/compare/v3.6.6...v3.6.7) (2023-05-18)


### Bug Fixes

* call `resolve_references` once per `__typename` ([#244](https://github.com/Gusto/apollo-federation-ruby/issues/244)) ([c21715d](https://github.com/Gusto/apollo-federation-ruby/commit/c21715d28b67764a078b4daefdfe490f50171817))

## [3.6.6](https://github.com/Gusto/apollo-federation-ruby/compare/v3.6.5...v3.6.6) (2023-04-26)


### Bug Fixes

* ApolloFederation::Tracing.should_add_traces() looks for correct headers ([#240](https://github.com/Gusto/apollo-federation-ruby/issues/240)) ([d609977](https://github.com/Gusto/apollo-federation-ruby/commit/d609977869721c168b33e50e3823cd97a7f81ae5))

## [3.6.5](https://github.com/Gusto/apollo-federation-ruby/compare/v3.6.4...v3.6.5) (2023-04-25)


### Bug Fixes

* **tracer:** add support for multiplex ([#243](https://github.com/Gusto/apollo-federation-ruby/issues/243)) ([c4f2eae](https://github.com/Gusto/apollo-federation-ruby/commit/c4f2eaed0b283c188f2fb932d5308dd3240bb2ec))

## [3.6.4](https://github.com/Gusto/apollo-federation-ruby/compare/v3.6.3...v3.6.4) (2023-04-19)


### Bug Fixes

* inherit Query type from schema superclass ([#241](https://github.com/Gusto/apollo-federation-ruby/issues/241)) ([0efb37e](https://github.com/Gusto/apollo-federation-ruby/commit/0efb37e2c2b14fc7ed99c695f35ed48d363d7695))

## [3.6.3](https://github.com/Gusto/apollo-federation-ruby/compare/v3.6.2...v3.6.3) (2023-04-12)


### Bug Fixes

* ensure correct ordering of `resolve_references` ([#239](https://github.com/Gusto/apollo-federation-ruby/issues/239)) ([f9948a7](https://github.com/Gusto/apollo-federation-ruby/commit/f9948a76c3e55e40cf2ae5e2bb8ca5575ca1a6a9))

## [3.6.2](https://github.com/Gusto/apollo-federation-ruby/compare/v3.6.1...v3.6.2) (2023-03-27)

## [3.6.1](https://github.com/Gusto/apollo-federation-ruby/compare/v3.6.0...v3.6.1) (2023-03-24)


### Bug Fixes

* run w/ multiple ruby versions in CI to ensure compatibility ([#232](https://github.com/Gusto/apollo-federation-ruby/issues/232)) ([978c941](https://github.com/Gusto/apollo-federation-ruby/commit/978c941a12b34a9f86b0eb179d82fdd3e70eaa3b))

## [3.6.1](https://github.com/Gusto/apollo-federation-ruby/compare/v3.6.0...v3.6.1) (2023-03-24)


### Bug Fixes

* run w/ multiple ruby versions in CI to ensure compatibility ([#232](https://github.com/Gusto/apollo-federation-ruby/issues/232)) ([978c941](https://github.com/Gusto/apollo-federation-ruby/commit/978c941a12b34a9f86b0eb179d82fdd3e70eaa3b))

# [3.6.0](https://github.com/Gusto/apollo-federation-ruby/compare/v3.5.3...v3.6.0) (2023-03-17)


### Features

* attempt to fix missing CHANGELOG entries ([07170d3](https://github.com/Gusto/apollo-federation-ruby/commit/07170d39738bec59952b0b952431ee2aecbf8f89))

## [3.5.3](https://github.com/Gusto/apollo-federation-ruby/compare/v3.5.2...v3.5.3) (2023-03-17)


### Features

* Support @inaccessible on remaining types ([#230](https://github.com/Gusto/apollo-federation-ruby/pull/230)) ([b62e6d9](https://github.com/Gusto/apollo-federation-ruby/commit/b62e6d9fc5ad0acae00746a80a622ac22dfa0c1f))

### Bug Fixes

* Inherit federation directives ([#94](https://github.com/Gusto/apollo-federation-ruby/issues/94)) ([822f92b](https://github.com/Gusto/apollo-federation-ruby/commit/822f92b229f3437c474721082033b74c8cc63553))

## [3.5.2](https://github.com/Gusto/apollo-federation-ruby/compare/v3.5.1...v3.5.2) (2023-03-08)


### Reverts

* Revert "chore: use Github App for authentication (#216)" (#227) ([f503704](https://github.com/Gusto/apollo-federation-ruby/commit/f5037047da67d809c3ffcbcc20318cd3996fb2e1)), closes [#216](https://github.com/Gusto/apollo-federation-ruby/issues/216) [#227](https://github.com/Gusto/apollo-federation-ruby/issues/227)

## [3.5.1](https://github.com/Gusto/apollo-federation-ruby/compare/v3.5.0...v3.5.1) (2023-03-08)


### Bug Fixes

* semantic PR title workflow ([#225](https://github.com/Gusto/apollo-federation-ruby/issues/225)) ([ee6041f](https://github.com/Gusto/apollo-federation-ruby/commit/ee6041f169b5f21427b704f4c71ee6dd0ea5c8b2))

# [3.5.0](https://github.com/Gusto/apollo-federation-ruby/compare/v3.4.1...v3.5.0) (2023-03-08)


### Features

* add tag directive from federation v2 ([#210](https://github.com/Gusto/apollo-federation-ruby/issues/210)) ([8c6e112](https://github.com/Gusto/apollo-federation-ruby/commit/8c6e11251b7bc7d6888a7a2b6e0feeea70171cb0))

## [3.4.1](https://github.com/Gusto/apollo-federation-ruby/compare/v3.4.0...v3.4.1) (2023-02-21)


### Bug Fixes

* import [@inaccessible](https://github.com/inaccessible) directive in Fed v2.3 ([#220](https://github.com/Gusto/apollo-federation-ruby/issues/220)) ([5d4d86e](https://github.com/Gusto/apollo-federation-ruby/commit/5d4d86e8155efe83470c58012454c79c910219ff))

# [3.4.0](https://github.com/Gusto/apollo-federation-ruby/compare/v3.3.1...v3.4.0) (2023-02-21)


### Bug Fixes

* address some lint violations ([#219](https://github.com/Gusto/apollo-federation-ruby/issues/219)) ([dcd11e9](https://github.com/Gusto/apollo-federation-ruby/commit/dcd11e9384f168d125d2b60941d4bff161799824))


### Features

* add support for the [@interface](https://github.com/interface)Object directive ([#218](https://github.com/Gusto/apollo-federation-ruby/issues/218)) ([c7b987d](https://github.com/Gusto/apollo-federation-ruby/commit/c7b987de1d2b32a4a77ceb09718373ffa5a60abb))

## [3.3.1](https://github.com/Gusto/apollo-federation-ruby/compare/v3.3.0...v3.3.1) (2023-01-05)


### Bug Fixes

* address SNYK-RUBY-GOOGLEPROTOBUF-3167775 ([#212](https://github.com/Gusto/apollo-federation-ruby/issues/212)) ([c36b51e](https://github.com/Gusto/apollo-federation-ruby/commit/c36b51e521a60e8186100405cf81bba1a37f5978))

# [3.3.0](https://github.com/Gusto/apollo-federation-ruby/compare/v3.2.0...v3.3.0) (2022-08-24)


### Features

* introduce optional `resolve_references` method ([#206](https://github.com/Gusto/apollo-federation-ruby/issues/206)) ([1e3b631](https://github.com/Gusto/apollo-federation-ruby/commit/1e3b631609e1dfec8c3f126cd9dc8e0a2b3a0a57))

# [3.2.0](https://github.com/Gusto/apollo-federation-ruby/compare/v3.1.0...v3.2.0) (2022-08-15)


### Features

* allow custom namespace for linked directives ([03fdfea](https://github.com/Gusto/apollo-federation-ruby/commit/03fdfeafaaea3c98ca4b7a734ce760ea08410530))

# [3.1.0](https://github.com/Gusto/apollo-federation-ruby/compare/v3.0.0...v3.1.0) (2022-06-21)


### Features

* Support Federation v2 ([#196](https://github.com/Gusto/apollo-federation-ruby/issues/196)) ([238736c](https://github.com/Gusto/apollo-federation-ruby/commit/238736cdb6f12121ce2a295c7a28fba3990012b9)), closes [/www.apollographql.com/docs/federation/federation-2/moving-to-federation-2/#opt-in-to-federation-2](https://github.com//www.apollographql.com/docs/federation/federation-2/moving-to-federation-2//issues/opt-in-to-federation-2)

# [3.0.0](https://github.com/Gusto/apollo-federation-ruby/compare/v2.2.4...v3.0.0) (2022-04-05)


### Bug Fixes

* camelize string fields to match sym behavior ([8f0382b](https://github.com/Gusto/apollo-federation-ruby/commit/8f0382b346d2cde5be252138275d67373b36acd7))


### BREAKING CHANGES

* string fields will be camelized by default rather than passed as is.

## [2.2.4](https://github.com/Gusto/apollo-federation-ruby/compare/v2.2.3...v2.2.4) (2022-04-01)


### Bug Fixes

* add linux and darwin platforms to lockfile ([#188](https://github.com/Gusto/apollo-federation-ruby/issues/188)) ([fbbb856](https://github.com/Gusto/apollo-federation-ruby/commit/fbbb856b315400f21c189c26488efbf030792ae1))
* bump circleci cache version ([#189](https://github.com/Gusto/apollo-federation-ruby/issues/189)) ([1b6c9d8](https://github.com/Gusto/apollo-federation-ruby/commit/1b6c9d8fc647c19a7eb4c95ab76b276aae9131c5))
* set env variables for release step ([#191](https://github.com/Gusto/apollo-federation-ruby/issues/191)) ([db0d1e6](https://github.com/Gusto/apollo-federation-ruby/commit/db0d1e688b93bfa2114eb91248d2f507a50fca8a))

## [2.2.3](https://github.com/Gusto/apollo-federation-ruby/compare/v2.2.2...v2.2.3) (2022-03-22)


### Bug Fixes

* **deps:** Bump minimist ([#186](https://github.com/Gusto/apollo-federation-ruby/issues/186)) ([a79cfe5](https://github.com/Gusto/apollo-federation-ruby/commit/a79cfe5ebf0a555b01446ed24abb53b11923a9b7))

## [2.2.2](https://github.com/Gusto/apollo-federation-ruby/compare/v2.2.1...v2.2.2) (2022-03-15)


### Bug Fixes

* add a ruby version file ([#185](https://github.com/Gusto/apollo-federation-ruby/issues/185)) ([b46346b](https://github.com/Gusto/apollo-federation-ruby/commit/b46346bbbccc51d77e67ce43f411a6ee72f1a1d5))

## [2.2.1](https://github.com/Gusto/apollo-federation-ruby/compare/v2.2.0...v2.2.1) (2022-03-08)


### Bug Fixes

* Remove to_graphql and make the interpreter runtime a requirement for older GraphQL versions ([#177](https://github.com/Gusto/apollo-federation-ruby/issues/177)) ([bfc3082](https://github.com/Gusto/apollo-federation-ruby/commit/bfc308260c34eee04c3b7a5f0e8a0bffe1cb88c4))

# [2.2.0](https://github.com/Gusto/apollo-federation-ruby/compare/v2.1.0...v2.2.0) (2022-02-04)


### Features

* Get Apollo Federation to work with GraphQL 1.13.x ([#160](https://github.com/Gusto/apollo-federation-ruby/issues/160)) ([800001b](https://github.com/Gusto/apollo-federation-ruby/commit/800001baa5a54ab377998c651e7049da254c451b)), closes [#147](https://github.com/Gusto/apollo-federation-ruby/issues/147)

# [2.1.0](https://github.com/Gusto/apollo-federation-ruby/compare/v2.0.3...v2.1.0) (2022-02-02)


### Features

* snake case field references ([f5506ae](https://github.com/Gusto/apollo-federation-ruby/commit/f5506aecd10ea0c4a72744be07e0a9ad5cd45b16))

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
