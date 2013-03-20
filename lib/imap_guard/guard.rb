require 'net/imap'
require 'mail'
require 'ostruct'

module IMAPGuard
  class Guard
    def initialize settings
      @settings = OpenStruct.new(settings).freeze

      # http://www.ruby-doc.org/stdlib-1.9.3/libdoc/net/imap/rdoc/Net/IMAP.html#method-c-new
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

    def delete query
      unless [Array, String].any? { |type| query.is_a? type }
        raise ArgumentError, "query must be either a string holding the entire search string, or a single-dimension array of search keywords and arguments"
      end

      messages = @imap.search query
      count = messages.size
      puts "Query: #{query.inspect}: #{count} results"

      messages.each_with_index do |message_id, index|
        puts "Processing UID #{message_id} (#{index + 1}/#{count})"
        mail = nil
        if block_given?
          msg = @imap.fetch(message_id, 'RFC822')[0].attr['RFC822']
          mail = Mail.read_from_string msg
          next unless yield(mail)
        end

        verbose.print "Deleting UID #{message_id} (#{index + 1}/#{count})"
        verbose.print " (DRY-RUN)" if @settings.read_only
        if mail
          verbose.puts ": #{mail.subject.inspect}"
        else
          verbose.puts
        end
        @imap.store(message_id, "+FLAGS", [:Deleted])
      end
    end

    def expunge
      @imap.expunge
    end

    def close
      puts "Expunging deleted messages and closing mailbox..."
      @imap.close
    end

  private

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
  end
end

