# frozen_string_literal: true

module Mutant
  class Reporter
    class CLI
      class Printer
        # Reporter for mutation results
        #
        # :reek:TooManyConstants
        class MutationResult < self

          delegate :mutation, :test_result

          MAP = {
            Mutant::Mutation::Evil    => :evil_details,
            Mutant::Mutation::Neutral => :neutral_details,
            Mutant::Mutation::Noop    => :noop_details
          }.freeze

          NEUTRAL_MESSAGE = <<~'MESSAGE'
            --- Neutral failure ---
            Original code was inserted unmutated. And the test did NOT PASS.
            Your tests do not pass initially or you found a bug in mutant / unparser.
            Subject AST:
            %s
            Unparsed Source:
            %s
            Test Result:
          MESSAGE

          NO_DIFF_MESSAGE = <<~'MESSAGE'
            --- Internal failure ---
            BUG: Mutation NOT resulted in exactly one diff hunk. Please report a reproduction!
            Original unparsed source:
            %s
            Original AST:
            %s
            Mutated unparsed source:
            %s
            Mutated AST:
            %s
          MESSAGE

          NOOP_MESSAGE = <<~'MESSAGE'
            ---- Noop failure -----
            No code was inserted. And the test did NOT PASS.
            This is typically a problem of your specs not passing unmutated.
            Test Result:
          MESSAGE

          FOOTER = '-----------------------'

          # Run report printer
          #
          # @return [undefined]
          def run
            puts(mutation.identification)
            print_details
            puts(FOOTER)
          end

        private

          # Print mutation details
          #
          # @return [undefined]
          def print_details
            __send__(MAP.fetch(mutation.class))
          end

          # Evil mutation details
          #
          # @return [String]
          def evil_details
            diff = Diff.build(mutation.original_source, mutation.source)
            diff = color? ? diff.colorized_diff : diff.diff
            if diff
              output.write(diff)
            else
              print_no_diff_message
            end
          end

          # Print no diff message
          #
          # @return [undefined]
          def print_no_diff_message
            info(
              NO_DIFF_MESSAGE,
              mutation.original_source,
              original_node.inspect,
              mutation.source,
              mutation.node.inspect
            )
          end

          # Noop details
          #
          # @return [String]
          def noop_details
            info(NOOP_MESSAGE)
            visit_test_result
          end

          # Neutral details
          #
          # @return [String]
          def neutral_details
            info(NEUTRAL_MESSAGE, original_node.inspect, mutation.source)
            visit_test_result
          end

          # Visit failed test results
          #
          # @return [undefined]
          def visit_test_result
            visit(TestResult, test_result)
          end

          # Original node
          #
          # @return [Parser::AST::Node]
          def original_node
            mutation.subject.node
          end

        end # MutationResult
      end # Printer
    end # CLI
  end # Reporter
end # Mutant
