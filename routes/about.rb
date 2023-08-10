get '/:mechanism/about/:file' do
  fn = File.join('public', 'static', params[:mechanism], "#{params[:file]}.html")
  # TODO error handle file doesn't exist
  @content = File.read(fn)
  erb :about
end
