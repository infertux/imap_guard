# ImapGuard

[![Build Status](https://secure.travis-ci.org/infertux/imap_guard.png?branch=master)](https://travis-ci.org/infertux/imap_guard)
[![Code Climate](https://codeclimate.com/github/infertux/imap_guard.png)](https://codeclimate.com/github/infertux/imap_guard)
[![Gem Version](https://badge.fury.io/rb/imap_guard.svg)](https://badge.fury.io/rb/imap_guard)

**A guard for your IMAP mailboxes.**

ImapGuard connects to your IMAP server and processes your emails.
You can finely pick them thanks to advanced search queries and Ruby blocks.
Then you can `move` or `delete` them in batch.

Of course, there is a _dry-run_ mode (i.e. read-only) available to double check what it would do.

It can be used by a disposable script to clean things up or with a cron job to keep them tidy.

## Installation

    $ gem install imap_guard

## Usage

Read below for detailed explanations.
If you prefer a quick overview, you can take a look at [this example](https://github.com/infertux/imap_guard/blob/master/examples/example.rb).

Example initialization:

```ruby
require 'imap_guard'

SETTINGS = {
  host: 'mail.google.com',
  port: 993,
  username: 'login',
  password: 'pass',
  read_only: true # don't perform any modification aka dry-run mode
}

guard = ImapGuard::Guard.new SETTINGS
guard.login # authenticate the user
guard.select 'INBOX.ops' # select the mailbox
```

IMAP search query syntax can be a bit tricky.
`ImapGuard::Query` can help you to build queries with a simple Ruby DSL:

```ruby
base_query = ImapGuard::Query.new.unflagged.unanswered.seen.freeze
query = base_query.dup.before(7).subject("abc").from("root")
p query #=> ["UNFLAGGED", "UNANSWERED", "SEEN", "BEFORE", "13-Mar-2013", "SUBJECT", "abc", "FROM", "root"]
guard.delete query # will delete every emails which match this query
```

Unfortunately, IMAP search queries are limited too.
For instance, the pattern passed to `subject` and `from` is a mere string.
IMAP doesn't allow advanced filtering such as regexp matching.

To do so, you can pass an optional block to `delete`.
The yielded object is a [Mail] instance of the current mail providing many methods.
However, wrapping the mail into a nice `Mail` object is slow and you should avoid to use it if you can.

```ruby
guard.delete base_query.dup.before(7).subject("Logwatch for ") do |mail|
  mail.subject =~ /\ALogwatch for \w \(Linux\)\Z/ and \
  mail.multipart? and \
  mail.parts.length == 2
end
```

You can always forge your own raw IMAP search queries (the [RFC](http://tools.ietf.org/html/rfc3501#section-6.4.4) can help in that case):

```ruby
query = 'SEEN SUBJECT "ALERT" FROM "root"'
guard.delete query do |mail|
  mail.body == "ALERT"
end
```

There is a `move` method as well:

```ruby
guard.move query, 'destination_folder' do |mail|
  # and it can take a filter block like `delete`
end
```

Finally, this should be handled automatically but you can explicitly expunge pending emails and close the connection:

```ruby
guard.expunge # effectively delete emails marked as deleted
guard.close # expunge then close the connection
```

### Advanced features

#### Mailbox list

You can list all mailboxes:

```ruby
p guard.list
```

#### Selected mailbox

You can output the currently selected mailbox:

```ruby
p guard.mailbox # nil if none has been selected
```

#### Debug block

You can pass a block which will be yielded for each matched email:

```ruby
# Print out the subject for each email
guard.debug = ->(mail) { print "#{mail.subject}: " }
```

You can think of it as Ruby's [Object#tap](http://ruby-doc.org/core-2.0/Object.html#method-i-tap) method.
Note this is slow since it needs to fetch the whole email to return a [Mail] object.

## Contributing

Bug reports and patches are most welcome.

## License

MIT


[Mail]: https://github.com/mikel/mail
