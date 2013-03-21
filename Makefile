base_items = herbs ores meats elemental cloth enchanting_mats leather gem_drops other_trade_items fished_items vendor_items misc_foods jewelcrafting_mats drops devices weapons quest parts
professions = alchemy blacksmithing enchanting engineering inscription jewelcrafting leatherworking mining tailoring cooking first_aid
ranks = apprentice journeyman expert artisan master grand_master illustrious zen
root = wowhead

base_targets = $(addsuffix .yml,$(addprefix $(root)/,$(base_items)))
prof_targets = $(addsuffix .yml,$(addprefix $(root)/,$(foreach prof,$(professions),$(addprefix $(prof)/,$(ranks)))))
prof_dirs = $(foreach prof,$(professions),$(root)/$(prof)/$(rank))

all: wowhead $(base_targets) $(prof_targets)

%.yml:
	mkdir -p $(dir $@)
	./load_wowhead.rb $(wordlist 2,3,$(subst /, ,$(basename $@))) > $@


wowhead:
	mkdir -p $@

