# InteractiveBrokers2TastyWorks

This library converts the output of an Interactive Brokers Execution Flex Query to a TastyWorks-compatible CSV file.

### Flex Query Parameters in Interactive Brokers

- Leave all defaults
- Set time period to LAST 365 DAYS (or whatever you want, really)
- In Sections, select Trades
    + Select Executions
    + Select All

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'interactive_brokers_2_tasty_works'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install interactive_brokers_2_tasty_works

## Usage

`InteractiveBrokers2TastyWorks.new(input_path: '~/trades.xml').save_as("/tmp/trades.csv")`

### Adding additional fields to the output (non standard output format)

```
InteractiveBrokers2TastyWorks.new(input_path: '~/trades.xml', add_output: ['ibExecID', 'ibOrderID'])

# or to specify a different header for the additional fields

InteractiveBrokers2TastyWorks.new(input_path: '~/trades.xml', add_output: { ibExecID: 'IB Execution ID', ibOrderID: 'IB Order ID' })
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/cmer/interactive_brokers_2_tasty_works. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the InteractiveBrokers2TastyWorks project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/cmer/interactive_brokers_2_tasty_works/blob/master/CODE_OF_CONDUCT.md).
