module IMAPGuard
  class Query
    SEEN = 'SEEN'
    UNANSWERED = 'UNANSWERED'
    UNFLAGGED = 'UNFLAGGED'
    SUBJECT = "SUBJECT \"%s\""
    FROM = "FROM \"%s\""
    BEFORE = "BEFORE %s"

    attr_reader :criteria

    def initialize
      @criteria = []
      seen.unanswered.unflagged
    end

    def to_s
      @criteria.join ' '
    end

    def seen
      @criteria << SEEN
      self
    end

    def unanswered
      @criteria << UNANSWERED
      self
    end

    def unflagged
      @criteria << UNFLAGGED
      self
    end

    def subject string
      @criteria << SUBJECT % string
      self
    end

    def from string
      @criteria << FROM % string
      self
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

      @criteria << BEFORE % date
      self
    end
  end
end

