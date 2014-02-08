module Ruport
  class Formatter::PrawnPDF < Formatter

    renders :prawn_pdf, :for =>[Controller::Row, Controller::Table,
                              Controller::Group, Controller::Grouping]

    attr_accessor :pdf

    def method_missing(id,*args, &block)
      pdf.send(id,*args, &block)
    end

    def initialize
      require 'prawn'
      require 'prawn/layout'
    end

    def pdf
      @pdf ||= (options.formatter || 
        ::Prawn::Document.new(options[:pdf_format] || {} ))
    end

    def draw_table(table, format_opts={}, &block)
      m = "PDF Formatter requires column_names to be defined"
      raise FormatterError, m if table.column_names.empty?

      table.rename_columns { |c| c.to_s }

      table_array = [table.column_names]
      table_array += table_to_array(table)
      table_array.map { |array| array.map! { |elem| elem.class != String ? elem.to_s : elem }}

      if options[:table_format]
        opt = options[:table_format] 
      else
        opt = format_opts
      end

      pdf.table(table_array, opt, &block)

    end

    def table_to_array(tbl)
      tbl.map { |row| row.to_a}
    end

    def finalize
      output << pdf.render
    end

    def build_table_body(&block)
      draw_table(data, &block)
    end

    def build_group_body
      render_table data, options.to_hash.merge(:formatter => pdf)
    end

    def build_grouping_body(&block)
      data.each do |name,group|

        # Group heading
        move_down(20)
        text name, :style => :bold, :size => 15

        # Table
        move_down(10)
        draw_table group, &block
      end
    end

    # Hook for setting available options using a template. See the template
    # documentation for the available options and their format.
    def apply_template
      apply_page_format_template(template.page)
      apply_text_format_template(template.text)
      apply_table_format_template(template.table)
      apply_column_format_template(template.column)
      apply_heading_format_template(template.heading)
      apply_grouping_format_template(template.grouping)
    end

    private

    def apply_page_format_template(t)
      options.pdf_format ||= {}
      t = (t || {}).merge(options.page_format || {})
      options.pdf_format[:page_size] ||= t[:size]
      options.pdf_format[:page_layout] ||= t[:layout]
    end

    def apply_text_format_template(t)
      t = (t || {}).merge(options.text_format || {})
      options.text_format = t unless t.empty?
    end

    def apply_table_format_template(t)
      t = (t || {}).merge(options.table_format || {})
      options.table_format = t unless t.empty?
    end

    def apply_column_format_template(t)
      t = (t || {}).merge(options.column_format || {})
      column_opts = {}
      column_opts.merge!(:justification => t[:alignment]) if t[:alignment]
      column_opts.merge!(:width => t[:width]) if t[:width]
      unless column_opts.empty?
        if options.table_format
          if options.table_format[:column_options]
            options.table_format[:column_options] =
              column_opts.merge(options.table_format[:column_options])
          else
            options.table_format.merge!(:column_options => column_opts)
          end
        else
          options.table_format = { :column_options => column_opts }
        end
      end
    end

    def apply_heading_format_template(t)
      t = (t || {}).merge(options.heading_format || {})
      heading_opts = {}
      heading_opts.merge!(:justification => t[:alignment]) if t[:alignment]
      heading_opts.merge!(:bold => t[:bold]) unless t[:bold].nil?
      heading_opts.merge!(:title => t[:title]) if t[:title]
      unless heading_opts.empty?
        if options.table_format
          if options.table_format[:column_options]
            if options.table_format[:column_options][:heading]
              options.table_format[:column_options][:heading] =
                heading_opts.merge(
                  options.table_format[:column_options][:heading]
                )
            else
              options.table_format[:column_options].merge!(
                :heading => heading_opts
              )
            end
          else
            options.table_format.merge!(
              :column_options => { :heading => heading_opts }
            )
          end
        else
          options.table_format = {
            :column_options => { :heading => heading_opts }
          }
        end
      end
    end

    def apply_grouping_format_template(t)
      t = (t || {}).merge(options.grouping_format || {})
      options.style ||= t[:style]
    end

  end
end
