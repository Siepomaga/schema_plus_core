module SchemaPlus
  module Core
    module ActiveRecord
      module ConnectionAdapters
        module AbstractAdapter

          def add_column(table_name, name, type, options = {})
            SchemaMonkey::Middleware::Migration::Column.start(caller: self, operation: :add, table_name: table_name, column_name: name, type: type, options: options.deep_dup) do |env|
              super env.table_name, env.column_name, env.type, env.options
            end
          end

          def add_reference(table_name, name, options = {})
            SchemaMonkey::Middleware::Migration::Column.start(caller: self, operation: :add, table_name: table_name, column_name: "#{name}_id", type: :reference, options: options.deep_dup) do |env|
              super env.table_name, env.column_name.sub(/_id$/, ''), env.options
            end
          end

          def add_index(*args)
            options = args.extract_options!
            table_name, column_names = args
            SchemaMonkey::Middleware::Migration::Index.start(caller: self, operation: :add, table_name: table_name, column_names: column_names, options: options.deep_dup) do |env|
              super env.table_name, env.column_names, env.options
            end
          end


          IndexComponentsSql = KeyStruct[:name, :type, :columns, :options, :algorithm, :using]

          def add_index_options(table_name, column_names, options={})
            SchemaMonkey::Middleware::Migration::IndexComponentsSql.start(connection: self, table_name: table_name, column_names: Array.wrap(column_names), options: options.deep_dup, sql: IndexComponentsSql.new) { |env|
              env.sql.name, env.sql.type, env.sql.columns, env.sql.options, env.sql.algorithm, env.sql.using = super env.table_name, env.column_names, env.options
            }.sql.to_hash.values
          end

          module SchemaCreation
            def self.prepended(base)
              base.class_eval do
                public :options_include_default?
              end
            end

            def add_column_options!(sql, options)
              SchemaMonkey::Middleware::Migration::ColumnOptionsSql.start(caller: self, connection: self.instance_variable_get('@conn'), sql: sql, options: options) { |env|
                super env.sql, env.options
              }.sql
            end
          end
        end
      end
    end
  end
end
