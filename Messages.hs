module Messages where

import Data
import Changes
import Utils4objects
import Colors
import Parts

import qualified Data.Map as M
import Data.Array

titleShow :: Object -> String
titleShow x = title x ++ 
	if isWand x
	then " (" ++ show (charge x) ++ ")"
	else if isWeapon x || isArmor x || isLauncher x || isJewelry x
	then " (" ++ (if enchantment x >= 0 then "+" else "") 
		++ show (enchantment x) ++ ")"
	else ""

numToStr :: Int -> String
numToStr t
	| t == 1 = "first"
	| t == 2 = "second"
	| t == 3 = "third"
	| t == 4 = "forth"
	| t == 5 = "fifth"
	| t == 6 = "sixth"
	| t == 7 = "seventh"
	| t == 8 = "eighth"
	| t == 9 = "ninth"
	| t == 10 = "tenth"
	| t == 11 = "eleventh"
	| t == 12 = "twelfth"
	| t == 13 = "thirteenth"
	| t == 14 = "fourteenth"
	| t == 15 = "fifteenth"
	| t == 16 = "sixteenth"
	| t == 17 = "seventeenth"
	| t == 18 = "eighteenth"
	| t == 19 = "nineteenth"
	| t == 20 = "twentieth"
	| t == 30 = "thirtieth"
	| t == 40 = "fortieth"
	| t == 50 = "fiftieth"
	| t == 60 = "sixtieth"
	| t == 70 = "seventieth"
	| t == 80 = "eigthieth"
	| t == 90 = "ninetieth"
	| t < 100 = decToStr (div t 10) ++ "-" ++ numToStr (mod t 10)
	| otherwise = show t
	
decToStr :: Int -> String
decToStr t
	| t == 2 = "twenty"
	| t == 3 = "thirty"
	| t == 4 = "forty"
	| t == 5 = "fifty"
	| t == 6 = "sixty"
	| t == 7 = "seventy"
	| t == 8 = "eighty"
	| t == 9 = "ninety"
	| otherwise = error "wrong number of tens"

capitalize :: String -> String
capitalize [] = []
capitalize (x:xs) = toEnum (fromEnum x - fromEnum 'a' + fromEnum 'A') : xs

ending :: World -> String
ending world =
	if isPlayerNow world
	then " "
	else "s "

addArticle :: String -> String
addArticle str = 
	if str == ""
	then ""
	else if (elem (head str) "aeiouAEIOU")
	then "an " ++ str
	else "a " ++ str

lostMsg :: String -> String -> String
lostMsg monName partName =
	if partName == "Main"
	then ""
	else monName ++ " lost " ++ addArticle partName ++ "."
	
maybeAddMessage :: String -> World -> World
maybeAddMessage msg w = 
	if isPlayerNow w
	then addMessage (msg, yELLOW) w
	else w
	
addNeutralMessage :: String -> World -> World
addNeutralMessage msg w = 
	if isPlayerNow w
	then addMessage (msg, gREEN) w
	else addMessage (msg, yELLOW) w
	
addDefaultMessage :: String -> World -> World
addDefaultMessage msg w = addMessage (msg, dEFAULT) w

msgWand :: String -> String -> String
msgWand title' name' = 
	case title' of
		"wand of striking" -> prefixPast ++ "struck!"
		"wand of stupidity" -> name' ++ " feel" ++ end ++ " stupid!"
		"wand of speed" -> prefix ++ "suddenly moving faster!"
		"wand of radiation" -> prefix ++ "infected by radiation!"
		"wand of psionic blast" -> name' ++ " feel" ++ end ++ 
			" that " ++ (if isYou then "your" else "its") ++ " brains melt!"
		"wand of poison" -> prefixPast ++ "poisoned!"
		"wand of slowing" -> prefix ++ "suddenly moving slowly!"
		"wand of stun" -> prefix ++ "stunned!"
		_ -> error "unknown wand"
	where
	isYou = name' == "You"
	prefix = if isYou then "You are " else name' ++ " is "
	prefixPast = if isYou then "You were " else name' ++ " was "
	end = if isYou then "" else "s"

attackName :: Elem -> String
attackName Fire = "burn"
attackName Poison' = "poison"
attackName Cold = "freeze"

getInfo :: World -> World
getInfo w = changeAction ' ' $ 
	addDefaultMessage msg w where msg = infoMessage w

infoMessage :: World -> String
infoMessage w = 
	if xInfo w < 0 || yInfo w < 0 || xInfo w > maxX || yInfo w > maxY
	then "This cell doesn't exist!"
	else if abs (xInfo w - xFirst w) > xSight || abs (yInfo w - yFirst w) > ySight
	then "You can't see this cell!"
	else if last str == ' ' then init str else str where
	x = xInfo w
	y = yInfo w
	terr = worldmap w ! (x, y)
	un = M.lookup (x, y) $ units w
	objs = filter (\(x',y',_,_) -> x' == x && y' == y) $ items w
	terrInfo = "Terrain: " ++ show terr ++ ". "
	monInfo = case un of
		Nothing -> ""
		Just mon -> "Monster: " ++ name mon ++ ". Parts: " ++ 
			(foldr (++) [] $ map (\p -> partToStr (kind p) ++ "; ") $ parts mon)
	objsInfo = case objs of
		[] -> ""
		_ -> (++) "Objects: " $ foldr (++) [] $ 
			map (\(_,_,i,n) -> titleShow i ++ 
			(if n == 1 then "; " else " (" ++ show n ++ "); ")) objs
	str = terrInfo ++ monInfo ++ objsInfo
