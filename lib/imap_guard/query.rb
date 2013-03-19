module IMAPGuard
  class Query
    def initialize
      @criteria = []
      seen.unanswered.unflagged
    end

    def to_s
      @criteria.join ' '
    end

    def seen
      @criteria << 'SEEN'
      self
    end

    def unanswered
      @criteria << 'UNANSWERED'
      self
    end

    def unflagged
      @criteria << 'UNFLAGGED'
      self
    end

    def subject string
      @criteria << "SUBJECT \"#{string}\""
      self
    end

    def from string
      @criteria << "FROM \"#{string}\""
      self
    end

    def before date
      case date
      when Fixnum
        date = (Date.today - date).strftime '%e-%b-%Y'
      when Date
        date = Date.strptime date, '%e-%b-%Y'
      end

      @criteria << "BEFORE #{date}"
      self
    end
  end
end

