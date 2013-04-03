module IMAPGuard
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

    def subject string
      self << 'SUBJECT' << string
    end

    def from string
      self << 'FROM' << string
    end

    def to string
      self << 'TO' << string
    end

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

