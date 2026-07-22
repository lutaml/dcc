# frozen_string_literal: true

require "tty-table"

module Dcc
  module Cli
    # `Dcc::Cli::Formatters` picks the right text/JSON/YAML representation
    # of a result model and prints it.
    module Formatters
      module_function

      def print(object, format: "text")
        case format
        when "json" then puts object.to_json
        when "yaml" then puts object.to_yaml
        else
          puts object.to_s
        end
      end

      def print_files(files)
        if files.empty?
          puts "(no embedded files)"
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
            [i, f.name.to_s, f.file_name.to_s, f.mime_type.to_s, f.ring, f.data.bytesize]
          end,
        )
        puts table.render
      rescue StandardError
        # Fallback if TTY::Table rendering fails for any reason.
        print_files_plain(files)
      end

      def print_files_plain(files)
        # Widths
        widths = ["Index".size, "Name".size, "File Name".size, "MIME".size, "Ring".size, "Size".size]
        rows = files.each_with_index.map do |f, i|
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