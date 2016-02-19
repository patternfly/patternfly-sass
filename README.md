#patternfly-sass

[![Gem Version](https://badge.fury.io/rb/patternfly-sass.svg)](http://badge.fury.io/rb/patternfly-sass)
[![Dependency Status](https://gemnasium.com/patternfly/patternfly-sass.svg)](https://gemnasium.com/patternfly/patternfly-sass)
[![Build Status](https://travis-ci.org/patternfly/patternfly-sass.svg)](https://travis-ci.org/patternfly/patternfly-sass)
[![Chat](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/patternfly/patternfly-sass?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

`patternfly-sass` is a Sass-powered version of [PatternFly](http://github.com/patternfly/patternfly), ready to drop right into your Sass powered applications.

## Installation

Please see the appropriate guide for your environment of choice:

* [Ruby on Rails](#a-ruby-on-rails).

### a. Ruby on Rails

`patternfly-sass` is easy to drop into Rails with the asset pipeline.

In your Gemfile you need to add the `patternfly-sass` gem, and ensure that the `sass-rails` gem is present - it is added to new Rails applications by default.

```ruby
gem 'patternfly-sass', '~> 3.0.0'
gem 'sass-rails', '>= 3.2'
```

`bundle install` and restart your server to make the files available through the pipeline.

Import Bootstrap styles in `app/assets/stylesheets/application.scss`:

```scss
// "patternfly-sprockets" must be imported before "patternfly" and "patternfly/variables"
@import "patternfly-sprockets";
@import "patternfly";
```

`patternfly-sprockets` must be imported before `patternfly` for the icon fonts to work.

Make sure the file has `.scss` extension (or `.sass` for Sass syntax). If you have just generated a new Rails app,
it may come with a `.css` file instead. If this file exists, it will be served instead of Sass, so rename it:

```console
$ mv app/assets/stylesheets/application.css app/assets/stylesheets/application.scss
```

Then, remove all the `//= require` and `//= require_tree` statements from the file. Instead, use `@import` to import Sass files.

Do not use `//= require` in Sass or your other stylesheets will not be [able to access][antirequire] the PatternFly mixins or variables.

Require PatternFly Javascripts in `app/assets/javascripts/application.js`:

```js
//= require jquery
//= require bootstrap
//= require patternfly
```

#### Rails 4.x

Please make sure `sprockets-rails` is at least v2.1.4.

#### Rails 3.2.x

patternfly-sass is no longer compatible with Rails 3.

### Configuration

#### Sass

By default all of PatternFly is imported.

You can also import components explicitly. To start with a full list of modules copy
[`_patternfly.scss`](assets/stylesheets/_patternfly.scss) file into your assets as `_patternfly-custom.scss`.
Then comment out components you do not want from `_patternfly-custom`.
In the application Sass file, replace `@import 'patternfly'` with:

```scss
@import 'patternfly-custom';
```

#### Sass: Number Precision

patternfly-sass [requires](https://github.com/twbs/bootstrap-sass/issues/409) minimum [Sass number precision][patternfly-precision] of 8 (default is 5).

Precision is set for Rails automatically.
When using ruby Sass compiler standalone you can set it with:

```ruby
::Sass::Script::Value::Number.precision = [8, ::Sass::Script::Value::Number.precision].max
```

#### Sass: Autoprefixer

PatternFly requires the use of [Autoprefixer][autoprefixer].
[Autoprefixer][autoprefixer] adds vendor prefixes to CSS rules using values from [Can I Use](http://caniuse.com/).

#### JavaScript

[`assets/javascripts/patternfly.js`](/assets/javascripts/patternfly.js) contains all of PatternFly JavaScript,
concatenated in the correct order.

#### Fonts

The fonts are referenced as:

```scss
"#{$icon-font-path}#{$icon-font-name}.eot"
```

`$icon-font-path` defaults to `patternfly/` if asset path helpers are used, and `../fonts/patternfly/` otherwise.

When using patternfly-sass with Sprockets, you **must** import the relevant path helpers before PatternFly itself, for example:

```scss
@import "patternfly-sprockets";
@import "patternfly";
```

## Usage

### Sass

Import PatternFly into a Sass file (for example, application.scss) to get all of PatternFly's styles, mixins and variables!

```scss
@import "patternfly";
```

The full list of patternfly variables can be found [here](/assets/stylesheets/patternfly/_variables.scss). You can override these by simply redefining the variable before the `@import` directive, e.g.:

```scss
$navbar-default-bg: #312312;
$light-orange: #ff8c00;
$navbar-default-color: $light-orange;

@import "patternfly";
```

## Version

PatternFly for Sass version may differ from the upstream version in the last number, known as
[MINOR](http://semver.org/spec/v2.0.0.html). The minor version may be ahead of the corresponding upstream minor.
This happens when we need to release Sass-specific changes.

Always refer to [CHANGELOG.md](/CHANGELOG.md) when upgrading.

---

## Development and Contributing

If you'd like to help with the development of patternfly-sass itself, read this section.

### Upstream Converter

Keeping patternfly-sass in sync with upstream changes from PatternFly used to be an error prone and time consuming manual process. With Bootstrap 3 we have introduced a converter that automates this.

**Note: if you're just looking to *use* PatternFly, see the [installation](#installation) section above.**

Upstream changes to the PatternFly project can now be pulled in using the `convert` rake task.

Here's an example run that would pull down the master branch from the main [patternfly/patternfly](https://github.com/patternfly/patternfly) repo:

    rake convert

This will convert the latest LESS to Sass and update to the latest JS.
To convert a specific branch or version, pass the branch name or the commit hash as the first task argument:

    rake convert[tags/v1.2.1]

The latest converter script is located [here][converter] and does the following:

* Converts upstream patternfly LESS files to its matching SCSS file.
* Copies all upstream JavaScript into `assets/javascripts/patternfly`, a Sprockets concatenation at `assets/javascripts/patternfly.js`.
* Copies all upstream font files into `assets/fonts/patternfly`.
* Sets `Patternfly::PATTERNFLY_SHA` in [version.rb][version] to the branch sha.

This converter fully converts original LESS to SCSS. Conversion is automatic but requires instructions for certain transformations (see converter output).
Please submit GitHub issues tagged with `conversion`.

## Credits

patternfly-sass's converter is a fork of [bootstrap-sass](https://github.com/twbs/bootstrap-sass). The modifications and all other code is made by:

<!-- feel free to make these link wherever you wish -->
* [Alex Wood](https://github.com/awood)
* [Dávid Halász](https://github.com/skateman)

[converter]: https://github.com/patternfly/patternfly-sass/blob/master/tasks/converter.rb
[version]: https://github.com/patternfly/patternfly-sass/blob/master/lib/patternfly-sass/version.rb
[contrib]: https://github.com/patternfly/patternfly-sass/graphs/contributors
[antirequire]: https://github.com/bootstrap/bootstrap-sass/issues/79#issuecomment-4428595
[autoprefixer]: https://github.com/ai/autoprefixer
