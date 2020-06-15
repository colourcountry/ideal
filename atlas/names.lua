--[[
Sprite assignments
==================

0x000000 - 0x0effff - Standard Unicode. Named in CAPITALS.
0x0f0000 - 0x0fffff - PUA A - IDEAL static sprites. Named in lower case.
0x100000 - 0x101fff - PUA B - IDEAL sprites, 2-frame animations
0x102000 - 0x107fff - PUA B - IDEAL sprites, 4-frame animations
0x108000 - 0x10ffff - PUA B - IDEAL sprites, 8-frame animations

--]]

return {
		["border bottom right"]		      =0x0f0000,
		["border bottom"]					      =0x0f0001,
		["border bottom left"]		      =0x0f0002,
	  ["border right"]					      =0x0f0010,
		["border full"]						      =0x0f0011,
		["border left"]						      =0x0f0012,
		["border top right"]			      =0x0f0020,
		["border top"]						      =0x0f0021,
		["border top left"]				      =0x0f0022,
		["brick wall top left"] 	  	  =0x0f0006,
		["brick wall top"]					    =0x0f0007,
		["brick wall top right"]		    =0x0f0008,
		["brick wall left"]				 	    =0x0f0016,
		["brick wall"]							    =0x0f0017,
		["brick wall right"]				    =0x0f0018,
		["brick wall bottom left"] 	    =0x0f0026,
		["brick wall bottom"]				    =0x0f0027,
		["brick wall bottom right"]	    =0x0f0028,

		["1/2 redgehog moving left"]     		=0x100000,
		["2/2 redgehog moving left"]     		=0x100001,
		["1/2 redgehog moving up"]   	  		=0x100002,
		["2/2 redgehog moving up"]   	  		=0x100003,
		["1/2 redgehog moving right"]    		=0x100004,
		["2/2 redgehog moving right"]    		=0x100005,
		["1/2 redgehog moving down"]     		=0x100006,
		["2/2 redgehog moving down"]     		=0x100007,
		["1/2 redgehog facing down"] 	  		=0x100008,
		["2/2 redgehog facing down"] 	  		=0x100009,
}
