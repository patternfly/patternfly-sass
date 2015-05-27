#patternfly-sass

[![Gem Version](https://badge.fury.io/rb/patternfly-sass.svg)](http://badge.fury.io/rb/patternfly-sass)
[![Dependency Status](https://gemnasium.com/patternfly/patternfly-sass.svg)](https://gemnasium.com/patternfly/patternfly-sass)
[![Build Status](https://travis-ci.org/patternfly/patternfly-sass.svg)](https://travis-ci.org/patternfly/patternfly-sass)

## Developer Set-Up

1. Install bower and phantomjs
   ```sh
   $ npm install bower phantomjs
   ```
1. Install bundler
   ```sh
   $ gem install bundler
   ```

1. Install required gems.
   ```sh
   $ bundle install
   ```

## Running the conversion
   ```sh
   $ bundle exec rake convert
   $ bundle exec rake compile
   ```

## Running the tests
   ```sh
   $ bundle exec rake test
   ```
