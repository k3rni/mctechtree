require 'i18n'
require 'sinatra'

I18n.load_path += Dir[File.join(File.dirname(__FILE__), 'locale', '*.yml')]

class TechTreeApp < Sinatra::Base
  
  register Sinatra::Twitter::Bootstrap::Assets
  use Rack::CommonLogger

  def self.db= value
    @@db = value
  end

  helpers do
    def recipe_counters
      @@db.each.group_by(&:group).map {|key, g| [key, g.size]}
    end

    def item_names
      @@db.to_a.map &:name
    end
  end
  get '/' do
    haml :index, layout: :base
  end

  post '/solve' do
    items = params[:items]
    solutions = items.map do |name|
      ItemResolver.new(@@db.find(name), 1).resolve
    end
    solver = Solver.new(solutions).solve

    haml :solution, layout: :base, locals: {raw: solver.raw_resources,
      crafts: solver.craft_sequence, targets: items}
  end
end
