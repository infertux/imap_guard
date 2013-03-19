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
    end

    def select mailbox
      if @settings.read_only
        @imap.examine(mailbox) # open in read-only
      else
        @imap.select(mailbox) # open in read-write
      end
    end

    def delete query
      unless query.is_a? String
        if query.respond_to? :to_s
          query = query.to_s
        else
          raise ArgumentError, "query must provide #to_s"
        end
      end

      messages = @imap.search query
      count = messages.size
      puts "Query: #{query.inspect}: #{count} results"

      counter = 0
      messages.each do |message_id|
        counter += 1
        # puts message_id
        mail = nil
        if block_given?
          msg = @imap.fetch(message_id, 'RFC822')[0].attr['RFC822']
          mail = Mail.read_from_string msg
          result = yield mail
          if result
            # puts "Given filter matched"
          else
            # puts "Given filter returned falsy"
            next
          end
        end

        print "Deleting UID #{message_id} (#{counter}/#{count})"
        print " (DRY-RUN)" if @settings.read_only
        if mail
          puts ": #{mail.subject} (#{mail.body.to_s.length})"
        else
          puts
        end
        @imap.store(message_id, "+FLAGS", [:Deleted])
      end
    end

    def close
      puts "Expunging deleted messages and closing mailbox..."
      # p imap.expunge
      @imap.close
    end
  end
end

