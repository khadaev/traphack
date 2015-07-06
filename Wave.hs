module Wave where

import Data
import Monsters
import MonsterList
import Ivy
import Forgotten
import Utils4mon

import System.Random (StdGen, randomR)
import qualified Data.Map as M

nameFromGen :: MonsterGen -> String
nameFromGen mgen = name $ fst $ mgen lol

addWaveBy :: ([MonsterGen] -> (Units, StdGen) -> (Units, StdGen)) 
	-> Int -> (Units, StdGen) -> (Units, StdGen)
addWaveBy fun n (uns, g) = 
	if null ms
	then addWave n (uns, g')
	else fun ms (uns, g')
	where
		(ms, g') = genWave n g

addWave, addWaveFull :: Int -> (Units, StdGen) -> (Units, StdGen)
addWave = addWaveBy addMonsters
addWaveFull = addWaveBy addMonstersFull
		
weigthW :: World -> Int
weigthW w = M.foldr (+) 0 $ M.map (weigth . name) $ M.filter isSoldier 
	$ M.filterWithKey (\(x, y) _ -> abs (x - xPlayer) <= xSight 
	&& abs (y - yPlayer) <= ySight) $ units w where
	[((xPlayer, yPlayer), _)] = filter (\(_,m) -> name m == "You") 
		$ M.toList $ units w
		
weigth :: String -> Int
weigth "Bat"             = 1
weigth "Homunculus"      = 3
weigth "Beetle"          = 5
weigth "Ivy"             = 3
weigth "Accelerator"     = 6
weigth "Floating eye"    = 5
weigth "Hunter"          = 7
weigth "Troll"           = 7
weigth "Worm"            = 5
weigth "Red dragon"      = 10
weigth "Green dragon"    = 10
weigth "White dragon"    = 10
weigth "Forgotten beast" = 15
weigth "Spider"          = 8
weigth "Soldier"         = 8
weigth "Umber hulk"      = 9
weigth _                 = 0
		
genWave :: Int -> StdGen -> ([MonsterGen], StdGen)
genWave n g = 
	if n <= 0
	then ([], g)
	else if d > n
	then (oldWave, g'')
	else (genM : oldWave, g'')
	where
		ind :: Int
		(ind, g') = randomR (0, 15) g
		genM = case ind of
			0  -> getHomunculus
			1  -> getBeetle
			2  -> getBat
			3  -> getHunter
			4  -> getIvy
			5  -> getAccelerator
			6  -> getTroll
			7  -> getWorm
			8  -> getFloatingEye
			9  -> getRedDragon
			10 -> getWhiteDragon
			11 -> getGreenDragon
			12 -> getForgottenBeast
			13 -> getSpider
			14 -> getSoldier
			15 -> getUmberHulk
			_  -> error "value error in function genWave"
		d = weigth $ nameFromGen genM
		(oldWave, g'') = genWave (n - d) g'

newWave :: World -> World
newWave w = w {units' = newUnits, stdgen = newStdGen, wave = wave w + 1} where
	(newUnits, newStdGen) = addWave (wave w) 
		$ addWaveFull (wave w) (units' w, stdgen w)
