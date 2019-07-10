# frozen_string_literal: true

module Ruport
  # This class produces Markdown table output from Ruport::Table data.
  #
  # === Rendering Options
  # <tt>:alignment:</tt> Default alignment for all columns.
  # Allowed values are :left, :center and :right. Default is :left.
  #
  # <tt>:column_alignments:</tt> Alignments for specific columns.
  # You can configure alignments by using
  # Hash (key: column name, value: alignment)
  class Formatter::MarkDown < Formatter
    renders :markdown, for: [Controller::Table]

    # Hook for setting available options using a template.
    def apply_template
      apply_table_format_template(template.table)
    end

    # Uses the column names from the given Data::Table to generate
    # a table header.
    # If no column names are given, first row will be
    # treated as table header.
    def build_table_header
      names = column_names(data)
      build_md_row(output, names)
      build_md_row(output, alignment_strings(names))
    end

    # Generates body of Markdown table data.
    # Following characters will be replaced as escape.
    #
    # * | -> &#124;
    # * newline code(\\n) -> \<br>
    def build_table_body
      body =
        if data.column_names && !data.column_names.empty?
          data
        else
          data[1..-1]
        end
      body.each { |row| build_md_row(output, row) }
    end

    private

    def column_names(data)
      if data.column_names && !data.column_names.empty?
        data.column_names
      else
        data[0]
      end
    end

    def build_md_row(output, row)
      output << "|"
      output << row.to_a.map { |cell| escape(cell.to_s.dup) }.join('|')
      output << "|\n"
    end

    def escape(cell)
      cell.gsub!("|", "&#124;")
      cell.gsub!("\n", "<br>")
      cell
    end

    def alignment_strings(column_names)
      column_names.map(&method(:alignment_string))
    end

    def alignment_string(column_name)
      case column_alignment(column_name)
      when :right
        "--:"
      when :center
        ":-:"
      else
        ":--"
      end
    end

    def column_alignment(column_name)
      if options.column_alignments && options.column_alignments.key?(column_name)
        options.column_alignments[column_name]
      elsif options.alignment
        options.alignment
      else
        :left
      end
    end

    def apply_table_format_template(template)
      template = (template || {}).merge(options.table_format || {})
      options.alignment ||= template[:alignment]
      options.column_alignments =
        merget_column_alignments(options, template)
    end

    def merget_column_alignments(options, template)
      (template[:column_alignments] || {})
        .merge(options.column_alignments || {})
    end
  end
end
