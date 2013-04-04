module IMAPGuard
  # Query is a neat DSL to help you generate IMAP search queries.
  class Query < Array
    def seen
      self << 'SEEN'
    end

    def unanswered
      self << 'UNANSWERED'
    end

    def unflagged
      self << 'UNFLAGGED'
    end

    def or
      self << 'OR'
    end

    def subject string
      self << 'SUBJECT' << string
    end

    def from string
      self << 'FROM' << string
    end

    def to string
      self << 'TO' << string
    end

    # Adds a `BEFORE date` condition
    # @param date Depending of its type:
    #   - String: uses it as is
    #   - Fixnum: _n_ days before today
    #   - Date: uses this date
    # @return [Query] self
    def before date
      case date
      when String
        # noop, uses it as is
      when Fixnum
        date = (Date.today - date).strftime '%e-%b-%Y'
      when Date
        date = date.strftime '%e-%b-%Y'
      else
        raise ArgumentError, "#{date.inspect} is invalid"
      end

      self << 'BEFORE' << date
    end
  end
end

