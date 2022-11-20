{-# LANGUAGE OverloadedStrings #-}

import           Language
import           Checker
import qualified RoundTrip as RT
import qualified Gradual as G

import           Control.Monad.Logic (LogicT)

main :: IO ()
main = do
  putStrLn ""
  gradualTests
  putStrLn ""
  roundTripTests

data Result = Error | OK

check :: (Environment -> Scheme -> Term Type -> Checker (LogicT IO) (Term Type)) -> (Result, Scheme, Term Type) -> IO ()
check go (OK, t, e) = do
  r <- runChecker go initEnv t e
  if r
    then putStrLn "OK"
    else putStrLn $ "Error on OK term: " ++ show e
check go (Error, t, e) = do
  r <- runChecker go initEnv t e
  if r
    then putStrLn $ "Checked bad term: " ++ show e
    else putStrLn "OK" 

gradualTests :: IO ()
gradualTests = do
  putStrLn "Gradual typechecker:"
  mapM_ (check G.checkGoal) tests

roundTripTests :: IO ()
roundTripTests = do
  putStrLn "Round trip typechecker:"
  mapM_ (check RT.checkGoal) tests

tests :: [(Result, Scheme, Term Type)]
tests = [
    (OK, Forall [TV "a"] ("a" --> "a"), lam "x" "x") 
  , (Error, Forall [TV "a", TV "b"] ("a" --> "b"), lam "x" "x") 
  , (OK, Forall [TV "a", TV "a"] (("a" --> "b") --> "a" --> "b"), lam "f" (lam "x" ("f" $$ "x")))    
  , (Error, Forall [TV "a", TV "a"] (("a" --> "b") --> "a" --> "b"), lam "f" (lam "x" ("x" $$ "f"))) 
  , (OK, Forall [TV "a", TV "b", TV "c"] (("a" --> "b") --> ("b" --> "c") --> "a" --> "c"), lam "f" (lam "g" (lam "x" ("g" $$ ("f" $$ "x")))))
  , (Error, Forall [TV "a", TV "b", TV "c"] (("a" --> "b") --> ("b" --> "c") --> "a" --> "c"), lam "f" (lam "g" (lam "x" ("f" $$ ("g" $$ "x")))))
  , (Error, Forall [TV "a", TV "b", TV "c"] (("a" --> "a") --> ("b" --> "c") --> "a" --> "c"), lam "f" (lam "g" (lam "x" ("g" $$ ("f" $$ "x")))))
  , (OK, Forall [] (tbool --> tbool), lam "x" "x") 
  , (OK, Forall [] (tint --> tint), lam "x" "x") 
  , (OK, Forall [] ((tint --> tbool) --> tint --> tbool), lam "f" (lam "x" ("f" $$ "x")))
  ]