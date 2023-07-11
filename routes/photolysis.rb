# frozen_string_literal: true

get '/?:mechanism?/rates/photolysis' do
  @mechanism = params[:mechanism] || settings.DEFAULT_MECHANISM
  @params = DB[:PhotolysisParameters]
            .exclude(l: nil)
  erb :photolysis
end
