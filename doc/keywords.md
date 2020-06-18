# Keyword reference 

## ABS 
No help for this. 

## API 
No help for this. 

## BLOCK 
No help for this. 

## BORDER 
No help for this. 

## BOX 
No help for this. 

## CEIL 
Return the next higher integer to the number supplied.
```
@ CEIL(2.2)
3
@ CEIL(-0.5)
0
```
 

## CHARAT 
No help for this. 

## CLS 
Clear the screen to black.
 

## COLOUR 
Set the current colour.
```
@ COLOUR(13) -- White colour.
```

The defined colours are
```
0 - red
1 - orange-red
2 - orange
3 - yellow
4 - chartreuse
5 - green
6 - turquoise
7 - cyan
8 - sky blue
9 - blue
10 - purple
11 - plum
12 - pink
13 - white
14 - grey
15 - brown
```
 

## COS 
Cosine function. 

## DAILY 
No help for this. 

## DISC 
No help for this. 

## DRAG 
No help for this. 

## DRAWFIELD 
No help for this. 

## EJECT 
No help for this. 

## ENT 
No help for this. 

## ERROR 
No help for this. 

## EXEC 
No help for this. 

## FIELD 
No help for this. 

## FLR 
Return the next lower integer to the number supplied.
```
@ FLR(4.6)
4
@ FLR(-8.1)
-9
```
 

## GO 
No help for this. 

## H 
The screen height, in graphics units.
```
PRINT("Left",H/2,0)
```
 

## HELP 
No help for this. 

## IS 
No help for this. 

## ITEMS 
No help for this. 

## KEY 
No help for this. 

## KEYWORDS 
No help for this. 

## L 
No help for this. 

## LOAD 
No help for this. 

## LOG 
No help for this. 

## LOOP 
No help for this. 

## LOWER 
No help for this. 

## MAP 
No help for this. 

## MAX 
No help for this. 

## MEMORY 
No help for this. 

## MENU 
No help for this. 

## MID 
No help for this. 

## MIN 
No help for this. 

## MODE 
No help for this. 

## MODEL 
{ [1] = IDEAL-5,}  

## POLAR 
No help for this. 

## POST 
No help for this. 

## PRINT 
No help for this. 

## PRINTLINES 
No help for this. 

## RANDOMIZE 
No help for this. 

## RELEASE 
No help for this. 

## RESET 
No help for this. 

## RESTART 
No help for this. 

## RING 
No help for this. 

## RND 
No help for this. 

## S 
The width or height of a sprite, in graphics units.

IDEAL sprites are always square.
 

## SAVE 
No help for this. 

## SIN 
Sine function. 

## SORT 
No help for this. 

## SPLIT 
No help for this. 

## SPR 
No help for this. 

## SPRCODE 
No help for this. 

## SPRGROUP 
No help for this. 

## SQRT 
No help for this. 

## STR 
Convert an object to a string.
```
@ STR(5)
"5"
```
 

## T 
The number of frames elapsed since the current MODE started up.

The IDEAL machine runs at 30 frames per second, but if you want to measure real times, use TIMER instead.
 

## TAU 
2π, the period of the sine and cosine functions. 

## TIMER 
Manage the internal timer.

The timer starts at 999 and counts down in seconds.
```
@ TIMER()
994.4867219
```

Supply a number as a parameter to set the timer to this many seconds.
```
@ TIMER(60)
60
```

If 999 seconds elapse within the same MODE, the IDEAL machine will forcibly restart that MODE.
You can use the default timer to help you prevent this happening.
Resetting the timer does not affect this feature.
 

## TITLE 
Paint a value in large letters.

Parameters:

1. The value to paint.
2. The X coordinate to paint at, in graphics units.
3. The Y coordinate to paint at, in graphics units.
4. _(Optional, default 0)_ -1 to anchor the right side of the text to the coordinates supplied; 0 for the centre; 1 for the left side.
5. _(Optional, default 0)_ -1 to anchor the bottom of the text to the coordinates supplied; 0 for the centre; 1 for the top.

```
PRINT("Centred text",x,y)
```
 

## TOUCH 
No help for this. 

## UPPER 
No help for this. 

## URL 
No help for this. 

## W 
The screen width, in graphics units.
```
PRINT("Top",W/2,0,0)
```
 
