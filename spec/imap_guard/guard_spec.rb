require 'spec_helper'

module IMAPGuard
  describe Guard do
    before do
      $stdout = StringIO.new # mute stdout - comment to debug
    end

    let(:settings) do
      {
        host: 'localhost',
        port: 993,
        username: 'bob',
        password: 'PASS',
      }
    end

    let(:imap) {
      double('Net::IMAP', search: [7, 28], expunge: nil, select: nil)
    }

    def guard_instance custom_settings = {}
      guard = Guard.new(settings.merge(custom_settings))
      guard.instance_variable_set(:@imap, imap)
      guard.stub(:fetch_mail)
      guard
    end

    describe "#select" do
      context "with settings.read_only = true" do
        let(:guard) { guard_instance(read_only: true) }

        it "opens the mailbox in read-only" do
          imap.should_receive(:examine)
          guard.select nil
        end
      end

      context "with settings.read_only = false" do
        let(:guard) { guard_instance(read_only: false) }

        it "opens the mailbox in read-write" do
          imap.should_receive(:select)
          guard.select nil
        end
      end
    end

    describe "#mailbox" do
      it "returns nil when no mailbox has been selected" do
        guard_instance.mailbox.should be_nil
      end

      it "returns the currently selected mailbox" do
        guard = guard_instance

        guard.select 'Sent'
        guard.mailbox.should eq 'Sent'
      end
    end

    describe "#search" do
      before do
        imap.should_receive(:search) do |arg|
          [13, 37] if [['ALL'], 'ALL'].include? arg
        end
      end

      it "accepts arrays" do
        expect {
          guard_instance.send(:search, ['ALL'])
        }.to_not raise_error
      end

      it "accepts strings" do
        expect {
          guard_instance.send(:search, 'ALL')
        }.to_not raise_error
      end

      it "returns results" do
        messages = guard_instance.send(:search, 'ALL')
        messages.should eq [13, 37]
      end
    end

    describe "#process" do
      let(:guard) { guard_instance(verbose: true) }
      let(:opeartion) { ->(id) {} }

      context "without a filter block" do
        it "does perform the operation" do
          opeartion.should_receive(:call).with(7)
          opeartion.should_receive(:call).with(28)

          guard.send(:process, 'ALL', opeartion)
        end

        it "does not execute the filter block" do
          guard.should_not_receive(:fetch_mail)

          guard.send(:process, 'ALL', opeartion)
        end
      end

      context "with a filter block" do
        it "executes the filter block" do
          guard.should_receive(:fetch_mail).twice

          guard.send(:process, 'ALL', opeartion) { }
        end

        context "returning false" do
          it "does not perform the operation" do
            opeartion.should_not_receive(:call)

            guard.send(:process, 'ALL', opeartion) { false }
          end
        end

        context "returning true" do
          it "does perform the operation" do
            opeartion.should_receive(:call).twice

            guard.send(:process, 'ALL', opeartion) { true }
          end
        end
      end
    end

    describe "#move" do
      it "copies emails before adding the :Deleted flag" do
        imap.should_receive(:search)
        imap.should_receive(:copy).with(7, 'destination').ordered
        imap.should_receive(:store).with(7, '+FLAGS', [:Deleted]).ordered
        imap.should_receive(:copy).with(28, 'destination').ordered
        imap.should_receive(:store).with(28, '+FLAGS', [:Deleted]).ordered

        guard_instance.move 'ALL', 'destination'
      end
    end

    describe "#delete" do
      it "adds the :Deleted flag" do
        imap.should_receive(:search)
        imap.should_receive(:store).with(7, '+FLAGS', [:Deleted])
        imap.should_receive(:store).with(28, '+FLAGS', [:Deleted])

        guard_instance.delete 'ALL'
      end
    end

    describe "#expunge" do
      it "expunges the folder" do
        imap.should_receive(:expunge)
        guard_instance.expunge
      end
    end

    describe "#close" do
      it "closes the IMAP connection" do
        imap.should_receive(:close)
        guard_instance.close
      end
    end

    describe "#disconnect" do
      it "disconnects from the server" do
        imap.should_receive(:disconnect)
        guard_instance.disconnect
      end
    end

    describe "#verbose" do
      context "with settings.verbose = true" do
        let(:guard) { guard_instance(verbose: true) }

        it "does output to $stdout" do
          $stdout.should_receive(:write).with("ham")
          guard.send(:verbose).print "ham"
        end
      end

      context "with settings.verbose = false" do
        let(:guard) { guard_instance(verbose: false) }

        it "does not output to $stdout" do
          $stdout.should_not_receive(:write)
          guard.send(:verbose).print "ham"
        end
      end
    end

    describe "#settings=" do
      it "freezes the settings" do
        guard = Guard.new(settings)

        expect {
          guard.settings.host = 'example.net'
        }.to raise_error(TypeError, /frozen/)
      end

      it "raises ArgumentError if any required key is missing" do
        expect {
          Guard.new({})
        }.to raise_error ArgumentError, /missing/i
      end

      it "raises ArgumentError if any key is unknown" do
        expect {
          Guard.new(settings.merge(coffee: true))
        }.to raise_error ArgumentError, /unknown/i
      end
    end
  end
end

