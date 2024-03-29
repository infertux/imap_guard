# frozen_string_literal: true

module ImapGuard
  describe Guard do
    before do
      $stdout = StringIO.new # mute stdout - comment to debug
    end

    after do
      $stdout = STDOUT
    end

    let(:settings) do
      {
        host: "localhost",
        port: 993,
        username: "bob",
        password: "PASS",
      }
    end

    let(:imap) do
      instance_double(Net::IMAP, search: [7, 28], expunge: nil, select: nil, list: [])
    end

    def guard_instance(custom_settings = {})
      guard = Guard.new(settings.merge(custom_settings))
      guard.instance_variable_set(:@imap, imap)
      allow(guard).to receive(:fetch_mail)
      guard
    end

    describe "#select" do
      context "with settings.read_only = true" do
        let(:guard) { guard_instance(read_only: true) }

        it "opens the mailbox in read-only" do
          expect(imap).to receive(:examine)
          guard.select nil
        end
      end

      context "with settings.read_only = false" do
        let(:guard) { guard_instance(read_only: false) }

        it "opens the mailbox in read-write" do
          expect(imap).to receive(:select)
          guard.select nil
        end
      end
    end

    describe "#mailbox" do
      it "returns nil when no mailbox has been selected" do
        expect(guard_instance.mailbox).to be_nil
      end

      it "returns the currently selected mailbox" do
        guard = guard_instance

        guard.select "Sent"
        expect(guard.mailbox).to eq "Sent"
      end
    end

    describe "#list" do
      it "returns the list of mailboxes" do
        expect(imap).to receive(:list)
        expect(guard_instance.list).to eq []
      end
    end

    describe "#search" do
      before do
        expect(imap).to receive(:search) do |arg|
          [13, 37] if [["ALL"], "ALL"].include? arg
        end
      end

      it "accepts arrays" do
        expect do
          guard_instance.send(:search, ["ALL"])
        end.not_to raise_error
      end

      it "accepts strings" do
        expect do
          guard_instance.send(:search, "ALL")
        end.not_to raise_error
      end

      it "returns results" do
        messages = guard_instance.send(:search, "ALL")
        expect(messages).to eq [13, 37]
      end
    end

    describe "#process" do
      let(:guard) { guard_instance(verbose: true) }
      let(:opeartion) { ->(id) {} }

      context "without a filter block" do
        it "does perform the operation" do
          expect(opeartion).to receive(:call).with(7)
          expect(opeartion).to receive(:call).with(28)

          guard.send(:process, "ALL", opeartion)
        end

        it "does not execute the filter block" do
          expect(guard).not_to receive(:fetch_mail)

          guard.send(:process, "ALL", opeartion)
        end

        context "with a debug proc" do
          it "calls the proc" do
            block = ->(mail) {}
            guard.debug = block
            expect(block).to receive(:call).twice

            guard.send(:process, "ALL", opeartion)
          end
        end
      end

      context "with a filter block" do
        it "executes the filter block" do
          expect(guard).to receive(:fetch_mail).twice

          guard.send(:process, "ALL", opeartion) { nil }
        end

        context "when returning false" do
          it "does not perform the operation" do
            expect(opeartion).not_to receive(:call)

            guard.send(:process, "ALL", opeartion) { false }
          end
        end

        context "when returning true" do
          it "does perform the operation" do
            expect(opeartion).to receive(:call).twice

            guard.send(:process, "ALL", opeartion) { true }
          end
        end
      end
    end

    describe "#move" do
      it "copies emails before adding the :Deleted flag" do
        expect(imap).to receive(:search)
        expect(imap).to receive(:copy).with(7, "destination").ordered
        expect(imap).to receive(:store).with(7, "+FLAGS", [:Deleted]).ordered
        expect(imap).to receive(:copy).with(28, "destination").ordered
        expect(imap).to receive(:store).with(28, "+FLAGS", [:Deleted]).ordered

        guard_instance.move "ALL", "destination"
      end
    end

    describe "#delete" do
      it "adds the :Deleted flag" do
        expect(imap).to receive(:search)
        expect(imap).to receive(:store).with(7, "+FLAGS", [:Deleted])
        expect(imap).to receive(:store).with(28, "+FLAGS", [:Deleted])

        guard_instance.delete "ALL"
      end
    end

    describe "#each" do
      it "iterates over messages without errors" do
        expect do
          guard_instance.each "ALL" do |message_id|
            # noop
          end
        end.not_to raise_error
      end
    end

    describe "#expunge" do
      it "expunges the folder" do
        expect(imap).to receive(:expunge)
        guard_instance.expunge
      end
    end

    describe "#close" do
      it "closes the IMAP connection" do
        expect(imap).to receive(:close)
        guard_instance.close
      end
    end

    describe "#disconnect" do
      it "disconnects from the server" do
        expect(imap).to receive(:disconnect)
        guard_instance.disconnect
      end
    end

    describe "#verbose" do
      context "with settings.verbose = true" do
        let(:guard) { guard_instance(verbose: true) }

        it "does output to $stdout" do
          expect($stdout).to receive(:write).with("ham")
          guard.send(:verbose).print "ham"
        end
      end

      context "with settings.verbose = false" do
        let(:guard) { guard_instance(verbose: false) }

        it "does not output to $stdout" do
          expect($stdout).not_to receive(:write)
          guard.send(:verbose).print "ham"
        end
      end
    end

    describe "#settings=" do
      it "freezes the settings" do
        guard = described_class.new(settings)

        expect do
          guard.settings.host = "example.net"
        end.to raise_error RuntimeError, /frozen/
      end

      it "raises ArgumentError if any required key is missing" do
        expect do
          described_class.new({})
        end.to raise_error ArgumentError, /missing/i
      end

      it "raises ArgumentError if any key is unknown" do
        expect do
          described_class.new(settings.merge(coffee: true))
        end.to raise_error ArgumentError, /unknown/i
      end
    end
  end
end
