# frozen_string_literal: true

get '/:mechanism/rates/photolysis' do
  @params = DB[:PhotolysisParameters]
            .exclude(l: nil)
  erb :photolysis
end
