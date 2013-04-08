module ImapGuard
  # Query is a neat DSL to help you generate IMAP search queries.
  # @note All methods return self so they can be chained.
  class Query < Array
    # Messages that have the +\Seen+ flag set.
    # @return [self]
    def seen
      self << 'SEEN'
    end

    # Messages that do not have the +\Answered+ flag set.
    # @return [self]
    def unanswered
      self << 'UNANSWERED'
    end

    # Messages that do not have the +\Flagged+ flag set.
    # @return [self]
    def unflagged
      self << 'UNFLAGGED'
    end

    # Messages with the +\Deleted+ flag set.
    # @return [self]
    def deleted
      self << 'DELETED'
    end

    # Messages that match either search key.
    # @param search_key1 Optional search key to pass to +OR+
    # @param search_key2 Optional search key to pass to +OR+
    # @note Reverse polish notation is expected,
    #   i.e. OR <search-key1> <search-key2>
    # @example
    #   or.unanswered.unflagged     #=> ["OR", "UNANSWERED", "UNFLAGGED"]
    #   or(:unanswered, :unflagged) #=> ["OR", "UNANSWERED", "UNFLAGGED"]
    # @return [self]
    def or search_key1 = nil, search_key2 = nil
      self << 'OR'

      if search_key1 and search_key2
        send(search_key1)
        send(search_key2)
      elsif search_key1 or search_key2
        raise ArgumentError, "You must give either zero or two arguments."
      end

      self
    end

    # Messages that do not match the specified search key.
    # @param search_key Optional search key to pass to +NOT+
    # @example
    #   not.deleted   #=> ["NOT", "DELETED"]
    #   not(:deleted) #=> ["NOT", "DELETED"]
    # @return [self]
    def not search_key = nil
      self << 'NOT'
      send(search_key) if search_key
      self
    end

    # Messages that contain the specified string in the envelope
    # structure's SUBJECT field.
    # @return [self]
    def subject string
      self << 'SUBJECT' << string
    end

    # Messages that contain the specified string in the envelope
    # structure's FROM field.
    # @return [self]
    def from string
      self << 'FROM' << string
    end

    # Messages that contain the specified string in the envelope
    # structure's TO field.
    # @return [self]
    def to string
      self << 'TO' << string
    end

    # Messages whose internal date (disregarding time and timezone)
    # is earlier than the specified date.
    # @param date Depending of its type:
    #   - [String]: uses it as is
    #   - [Fixnum]: _n_ days before today
    #   - [Date]: uses this date
    # @return [self]
    def before date
      case date
      when String
        # noop, uses it as is
      when Fixnum
        date = (Date.today - date).strftime '%e-%b-%Y'
      when Date
        date = date.strftime '%e-%b-%Y'
      else
        raise ArgumentError, "#{date.inspect} is invalid."
      end

      self << 'BEFORE' << date
    end
  end
end

