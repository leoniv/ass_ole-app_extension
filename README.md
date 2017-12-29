# AssOle::AppExtension

Gem for working with 1C:Enterprise `ConfigurationExtension`. Provides features
for hot plug a `ConfigurationExtension` to 1C:Enterprise application
instance (aka infobase) and some more.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'ass_ole-app_extension'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install ass_ole-app_extension

## Usage

1. Describe your extension

```ruby
require 'ass_ole/app_extension'

class FooExtension < AssOle::AppExtension::Abstract::Extension

  VERSION = '1.1.1'.freeze

  def path
    File.expand_path '../foo_extension.cfe', __FILE__
  end

  # Override abstract method
  # must returns WIN32OLE object(1C extension BinaryData)'
  def data
    newObject('BinaryData', real_win_path(path))
  end

  # Override abstract method
  # must returns `Gem::Requirement` 1C platform version requirement
  def platform_require
    Gem::Requirement.new '~> 8.3.10'
  end

  # Override abstract method
  # must returns `Hash` :1c_app_name => (Gem::Requirement|String '~> 1.2.4')
  # or nil for independent extension
  def app_requirements
    {Accounting: '~> 3.0.56',
     AccountingCorp: '~> 3.0.56'}
  end

  # Override abstract method
  # must returns extension name
  def name
    'FooExtension'
  end

  # Override abstract method
  # must returns extension version
  def name
    VERSION
  end
end
```

2. Plug extension

```ruby
require 'ass_maintainer/info_base'

# Describe 1C application instance
ib = AssMaintainer::InfoBase.new('app_name', 'File="path"')

extension = AssOle::AppExtension.plug(ib, FooExtension, 'safe profile name')

extension.plugged? # => true
```

3. Or explore infobase extensions with `AssOle::AppExtension::Spy`

```ruby
require 'ass_maintainer/info_base'

# Describe 1C application instance
ib = AssMaintainer::InfoBase.new('app_name', 'File="path"')

# Get all extensions and check all is plugged
AssOle::AppExtension::Spy.explore(ib).each do |spy|
  logger.error "#{spy.name} isn't plugged because:\n - "\
    "#{spy.apply_errors.map(&:Description).join(' - ')}"\
    unless spy.plugged?
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/ass_ole-app_extension.
