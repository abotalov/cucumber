module Cucumber
  module Ast
    # Walks the AST, executing steps and notifying listeners
    class Runner
      attr_accessor :options #:nodoc:
      attr_reader :step_mother #:nodoc:

      def initialize(step_mother, listeners, options)
        @step_mother, @listeners, @options = step_mother, listeners, options
      end

      def visit_features(features)
        broadcast(features) do
          features.accept(self)
        end
      end

      def visit_feature(feature)
        broadcast(feature) do
          feature.accept(self)
        end
      end

      def visit_comment(comment)
        broadcast(comment) do
          comment.accept(self)
        end
      end

      def visit_comment_line(comment_line)
        broadcast(comment_line)
      end

      def visit_tags(tags)
        broadcast(tags) do
          tags.accept(self)
        end
      end

      def visit_tag_name(tag_name)
        broadcast(tag_name)
      end

      def visit_feature_name(name)
        broadcast(name)
      end

      # +feature_element+ is either Scenario or ScenarioOutline
      def visit_feature_element(feature_element)
        broadcast(feature_element) do
          feature_element.accept(self)
        end
      end

      def visit_background(background)
        broadcast(background) do
          background.accept(self)
        end
      end

      def visit_background_name(keyword, name, file_colon_line, source_indent)
        broadcast(keyword, name, file_colon_line, source_indent)
      end

      def visit_examples_array(examples_array)
        broadcast(examples_array) do
          examples_array.accept(self)
        end
      end

      def visit_examples(examples)
        broadcast(examples)
        examples.accept(self)
      end

      def visit_examples_name(keyword, name)
        broadcast(keyword, name)
      end

      def visit_outline_table(outline_table)
        broadcast(outline_table) do
          @table = outline_table # TODO: remove? who needs this?
          outline_table.accept(self)
        end
      end

      def visit_scenario_name(keyword, name, file_colon_line, source_indent)
        broadcast(keyword, name, file_colon_line, source_indent)
      end

      def visit_steps(steps)
        broadcast(steps) do
          steps.accept(self)
        end
      end

      def visit_step(step)
        broadcast(step) do
          step.accept(self)
        end
      end

      def visit_step_result(keyword, step_match, multiline_arg, status, exception, source_indent, background)
        broadcast(keyword, step_match, multiline_arg, status, exception, source_indent, background) do
          visit_step_name(keyword, step_match, status, source_indent, background)
          visit_multiline_arg(multiline_arg) if multiline_arg
          visit_exception(exception, status) if exception
        end
      end

      def visit_step_name(keyword, step_match, status, source_indent, background) #:nodoc:
        broadcast(keyword, step_match, status, source_indent, background)
      end

      def visit_multiline_arg(multiline_arg) #:nodoc:
        broadcast(multiline_arg) do
          multiline_arg.accept(self)
        end
      end

      def visit_exception(exception, status) #:nodoc:
        broadcast(exception, status)
      end

      def visit_py_string(string)
        broadcast(string)
      end

      def visit_table_row(table_row)
        broadcast(table_row) do
          table_row.accept(self)
        end
      end

      def visit_table_cell(table_cell)
        broadcast(table_cell) do
          table_cell.accept(self)
        end
      end

      def visit_table_cell_value(value, status)
        broadcast(value, status)
      end

      # Print +announcement+. This method can be called from within StepDefinitions.
      def announce(announcement)
        broadcast(announcement)
      end
      
      private
      
      def broadcast(*args, &block)
        message = caller[0].match(/in `(.*)'/).captures[0]
        
        # send_to_all "before_#{message}", *args
        run_before_on_legacy_listeners message, *args

        yield if block_given?

        # send_to_all "after_#{message}", *args
        run_after_on_legacy_listeners(message)
      end
      
      # def send_to_all(message, *args)
      #   @listeners.each do |listener|
      #     if listener.respond_to?(message)
      #       listener.__send__(message, *args)
      #     end
      #   end
      # end
      
      def legacy_listeners
        @listeners.select{ |l| l.is_a?(Cucumber::Ast::Visitor)}
      end
      
      def run_after_on_legacy_listeners(message)
        legacy_listeners.each do |listener| 
          listener.run_after
        end
      end
      
      def run_before_on_legacy_listeners(message, *args)
        *the_args = *args.dup
        the_args[0].extend(NullAcceptor)
        legacy_listeners.each { |l| l.run_before(message, *the_args) }
      end
      
      module NullAcceptor
        def accept(visitor)
          unless visitor.instance_of?(Cucumber::Ast::Runner)
            # warn("Deprecated: stop visiting things like #{self.class} from #{caller[0]}") unless @options[:quiet]
            # puts "pausing #{Thread.current[:method]} thread as it as called #accept"
            sleep
            return
          end
          super
        end
      end
    end
  end
end