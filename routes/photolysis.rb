# frozen_string_literal: true

get '/?:mechanism?/rates/photolysis' do
  @mechanism = params[:mechanism] ? params[:mechanism] : 'mcm'
  @params = DB[:PhotolysisParameters]
            .exclude(l: nil)
  erb :photolysis
end
