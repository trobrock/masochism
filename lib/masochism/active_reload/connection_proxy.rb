module Masochism
  module ActiveReload
    class MasterDatabase < ActiveRecord::Base
      self.abstract_class = true
      establish_connection configurations[Rails.env]['master_database'] || configurations['master_database'] || Rails.env
    end

    class ConnectionProxy

      def initialize(master_class, slave_class)
        @master  = master_class
        @slave   = slave_class
        @current = :slave
      end

      def master
        @slave.connection_handler.retrieve_connection(@master)
      end

      def slave
        @slave.retrieve_connection
      end

      def current
        send @current
      end

      def self.setup!
        setup_for ActiveReload::MasterDatabase
      end

      def self.setup_for(master, slave = nil)
        slave ||= ActiveRecord::Base
        slave.send :include, ActiveRecordConnectionMethods
        ActiveRecord::Observer.send :include, ActiveReload::ObserverExtensions
        slave.establish_connection slave.configurations[Rails.env]['slave_database'] || Rails.env
        slave.connection_proxy = new(master, slave)
      end

      def with_master
        set_to_master!
        yield
      ensure
        set_to_slave! if master.open_transactions == 0
      end

      def set_to_master!
        unless @current == :master
          @slave.logger.info "Switching to Master"
          @current = :master
        end
      end

      def set_to_slave!
        unless @current == :slave
          @master.logger.info "Switching to Slave"
          @current = :slave
        end
      end

      delegate :insert, :update, :delete, :create_table, :rename_table, :drop_table, :add_column, :remove_column,
        :change_column, :change_column_default, :rename_column, :add_index, :remove_index, :initialize_schema_information,
        :dump_schema_information, :execute, :columns, :to => :master

      def transaction(options = {}, &block)
        with_master {current.transaction(options, &block)}
      end

      def method_missing(method, *args, &block)
        current.send(method, *args, &block)
      end
    end

    module ActiveRecordConnectionMethods
      def self.included(base)
        base.alias_method_chain :reload, :master
        base.extend ClassMethods

        class << base
          alias_method :connection_without_connection_proxy, :connection
          alias_method :connection, :connection_with_connection_proxy
        end
      end

      module ClassMethods
        def connection_proxy=(proxy)
          @@connection_proxy = proxy
        end

        def connection_with_connection_proxy
          @@connection_proxy.current
          @@connection_proxy
        end
      end

      def reload_with_master(*args, &block)
        if connection.class.name == "ActiveReload::ConnectionProxy"
          connection.with_master { reload_without_master }
        else
          reload_without_master
        end
      end
    end

    # extend observer to always use the master database
    # observers only get triggered on writes, so shouldn't be a performance hit
    # removes a race condition if you are using conditionals in the observer
    module ObserverExtensions
      def self.included(base)
        base.alias_method_chain :update, :masterdb
      end

      # Send observed_method(object) if the method exists.
      def update_with_masterdb(observed_method, object) #:nodoc:
        if object.class.connection.respond_to?(:with_master)
          object.class.connection.with_master do
            update_without_masterdb(observed_method, object)
          end
        else
          update_without_masterdb(observed_method, object)
        end
      end
    end
  end
end
