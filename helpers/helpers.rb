# frozen_string_literal: true

helpers do
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
end
