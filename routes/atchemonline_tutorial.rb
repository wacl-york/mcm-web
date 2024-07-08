# frozen_string_literal: true

get '/:mechanism/atchemonline/:file' do
  fn = File.join('public', 'static', 'atchemonline_tutorial', "#{params[:file]}.html")
  @content = File.file?(fn) ? File.read(fn) : "<h1>Error</h1><p>Unknown page '#{params[:file]}'.</p>"
  @title = "#{params[:mechanism]} - AtChemOnline Tutorial"
  erb :about
end
