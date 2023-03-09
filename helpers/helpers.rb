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

  def display_reaction(rxn, species)
    # Parses a Reaction dataset into a visual UI
    reactants_parsed = rxn[:Reactants]
                       .map { |x| create_link_from_species_name(x[:Name], x[:Category], species) }
                       .join(' + ')
    prods_parsed = rxn[:Products]
                   .map { |x| create_link_from_species_name(x[:Name], x[:Category], species) }
                   .join(' + ')
    "#{reactants_parsed} -> #{prods_parsed}"
    # TODO: add rate and image in
    # img = "<img class='img-fluid' src='species_images/.png' />"
  end

  def create_link_from_species_name(name, category, species_page)
    # Creates a link to a species page under 2 conditions:
    # 1) It is a VOC, and 2) it is not the species that the current
    # page is displaying.
    if (category == 'VOC') && (name != species_page)
      "<a href='/species/#{name}'>#{name}</a>"
    else
      name.to_s
    end
  end
end
# rubocop:enable Metrics/BlockLength
