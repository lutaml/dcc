# frozen_string_literal: true

module Dcc
  module Diff
    # Result of comparing two DCC object trees.
    class Result
      attr_reader :changes

      def initialize(changes:)
        @changes = changes
      end

      def additions
        changes.select(&:added?)
      end

      def removals
        changes.select(&:removed?)
      end

      def modifications
        changes.select(&:changed?)
      end

      def empty?
        changes.empty?
      end

      def to_s
        if empty?
          "(no structural changes)"
        else
          header = "#{changes.size} change(s): " \
                  "#{additions.size} added, #{removals.size} removed, #{modifications.size} changed"
          ([header] + changes.map(&:to_s)).join("\n")
        end
      end

      def to_json(*_args)
        require "json"
        ::JSON.pretty_generate(
          additions: additions.map { |c| { path: c.path, value: c.after } },
          removals: removals.map { |c| { path: c.path, value: c.before } },
          modifications: modifications.map { |c| { path: c.path, before: c.before, after: c.after } },
        )
      end

      def to_yaml(*_args)
        require "yaml"
        {
          additions: additions.map { |c| { path: c.path, value: c.after } },
          removals: removals.map { |c| { path: c.path, value: c.before } },
          modifications: modifications.map { |c| { path: c.path, before: c.before, after: c.after } },
        }.to_yaml
      end
    end
  end
end