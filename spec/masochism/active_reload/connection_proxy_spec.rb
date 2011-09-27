require 'spec_helper'
require 'fileutils'

module Masochism
  module ActiveReload
    describe ConnectionProxy do
      MASTER = 'db/test.sqlite3'
      SLAVE = 'db/test_slave.sqlite3'

      it "should return nil when asking if a slave is defined" do
        ActiveRecord::Base.configurations = default_config
        described_class.slave_defined?.should be_nil
      end

      it "should return true when asking if a slave is defined" do
        ActiveRecord::Base.configurations = slave_inside_config
        described_class.slave_defined?.should be_true
      end

      context "no slave is defined" do
        it "should use the master database for reads" do
          ActiveRecord::Base.configurations = default_config
          force_connection_reset!
          ActiveReload::ConnectionProxy.setup!

          ActiveRecord::Base.connection.master.execute('CREATE TABLE foo (id int)')

          ActiveRecord::Base.connection.tables.should == ['foo']
          ActiveRecord::Base.connection.slave.tables.should == ['foo']
        end
      end

      context "both slave and master are defined" do
        it "should read from the slave database when master is defined globally" do
          ActiveRecord::Base.configurations = master_outside_config
          force_connection_reset!
          ActiveReload::ConnectionProxy.setup!

          ActiveRecord::Base.connection.master.execute('CREATE TABLE foo (id int)')

          ActiveRecord::Base.connection.tables.should == []
          ActiveRecord::Base.connection.slave.tables.should == []
          ActiveRecord::Base.connection.master.tables.should == ['foo']
        end

        it "should read from the slave when master is defined inside of the slave" do
          ActiveRecord::Base.configurations = master_inside_config
          force_connection_reset!
          ActiveReload::ConnectionProxy.setup!

          ActiveRecord::Base.connection.master.execute('CREATE TABLE foo (id int)')

          ActiveRecord::Base.connection.tables.should == []
          ActiveRecord::Base.connection.slave.tables.should == []
          ActiveRecord::Base.connection.master.tables.should == ['foo']
        end

        it "should read from the slave when the slave is defined inside the master" do
          ActiveRecord::Base.configurations = slave_inside_config
          force_connection_reset!
          ActiveReload::ConnectionProxy.setup!

          ActiveRecord::Base.connection.master.execute('CREATE TABLE foo (id int)')

          ActiveRecord::Base.connection.tables.should == []
          ActiveRecord::Base.connection.slave.tables.should == []
          ActiveRecord::Base.connection.master.tables.should == ['foo']
        end
      end

      after(:each) do
        ActiveRecord::Base.remove_connection
        FileUtils.rm_f(File.join(Rails.root, MASTER))
        FileUtils.rm_f(File.join(Rails.root, SLAVE))
      end

      def force_connection_reset!
        load File.dirname(__FILE__)+'/../../../lib/masochism/active_reload/connection_proxy.rb'
      end

      def default_config
        {
          Rails.env => {
            'adapter' => 'sqlite3',
            'database' => MASTER
          }
        }
      end

      def master_outside_config
        {
          Rails.env => {
            'adapter' => 'sqlite3',
            'database' => SLAVE
          },
          'master_database' => {
            'adapter' => 'sqlite3',
            'database' => MASTER
          }
        }
      end

      def master_inside_config
        {
          Rails.env => {
            'adapter' => 'sqlite3',
            'database' => SLAVE,
            'master_database' => {
              'adapter' => 'sqlite3',
              'database' => MASTER
            }
          }
        }
      end

      def slave_inside_config
        {
          Rails.env => {
            'adapter' => 'sqlite3',
            'database' => MASTER,
            'slave_database' => {
              'adapter' => 'sqlite3',
              'database' => SLAVE
            }
          }
        }
      end
    end
  end
end
