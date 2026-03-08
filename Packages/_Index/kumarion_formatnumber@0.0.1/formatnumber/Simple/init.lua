-- Configuration
-- The suffixes for abbreviation in every power of thousands.
local COMPACT_SUFFIX = {
	"K",    -- Thousand (1e3)
	"M",    -- Million (1e6)
	"B",    -- Billion (1e9)
	"T",    -- Trillion (1e12)
	"Qd",   -- Quadrillion (1e15)
	"Qn",   -- Quintillion (1e18)
	"Sx",   -- Sextillion (1e21)
	"Sp",   -- Septillion (1e24)
	"Oc",   -- Octillion (1e27)
	"No",   -- Nonillion (1e30)
	"Dc",   -- Decillion (1e33)
	"UDc",  -- Undecillion (1e36)
	"DDc",  -- Duodecillion (1e39)
	"TDc",  -- Tredecillion (1e42)
	"QdDc", -- Quattuordecillion (1e45)
	"QnDc", -- Quindecillion (1e48)
	"SxDc", -- Sexdecillion (1e51)
	"SpDc", -- Septendecillion (1e54)
	"OcDc", -- Octodecillion (1e57)
	"NoDc", -- Novemdecillion (1e60)
	"Vg",   -- Vigintillion (1e63)
	"UVg",  -- Unvigintillion (1e66)
	"DVg",  -- Duovigintillion (1e69)
	"TVg",  -- Trevigintillion (1e72)
	"QdVg", -- Quattuorvigintillion (1e75)
	"QnVg", -- Quinvigintillion (1e78)
	"SxVg", -- Sexvigintillion (1e81)
	"SpVg", -- Septenvigintillion (1e84)
	"OcVg", -- Octovigintillion (1e87)
	"NoVg", -- Novemvigintillion (1e90)
	"Tg",   -- Trigintillion (1e93)
	"UTg",  -- Untrigintillion (1e96)
	"DTg",  -- Duotrigintillion (1e99)
	"TTg",  -- Tretrigintillion (1e102)
}
local CACHED_SKELETON_SETTINGS = true
--

local MainAPI = require(script.Parent.Main)
local FormatNumberSimpleAPI = { }

local SKELETON_CACHE = if CACHED_SKELETON_SETTINGS then { } else nil
local COMPACT_SKELETON_CACHE = if CACHED_SKELETON_SETTINGS then { } else nil

function FormatNumberSimpleAPI.Format(value: number, skeleton: string?): string
	local success
	local formatter = nil

	assert(type(value) == "number", "Value provided must be a number")

	if skeleton == nil then
		skeleton = ""
	end
	assert(type(skeleton) == "string", "Skeleton provided must be a string")

	if CACHED_SKELETON_SETTINGS then
		formatter = SKELETON_CACHE[skeleton]
	end

	if not formatter then
		success, formatter =
			MainAPI.NumberFormatter.forSkeleton(skeleton)
		assert(success, formatter :: string)

		if CACHED_SKELETON_SETTINGS then
			SKELETON_CACHE[skeleton] = formatter
		end
	end

	return (formatter :: MainAPI.NumberFormatter):Format(value)
end

function FormatNumberSimpleAPI.FormatCompact(value: number, skeleton: string?): string
	local success
	local formatter = nil

	assert(type(value) == "number", "Value provided must be a number")

	if skeleton == nil then
		skeleton = ""
	end
	assert(type(skeleton) == "string", "Skeleton provided must be a string")

	if CACHED_SKELETON_SETTINGS then
		formatter = COMPACT_SKELETON_CACHE[skeleton]
	end

	if not formatter then
		success, formatter =
			MainAPI.NumberFormatter.forSkeleton(skeleton)
		assert(success, formatter :: string)

		formatter = (formatter :: MainAPI.NumberFormatter)
			:Notation(MainAPI.Notation.compactWithSuffixThousands(COMPACT_SUFFIX))

		if CACHED_SKELETON_SETTINGS then
			COMPACT_SKELETON_CACHE[skeleton] = formatter
		end
	end

	assert(#COMPACT_SUFFIX ~= 0, "Please provide the suffix abbreviations for FormatCompact at the top of the Simple ModuleScript")

	return formatter:Format(value)
end

return table.freeze(FormatNumberSimpleAPI)