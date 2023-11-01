# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
helpers do
  def display_reaction(rxn, species_page, doc_link: true)
    output = "<div class='rxn-reactants'>#{parse_multiple_species(rxn[:Reactants], species_page)}</div>
    <div class='rxn-rate'><a#{rxn[:RateURL].nil? ? '' : " href='#{rxn[:RateURL]}'"}>#{parse_rate(rxn[:Rate])}</a></div>
    <div class='rxn-products'>#{parse_multiple_species(rxn[:Products], species_page)}</div>
    <div class='rxn-category'>"
    if doc_link && !rxn[:Category].nil?
      output += "<a href='/#{@mechanism}/reaction_category?category=#{rxn[:Category]}&reactionid=#{rxn[:ReactionID]}'>
                 Doc</a>"
    end
    output += '</div>'
    output
  end

  # rubocop:disable Metrics/MethodLength
  def parse_rate(rate, display_arrow: true)
    # Parses a raw rate string into a MathJAX formatted label with matching length arrow
    # Converts the FACSIMILIE rate equation into human readable math in 3 ways:
    # 1) converts x / y fractions into \frac{x}{y}
    # 2) replaces EXP with the \exp function
    # 3) replaces aD-b with a \times 10^{-b}
    # NB: Should this be done in SQL as a View?
    return if rate.nil?

    # Replace @ with exponent when it's just a number to the power
    parsed = replace_capture_group_multiple(rate, /@\(([0-9.+-]+)\)/, '^{\\1}')
    parsed = replace_capture_group_multiple(parsed, /\*\*\(([0-9.+-]+)\)/, '^{\\1}')
    # Use Latex exp markup
    parsed = parsed.gsub('EXP', '\\exp')
    # Replace a / b with marked up fractions
    parsed = replace_capture_group_multiple(parsed, %r{([a-zA-Z0-9.+-{}]+)/([a-zA-Z0-9.+-{}]+)}, '{\\frac{\1}{\2}}')
    # Replace LOG10 with log_10
    parsed = replace_capture_group_multiple(parsed, /LOG10\((.+)\)/, '\\log_{10}(\\1)')
    # Convert D to scientific notation
    parsed = replace_capture_group_multiple(parsed, /([0-9.+-]+)[D|E]([0-9+-]+)/, '\1\\times10^{\2}')
    # Replace @ with exponent when there's an expression in parentheses
    parsed = replace_capture_group_multiple(parsed, /@\((.+)\)/, '^{\\1}')
    # Replace TEMP with T for brevity
    parsed = parsed.gsub('TEMP', '{T}')

    # Escape compound or rate names so numbers aren't subscripted
    # Compound or rate names are defined as having at least 1 capital letter and
    # at least 1 number in either order (is this realistic? would ever have 3H...?)
    parsed = parsed.gsub(/([A-Z]+[0-9]+[A-Z0-9]*|[0-9]+[A-Z]+[A-Z0-9]*)/, '{\1}')

    # Use mhchem's ce environment for getting reaction arrow that stretches with rate
    inner = display_arrow ? "->[#{parsed}]" : parsed
    "\\(\\ce{#{inner}}\\)"
  end
  # rubocop:enable Metrics/MethodLength

  def parse_multiple_species(values, species_page)
    # Parses an array of species into a '+' delimited string with hyperreferences
    # to a compound's own page. MathJAX is used to format the text
    values
      .map { |x| parse_species(x[:Name], x[:Category], species_page) }
      .join(' <div class="rxn-plus"> + </div>')
  end

  # rubocop:disable Metrics/MethodLength
  # rubocop:disable Metrics/PerceivedComplexity
  def parse_species(name, category, species_page)
    # Creates a link to a species page under 2 conditions:
    # 1) It is a VOC, and 2) it is not the species that the current
    # page is displaying.
    outer_open_tag = if category == 'VOC'
                       if name == species_page
                         "<div class='rxn-species-image'>"
                       else
                         "<a class='rxn-species-image' href='/#{@mechanism}/species/#{name}'>"
                       end
                     else
                       ''
                     end
    outer_close_tag = if category == 'VOC'
                        if name == species_page
                          '</div>'
                        else
                          '</a>'
                        end
                      else
                        ''
                      end
    inner_open_tag = category == 'VOC' ? "<img src='/species_images/#{name}.png'/>" : '<span>'
    inner_close_tag = category == 'VOC' ? '' : '</span>'

    ['<div>', outer_open_tag, inner_open_tag, name, inner_close_tag, outer_close_tag, '</div>'].join("\n")
  end
  # rubocop:enable Metrics/MethodLength
  # rubocop:enable Metrics/PerceivedComplexity

  def remove_spaces(input)
    # Replaces spaces with hyphens and also makes the text all lower-case
    input.downcase.tr(' ', '-')
  end

  def replace_capture_group_multiple(input, pattern, replacement)
    # If the same capture group occurs multiple times in the string, gsub will only
    # replace the first match. I'm sure there's a way of doing this in regex but
    # I'm hacking it with a loop.
    # i.e. if string is "LOG(5) + LOG(3)", then string.gsub(/LOG\((.+)\)/, 'log_{\1}')
    # Will return log_{5} + LOG(3)
    input = input.gsub(pattern, replacement) while input.match? pattern
    input
  end

  def generate_photolysis_link(species)
    "<a href='/static/MCM/download/#{species}.zip'>#{species}</a>"
  end
end
# rubocop:enable Metrics/BlockLength
