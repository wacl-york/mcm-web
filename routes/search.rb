# frozen_string_literal: true

get '/:mechanism/search' do
  q = params[:q]
  output = if q.nil?
             nil
           else
             MCM::Search::Basic.search(q, @mechanism)
           end
  content_type :json
  output.all.to_json
end
