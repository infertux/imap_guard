# frozen_string_literal: true

require "net/imap"
require "ostruct"
require "mail"
require "term/ansicolor"

String.include Term::ANSIColor
Term::ANSIColor.coloring = STDOUT.isatty

module ImapGuard
  # Guard allows you to process your mailboxes.
  class Guard
    # List of required settings
    REQUIRED_SETTINGS = %i[host port username password].freeze

    # List of optional settings
    OPTIONAL_SETTINGS = %i[read_only verbose].freeze

    # @return [Proc, nil] Matched emails are passed to this debug lambda if present
    attr_accessor :debug

    # @note The settings are frozen
    # @return [OpenStruct] ImapGuard settings
    attr_reader :settings

    # @return [String, nil] Currently selected mailbox
    attr_reader :mailbox

    def initialize(settings)
      self.settings = settings
    end

    # Authenticates to the given IMAP server
    # @see http://www.ruby-doc.org/stdlib-1.9.3/libdoc/net/imap/rdoc/Net/IMAP.html#method-c-new
    # @return [void]
    def login
      @imap = Net::IMAP.new(@settings.host, @settings.port, true, nil, false)
      @imap.login(@settings.username, @settings.password)
      verbose.puts "Logged in successfully"
    end

    # Selects a mailbox (folder)
    # @return [void]
    def select(mailbox)
      if @settings.read_only
        @imap.examine(mailbox) # open in read-only
      else
        @imap.select(mailbox) # open in read-write
      end
      @mailbox = mailbox
    end

    # Moves messages matching the query and filter block
    # @param query IMAP query
    # @param mailbox Destination mailbox
    # @param filter Optional filter block
    # @return [void]
    def move(query, mailbox, &filter)
      operation = lambda do |message_id|
        unless @settings.read_only
          @imap.copy(message_id, mailbox)
          @imap.store(message_id, "+FLAGS", [Net::IMAP::DELETED])
        end

        "moved to #{mailbox}".yellow
      end
      process query, operation, &filter
    end

    # Deletes messages matching the query and filter block
    # @param query IMAP query
    # @param filter Optional filter block
    # @return [void]
    def delete(query, &filter)
      operation = lambda do |message_id|
        @imap.store(message_id, "+FLAGS", [Net::IMAP::DELETED]) unless @settings.read_only

        "deleted".red
      end
      process query, operation, &filter
    end

    # Runs operation on messages matching the query
    # @param query IMAP query
    # @param opration Lambda to call on each message
    # @return [void]
    def each(query)
      operation = ->(message_id) { yield message_id }
      process query, operation
    end

    # Fetches a message from its UID
    # @return [Mail]
    # @note We use "BODY.PEEK[]" to avoid setting the \Seen flag.
    def fetch_mail(message_id)
      msg = @imap.fetch(message_id, "BODY.PEEK[]").first.attr["BODY[]"]
      Mail.read_from_string msg
    end

    # @return [Array<String>] Sorted list of all mailboxes
    def list
      @imap.list("", "*").map(&:name).sort
    end

    # Sends a EXPUNGE command to permanently remove from the currently selected
    # mailbox all messages that have the Deleted flag set.
    # @return [void]
    def expunge
      @imap.expunge unless @settings.read_only
    end

    # Sends a CLOSE command to close the currently selected mailbox. The CLOSE
    # command permanently removes from the mailbox all messages that have the
    # Deleted flag set.
    # @return [void]
    def close
      @imap.close unless @settings.read_only
    end

    # Disconnects from the server.
    # @return [void]
    def disconnect
      @imap.disconnect
    end

  private

    def process(query, operation)
      message_ids = search query
      count = message_ids.size

      message_ids.each_with_index do |message_id, index|
        print "Processing UID #{message_id} (#{index.succ}/#{count}): "

        result = true
        if block_given? || debug
          mail = fetch_mail message_id

          debug.call(mail) if debug

          if block_given?
            result = yield(mail)
            verbose.print "(given filter result: #{result.inspect}) "
          end
        end

        puts result ? operation.call(message_id) : "ignored".green
      end
    ensure
      expunge
    end

    def search(query)
      raise TypeError, "Query must be either a string holding the entire search string, or a single-dimension array of search keywords and arguments." unless [Array, String].any? { |type| query.is_a? type }

      messages = @imap.search query
      puts "Query on #{mailbox}: #{query.inspect}: #{messages.count} results".cyan

      messages
    end

    def verbose
      @verbose ||= if @settings.verbose
                     $stdout
                   else
                     # anonymous null object
                     # rubocop:disable all
                     Class.new do def method_missing(*); nil end end.new
                     # rubocop:enable all
                   end
    end

    def settings=(settings)
      missing = REQUIRED_SETTINGS - settings.keys
      raise ArgumentError, "Missing settings: #{missing}" unless missing.empty?

      unknown = settings.keys - REQUIRED_SETTINGS - OPTIONAL_SETTINGS
      raise ArgumentError, "Unknown settings: #{unknown}" unless unknown.empty?

      @settings = OpenStruct.new(settings).freeze
      puts "DRY-RUN MODE ENABLED".yellow.bold.negative if @settings.read_only
    end
  end
end
