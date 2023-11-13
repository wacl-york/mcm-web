# frozen_string_literal: true

module MCM
  # Static functions for exporters
  module Export
    module_function

    # rubocop:disable Metrics/MethodLength, Metrics/ParameterLists, Metrics/AbcSize
    def wrap_lines(words,
                   max_line_length: 68,
                   starting_char: ' ',
                   ending_char: ';',
                   sep: ' ',
                   every_line_start: '',
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
      if words.count.positive?
        out = (out[..-(sep.length + 1)]).to_s # remove last unused separating space if added one
      end
      out = "#{out}#{ending_char}\n"
    end
    # rubocop:enable Metrics/MethodLength, Metrics/ParameterLists, Metrics/AbcSize
  end
end
