require File.dirname(__FILE__) + '/../../spec_helper'
require 'database_cleaner/active_record/dirty_read_transaction'
require 'active_record'

module DatabaseCleaner
  module ActiveRecord

    describe DirtyReadTransaction do
      let (:connection) { double("connection") }
      before(:each) do
        ::ActiveRecord::Base.stub(:connection).and_return(connection)
      end

      describe "#start" do
        context "using begin_isolated_db_transaction" do
          before do
            connection.stub(:transaction)
            connection.stub(:begin_isolated_db_transaction).with(:read_uncommitted)
            connection.stub(:respond_to?).with(:begin_isolated_db_transaction).and_return(true)
          end

          it "should raise an exception if isolated transactions aren't supported" do
            connection.stub(:respond_to?).with(:begin_isolated_db_transaction).and_return(false)
            expect {DirtyReadTransaction.new.start}.to raise_error
          end

          it "should increment open transactions if possible" do
            connection.stub(:respond_to?).with(:increment_open_transactions).and_return(true)
            connection.should_receive(:increment_open_transactions)
            DirtyReadTransaction.new.start
          end

          it "should tell ActiveRecord to increment connection if its not possible to increment current connection" do
            connection.stub(:respond_to?).with(:increment_open_transactions).and_return(false)
            ::ActiveRecord::Base.should_receive(:increment_open_transactions)
            DirtyReadTransaction.new.start
          end

          it "should start a transaction with an appropriate isolation level" do
            connection.stub(:respond_to?).with(:increment_open_transactions).and_return(true)
            connection.stub(:increment_open_transactions)
            connection.should_receive(:begin_isolated_db_transaction).with(:read_uncommitted)
            connection.should_receive(:transaction)
            DirtyReadTransaction.new.start
          end
        end
      end

    end
  end
end
