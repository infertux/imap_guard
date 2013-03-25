require 'net/imap'
require 'ostruct'
require 'mail'
require 'colored'

module IMAPGuard
  class Guard
    attr_reader :settings

    def initialize settings
      self.settings = settings
    end

    # @see http://www.ruby-doc.org/stdlib-1.9.3/libdoc/net/imap/rdoc/Net/IMAP.html#method-c-new
    def login
      @imap = Net::IMAP.new(@settings.host, @settings.port, true, nil, false)
      @imap.login(@settings.username, @settings.password)
      verbose.puts "Logged in successfully"
    end

    def select mailbox
      if @settings.read_only
        @imap.examine(mailbox) # open in read-only
      else
        @imap.select(mailbox) # open in read-write
      end
    end

    # @param mailbox Destination mailbox
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

    def delete query, &filter
      operation = lambda { |message_id|
        unless @settings.read_only
          @imap.store(message_id, "+FLAGS", [Net::IMAP::DELETED])
        end

        'deleted'.red
      }
      process query, operation, &filter
    end

    def expunge
      @imap.expunge unless @settings.read_only
    end

    def close
      puts "Expunging deleted messages and closing mailbox..."
      @imap.close
    end

  private

    def process query, operation
      message_ids = search query
      count = message_ids.size

      message_ids.each_with_index do |message_id, index|
        print "Processing UID #{message_id} (#{index + 1}/#{count}): "

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
        raise ArgumentError, "query must be either a string holding the entire search string, or a single-dimension array of search keywords and arguments"
      end

      messages = @imap.search query
      puts "Query: #{query.inspect}: #{messages.count} results".cyan

      messages
    end

    def verbose
      @verbose ||= if @settings.verbose
        $stdout
      else
        # anonymous null object
        Class.new do
          def method_missing(*args, &block)
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

