# frozen_string_literal: true

module ImapGuard
  describe Query do
    describe "#initialize" do
      it { should be_empty }
    end

    describe "#seen" do
      it "adds 'SEEN'" do
        subject.seen
        expect(subject.last).to eq "SEEN"
      end
    end

    describe "#unseen" do
      it "adds 'UNSEEN'" do
        subject.unseen
        expect(subject.last).to eq "UNSEEN"
      end
    end

    describe "#unanswered" do
      it "adds 'UNANSWERED'" do
        subject.unanswered
        expect(subject.last).to eq "UNANSWERED"
      end
    end

    describe "#unflagged" do
      it "adds 'UNFLAGGED'" do
        subject.unflagged
        expect(subject.last).to eq "UNFLAGGED"
      end
    end

    describe "#deleted" do
      it "adds 'DELETED'" do
        subject.deleted
        expect(subject.last).to eq "DELETED"
      end
    end

    describe "#or" do
      context "without a search key" do
        it "adds 'OR'" do
          subject.or
          expect(subject.last).to eq "OR"
        end
      end

      context "with search keys" do
        it "adds 'OR UNANSWERED UNFLAGGED '" do
          subject.or(:unanswered, :unflagged)
          expect(subject.last(3)).to eq %w[OR UNANSWERED UNFLAGGED]
        end
      end

      context "with only one non-nil search key" do
        it "raises ArgumentError" do
          expect do
            subject.or(:whatever)
          end.to raise_error(ArgumentError)

          expect do
            subject.or(nil, :whatever)
          end.to raise_error(ArgumentError)
        end
      end
    end

    describe "#subject" do
      it "adds the search value" do
        subject.subject("Hey you")
        expect(subject.last).to eq "Hey you"
      end
    end

    describe "#from" do
      it "adds the search value" do
        subject.from("root@example.net")
        expect(subject.last).to eq "root@example.net"
      end
    end

    describe "#to" do
      it "adds the search value" do
        subject.to("root@example.net")
        expect(subject.last).to eq "root@example.net"
      end
    end

    describe "#cc" do
      it "adds the search value" do
        subject.cc("root@example.net")
        expect(subject.last).to eq "root@example.net"
      end
    end

    describe "#not" do
      context "without a search key" do
        it "adds 'NOT'" do
          subject.not.deleted
          expect(subject.last(2)).to eq %w[NOT DELETED]
        end
      end

      context "with a search key" do
        it "adds 'NOT DELETED'" do
          subject.not(:deleted)
          expect(subject.last(2)).to eq %w[NOT DELETED]
        end
      end
    end

    describe "#before" do
      context "when I pass 'nil' as an argument" do
        it "raises" do
          expect do
            subject.before(nil)
          end.to raise_error ArgumentError
        end
      end

      context "when I pass '1' as an argument" do
        it "returns yesterday" do
          subject.before(1)
          expect(Date.parse(subject.last)).to eq Date.today.prev_day
        end
      end

      context "when I pass an integer" do
        it "uses it as a negative offset in days" do
          subject.before(3)
          expect((Date.today - Date.parse(subject.last))).to eq 3
        end
      end

      context "when I pass '18-Mar-2013' as an argument" do
        it "uses it as is" do
          subject.before("18-Mar-2013")
          expect(subject.last).to eq "18-Mar-2013"
        end
      end

      context "when I pass an instance of Date as an argument" do
        it "extracts the date" do
          subject.before(Date.today)
          expect(Date.parse(subject.last)).to eq Date.today
        end
      end
    end
  end
end
