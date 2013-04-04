require 'net/imap'
require 'ostruct'
require 'mail'
require 'colored'

module IMAPGuard
  # Guard allows you to process your mailboxes.
  class Guard
    # @return [OpenStruct] IMAPGuard settings
    attr_reader :settings

    # @return [String] Currently selected mailbox
    attr_reader :mailbox

    def initialize settings
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
    # @see {settings.read_only}
    # @return [void]
    def select mailbox
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
    def move query, mailbox, &filter
      operation = lambda { |message_id|
        unless @settings.read_only
          @imap.copy(message_id, mailbox)
          @imap.store(message_id, "+FLAGS", [Net::IMAP::DELETED])
        end

        "moved to #{mailbox}".cyan
      }
      process query, operation, &filter
    end

    # Deletes messages matching the query and filter block
    # @param query IMAP query
    # @param filter Optional filter block
    # @return [void]
    def delete query, &filter
      operation = lambda { |message_id|
        unless @settings.read_only
          @imap.store(message_id, "+FLAGS", [Net::IMAP::DELETED])
        end

        'deleted'.red
      }
      process query, operation, &filter
    end

    # @return [Array] Sorted list of all mailboxes
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

    def process query, operation
      message_ids = search query
      count = message_ids.size

      message_ids.each_with_index do |message_id, index|
        print "Processing UID #{message_id} (#{index.succ}/#{count}): "

        result = true
        if block_given?
          mail = fetch_mail message_id
          result = yield(mail)
          verbose.print "(given filter result: #{result.inspect}) "
        end

        if result
          puts operation.call(message_id)
        else
          puts "ignored".yellow
        end
      end

    ensure
      expunge
    end

    def fetch_mail message_id
      msg = @imap.fetch(message_id, 'RFC822')[0].attr['RFC822']
      Mail.read_from_string msg
    end

    def search query
      unless [Array, String].any? { |type| query.is_a? type }
        raise TypeError, "query must be either a string holding the entire search string, or a single-dimension array of search keywords and arguments"
      end

      messages = @imap.search query
      puts "Query on #{mailbox}: #{query.inspect}: #{messages.count} results".cyan

      messages
    end

    def verbose
      @verbose ||= if @settings.verbose
        $stdout
      else
        # anonymous null object
        Class.new do
          def method_missing(*)
            nil
          end
        end.new
      end
    end

    def settings= settings
      required = %w(host port username password).map!(&:to_sym)
      missing = required - settings.keys
      raise ArgumentError, "Missing settings: #{missing}" unless missing.empty?

      optional = %w(read_only verbose).map!(&:to_sym)
      unknown = settings.keys - required - optional
      raise ArgumentError, "Unknown settings: #{unknown}" unless unknown.empty?

      @settings = OpenStruct.new(settings).freeze
      puts "DRY-RUN MODE ENABLED".yellow.bold.reversed if @settings.read_only
    end
  end
end

