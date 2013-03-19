# ImapGuard

TODO: Write a gem description

## Installation

Add this line to your application's Gemfile:

    gem 'imap_guard'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install imap_guard

## Usage

TODO: Write usage instructions here


```ruby
require 'imap_guard'
load File.expand_path('../settings.rb', __FILE__)
settings = SETTINGS.merge({ read_only: true })

s = IMAPGuard::Guard.new settings
s.select 'INBOX.ops'

query = IMAPGuard::Query.new.before(7).subject("abc").from("root")
s.delete query

pattern = "monit alert -- Resource limit "
query = IMAPGuard::Query.new.subject(pattern).before(7)
s.delete query do |mail|
  # the pattern given to subject() is a mere string
  # pass an optional block to perform advanced filtering such as regexp matching
  # the yielded mail object is an instance of the current mail providing many methods
  mail.subject.start_with? pattern
end

query = IMAPGuard::Query.new.before(7).subject("Logwatch for ")
s.delete query do |mail|
  mail.subject =~ /\ALogwatch for \w \(Linux\)\Z/
end

# You can also forge your own raw IMAP search queries like this
query = 'SEEN SUBJECT "ALERT" FROM "root"'
s.delete query do |mail|
  mail.subject == "ALERT" and \
  mail.body == "ALERT"
end

s.close
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
