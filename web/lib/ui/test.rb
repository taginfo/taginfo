# web/lib/ui/test.rb
class Taginfo < Sinatra::Base

    get! '/test' do
        @title = 'Test'
        erb :'test/index'
    end

end
