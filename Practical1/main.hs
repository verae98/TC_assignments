{-# language CPP #-}
#if __GLASGOW_HASKELL__ >= 804
import Prelude hiding ((*>), (<*), Monoid, mempty, foldMap, Foldable, (<>))
#elif __GLASGOW_HASKELL__ >= 710
import Prelude hiding ((*>), (<*), Monoid, mempty, foldMap, Foldable)
#endif

import ParseLib.Abstract
import System.Environment

-- Starting Framework

-- | "Target" datatype for the DateTime parser, i.e, the parser should produce elements of this type.
data DateTime = DateTime { date :: Date
                         , time :: Time
                         , utc :: Bool }
    deriving (Eq, Ord)

data Date = Date { year  :: Year
                 , month :: Month
                 , day   :: Day }
    deriving (Eq, Ord)

newtype Year  = Year { unYear :: Int }  deriving (Eq, Ord)
newtype Month = Month { unMonth :: Int } deriving (Eq, Ord)
newtype Day   = Day { unDay :: Int } deriving (Eq, Ord)

data Time = Time { hour   :: Hour
                 , minute :: Minute
                 , second :: Second }
    deriving (Eq, Ord)

newtype Hour   = Hour { unHour :: Int } deriving (Eq, Ord)
newtype Minute = Minute { unMinute :: Int } deriving (Eq, Ord)
newtype Second = Second { unSecond :: Int } deriving (Eq, Ord)


-- | The main interaction function. Used for IO, do not edit.
data Result = SyntaxError | Invalid DateTime | Valid DateTime deriving (Eq, Ord)

instance Show DateTime where
    show = printDateTime

instance Show Date where
    show = printDate

instance Show Result where
    show SyntaxError = "date/time with wrong syntax"
    show (Invalid _) = "good syntax, but invalid date or time values"
    show (Valid x)   = "valid date: " ++ show x

main :: IO ()
main = mainDateTime

mainDateTime :: IO ()
mainDateTime = interact (printOutput . processCheck . processInput)
    where
        processInput = map (run parseDateTime) . lines
        processCheck = map (maybe SyntaxError (\x -> if checkDateTime x then Valid x else Invalid x))
        printOutput  = unlines . map show

mainCalendar :: IO ()
mainCalendar = do
    file:_ <- getArgs
    res <- readCalendar file
    putStrLn $ maybe "Calendar parsing error" (ppMonth (Year 2012) (Month 11)) res

-- Exercise 1
parseDateTime :: Parser Char DateTime
parseDateTime = do 
                d <- parseDate
                sep <- symbol 'T' 
                t <- parseTime   
                sep2 <- symbol 'Z'       
                return (DateTime d t True) -- TODO: how to create bool?
parseHour :: Parser Char Hour
parseHour = do 
            d1 <- integer
            d2 <- integer
            return(Hour (d1 *10 + d2))
parseMinute :: Parser Char Minute
parseMinute = do    
              d1 <- integer
              d2 <- integer
              return (Minute (d1 *10 + d2))
parseSecond :: Parser Char Second
parseSecond = do
              d1 <- integer
              d2 <- integer
              return (Second (d1 *10 + d2))
parseTime :: Parser Char Time
parseTime = do
            h <- parseHour
            m <- parseMinute
            s <- parseSecond
            return (Time h m s)
parseYear :: Parser Char Year
parseYear = do
            d1 <- integer
            d2 <- integer
            d3 <- integer
            d4 <- integer
            return (Year (d1*1000 + d2*100 + d3*10 + d4))
parseMonth :: Parser Char Month
parseMonth = do
             d1 <- integer
             d2 <- integer
             return (Month (d1 *10 + d2))
parseDay :: Parser Char Day
parseDay = do
           d1 <- integer
           d2 <- integer
           return (Day (d1 *10 + d2))
parseDate :: Parser Char Date
parseDate = do 
            y <- parseYear
            m <- parseMonth
            d <- parseDay
            return (Date y m d)

-- Exercise 2
run :: Parser a b -> [a] -> Maybe b
run p l = let x = filter (\(a,sl) -> length sl == 0)(parse p l) in case x of
          [] -> Nothing
          _  -> Just (fst (x!!0))

-- Exercise 3
printDateTime :: DateTime -> String
printDateTime dt = printDate (date dt) ++ "T" ++ printTime (time dt) ++ if (utc dt) then "Z" else ""

printDate :: Date -> String
printDate d =  printYear (year d) ++ printMonth (month d) ++ printDay (day d)

printYear :: Year -> String
printYear y = show (unYear y)
printMonth :: Month -> String
printMonth m = show (unMonth m)
printDay :: Day -> String
printDay d = show (unDay d)

printTime :: Time -> String
printTime t = printHour (hour t) ++ printMinute (minute t) ++ printSecond (second t)

printHour :: Hour -> String
printHour h = show (unHour h)
printMinute :: Minute -> String
printMinute m = show (unMinute m)
printSecond :: Second -> String
printSecond s = show (unSecond s)

-- Exercise 4
parsePrint s = fmap printDateTime $ run parseDateTime s

-- Exercise 5
checkDateTime :: DateTime -> Bool
checkDateTime dt | (unMonth(month (date dt)) < 0 || unMonth(month (date dt)) > 13) = False
                 | (unYear(year (date dt)) < 0 ) = False
                 | (unMonth(month (date dt)) `elem` [1,3,5,7,8,10,12] && unDay(day (date dt)) > 31) = False
                 | (unMonth(month (date dt)) `elem` [4,6,9,11] && unDay(day (date dt)) > 30) = False
                 | (unHour(hour (time dt)) < 0 || unHour(hour (time dt)) >= 24) = False
                 | (unMinute(minute (time dt)) < 0 || unMinute(minute (time dt)) >= 60) = False
                 | (unMonth(month (date dt)) == 2) = if unYear(year (date dt)) `mod` 4 == 0 then unDay(day(date dt)) <= 29 else unDay(day (date dt)) <= 28
                 | otherwise = True

-- Exercise 6
data Calendar = Calendar CalProp EventProp
    deriving (Eq, Ord, Show)

data Event = Event EventProp  deriving (Eq, Ord, Show)
data EventProp = DTStamp DateTime | UID String | DTStart DateTime
                | DTEnd DateTime | Discription String
                | Summary String | Location String
    deriving (Eq, Ord, Show)

data CalProp = Prodid String | Version deriving (Eq, Ord, Show)

-- Exercise 7
data Token = Token String
    deriving (Eq, Ord, Show)

scanCalendar :: Parser Char [Token]
scanCalendar = (:) <$> scanCalendar2 <*> many scanCalendar2

scanCalendar2 :: Parser Char Token
scanCalendar2 = Token <$> token ":" <|> Token <$> token "\r\n" <|> Token <$> identifier 


parseCalendar :: Parser Token Calendar
parseCalendar = undefined

recognizeCalendar :: String -> Maybe Calendar
recognizeCalendar s = run scanCalendar s >>= run parseCalendar

-- Exercise 8
readCalendar :: FilePath -> IO (Maybe Calendar)
readCalendar = undefined

-- Exercise 9
-- DO NOT use a derived Show instance. Your printing style needs to be nicer than that :)
printCalendar :: Calendar -> String
printCalendar = undefined

-- Exercise 10
countEvents :: Calendar -> Int
countEvents = undefined

findEvents :: DateTime -> Calendar -> [Event]
findEvents = undefined

checkOverlapping :: Calendar -> Bool
checkOverlapping = undefined

timeSpent :: String -> Calendar -> Int
timeSpent = undefined

-- Exercise 11
ppMonth :: Year -> Month -> Calendar -> String
ppMonth = undefined

