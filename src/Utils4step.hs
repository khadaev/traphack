module Utils4step where

import Data
import Changes
import Stuff
import Utils4mon
import Utils4stuff
import Wave
import HealDamage
import Messages
import Colors

import System.Random (StdGen, randomR)
import Data.List (sort)
import qualified Data.Map as M
import qualified Data.Array as A

bIGpAUSE, pAUSE :: Int
bIGpAUSE = 100
pAUSE    = 3

minSnd :: (Ord b) => (a,b) -> (a,b) -> (a,b)
minSnd x y = if snd x > snd y then y else x

minValue :: (Ord k, Ord a) => M.Map k a -> (k, a)
minValue m = foldr1 minSnd $ M.toList m
	
minimumOn :: (Ord b, Ord k) => (a -> b) -> M.Map k a -> (k, a)
minimumOn f m = (k, m M.! k) where
	k = fst $ minValue $ M.map f m

wait :: Int -> Int
wait n = case mod n 10 of
	0 -> bIGpAUSE
	_ -> pAUSE
	
almostTime :: Monster -> Int
almostTime mon = 
	if alive mon
	then time mon
	else 0

updateFirst :: World -> World
updateFirst w = changeMons newUnits w where
	newUnits = (units' w) {
		xF = x,
		yF = y,
		getFirst' = monNew
	}
	((x, y), monNew) = minimumOn almostTime $ units w

newWaveIf :: World -> World
newWaveIf world =
	if (not $ isPlayerNow world) ||
		weigthW world * 3 > wave world
	then newWorld
	else
		if stepsBeforeWave world > 0
		then newWorld
			{stepsBeforeWave = stepsBeforeWave world - 1}
		else if stepsBeforeWave world == 0
		then callUpon world
		else newWorld {stepsBeforeWave = wait $ wave world}
	where
		newWorld = cycleWorld world
		
cycleWorld :: World -> World
cycleWorld w = tempFirst $ actTrapFirst $ regFirst $ cleanFirst 
	$ changeMons newUnits $ addMessages (msgCleanParts monNew) newWorld where
		newUnits = (units' newWorld) {
			xF = x,
			yF = y,
			getFirst' = monNew
		}
		((x, y), monNew) = minimumOn almostTime $ units newWorld
		newWorld = tickFirst w

cleanFirst :: World -> World
cleanFirst w = changeMon (cleanParts $ getFirst w) w

remFirst :: World -> World
remFirst world = updateFirst $ changeMons 
	(deleteU (xFirst world, yFirst world) $ units' world) 
	$ changeAction ' ' world

closestPlayerChar :: Int -> Int -> World -> Maybe (Int, Int)
closestPlayerChar x y w = 
	if M.null yous || abs (x - xP) > xSight || abs (y - yP) > ySight
	then Nothing
	else Just (xP, yP)
	where
	yous = M.filter (\q -> case ai q of
		You -> True
		_ -> False) $ units w
	closest (x1,y1) (x2,y2) = 
		if max (abs $ x1 - x) (abs $ y1 - y) > 
			max (abs $ x2 - x) (abs $ y2 - y)
		then (x2, y2)
		else (x1, y1)
	(xP, yP) = foldr1 closest $ M.keys yous

tempFirst :: World -> World
tempFirst w = changeMon newMon w where
	mon = getFirst w
	newMon = mon {temp = map decMaybe $ temp mon}

decMaybe :: Maybe Int -> Maybe Int
decMaybe Nothing = Nothing
decMaybe (Just 0) = Nothing
decMaybe (Just n) = Just $ n - 1

addDeathDrop :: Monster -> StdGen -> (Monster, StdGen)
addDeathDrop mon g = (changeInv (M.union (inv mon) newDrop) mon, newGen) where
	(newDrop, newGen) = deathDrop (name mon) g

tickFirst :: World -> World
tickFirst w = changeMon (tickFirstMon $ getFirst w) w

listOfValidChars :: (Object -> Bool) -> World -> [Char]
listOfValidChars f world = sort $ M.keys 
	$ M.filter (f . fst) $ inv $ getFirst world
	
doIfCorrect :: (World, Bool) -> Either World String
doIfCorrect (rez, correct) = 
	if correct
	then Left $ newWaveIf rez
	else Left rez

actTrapFirst :: World -> World
actTrapFirst w = addMessage (newMsg, rED) $ changeGen g $ changeMon newMon w where
	x = xFirst w
	y = yFirst w
	mon = getFirst w
	trap = worldmap w A.! (x,y)
	((newMon, g), newMsg) = 
		if trap == FireTrap
		then (dmgRandomElem Fire (Just 8) mon $ stdgen w,
			if name mon == "You"
			then "You are in fire!"
			else name mon ++ " is in fire!")
		else if trap == PoisonTrap
		then (randTemp Poison (5, 15) (mon, stdgen w),
			if name mon == "You"
			then "You were poisoned!"
			else name mon ++ " was poisoned!")
		else if trap == MagicTrap
		then let
			(ind, g') = randomR (0, length wANDS - 1) $ stdgen w
			obj = wANDS !! ind
			(newMon', g'') = act obj (mon, g')
			in ((newMon', g''), msgWand (title obj) (name mon))
		else ((mon, stdgen w), "")

callUpon :: World -> World
callUpon w = changeAction ' ' $ addMessage ("Squad #" 
	++ show (wave w) ++ " landed around you!", rED) 
	$ newWave $ cycleWorld w {stepsBeforeWave = -1}

