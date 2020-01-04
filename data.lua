local util = require("util")

local sensor_icon = "__IndustrialRevolution__/graphics/icons/64/sensor.png"
local item_template = "__miniloader__/graphics/item/template.png"
local item_filter_template = "__miniloader__/graphics/item/filter-template.png"
local item_mask = "__miniloader__/graphics/item/mask.png"

local entity_template = "__miniloader__/graphics/entity/template.png"
local entity_hr_template = "__miniloader__/graphics/entity/hr-template.png"
local entity_mask = "__miniloader__/graphics/entity/mask.png"
local entity_hr_mask = "__miniloader__/graphics/entity/hr-mask.png"
local entity_filter_template = "__miniloader__/graphics/entity/filter-template.png"
local entity_filter_hr_template = "__miniloader__/graphics/entity/hr-filter-template.png"
local entity_filter_mask = "__miniloader__/graphics/entity/mask.png"
local entity_filter_hr_mask = "__miniloader__/graphics/entity/hr-mask.png"

local recipe_ingredients = {
	["chute-miniloader"] = {
	    {"copper-chassis-small", 1},
	    {"wood-beam", 2},
	    {"tin-rod", 4},
	    {"tin-gear-wheel", 2},
	},
	["miniloader"] = {
	    {"copper-chassis-small", 1},
	    {"inserter", 2},
	    {"tin-rod", 4},
	    {"tin-gear-wheel", 2},
	},
	["fast-miniloader"] = {
	    {"iron-chassis-small", 1},
	    {"fast-inserter", 2},
	    {"iron-stick", 4},
	    {"iron-gear-wheel", 2},
	},
	["express-miniloader"] = {
	    {"steel-chassis-small", 1},
	    {"stack-inserter", 2},
	    {"steel-rod", 4},
	    {"steel-gear-wheel", 2},
	},
}

local icons_tint = {}

local function add_tint(name, tint)
	icons_tint[name] = tint
	icons_tint[name .. "-inserter"] = tint
	icons_tint[name .. "-loader"] = tint
end

add_tint("filter-miniloader", {
	r=0.75,
	g=0.25,
	b=0.00,
})
add_tint("fast-filter-miniloader", {
	r=0.50,
	g=0.15,
	b=0.75,
})
add_tint("express-filter-miniloader", {
	r=0.75,
	g=0.75,
	b=0.75,
})

local function string_ends_with(text, ends_with)
	return string.sub(text, -string.len(ends_with)) == ends_with
end

local function match_miniloader_name(name, suffix)
	local prefix = nil
	local is_filter = false

	if suffix == nil then
		suffix = ""
	end

	if name == ("miniloader" .. suffix) then
		prefix = ""
	elseif name == ("filter-miniloader" .. suffix) then
		prefix = ""
		is_filter = true
	elseif string_ends_with(name, "-miniloader" .. suffix) then
		is_filter = string_ends_with(name, "-filter-miniloader" .. suffix)
		prefix = string.sub(name, 1, string.len(name) - (is_filter and string.len("-filter-miniloader" .. suffix) or string.len("-miniloader" .. suffix)) + 1)
	end

	return prefix, is_filter
end

local function create_filter_icons(filter_recipe, nonfilter_recipe)
	local tint = icons_tint[filter_recipe.name .. "-inserter"]
	local can_set_tint = tint ~= nil and #filter_recipe.icons >= 2 and filter_recipe.icons[1].icon == item_filter_template and filter_recipe.icons[2].icon == item_mask
	local icons

	if can_set_tint then
		icons = util.table.deepcopy(filter_recipe.icons)
		icons[1].icon = item_template
		icons[2].tint = tint
	else
		icons = util.table.deepcopy(nonfilter_recipe.icons)
	end

	table.insert(icons, {
		icon = sensor_icon,
		icon_size = 64,
		scale = 0.25,
		shift = {-8, 8}
	})

	return icons
end


local function is_entity_expected_structure(entity)
	if entity.structure == nil then
		return false
	end

	local direction_in = entity.structure.direction_in
	local direction_out = entity.structure.direction_out

	-- Check that the expected number of sheets exists
	if direction_in == nil or #direction_in.sheets < 2 or direction_out == nil or #direction_out.sheets < 2 then
		return false
	end

	local in_sheet_template = entity.structure.direction_in.sheets[1]
	local out_sheet_template = entity.structure.direction_in.sheets[1]

	-- Check standard templates
	if in_sheet_template.filename ~= entity_filter_template or out_sheet_template.filename ~= entity_filter_template then
		return false
	end

	-- Check HR templates
	if in_sheet_template.hr_version == nil or in_sheet_template.hr_version.filename ~= entity_filter_hr_template then
		return false
	end
	if out_sheet_template.hr_version == nil or out_sheet_template.hr_version.filename ~= entity_filter_hr_template then
		return false
	end
	
	local in_sheet_mask = entity.structure.direction_in.sheets[2]
	local out_sheet_mask = entity.structure.direction_in.sheets[2]

	-- Check standard masks
	if in_sheet_mask.filename ~= entity_filter_mask or out_sheet_mask.filename ~= entity_filter_mask then
		return false
	end

	-- Check HR masks
	if in_sheet_mask.hr_version == nil or in_sheet_mask.hr_version.filename ~= entity_filter_hr_mask then
		return false
	end
	if out_sheet_mask.hr_version == nil or out_sheet_mask.hr_version.filename ~= entity_filter_hr_mask then
		return false
	end

	return true
end

local function is_entity_expected_platform_picture(entity)
	if entity.platform_picture == nil or entity.platform_picture.sheets == nil or #entity.platform_picture.sheets < 2 then
		return false
	end

	local template = entity.platform_picture.sheets[1]
	local mask = entity.platform_picture.sheets[2]

	-- Check standard and HR templates
	if template.filename ~= entity_filter_template or template.hr_version == nil or template.hr_version.filename ~= entity_filter_hr_template then
		return false
	end

	-- Check standard and HR masks
	if mask.filename ~= entity_filter_mask or mask.hr_version == nil or mask.hr_version.filename ~= entity_filter_hr_mask then
		return false
	end

	return true
end

if mods["miniloader"] and mods["IndustrialRevolution"] then

	for _, recipe in pairs(data.raw.recipe) do
		if recipe_ingredients[recipe.name] ~= nil then
			recipe.ingredients = recipe_ingredients[recipe.name]
		end

		local prefix, is_filter = match_miniloader_name(recipe.name)

		if is_filter then
			local nonfilter_recipe = data.raw.recipe[prefix .. "miniloader"]
			if nonfilter_recipe ~= nil then

				if recipe_ingredients[recipe.name] == nil then
					recipe.ingredients = {
						{ nonfilter_recipe.name, 1 },
						{ "sensor", 1 }
					}
				end

				if nonfilter_recipe.order ~= nil then
					recipe.order = nonfilter_recipe.order .. "-filter"
				end

				if nonfilter_recipe.icons ~= nil then
					recipe.icons = create_filter_icons(recipe, nonfilter_recipe)
				end
			end
		end
	end

	for _, item in pairs(data.raw.item) do
		local prefix, is_filter = match_miniloader_name(item.name)

		if is_filter then
			local nonfilter_item = data.raw.item[prefix .. "miniloader"]
			if nonfilter_item ~= nil then
				if nonfilter_item.order ~= nil then
					item.order = nonfilter_item.order .. "-filter"
				end

				if nonfilter_item.icons ~= nil then
					item.icons = create_filter_icons(item, nonfilter_item)
				end
			end
		end
	end

	for _, loader in pairs(data.raw.loader) do
		local prefix, is_filter = match_miniloader_name(loader.name, "-loader")

		if is_filter then
			local nonfilter_loader = data.raw.loader[prefix .. "miniloader-loader"]
			if nonfilter_loader ~= nil then
				if nonfilter_loader.order ~= nil then
					loader.order = nonfilter_loader.order .. "-loader"
				end

				if nonfilter_loader.icons ~= nil then
					loader.icons = create_filter_icons(loader, nonfilter_loader)
				end

				local tint = icons_tint[loader.name]

				if tint ~= nil and is_entity_expected_structure(loader) then
					-- Set template to normal
					loader.structure.direction_in.sheets[1].filename = entity_template
					loader.structure.direction_in.sheets[1].hr_version.filename = entity_hr_template
					loader.structure.direction_out.sheets[1].filename = entity_template
					loader.structure.direction_out.sheets[1].hr_version.filename = entity_hr_template

					-- Set mask to normal
					loader.structure.direction_in.sheets[2].filename = entity_mask
					loader.structure.direction_in.sheets[2].hr_version.filename = entity_hr_mask
					loader.structure.direction_out.sheets[2].filename = entity_mask
					loader.structure.direction_out.sheets[2].hr_version.filename = entity_hr_mask

					-- Adjust tint of mask
					loader.structure.direction_in.sheets[2].tint = tint
					loader.structure.direction_in.sheets[2].hr_version.tint = tint
					loader.structure.direction_out.sheets[2].tint = tint
					loader.structure.direction_out.sheets[2].hr_version.tint = tint
				end
			end
		end
	end

	for _, inserter in pairs(data.raw.inserter) do
		local prefix, is_filter = match_miniloader_name(inserter.name, "-inserter")

		if is_filter then
			local nonfilter_inserter = data.raw.inserter[prefix .. "miniloader-inserter"]
			if nonfilter_inserter ~= nil then

				if nonfilter_inserter.order ~= nil then
					inserter.order = nonfilter_inserter.order .. "-filter"
				end

				if nonfilter_inserter.icons ~= nil then
					inserter.icons = create_filter_icons(inserter, nonfilter_inserter)
				end

				local tint = icons_tint[inserter.name]

				if tint ~= nil and is_entity_expected_platform_picture(inserter) then
					-- Set template to normal
					inserter.platform_picture.sheets[1].filename = entity_template
					inserter.platform_picture.sheets[1].hr_version.filename = entity_hr_template

					-- Set mask to normal
					inserter.platform_picture.sheets[2].filename = entity_mask
					inserter.platform_picture.sheets[2].hr_version.filename = entity_hr_mask

					-- Adjust tint of mask
					inserter.platform_picture.sheets[2].tint = tint
					inserter.platform_picture.sheets[2].hr_version.tint = tint
				end
			end
		end
	end
end
