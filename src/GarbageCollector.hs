module GarbageCollector where

import Data
import Monsters
import Random
import Move
import Changes
import ObjectOverall
import Parts

import Data.List (minimumBy)
import Data.Function (on)
import Data.Maybe (fromJust)
import UI.HSCurses.Curses (Key (..))

collectorAI :: AIfunc
collectorAI _ _ world = 
	if isItemHere
	then fromJust $ fst $ pickFirst $ foldr ($) world $ map (changeChar . KeyChar) alphabet
	else moveFirst dx dy world
	where
		isItemHere = not $ null $ filter (\(x, y, _, _) -> x == xNow && y == yNow) $ items world
		xNow = xFirst world
		yNow = yFirst world
		(xItem, yItem, _, _) = minimumBy cmp $ items world
		dist x y = max (x - xNow) (y - yNow)
		cmp = on compare (\(x, y, _, _) -> dist x y)
		(dx, dy) = 
			if null $ items world
			then (0, 0)
			else (signum $ xItem - xNow,
				  signum $ yItem - yNow)

getGarbageCollector :: MonsterGen		  
getGarbageCollector = getMonster collectorAI
	[(getBody 1, (20, 40)), 
	 (getHead 1, (10, 30)),
	 (getLeg  1, ( 8, 12)),
	 (getLeg  1, ( 8, 12)),
	 (getArm  1, ( 8, 12)),
	 (getArm  1, ( 8, 12))]
	 "Garbage collector" (dices (2,4) 0.4) emptyInv 100