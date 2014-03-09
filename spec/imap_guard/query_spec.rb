require 'spec_helper'

module ImapGuard
  describe Query do
    describe "#initialize" do
      it { should be_empty }
    end

    describe "#seen" do
      it "adds 'SEEN'" do
        subject.seen
        subject.last.should eq 'SEEN'
      end
    end

    describe "#unseen" do
      it "adds 'UNSEEN'" do
        subject.unseen
        subject.last.should eq 'UNSEEN'
      end
    end

    describe "#unanswered" do
      it "adds 'UNANSWERED'" do
        subject.unanswered
        subject.last.should eq 'UNANSWERED'
      end
    end

    describe "#unflagged" do
      it "adds 'UNFLAGGED'" do
        subject.unflagged
        subject.last.should eq 'UNFLAGGED'
      end
    end

    describe "#deleted" do
      it "adds 'DELETED'" do
        subject.deleted
        subject.last.should eq 'DELETED'
      end
    end

    describe "#or" do
      context "without a search key" do
        it "adds 'OR'" do
          subject.or
          subject.last.should eq 'OR'
        end
      end

      context "with search keys" do
        it "adds 'OR UNANSWERED UNFLAGGED '" do
          subject.or(:unanswered, :unflagged)
          subject.last(3).should eq ["OR", "UNANSWERED", "UNFLAGGED"]
        end
      end

      context "with only one non-nil search key" do
        it "raises ArgumentError" do
          expect {
            subject.or(:whatever)
          }.to raise_error(ArgumentError)

          expect {
            subject.or(nil, :whatever)
          }.to raise_error(ArgumentError)
        end
      end
    end

    describe "#subject" do
      it "adds the search value" do
        subject.subject("Hey you")
        subject.last.should eq "Hey you"
      end
    end

    describe "#from" do
      it "adds the search value" do
        subject.from("root@example.net")
        subject.last.should eq "root@example.net"
      end
    end

    describe "#to" do
      it "adds the search value" do
        subject.to("root@example.net")
        subject.last.should eq "root@example.net"
      end
    end

    describe "#not" do
      context "without a search key" do
        it "adds 'NOT'" do
          subject.not.deleted
          subject.last(2).should eq ["NOT", "DELETED"]
        end
      end

      context "with a search key" do
        it "adds 'NOT DELETED'" do
          subject.not(:deleted)
          subject.last(2).should eq ["NOT", "DELETED"]
        end
      end
    end

    describe "#before" do
      context "when I pass 'nil' as an argument" do
        it "raises" do
          expect {
            subject.before(nil)
          }.to raise_error ArgumentError
        end
      end

      context "when I pass '1' as an argument" do
        it "returns yesterday" do
          subject.before(1)
          Date.parse(subject.last).should eq Date.today.prev_day
        end
      end

      context "when I pass an integer" do
        it "uses it as a negative offset in days" do
          subject.before(3)
          (Date.today - Date.parse(subject.last)).should eq 3
        end
      end

      context "when I pass '18-Mar-2013' as an argument" do
        it "uses it as is" do
          subject.before('18-Mar-2013')
          subject.last.should eq '18-Mar-2013'
        end
      end

      context "when I pass an instance of Date as an argument" do
        it "extracts the date" do
          subject.before(Date.today)
          Date.parse(subject.last).should eq Date.today
        end
      end
    end
  end
end

