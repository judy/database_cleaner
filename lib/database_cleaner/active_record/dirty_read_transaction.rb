require 'database_cleaner/active_record/base'
require 'database_cleaner/generic/transaction'
require 'database_cleaner/active_record/transaction'

module DatabaseCleaner::ActiveRecord
  class DirtyReadTransaction < Transaction
    include ::DatabaseCleaner::ActiveRecord::Base
    include ::DatabaseCleaner::Generic::Transaction

    def start
      # Hack to make sure that the connection is properly setup for
      # the clean code.
      connection_class.connection.transaction{ }

      if connection_class.connection.respond_to?(:begin_isolated_db_transaction)
        if connection_maintains_transaction_count?
          if connection_class.connection.respond_to?(:increment_open_transactions)
            connection_class.connection.increment_open_transactions
          else
            connection_class.__send__(:increment_open_transactions)
          end
        end
        connection_class.connection.begin_isolated_db_transaction(:read_uncommitted)
      else
        raise "This connection does not support setting isolation level for transactions."
      end
    end

  end
end
