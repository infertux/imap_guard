# ImapGuard

A guard for your IMAP mailboxes.

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
guard.select 'INBOX.ops' # select the mailbox
```

IMAP search query syntax can be a bit tricky.
`IMAPGuard::Query` can help you to build queries with a simple Ruby DSL:

```ruby
query = IMAPGuard::Query.new.before(7).subject("abc").from("root")
p query #=> SEEN UNANSWERED UNFLAGGED BEFORE 12-Mar-2013 SUBJECT "abc" FROM "root"
guard.delete query # will delete every emails which match this query
```

Unfortunately, IMAP search queries are limited too.
For instance, the pattern passed to `subject` and `from` is a mere string.
IMAP doesn't allow advanced filtering such as regexp matching.

To do so, you can pass an optional block to `delete`.
The yielded object is a [Mail](https://github.com/mikel/mail) instance of the current mail providing many methods.
However, wrapping the mail into a nice `Mail` object is slow and you should avoid to use it if you can.

```ruby
query = IMAPGuard::Query.new.before(7).subject("Logwatch for ")
guard.delete query do |mail|
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

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
