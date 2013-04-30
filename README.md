# Porpoise

A client library for the Purpose Platform

[![Build Status](https://travis-ci.org/PurposeOpen/Porpoise.png?branch=master)](https://travis-ci.org/PurposeOpen/Porpoise)

### Creating a new movement

1. Create a new rails application for the movement using:
   
   ~~~~~~~~~
   $ rails new movement_name --skip-active-record --builder='<path-to-porpoise-movement-builder>' --movement_password='movement-password'
   ~~~~~~~~~~
   * for _path-to-porpoise-movement-builder_, specify the path to movement_builder.rb file (found in lib/porpoise directory) or the github raw url of the file.
   * _skip-active-record_ option is used as we dont require database for this project.
   * _builder_ adds the porpoise library to the rails project and also creates the required configuration files.
   * Movement specific constants ( _movement_name_, _movement_id_, _movement_password_ ) have to be passed as options.

2. Create your movement in the Platform admin (with the same name you used above)
3. Start the rails server:

   `$ cd movement_name; source .env; rails s`

 The new movement now runs at rails default port 3000. (http://localhost:3000)

### Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

### [Wiki](https://github.com/PurposeOpen/Porpoise/wiki)

### [LICENSE](https://github.com/PurposeOpen/Porpoise/wiki/LICENSE)
