# Ruport : Extensible Reporting System                                
#
# template.rb provides templating support for Ruby Reports.
#
# Copyright August 2007, Gregory Brown / Michael Milner.  All Rights Reserved.
#
# This is free software. Please see the LICENSE and COPYING files for details.


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
    templates[label]
  end
end
