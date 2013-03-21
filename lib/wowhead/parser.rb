module Wowhead
  class << self
    def lookup_item itemlist, objid
      return nil if objid.nil?
      itemlist[objid]['name_enus']
    end

    def format_reagents reagent_list
      reagent_list.map do |item, count|
        if count == 1
          item
        else
          "#{item}*#{count}"
        end
      end
    end

    def parse_recipes objects, items, include_noncreating=false
      objects.map do |obj|
        itemnum, count, _x = obj['creates']
        # metadata = extract_recipe_metadata obj
        result_name = lookup_item items, itemnum
	if result_name.nil? && include_noncreating
		result_name = obj['name'].slice(1..-1)
		count = 1
	else
		next
	end
        reagents = obj['reagents'].to_a.map do |itemid, num|
          [lookup_item(items, itemid), num]
        end
	next if reagents.empty?
        {result_name => { 
		makes: count, 
		ingredients: format_reagents(reagents), 
		# meta: metadata.stringify_keys 
		}.stringify_keys
	}
      end.compact
    end

    def parse_objects objects, extra, zones
        objects.map do |obj|
            key = obj['id']
            item = extra[key] || {} # niema to niema
            # puts "K #{key} O #{obj} X #{item}"
            name = item['name_enus'] || obj['name']
            if name =~ /^[0-9](.*)/
                name = $1
            end
            info = {
                level: obj['level'],
            }
            # TODO: url
            # info[:url] = item_url(item['id']).to_s if item['id']
            info[:quality] = QUALITY[item['quality']].to_s if item['quality']
            info[:sources] = list_sources(obj['source']) if obj['source']
            info[:location] = list_locations(zones, item['location']) if item['location'] && zones
            info[:req_level] = item['reqlevel'] if item['reqlevel']
            info[:skill] = item['skill'] if item['skill']
            # TODO: sourcemore
            {name => info.stringify_keys}
        end
    end

    def parse_herbs raw_herbs, zones
      raw_herbs.map do |obj|
        name = obj['name']
        meta = { 
          skill: obj['skill'], 
          location: obj['location'].to_a.map { |z| zones[z]['name'] rescue nil }.compact
        }
        {name => {cost: 1}.merge(meta).stringify_keys}
      end
    end

    def parse_zones zonedefs
      Hash[zonedefs.map do |zone|
        [zone['id'], { 'name' => zone['name'] }]
        # reszta? może, na razie zbędne
      end]
    end

    def list_sources srclist
        srclist.map {|srcid| Wowhead::SOURCES[srcid] }.compact.map(&:to_s)
    end

    def list_locations zones, srclist
        srclist.map { |zoneid| zones[zoneid]['name'] rescue nil }.compact
    end

    def merge_hl hash, list, hkey, lkey
        result = {}
        list.map do |e|
            key = hash.select { |k, v| v[hkey] == e[lkey] }.keys.first
            old = hash[key]
            if old
                result[key] = old.merge(e)
            else
                result[key] = e
            end
        end
        result
    end

  end
end
