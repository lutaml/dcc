# frozen_string_literal: true

module Dcc
  module Cli
    # `Dcc::Cli::Formatters` picks the right text/JSON/YAML representation
    # of a result model and prints it.
    module Formatters
      # Goes to stderr, so a piped `extract files` still yields clean data.
      TTY_TABLE_HINT = "note: install tty-table for aligned output " \
                       "(gem install tty-table)"

      # `tty-table` is optional. It pulls in eight further gems to prettify
      # one command, which every library user would otherwise install just
      # to parse XML. Loaded on first use, and its absence falls back to the
      # plain renderer rather than raising the way `Dcc::Server` does.
      def self.table_available?
        return @table_available unless @table_available.nil?

        begin
          require "tty-table"
          @table_available = true
        rescue ::LoadError
          @table_available = false
        end
        @table_available
      end

      module_function

      def print(object, format: "text")
        case format
        when "json" then puts object.to_json
        when "yaml" then puts object.to_yaml
        else
          puts object
        end
      end

      def print_files(files)
        if files.empty?
          puts "(no embedded files)"
          return
        end

        unless table_available?
          # Hint first: a stderr that raises is caught by the rescue below,
          # which re-runs the renderer. Printing first would duplicate it.
          warn TTY_TABLE_HINT
          print_files_plain(files)
          return
        end

        # TTY::Table calls ioctl which fails on StringIO / pipes. Fall back
        # to a plain-text rendering when stdout isn't a real terminal.
        if $stdout.is_a?(::IO) && !$stdout.tty?
          print_files_plain(files)
          return
        end

        table = ::TTY::Table.new(
          ["Index", "Name", "File Name", "MIME", "Ring", "Size"],
          files.each_with_index.map do |f, i|
            [i, f.name.to_s, f.file_name.to_s, f.mime_type.to_s, f.ring,
             f.data.bytesize]
          end,
        )
        puts table.render
      rescue StandardError
        # Fallback if TTY::Table rendering fails for any reason.
        print_files_plain(files)
      end

      def print_files_plain(files)
        # Widths
        widths = ["Index".size, "Name".size, "File Name".size, "MIME".size,
                  "Ring".size, "Size".size]
        files.each_with_index.map do |f, i|
          [
            i.to_s,
            f.name.to_s,
            f.file_name.to_s,
            f.mime_type.to_s,
            f.ring.to_s,
            f.data.bytesize.to_s,
          ].each_with_index { |v, idx| widths[idx] = [widths[idx], v.size].max }
        end
        header = ["Index", "Name", "File Name", "MIME", "Ring", "Size"]
        sep = widths.map { |w| "-" * (w + 2) }.join("+")
        puts header.zip(widths).map { |c, w| " #{c.ljust(w)} " }.join("|")
        puts sep
        files.each_with_index do |f, i|
          row = [
            i.to_s,
            f.name.to_s,
            f.file_name.to_s,
            f.mime_type.to_s,
            f.ring.to_s,
            f.data.bytesize.to_s,
          ]
          puts row.zip(widths).map { |c, w| " #{c.ljust(w)} " }.join("|")
        end
      end
    end
  end
end
