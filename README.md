# ImapGuard [![Build Status](https://secure.travis-ci.org/infertux/imap_guard.png?branch=master)](https://travis-ci.org/infertux/imap_guard) [![Dependency Status](https://gemnasium.com/infertux/imap_guard.png)](https://gemnasium.com/infertux/imap_guard) [![Code Climate](https://codeclimate.com/github/infertux/imap_guard.png)](https://codeclimate.com/github/infertux/imap_guard)

A guard for your IMAP mailboxes.

ImapGuard connects to your IMAP server and processes your emails.
You can finely pick them thanks to advanced search queries and Ruby blocks.
Then you can `move` or `delete` them in batch.

Of course, there is a _dry-run_ mode (i.e. read-only) available to double check what it would do.

It can be used by a disposable script to clean things up or with a cron job to keep them tidy.

## Installation

    $ gem install imap_guard

## Usage

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

guard = IMAPGuard::Guard.new SETTINGS
guard.login # authenticate the user
guard.select 'INBOX.ops' # select the mailbox
```

IMAP search query syntax can be a bit tricky.
`IMAPGuard::Query` can help you to build queries with a simple Ruby DSL:

```ruby
base_query = IMAPGuard::Query.new.unflagged.unanswered.seen.freeze
query = base_query.dup.before(7).subject("abc").from("root")
p query #=> ["UNFLAGGED", "UNANSWERED", "SEEN", "BEFORE", "13-Mar-2013", "SUBJECT", "abc", "FROM", "root"]
guard.delete query # will delete every emails which match this query
```

Unfortunately, IMAP search queries are limited too.
For instance, the pattern passed to `subject` and `from` is a mere string.
IMAP doesn't allow advanced filtering such as regexp matching.

To do so, you can pass an optional block to `delete`.
The yielded object is a [Mail](https://github.com/mikel/mail) instance of the current mail providing many methods.
However, wrapping the mail into a nice `Mail` object is slow and you should avoid to use it if you can.

```ruby
guard.delete base_query.dup.before(7).subject("Logwatch for ") do |mail|
  mail.subject =~ /\ALogwatch for \w \(Linux\)\Z/ and \
  mail.multipart? and \
  mail.parts.length == 2
end
```

Finally, you can always forge your own raw IMAP search queries (the [RFC](http://tools.ietf.org/html/rfc3501#section-6.4.4) can help in that case):

```ruby
query = 'SEEN SUBJECT "ALERT" FROM "root"'
guard.delete query do |mail|
  mail.body == "ALERT"
end
```

Be aware that emails won't be touched until you `expunge` or `close` the mailbox:

```ruby
guard.expunge # effectively delete emails marked as deleted
guard.close # expunge then close the connection
```

Oh, and there is a `move` method as well:

```ruby
guard.move query, 'destination_folder' do |mail|
  # and it can take a filter block like `delete`
end
```

## Contributing

Bug reports and patches are most welcome.

## License

MIT

