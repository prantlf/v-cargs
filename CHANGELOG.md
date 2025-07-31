# Changes

## [0.7.4](https://github.com/prantlf/v-cargs/compare/v0.7.3...v0.7.4) (2025-07-31)

### Bug Fixes

* Work around compiler bug with optional fields ([7e8b4bf](https://github.com/prantlf/v-cargs/commit/7e8b4bf53860638388c8c89baf9ae316f10d9254))

## [0.7.3](https://github.com/prantlf/v-cargs/compare/v0.7.2...v0.7.3) (2024-11-16)

### Bug Fixes

* Fix sources for the new V compiler ([0033546](https://github.com/prantlf/v-cargs/commit/003354680ebca5d4a52fb725a0bfeb2cc1ae93bd))

## [0.7.2](https://github.com/prantlf/v-cargs/compare/v0.7.1...v0.7.2) (2024-01-28)

### Bug Fixes

* Fix sources for the new V compiler ([793e304](https://github.com/prantlf/v-cargs/commit/793e304581a78013dd00138138ac5f93a7a98a93))

## [0.7.1](https://github.com/prantlf/v-cargs/compare/v0.7.0...v0.7.1) (2023-12-11)

### Bug Fixes

* Adapt for V langage changes ([201efd6](https://github.com/prantlf/v-cargs/commit/201efd6317ce97ffd49d0d038020882deacf6924))

## [0.7.0](https://github.com/prantlf/v-cargs/compare/v0.6.0...v0.7.0) (2023-10-15)

### Features

* Support getting boolean arguments - flags - from scanned usage ([e61087f](https://github.com/prantlf/v-cargs/commit/e61087fd0e766a31e27973575f3e716d18df4e4e))

### BREAKING CHANGES

* The `input` argument was removed from the `get_val` function. It was unused.

## [0.6.0](https://github.com/prantlf/v-cargs/compare/v0.5.1...v0.6.0) (2023-10-15)

### Features

* Allow disabling negative options by no_negative_options ([a53f710](https://github.com/prantlf/v-cargs/commit/a53f710c25230cf6644edeb1a36f6699ee07e1ac))

## [0.5.1](https://github.com/prantlf/v-cargs/compare/v0.5.0...v0.5.1) (2023-09-10)

### Performance Improvements

* Create the regex for an option only once ([6282a5f](https://github.com/prantlf/v-cargs/commit/6282a5f782882950a156d9f87bfc7489e5b90d20))

## [0.5.0](https://github.com/prantlf/v-cargs/compare/v0.4.0...v0.5.0) (2023-09-10)

### Features

* Allow scanning usage description before parsing arguments ([14ff0db](https://github.com/prantlf/v-cargs/commit/14ff0dbdec261d604efa92c76d596506c3128b03))

## [0.4.0](https://github.com/prantlf/v-cargs/compare/v0.3.0...v0.4.0) (2023-08-18)

### Features

* Add options_anywhere not to require the Options: line ([38fc333](https://github.com/prantlf/v-cargs/commit/38fc333ee56f30035ba28640e7424a90cc0b3cac))

## [0.3.0](https://github.com/prantlf/v-cargs/compare/v0.2.0...v0.3.0) (2023-08-17)

### Features

* Allow specifing --no-* options in the usage ([029920d](https://github.com/prantlf/v-cargs/commit/029920d4ffde41d2ec3b814743bc1c446cee5279))

## [0.2.0](https://github.com/prantlf/v-cargs/compare/v0.1.0...v0.2.0) (2023-08-16)

### Features

* Swap regex with prantlf.pcre ([8e74fac](https://github.com/prantlf/v-cargs/commit/8e74fac503a45b64f4102b4941295f567431b2bb))

## [0.1.0](https://github.com/prantlf/v-cargs/compare/v0.0.6...v0.1.0) (2023-08-07)

### Features

* Add parse_to to fill an existing struct ([3b395b2](https://github.com/prantlf/v-cargs/commit/3b395b270c8918b36c258883fd95e531efa87707))

## [0.0.6](https://github.com/prantlf/v-cargs/compare/v0.0.5...v0.0.6) (2023-07-09)

### Bug Fixes

* Accept brackets to enclose parameters names too ([3af198b](https://github.com/prantlf/v-cargs/commit/3af198b0f13a7bf5a3c3735f3d461df00362759c))

## [0.0.5](https://github.com/prantlf/v-cargs/compare/v0.0.4...v0.0.5) (2023-06-18)

### Features

* Support multiple values for a single option as arrays ([e6ef54a](https://github.com/prantlf/v-cargs/commit/e6ef54aed475d7bf4511b32e84c468e58aa412f5))

## [0.0.4](https://github.com/prantlf/v-cargs/compare/v0.0.3...v0.0.4) (2023-06-18)

### Features

* Recognise attributes arg, nooverflow and required ([dbf1711](https://github.com/prantlf/v-cargs/commit/dbf1711025a52bf520e13144658779d08307632f))

## [0.0.3](https://github.com/prantlf/v-cargs/compare/v0.0.2...v0.0.3) (2023-06-12)

### Bug Fixes

* Fix checks for float overflow ([c5e95c8](https://github.com/prantlf/v-cargs/commit/c5e95c8949e0a789d2088ff192436ae6240d1ad9))

## [0.0.2](https://github.com/prantlf/v-cargs/compare/v0.0.1...v0.0.2) (2023-06-11)

### Features

* Allow condensing multiple flags to one argument ([9a6cb41](https://github.com/prantlf/v-cargs/commit/9a6cb41f6faef02db3bd7323040e6a48e56bc707))

## 0.0.1 (2023-06-11)

Initial release.
