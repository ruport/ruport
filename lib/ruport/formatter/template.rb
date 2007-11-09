# Ruport : Extensible Reporting System                                
#
# template.rb provides templating support for Ruby Reports.
#
# Copyright August 2007, Gregory Brown / Michael Milner.  All Rights Reserved.
#
# This is free software. Please see the LICENSE and COPYING files for details.


class Ruport::Formatter::TemplateNotDefined < StandardError; end       

# This class provides templating functionality for Ruport.
# New templates are created using the Template.create method.
#
# Example:
#
#   Ruport::Formatter::Template.create(:simple) do |t|
#     t.page_layout = :landscape
#     t.grouping_style = :offset
#   end
#
# You can then determine how the template should be used by defining
# an <tt>apply_template</tt> method in your formatter.
#
# Example:
#
#   class Ruport::Formatter::PDF 
#     def apply_template
#       options.paper_orientation = template.page_layout
#       options.style = template.grouping_style
#     end
#   end
#
# When you're ready to render the output, you can set the :template as an
# option for the formatter. Using the template remains optional and you can
# still render the report without it.
#
# Example:
#
#   puts g.to_pdf(:template => :simple) #=> uses the template
#   puts g.to_pdf                       #=> doesn't use the template
#
# The built-in formatters all have <tt>apply_template</tt> methods defined that
# accept a standard set of options. Each option can be set by supplying a hash
# with the keys/values listed in the tables below.
#
# Example:
#
#   Ruport::Formatter::Template.create(:simple) do |t|
#     t.page_format = {
#       :size   => "LETTER",
#       :layout => :landscape
#     }
#   end
#
# ==== PDF Formatter Options
#
#   Option          Key                 Value
# 
#   page_format     :size               Any size supported by the :paper
#                                       option to PDF::Writer.new
# 
#                   :layout             :portrait, :landscape
# 
#   text_format     Any available to    Corresponding values
#                   PDF::Writer#text
# 
#   table_format    All attributes of   Corresponding values
#                   PDF::SimpleTable
# 
#                   :column_options     - All attributes of
#                                         PDF::SimpleTable::Column
#                                         except :heading
#                                       - Hash keyed by a column name, whose
#                                         value is a hash containing any of
#                                         the other:column_options (sets values
#                                         for specific columns)
#                                       - :heading => { All attributes of
#                                         PDF::SimpleTable::Column::Heading }
# 
#   column_format   :alignment          :left, :right, :center, :full
# 
#                   :width              column width
# 
#   heading_format  :alignment          :left, :right, :center, :full
# 
#                   :bold               true or false
# 
#                   :title              heading title (if not set,
#                                       defaults to column name)
# 
#   grouping_format :style              :inline, :justified, :separated, :offset
#
#
# ==== Text Formatter Options
# 
#   Option          Key                 Value
# 
#   table_format    :show_headings      true or false
#                   :width              Table width
#                   :ignore_width       true or false
# 
#   column_format   :alignment          :center
#                   :maximum_width      Max column width
# 
#   grouping_format :show_headings      true or false
#
#
# ==== HTML Formatter Options
# 
#   Option          Key                 Value
# 
#   table_format    :show_headings      true or false
# 
#   grouping_format :style              :inline, :justified
#                   :show_headings      true or false
#
#
# ==== CSV Formatter Options
# 
#   Option          Key                 Value
# 
#   table_format    :show_headings      true or false
# 
#   grouping_format :style              :inline, :justified, :raw
#                   :show_headings      true or false
# 
#   format_options  All options         Corresponding values
#                   available to
#                   FasterCSV.new
#
class Ruport::Formatter::Template < Ruport::Renderer::Options
  
  # Returns all existing templates in a hash keyed by the template names.
  def self.templates
    @templates ||= Hash.new 
  end
  
  # Creates a new template with a name given by <tt>label</tt>.
  #
  # Example:
  #
  #   Ruport::Formatter::Template.create(:simple) do |t|
  #     t.page_layout = :landscape
  #     t.grouping_style = :offset
  #   end
  #
  # You can inherit all the options set in a template by using the :base option
  # and providing an existing template name to use as the base.
  #
  # Example:
  #
  #   Ruport::Formatter::Template.create(:derived, :base => :simple)
  #
  def self.create(label,opts={})
    if opts[:base]
      obj = Marshal.load(Marshal.dump(self[opts[:base]]))
    else
      obj = new
    end
    yield(obj) if block_given?
    templates[label] = obj
  end
  
  # Returns an existing template with the provided name (label).
  def self.[](label) 
    templates[label] or raise Ruport::Formatter::TemplateNotDefined
  end
end   
