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

  # TODO: refactor all of these. Remove unused, add docs, rename to include 'Token' etc...
  def get_parent_from_children(children, _db)
    DB[:TokenRelationships]
      .where(ChildToken: children)
      .distinct
      .select_map(:ParentToken)
  end

  def get_children_from_parents_set(parents, _db)
    # Difference between and similarily named function
    # below is this accepts the children as a set of Token names,
    # whereas the other accepts a SQL dataset
    DB[:TokenRelationships]
      .where(ParentToken: parents)
      .distinct
      .select_map(:ChildToken)
  end

  def get_children_from_parent(parents, _db)
    DB[:TokenRelationships]
      .join(parents, Child: :ParentToken)
      .select(Sequel.lit('RootToken, ChildToken as Child'))
  end

  def get_token_definition(token, _db)
    DB[:Tokens]
      .where(Token: token)
      .get(:Definition)
  end

  def link_from_category(category)
    category.split[0].downcase
  end

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
    parsed = rate.gsub(/@([0-9.+-]+)/, '^{\\1}')
    # Use Latex exp markup
    parsed = parsed.gsub('EXP', '\\exp')
    # Replace a / b with marked up fractions
    parsed = replace_capture_group_multiple(parsed, %r{([a-zA-Z0-9.+-{}]+)/([a-zA-Z0-9.+-{}]+)}, '{\\frac{\1}{\2}}')
    # Replace LOG10 with log_10
    parsed = replace_capture_group_multiple(parsed, /LOG10\((.+)\)/, '\\log_{10}(\\1)')
    # Convert D to scientific notation
    parsed = replace_capture_group_multiple(parsed, /([0-9.+-]+)[D|E]([0-9+-]+)/, '\1\\times10^{\2}')
    # The only use of ** to indicate exponent is for squared
    parsed = replace_capture_group_multiple(parsed, /\*\*2/, '^{2}')
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

  # rubocop:disable Metrics/MethodLength
  # rubocop:disable Metrics/AbcSize
  def read_reaction(reaction_ids)
    # Parses given reactions from the DB into a hierarchical data structure
    # Ideally this would be done as a Sequel Model rather than manually here
    #
    # Args:
    #   - reaction_ids ([Int]): Array of integers
    #
    # Returns:
    # A list of reactions in the following format:
    #   [
    #     {
    #       ReactionID: <id>,
    #       Rate: '<rate>',
    #       ReactionCategory: '<category>',
    #       Reactants: [...],
    #       Products: [...]
    #     }
    #   ]

    # Extract the constituent parts of a reaction
    reactants = DB[:Reactions]
                .where(ReactionID: reaction_ids)
                .left_join(:Reactants, [:ReactionID])
                .left_join(:Species, Name: :Species)
                .to_hash_groups(:ReactionID)
    products = DB[:Reactions]
               .where(ReactionID: reaction_ids)
               .left_join(:Products, [:ReactionID])
               .left_join(:Species, Name: :Species)
               .to_hash_groups(:ReactionID)
    rxns = DB[:Reactions]
           .from_self(alias: :rxn)
           .where(ReactionID: reaction_ids)
           .left_join(DB[:RatesWeb].from_self(alias: :rw), Rate: :Rate)
           .left_join(DB[:RateTypesWeb].from_self(alias: :rtw), RateTypeWeb: :RateTypeWeb)
           .select(Sequel.lit('rxn.ReactionId, ' \
                              'rxn.ReactionCategory, ' \
                              'rxn.Rate, ' \
                              '\'/\' || rxn.Mechanism || WebRoute AS WebRoute'))
           .to_hash(:ReactionID)

    # And parse into the desired output format
    reaction_ids.map do |id|
      {
        ReactionID: id,
        Rate: rxns[id][:Rate],
        RateURL: rxns[id][:WebRoute],
        Category: rxns[id][:ReactionCategory],
        Products: products[id].map { |x| { Name: x[:Species], Category: x[:SpeciesCategory] } },
        Reactants: reactants[id].map { |x| { Name: x[:Species], Category: x[:SpeciesCategory] } }
      }
    end
  end
  # rubocop:enable Metrics/MethodLength
  # rubocop:enable Metrics/AbcSize

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

  # rubocop:disable Metrics/MethodLength
  # rubocop:disable Metrics/AbcSize
  def traverse_complex_rates(parents)
    # Traverses complex tokenized rates from parents (i.e. KMT04) down to children.
    # Returns in order firstly by parent, and then by child depth
    # (highest depth first, i.e. FCC, KCO, KCI, KRC, NC, FC, KFPAN)
    # This is a breadth-first traversal, finding all root tokens, then all tokens at the next level down, etc...
    #
    # Args:
    #   - parents: Array of strings with Token names to use as initial parents
    #
    # Returns:
    #   - A dataset with 4 columns and 1 row per child token.
    #     - RootToken: The root parent token
    #     - Child: The child's token name
    #     - Definition: The child's rate definition
    #     - Depth: How many branches down the tree from the root parent was this child
    depth = 0
    new_children = DB[:Tokens]
                   .where(Token: parents)
                   .select(Sequel.lit("Token as RootToken, Token as Child, #{depth} as depth"))
    all_tokens = new_children
    # TODO: change to while loop with new children being empty
    loop do
      depth += 1
      new_children = get_children_from_parent(new_children, DB)
                     .select_append(Sequel.lit("#{depth} as depth"))
      break if new_children.empty?

      all_tokens = all_tokens.union(new_children)
    end

    # Get each child's rate Definition and limit each child to highest depth
    # In SQLite when using Max or Min in a grouped select, it only returns the corresponding row with the max or min
    # So no need to add a WHERE clause. Madness.
    all_tokens = all_tokens
                 .distinct
                 .join(DB[:Tokens], Token: :Child)
                 .group_by(:RootToken, :Child, :Definition)
                 .select_append(Sequel.lit('max(depth) as Depth'))
                 .from_self(alias: :all)

    # Identify which root tokens are simple or complex for later ordering
    simple_generic_order = all_tokens
                           .group_and_count(:RootToken)
                           .from_self(alias: :sim)
                           .select_append(Sequel.lit('count > 1 as IsComplex'))

    # Want to order by 3 conditions:
    #   - Whether simple or complex (simple has a tree with depth=1)
    #   - By root parent token
    #   - By depth of child token
    all_tokens
      .join(simple_generic_order, RootToken: :RootToken)
      .order(:IsComplex, :RootToken, Sequel.desc(:depth))
      .from_self(alias: :out)
      .select(:RootToken, :Child, :Definition, :depth)
  end
  # rubocop:enable Metrics/MethodLength
  # rubocop:enable Metrics/AbcSize
end
# rubocop:enable Metrics/BlockLength
