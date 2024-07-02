# frozen_string_literal: true

get '/:mechanism/about/:file' do
  fn = File.join('public', 'static', params[:mechanism], "#{params[:file]}.html")
  @content = File.file?(fn) ? File.read(fn) : "<h1>Error</h1><p>Unknown page '#{params[:file]}'.</p>"
  @title = "#{params[:mechanism]} - #{params[:file].capitalize}"
  erb :about
end
