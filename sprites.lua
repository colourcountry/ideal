--[[
Sprite assignments
==================

0x000000 - 0x0effff - Standard Unicode
0x0f0000 - 0x0fffff - PUA A - IDEAL static sprites
0x100000 - 0x101fff - PUA B - IDEAL sprites, 2-frame animations
0x102000 - 0x107fff - PUA B - IDEAL sprites, 4-frame animations
0x108000 - 0x10ffff - PUA B - IDEAL sprites, 8-frame animations

--]]

return {
	names = {
		-- emoji
		-- food-fruit
		["grapes"]								=0x01f347,
		["melon"]									=0x01f348,
		["watermelon"]						=0x01f349,
		["tangerine"]							=0x01f34a,
		["lemon"]									=0x01f34b,
		["banana"]								=0x01f34c,
		["pineapple"]							=0x01f34d,
		["mango"]								  =0x01f96d,
		["red apple"]							=0x01f34e,
		["green apple"]						=0x01f34f,
		["pear"]									=0x01f350,
		["peach"]									=0x01f351,
		["cherries"]							=0x01f352,
		["strawberry"]						=0x01f353,
		["blueberries"]						=0x01fad0,
		["kiwi fruit"]						=0x01f95d,
		["tomato"]								=0x01f345,
		["olive"]									=0x01fad2,
		["coconut"]								=0x01f965,
		["brick"]									=0x01f9f1,
		-- 0f00 wall tiles
		["border bottom right"]		=0x0f0000,
		["border bottom"]					=0x0f0001,
		["border bottom left"]		=0x0f0002,
		["brick wall left corner"] 	=0x0f0006,
		["brick wall face"]					=0x0f0007,
		["brick wall right corner"]	=0x0f0008,
	  ["border right"]					=0x0f0010,
		["border full"]						=0x0f0011,
		["border left"]						=0x0f0012,
		["border top right"]			=0x0f0020,
		["border top"]						=0x0f0021,
		["border top left"]				=0x0f0022,
		-- 1000 characters animated by horizontal flip
		["redgehog"]              =0x100000
	},

	groups = {
		["food-fruit"] = {
			"grapes", "melon", "watermelon", "tangerine", "lemon", "banana",
			"pineapple", "mango",	"red apple", "green apple", "pear", "peach",
			"cherries", "strawberry", "blueberries", "kiwi fruit", "tomato",
			"olive", "coconut",
		}
	}
}
