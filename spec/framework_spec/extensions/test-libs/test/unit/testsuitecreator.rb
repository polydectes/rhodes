#--
#
# Author:: Kouhei Sutou
# Copyright::
#   * Copyright (c) 2011 Kouhei Sutou <tt><kou@clear-code.com></tt>
# License:: Ruby license.

module Test
  module Unit
    class TestSuiteCreator # :nodoc:
      def initialize(test_case)
        @test_case = test_case
      end

      def create
        suite = TestSuite.new(@test_case.name, @test_case)
        collect_test_names.each do |test_name|
          data_sets = @test_case.attributes(test_name)[:data]
          if data_sets
            data_sets.each do |data_set|
              data_set = data_set.call if data_set.respond_to?(:call)
              data_set.each do |label, data|
                append_test(suite, test_name) do |test|
                  test.assign_test_data(label, data)
                end
              end
            end
          else
            append_test(suite, test_name)
          end
        end
        append_test(suite, "default_test") if suite.empty?
        suite
      end

      private
      def append_test(suite, test_name)
        test = @test_case.new(test_name)
        yield(test) if block_given?
        suite << test if test.valid?
      end

      def collect_test_names
        method_names = @test_case.public_instance_methods(true).collect do |name|
          name.to_s
        end
        test_names = method_names.find_all do |method_name|
          method_name =~ /^test./ or @test_case.attributes(method_name)[:test]
        end
        send("sort_test_names_in_#{@test_case.test_order}_order", test_names)
      end

      def sort_test_names_in_alphabetic_order(test_names)
        test_names.sort
      end

      def sort_test_names_in_random_order(test_names)
        test_names.sort_by {rand(test_names.size)}
      end

      def sort_test_names_in_defined_order(test_names)
        added_methods = @test_case.added_methods
        test_names.sort do |test1, test2|
          test1_defined_order = added_methods.index(test1)
          test2_defined_order = added_methods.index(test2)
          if test1_defined_order and test2_defined_order
            test1_defined_order <=> test2_defined_order
          elsif test1_defined_order
            1
          elsif test2_defined_order
            -1
          else
            test1 <=> test2
          end
        end
      end
    end
  end
end
