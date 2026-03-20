fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

### set_price

```sh
[bundle exec] fastlane set_price
```

Set app price to free

----


## iOS

### ios setup

```sh
[bundle exec] fastlane ios setup
```

Install dependencies and setup project

### ios test

```sh
[bundle exec] fastlane ios test
```

Run all tests

### ios unit_tests

```sh
[bundle exec] fastlane ios unit_tests
```

Run unit tests only

### ios ui_tests

```sh
[bundle exec] fastlane ios ui_tests
```

Run UI tests only

### ios build_dev

```sh
[bundle exec] fastlane ios build_dev
```

Build the app for development

### ios build_release

```sh
[bundle exec] fastlane ios build_release
```

Build the app for release

### ios certificates

```sh
[bundle exec] fastlane ios certificates
```

Sync certificates and provisioning profiles using match

### ios certificates_dev

```sh
[bundle exec] fastlane ios certificates_dev
```

Sync development certificates

### ios register_devices

```sh
[bundle exec] fastlane ios register_devices
```

Register new devices and update provisioning profiles

### ios beta

```sh
[bundle exec] fastlane ios beta
```

Push a new beta build to TestFlight

### ios upload

```sh
[bundle exec] fastlane ios upload
```

Quick TestFlight upload (uses automatic signing, no git checks)

### ios create_app

```sh
[bundle exec] fastlane ios create_app
```

Create app in App Store Connect

### ios release

```sh
[bundle exec] fastlane ios release
```

Deploy a new version to the App Store

### ios screenshots

```sh
[bundle exec] fastlane ios screenshots
```

Capture screenshots for App Store

### ios upload_screenshots

```sh
[bundle exec] fastlane ios upload_screenshots
```

Upload screenshots to App Store Connect

### ios upload_metadata_with_key

```sh
[bundle exec] fastlane ios upload_metadata_with_key
```

Upload metadata and privacy nutrition labels

### ios bump_version

```sh
[bundle exec] fastlane ios bump_version
```

Increment version number

### ios clean

```sh
[bundle exec] fastlane ios clean
```

Clean build artifacts

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
