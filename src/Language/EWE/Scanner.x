{
module Language.EWE.Scanner(Alex(..),
                            AlexPosn(..),
                            alexMonadScan,
                            alexExec,
                            runAlex,
                            alexGetInput,
                            getPosn
                           ) where

import Language.EWE.Token(Tkns,Tkn(..),Tkn_(..))
}

%wrapper "monad"

$alpha       = [a-zA-Z]
$digit       = [0-9]
$nozerodigit = [1-9]
$graphic     = $printable
$eol         = [\n]

@string = \" (graphic # \")* \"

tokens :-

       $white+                      ;
       \#.*                         ;
       $eol                         { returnEOL }
       \:\=                         { returnAssgn }
       \:                           { returnColon }
       [\*\+\-\/\%]                 { returnOper }
       \(                           { returnLPar}
       \)                           { returnRPar }
       \[                           { returnLBrk }
       \]                           { returnRBrk }
       \,                           { returnComma }
       (\>|\>\=|\<|\<\=|\=|\<\>)    { returnCond }
       "M"                          { returnResWrd }
       "PC"                         { returnResWrd }
       "randInt"                    { returnResWrd }
       "readInt"                    { returnResWrd }
       "writeInt"                   { returnResWrd }
       "readStr"                    { returnResWrd }
       "writeStr"                   { returnResWrd }
       "goto"                       { returnResWrd }
       "if"                         { returnResWrd }
       "then"                       { returnResWrd }
       "halt"                       { returnResWrd }
       "break"                      { returnResWrd }
       "equ"                        { returnResWrd }
       \" [^\"]* \"                 { returnStr }
       (($nozerodigit $digit*)| 0)  { returnInt }
       $alpha [$alpha $digit]*      { returnId }

{
returnTkn :: Tkn_ -> AlexInput -> Int -> Alex Tkn
returnTkn tkn _ _ = do pos <- getPosn 
                       return $ Tkn pos tkn

returnEOL :: AlexInput -> Int -> Alex Tkn
returnEOL = returnTkn $ TknEOL

returnAssgn :: AlexInput -> Int -> Alex Tkn
returnAssgn = returnTkn $ TknAssgn

returnColon :: AlexInput -> Int -> Alex Tkn
returnColon = returnTkn $ TknColon

returnLPar :: AlexInput -> Int -> Alex Tkn
returnLPar = returnTkn $ TknLPar

returnRPar :: AlexInput -> Int -> Alex Tkn
returnRPar = returnTkn $ TknRPar

returnLBrk :: AlexInput -> Int -> Alex Tkn
returnLBrk = returnTkn $ TknLBrk

returnRBrk :: AlexInput -> Int -> Alex Tkn
returnRBrk = returnTkn $ TknRBrk

returnComma :: AlexInput -> Int -> Alex Tkn
returnComma = returnTkn $ TknComma

returnOper :: AlexInput -> Int -> Alex Tkn
returnOper = returnFunction (TknOper . head)

returnCond :: AlexInput -> Int -> Alex Tkn
returnCond = returnFunction TknCond

returnStr :: AlexInput -> Int -> Alex Tkn
returnStr = returnFunction (TknStr . read)

returnInt :: AlexInput -> Int -> Alex Tkn
returnInt = returnFunction (TknInt . read)

returnId :: AlexInput -> Int -> Alex Tkn
returnId = returnFunction TknId

returnResWrd :: AlexInput -> Int -> Alex Tkn
returnResWrd = returnFunction TknResWrd

returnFunction :: (String -> Tkn_) -> AlexInput -> Int -> Alex Tkn
returnFunction f (_,_,_,s) i = do pos <- getPosn
                                  return $ (Tkn pos (f (take i s)))

alexEOF :: Alex Tkn
alexEOF = do pos <- getPosn
             return $ Tkn pos TknEOF

alexExec :: Alex Tkns
alexExec = do
   t <- alexMonadScan
   case t of
     (Tkn pos TknEOF) -> return $ [t]
     _                -> do ts <- alexExec
                            return (t:ts)

getPosn :: Alex (Int,Int)
getPosn = do
 (AlexPn _ l c,_,_,_) <- alexGetInput
 return (l,c)
}
