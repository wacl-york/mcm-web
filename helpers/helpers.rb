# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
helpers do
  # rubocop:disable Metrics/MethodLength, Metrics/ParameterLists
  def wrap_lines(words, max_line_length: 68, starting_char: ' ', ending_char: ';', sep: ' ', every_line_start: '',
                 every_line_end: '')
    out = starting_char
    current_line_length = 0
    words.each do |word|
      to_add = "#{word}#{sep}"
      if (current_line_length + to_add.length) > max_line_length
        out = "#{out[..-2]}#{every_line_end}\n" # remove last unused separating space
        out += every_line_start
        current_line_length = every_line_start.length
      end
      out += to_add
      current_line_length += to_add.length
    end
    out = "#{out[..-sep.length]}#{ending_char}\n" # remove last unused separating space
  end
  # rubocop:enable Metrics/MethodLength, Metrics/ParameterLists

  def get_parent_from_children(children, _db)
    DB[:TokenRelationships]
      .where(ChildToken: children)
      .distinct
      .select_map(:ParentToken)
  end

  def get_token_definition(token, _db)
    DB[:Tokens]
      .where(Token: token)
      .get(:Definition)
  end

  def link_from_category(category)
    category.split[0].downcase
  end

  def parse_rate(rate)
    # Parses a raw rate string into a MathJAX formatted label with matching length arrow
    # Converts the FACSIMILIE rate equation into human readable math in 3 ways:
    # 1) converts x / y fractions into \frac{x}{y}
    # 2) replaces EXP with the \exp function
    # 3) replaces aD-b with a \times 10^{-b}
    # NB: Should really hardcode this into DB rather than doing on fly

    # Convert EXP() and fractions
    parsed = rate.gsub(%r{EXP\(([a-zA-Z0-9-]+)/([a-zA-Z0-9-]+)\)}, '\\exp{\\frac{\1}{\2}}')

    # Convert D to scientific notation
    parsed = parsed.gsub(/([0-9.-]+)D([0-9-]+)/, '\1\\times10^{\2}')

    # Use mhchem's ce environment for getting reaction arrow that stretches with rate
    "\\(\\ce{->[#{parsed}]}\\)"
  end

  def parse_multiple_species(values, species_page)
    # Parses an array of species into a '+' delimited string with hyperreferences
    # to a compound's own page. MathJAX is used to format the text
    parsed = values
             .map { |x| create_link_from_species_name(x[:Name], x[:Category], species_page) }
             .join(' + ')
    "\\(#{parsed}\\)"
  end

  def create_link_from_species_name(name, category, species_page)
    # Creates a link to a species page under 2 conditions:
    # 1) It is a VOC, and 2) it is not the species that the current
    # page is displaying.
    if (category == 'VOC') && (name != species_page)
      "\\href{/species/#{name}}{\\text{#{name}}}"
    else
      "\\text{#{name}}"
    end
  end
end
# rubocop:enable Metrics/BlockLength
