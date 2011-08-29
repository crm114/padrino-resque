class ResqueWeb < Padrino::Application
  register Padrino::Rendering
  register Padrino::Mailer
  register Padrino::Helpers

  use Rack::Auth::Basic, "Restricted Area" do |username, password|
    [username, password] == ['admin', 'admin']
  end

  enable :sessions


  ResqueWeb.controllers  do

  
    get "/?" do
      redirect url_path(:overview)
    end

    %w( overview workers ).each do |page|
      get "/#{page}.poll" do
        show_for_polling(page)
      end

    get "/#{page}/:id.poll" do
      show_for_polling(page)
      end
    end

    %w( overview queues working workers key ).each do |page|
      get "/#{page}" do
        show page
      end

      get "/#{page}/:id" do
        show page
      end
    end

    post "/queues/:id/remove" do
      Resque.remove_queue(params[:id])
      redirect u('queues')
    end

    get "/failed" do
      if Resque::Failure.url
        redirect Resque::Failure.url
      else
        show :failed
      end
    end

    post "/failed/clear" do
      Resque::Failure.clear
      redirect u('failed')
    end

    get "/failed/requeue/:index" do
      Resque::Failure.requeue(params[:index])
      if request.xhr?
        return Resque::Failure.all(params[:index])['retried_at']
      else
        redirect u('failed')
      end
    end

    get "/failed/remove/:index" do
      Resque::Failure.remove(params[:index])
      redirect u('failed')
    end

    get "/stats" do
      redirect url_path("/stats/resque")
    end

    get "/stats/:id" do
      show :stats
    end

    get "/stats/keys/:key" do
      show :stats
    end

    get "/stats.txt" do
      info = Resque.info

      stats = []
      stats << "resque.pending=#{info[:pending]}"
      stats << "resque.processed+=#{info[:processed]}"
      stats << "resque.failed+=#{info[:failed]}"
      stats << "resque.workers=#{info[:workers]}"
      stats << "resque.working=#{info[:working]}"

      Resque.queues.each do |queue|
        stats << "queues.#{queue}=#{Resque.size(queue)}"
      end

      content_type 'text/html'
      stats.join "\n"
    end

    def resque
      Resque
    end

    def self.tabs
      @tabs ||= ["Overview", "Working", "Failed", "Queues", "Workers", "Stats"]
    end
  end
end