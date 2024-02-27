# Uuidable

[![Build](https://github.com/flant/uuidable/actions/workflows/ruby.yml/badge.svg)](https://github.com/flant/uuidable/actions/workflows/ruby.yml) [![Gem Version](https://badge.fury.io/rb/uuidable.svg)](https://badge.fury.io/rb/uuidable)

With this gem you can use UUID instead of id in routes. But id is still primary key.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'uuidable'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install uuidable

## Usage

Simply add `uuidable` in your ActiveRecord model:

```ruby
class Project < ActiveRecord::Base
    uuidable

    # Rest of the code
end
```

You can use special methods in migrations:
```ruby
class CreateProjects < ActiveRecord::Migration
    def change
        create_table :projects do |t|
            t.uuid
            #...
        end
        # Or
        add_uuid_column :projects
    end
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/flant/uuidable.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
