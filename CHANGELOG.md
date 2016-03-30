#Change Log
This project adheres to [Semantic Versioning](http://semver.org/).

This CHANGELOG follows the format listed at [Keep A Changelog](http://keepachangelog.com/)

## [Unreleased][unreleased]

## [0.2.1] - 2015-01-10
### Added
- added support for nil es results

## [0.2.0] - 2015-12-18
### Added
- added support for avg aggregations

## [0.1.2] - 2015-08-11
### Added
- add parameters for elasticsearch auth

## [0.1.1] - 2015-07-14
### Changed
- updated sensu-plugin gem to 1.2.0

## [0.1.0] - 2015-07-06
### Added
- `check-es-node-status` node status check

### Fixed
- uri resource path for `get_es_resource` method

### Changed
- `get_es_resource` URI path needs to start with `/`
- clean cruft from Rakefile
- put deps in alpha order in gemspec
- update documentation links in README and CONTRIBUTING

## [0.0.2] - 2015-06-02
### Fixed
- added binstubs

### Changed
- removed cruft from /lib

## 0.0.1 - 2015-05-21
### Added
- initial release

[unreleased]: https://github.com/ministryofjustice/sensu-plugins-elasticsearch/compare/0.2.0...HEAD
[0.2.0]: https://github.com/ministryofjustice/sensu-plugins-elasticsearch/compare/0.1.4...0.2.0
[0.1.2]: https://github.com/ministryofjustice/sensu-plugins-elasticsearch/compare/0.1.1...0.1.2
[0.1.1]: https://github.com/ministryofjustice/sensu-plugins-elasticsearch/compare/0.1.0...0.1.1
[0.1.0]: https://github.com/ministryofjustice/sensu-plugins-elasticsearch/compare/0.0.2...0.1.0
[0.0.2]: https://github.com/ministryofjustice/sensu-plugins-elasticsearch/compare/0.0.1...0.0.2
