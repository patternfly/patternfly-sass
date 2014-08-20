# Developer Set-Up
For more specific instructions on Fedora, see
[Fedora Specific Set-Up](#fedora-setup).

1. Install nodejs and npm.
1. Install grunt.
1. Install bower.

   ```sh
   $ sudo npm install -g bower
   ```

1. Install required node components.

   ```sh
   $ npm install
   ```

1. Install Ruby and Bundler.  I also recommend installing your distribution's
   ruby-devel package so that Bundler can install gems with native extensions.

1. Install required gems.

   ```sh
   $ bundle install
   ```

<a name="fedora-setup"></a>
## Fedora Specific Set-Up
These steps are current as of Fedora 20.

For the NodeJs dependencies:
 
```sh
$ sudo yum install -y nodejs-grunt-cli npm
```

For the Ruby dependencies:

```sh
$ sudo yum install -y rubygem-bundler ruby-devel
```
