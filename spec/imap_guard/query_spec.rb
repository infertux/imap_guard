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

    describe "#or" do
      it "adds 'OR'" do
        subject.or
        subject.last.should eq 'OR'
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

