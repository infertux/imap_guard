#!/usr/bin/env ruby

# frozen_string_literal: true
# rubocop:disable all

require "imap_guard"

SETTINGS = {
  host: "imap.googlemail.com",
  port: 993,
  username: "you@gmail.com",
  password: "your_pass",
}.freeze

settings = SETTINGS.merge(read_only: false)
base_query = ImapGuard::Query.new.unflagged.unanswered.freeze
guard = ImapGuard::Guard.new settings
# guard.debug = ->(mail) { print "#{mail.subject}: " }
guard.login

guard.select "INBOX"

# Github
%w(github.com notifications@travis-ci.org app@gemnasium.com).map do |from|
  base_query.dup.from(from)
end.each do |query|
  guard.move query, "INBOX.Github"
end

# To Do
guard.move base_query.dup.from("me").to("me"), "INBOX.TODO"

# Ops
guard.select "INBOX.Ops"
query = base_query.dup.seen
guard.delete query.dup.subject("monit alert -- ").before(7)
guard.delete query.dup.subject("CRON-APT completed on ").before(3)
guard.delete query.dup.subject("Logwatch for ").before(7)
guard.select "INBOX"

# Uni
guard.move base_query.dup.or.from("uni.tld").to("uni.tld"), "INBOX.Uni"

# Bye!
guard.disconnect
