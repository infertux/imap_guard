require 'spec_helper'

module IMAPGuard
  describe Query do
    def last_criterion
      subject.criteria.last
    end

    describe "#initialize" do
      let(:query) { Query.new.to_s }
      subject { query }

      it { should include Query::SEEN }
      it { should include Query::UNANSWERED }
      it { should include Query::UNFLAGGED }
    end

    describe "#subject" do
      it "adds the criterion" do
        subject.subject("Hey you")
        last_criterion.should eq Query::SUBJECT % "Hey you"
      end
    end

    describe "#from" do
      it "adds the criterion" do
        subject.from("root@example.net")
        last_criterion.should eq Query::FROM % "root@example.net"
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
          date = last_criterion.split.last
          Date.parse(date).should eq Date.today.prev_day
        end
      end

      context "when I pass an integer" do
        it "uses it as a negative offset in days" do
          subject.before(3)
          date = last_criterion.split.last
          (Date.today - Date.parse(date)).should eq 3
        end
      end

      context "when I pass '18-Mar-2013' as an argument" do
        it "uses it as is" do
          subject.before('18-Mar-2013')
          last_criterion.should eq Query::BEFORE % '18-Mar-2013'
        end
      end

      context "when I pass an instance of Date as an argument" do
        it "extracts the date" do
          subject.before(Date.today)
          date = last_criterion.split.last
          Date.parse(date).should eq Date.today
        end
      end
    end

  end
end

