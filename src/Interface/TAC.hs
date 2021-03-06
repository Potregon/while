{-|
  Module      : Interface.TAC
  Description : Defines the three address code which is generated from the
                syntax tree.
  Copyright   : 2014, Jonas Cleve
                2015, Tay Phuong Ho
                2016, Philip Schmiel
  License     : GPL-3
-}
module Interface.TAC (
  TAC, Command (..), Data (..), Variable, ImmediateInteger, ImmediateDouble, ImmediateChar, Label, GotoCondition1 (..),
  GotoCondition2 (..),
  invertCond1, invertCond2, isGoto, getLabelFromGoto,
  getDefVariables, getUseVariables, getVariables, renameVariables, getCalculation
) where

import Prelude (
    Show (show), Eq, Char,
    String, Bool (..),
    error,
    (++), ($), (==),
    Double
  )

import Data.Int (
    Int64
  )

import qualified Interface.Token as T

-- | A three address code is a list of three address code commands
type TAC = [Command]

-- | The three address code commands are low level instructions (similar to
-- machine instruction).
data Command
  = Read Variable
  | Output Data
  | FRead Variable          -- $ added
  | FOutput Data            -- $ added
  | CRead Variable
  | COutput Data
  | Return Data             -- $ added
  | FReturn Data            -- $ added
  | Pop Variable            -- $ added
  | Push Data               -- $ added
  | ArrayAlloc Variable Data-- $ added
  | ArrayDealloc Variable   -- $ added
  | FromArray Variable Variable Data-- $ added
  | ToArray Variable Data Data-- $ added
  | ArrayCopy Variable Data -- $ added
  | Copy Variable Data
  | Convert Variable Data   -- $ added
  | ConvertInt Variable Data
  | Add Variable Data Data
  | Sub Variable Data Data
  | Mul Variable Data Data
  | Div Variable Data Data
  | Mod Variable Data Data
  | Neg Variable Data
  | Call Variable Label     -- $ added
  | VCall Variable Variable -- a call from a TFunction variable
  | MCall Variable Data String   -- method call @MCall resultVariable ref labelName@
  | FAdd Variable Data Data -- $ added
  | FSub Variable Data Data -- $ added
  | FMul Variable Data Data -- $ added
  | FDiv Variable Data Data -- $ added
  | FNeg Variable Data      -- $ added
  | Goto Label
  | GotoCond1 Label GotoCondition1 Data
  | GotoCond2 Label GotoCondition2 Data Data
  | Label Label
  | ShowError Label
  | CustomLabel Label
  | ToClass Data
  | FromMemory Variable Data
  | ToMemory Data Data
  | Solve Variable Data String  -- Solve a Variable with a Label
  | DatLabel Label Int64 Data String -- label index type name
  | DATA Data
  | Comment String
  | Send Data Data         -- send message object
  | SET Variable Data Data          -- {set label value}
  | GET Variable Data               -- {set label}
  | SETARRAY Variable Data Data     -- (setarray index value)
  | GETARRAY Variable Data          -- (getarray index)
  | METHOD Variable Data [Data] --{mehode label [Parameter]}
  | GETResult Variable Variable Variable -- variable type-variable message
  | METHODResult Variable Variable Variable -- variable type-variable message
  | Accept Variable Variable              -- Accepts a handler for an object @Accept object handler@
  deriving (Eq)

-- | Gives a neat output for three address commands.
instance Show Command where
  show (Read v) = "read " ++ v
  show (Output d) = "output " ++ show d
  show (FRead v) = "read " ++ v                                   -- $ added
  show (FOutput d) = "output " ++ show d                          -- $ added
  show (CRead v) = "read " ++ v
  show (COutput d) = "output " ++ show d
  show (Return d) = "return " ++ show d                           -- $ added
  show (FReturn d) = "return " ++ show d                          -- $ added
  show (Pop v) = "pop " ++ v                                      -- $ added
  show (Push d) = "push " ++ show d                               -- $ added
  show (ArrayAlloc v _) = "alloc " ++ v                           -- $ added
  show (ArrayDealloc v) = "dealloc " ++ v                         -- $ added
  show (FromArray v1 v2 d) = v1++" = "++v2++"["++show d++"]"      -- $ added
  show (ToArray v d1 d2) = v ++ "[" ++ show d1 ++ "] = " ++ show d2-- $ added
  show (ArrayCopy v d) = if v == show d then ""
                                        else v ++ " = " ++ show d -- $ added
  show (Copy v d) = v ++ " = " ++ show d
  show (Convert v d) = v ++ " = (double)" ++ show d               -- $ added
  show (ConvertInt v d) = v ++ " = (int)" ++ show d
  show (Add v d1 d2) = v ++ " = " ++ show d1 ++ " + " ++ show d2
  show (Sub v d1 d2) = v ++ " = " ++ show d1 ++ " - " ++ show d2
  show (Mul v d1 d2) = v ++ " = " ++ show d1 ++ " * " ++ show d2
  show (Div v d1 d2) = v ++ " = " ++ show d1 ++ " / " ++ show d2
  show (Mod v d1 d2) = v ++ " = " ++ show d1 ++ " % " ++ show d2
  show (Neg v d) = v ++ " = -" ++ show d
  show (Call v l) = v ++ " = call " ++ l     
  show (VCall v1 v2) = v1 ++ " = call " ++ v2                     -- $ added
  show (MCall var ref label) = var ++ " = call "++label++" at "++show ref
  show (FAdd v d1 d2) = v ++ " = " ++ show d1 ++ " + " ++ show d2 -- $ added
  show (FSub v d1 d2) = v ++ " = " ++ show d1 ++ " - " ++ show d2 -- $ added
  show (FMul v d1 d2) = v ++ " = " ++ show d1 ++ " * " ++ show d2 -- $ added
  show (FDiv v d1 d2) = v ++ " = " ++ show d1 ++ " / " ++ show d2 -- $ added
  show (FNeg v d) = v ++ " = -" ++ show d                         -- $ added
  show (Goto l) = "goto " ++ l
  show (GotoCond1 l cond d) = "goto " ++ l ++ " if " ++ show cond ++ " " ++
                              show d
  show (GotoCond2 l cond d1 d2) = "goto " ++ l ++ " if " ++ show d1 ++ " " ++
                                  show cond ++ " " ++ show d2
  show (FromMemory v d) = v ++" = &"++show d;
  show (ToMemory d1 d2) = "&"++show d1++" = "++show d2;
  show (ShowError l) = "error ("++l++")"
  show (Label l) = l ++ ":"
  show (DatLabel l i t s) = ".CREATE label "++l++" ( name='"++s++"' type='"++show t++"' index='"++ show i++"')"
  show (ToClass l) = "toClass "++show l 
  show (DATA d) = ".DATA "++ show d
  show (CustomLabel l) = l++":"
  show (Solve var id label) = var ++" = "++show id++" -> "++ label
  show (SET var label value) = var ++ " = .SET ("++ show label ++ ", "++show value++")"
  show (GET var label) = var++" = .GET ("++show label++")"
  show (SETARRAY var index value) = var ++" = .SET_ARRAY ("++show index++", "++show value++")"
  show (GETARRAY var index) = var ++" = .GET_ARRAY ("++show index++")"
  show (METHOD var label param) = var ++ " = .METHOD ("++show label++", "++show param++")"
  show (Send message obj) = show message++" ==> "++ show obj
  show (GETResult var t message) = var ++" = ("++show t++") .READ_ANSWER "++message
  show (METHODResult var t message) = var ++ " = ("++show t++") .READ_ANSWER "++message
  show (Comment s) = "; "++s
  show (Accept object handler) = object++" accepts "++handler

getCalculation :: T.MathOp -> T.Type -> Variable -> Data -> Data -> Command
getCalculation T.Plus T.TDouble v d1 d2 = FAdd v d1 d2
getCalculation T.Plus _ v d1 d2 = Add v d1 d2
getCalculation T.Minus T.TDouble v d1 d2 = FSub v d1 d2
getCalculation T.Minus _ v d1 d2 = Sub v d1 d2
getCalculation T.Times T.TDouble v d1 d2 = FMul v d1 d2
getCalculation T.Times _ v d1 d2 = Mul v d1 d2
getCalculation T.DivBy T.TDouble v d1 d2 = FDiv v d1 d2
getCalculation T.DivBy _ v d1 d2 = Div v d1 d2
getCalculation T.Mod _ v d1 d2 = Mod v d1 d2

-- | The different conditions for a goto statement with one parameter.
data GotoCondition1
  = IsTrue  -- ^ The parameter (a boolean value) should be true
  | IsFalse -- ^ The parameter (a boolean value) should be false
  deriving (Eq)

-- | Show nothing for 'IsTrue' and @not@ for 'IsFalse'.
instance Show GotoCondition1 where
  show IsTrue = ""
  show IsFalse = "not"

-- | Invert the one-parameter-condition (effectively swapping true and false).
invertCond1 :: GotoCondition1 -> GotoCondition1
invertCond1 IsTrue = IsFalse
invertCond1 IsFalse = IsTrue

-- | The different conditions for a goto statement with two parameters, i.e.
--   jumps with a comparison operator.
data GotoCondition2
  = Equal
  | NotEqual
  | Greater
  | GreaterEqual
  | Less
  | LessEqual
  | FEqual         -- $ added
  | FNotEqual      -- $ added
  | FGreater       -- $ added
  | FGreaterEqual  -- $ added
  | FLess          -- $ added
  | FLessEqual     -- $ added
  deriving (Eq)

-- | Display the symbol which belongs to the condition.
instance Show GotoCondition2 where
  show Equal = "=="
  show NotEqual = "!="
  show Greater = ">"
  show GreaterEqual = ">="
  show Less = "<"
  show LessEqual = "<="
  show FEqual = "=="        -- $ added
  show FNotEqual = "!="     -- $ added
  show FGreater = ">"       -- $ added
  show FGreaterEqual = ">=" -- $ added
  show FLess = "<"          -- $ added
  show FLessEqual = "<="    -- $ added

-- | Invert the two-parameter-condition (@Equal@ ⇔ @NotEqual@, @Greater@ ⇔
--   @LessEqual@, @GreaterEqual@ ⇔ @Less@).
invertCond2 :: GotoCondition2 -> GotoCondition2
invertCond2 Equal = NotEqual
invertCond2 NotEqual = Equal
invertCond2 Greater = LessEqual
invertCond2 GreaterEqual = Less
invertCond2 Less = GreaterEqual
invertCond2 LessEqual = Greater
invertCond2 FEqual = FNotEqual    -- $ added
invertCond2 FNotEqual = FEqual    -- $ added
invertCond2 FGreater = FLessEqual -- $ added
invertCond2 FGreaterEqual = FLess -- $ added
invertCond2 FLess = FGreaterEqual -- $ added
invertCond2 FLessEqual = FGreater -- $ added

-- | Three address codes can work on general data, i.e. they don't care whether
-- they work on variables or immediate values.
data Data
  = Variable Variable
  | ImmediateInteger ImmediateInteger -- $ modified
  | ImmediateDouble ImmediateDouble   -- $ added
  | ImmediateChar ImmediateChar
  | ImmediateReference String String
  deriving (Eq)

-- | Returns variable names as they are and applies `show` to immediate values.
instance Show Data where
  show (Variable v) = v
  show (ImmediateInteger i) = show i                             -- $ modified
  show (ImmediateDouble i) = show i                              -- $ added
  show (ImmediateChar c) = show c 
  show (ImmediateReference [] l) = l
  show (ImmediateReference ns l) = "label_"++ns++"_"++l    
                         

-- | Variable as String.
type Variable = String

-- $| Integers as values.
type ImmediateInteger = Int64

-- $| Double-precision floating-point numbers as values.
type ImmediateDouble = Double

-- |Character as values
type ImmediateChar = Char

-- | Labels are just names, i.e. strings.
type Label = String

-- * Helper functions

-- | Check whether a command is a goto instruction.
isGoto :: Command -> Bool
isGoto (Goto _)            = True
isGoto (GotoCond1 _ _ _)   = True
isGoto (GotoCond2 _ _ _ _) = True
isGoto _                   = False

-- | Retrieve the target label from a goto instruction.
getLabelFromGoto :: Command -> Label
getLabelFromGoto (Goto l)            = l
getLabelFromGoto (GotoCond1 l _ _)   = l
getLabelFromGoto (GotoCond2 l _ _ _) = l
getLabelFromGoto c = error $ "Cannot get label from " ++ show c


getDefVariables :: Command -> [Variable]
getDefVariables (Read v) = [v]
getDefVariables (FRead v) = [v]        -- $ added
getDefVariables (CRead v) = [v]
getDefVariables (Pop v) = [v]          -- $ added
getDefVariables (ArrayAlloc v _) = [v] -- $ added
getDefVariables (FromArray v _ _) = [v]-- $ added
getDefVariables (ArrayCopy v _) = [v]  -- $ added
getDefVariables (Copy v _) = [v]
getDefVariables (Convert v _) = [v]    -- $ added
getDefVariables (ConvertInt v _ ) = [v]
getDefVariables (Add v _ _) = [v]
getDefVariables (Sub v _ _) = [v]
getDefVariables (Mul v _ _) = [v]
getDefVariables (Div v _ _) = [v]
getDefVariables (Mod v _ _) = [v]
getDefVariables (Neg v _) = [v]
getDefVariables (Call v _) = [v]       -- $ added
getDefVariables (VCall v1 _) = [v1]
getDefVariables (MCall var _ _) = [var]
getDefVariables (FAdd v _ _) = [v]     -- $ added
getDefVariables (FSub v _ _) = [v]     -- $ added
getDefVariables (FMul v _ _) = [v]     -- $ added
getDefVariables (FDiv v _ _) = [v]     -- $ added
getDefVariables (FNeg v _) = [v]       -- $ added
getDefVariables (Solve v _ _) = [v]
getDefVariables (FromMemory v _) = [v]
getDefVariables (GET v _) = [v]
getDefVariables (SET v _ _)= [v]
getDefVariables (GETARRAY v _) = [v]
getDefVariables (SETARRAY v _ _) = [v]
getDefVariables (METHOD v _ _) = [v]
getDefVariables (GETResult v t _) = [v,t]
getDefVariables (METHODResult v t _)= [v,t]
getDefVariables _ = []

getUseVariables :: Command -> [Variable]
getUseVariables (Output (Variable v)) = [v]
getUseVariables (Return (Variable v)) = [v]               -- $ added
getUseVariables (FReturn (Variable v)) = [v]              -- $ added
getUseVariables (FOutput (Variable v)) = [v]                -- $ added
getUseVariables (COutput (Variable v)) = [v]
getUseVariables (Push (Variable v)) = [v]                   -- $ added
getUseVariables (VCall _ v2) = [v2]
getUseVariables (MCall _ ref _) = variablesFromData [ref]
getUseVariables (ArrayAlloc _ d1) = variablesFromData [d1]  -- $ added
getUseVariables (ArrayDealloc v) = [v]                     -- $ added
getUseVariables (FromArray _ v2 d1) = [v2] ++ variablesFromData [d1] -- $ added
getUseVariables (ToArray v d1 d2) = [v] ++ variablesFromData [d1, d2] -- $ added
getUseVariables (ArrayCopy _ d1) = variablesFromData [d1]   -- $ added
getUseVariables (Copy _ d1) = variablesFromData [d1]
getUseVariables (Convert _ d1) = variablesFromData [d1]     -- $ added
getUseVariables (ConvertInt _ d1) = variablesFromData [d1]
getUseVariables (Add _ d1 d2) = variablesFromData [d1, d2]
getUseVariables (Sub _ d1 d2) = variablesFromData [d1, d2]
getUseVariables (Mul _ d1 d2) = variablesFromData [d1, d2]
getUseVariables (Div _ d1 d2) = variablesFromData [d1, d2]
getUseVariables (Mod _ d1 d2) = variablesFromData [d1, d2]
getUseVariables (Neg _ d1) = variablesFromData [d1]
getUseVariables (FAdd _ d1 d2) = variablesFromData [d1, d2] -- $ added
getUseVariables (FSub _ d1 d2) = variablesFromData [d1, d2] -- $ added
getUseVariables (FMul _ d1 d2) = variablesFromData [d1, d2] -- $ added
getUseVariables (FDiv _ d1 d2) = variablesFromData [d1, d2] -- $ added
getUseVariables (FNeg _ d1) = variablesFromData [d1]        -- $ added
getUseVariables (GotoCond1 _ _ d1) = variablesFromData [d1]
getUseVariables (GotoCond2 _ _ d1 d2) = variablesFromData [d1, d2]
getUseVariables (Solve _ v _) = variablesFromData [v]
getUseVariables (FromMemory _ d) = variablesFromData [d]
getUseVariables (ToMemory d1 d2) = variablesFromData [d1, d2]
getUseVariables (GET _ d1) = variablesFromData [d1]
getUseVariables (SET _ d1 d2) = variablesFromData [d1, d2]
getUseVariables (GETARRAY _ d1) = variablesFromData [d1]
getUseVariables (SETARRAY _ d1 d2) = variablesFromData [d1, d2]
getUseVariables (METHOD _ d1 d2) = variablesFromData ([d1] ++ d2)
getUseVariables (Send msg obj) = variablesFromData [msg, obj]
getUseVariables (GETResult _ _ msg) = [msg]
getUseVariables (METHODResult _ _ msg) = [msg]
getUseVariables (Accept obj hand) = [obj, hand]
getUseVariables _ = []

getVariables :: Command -> [Variable]
getVariables c = getDefVariables c ++ getUseVariables c

renameVariables :: Command -> Variable -> Variable -> Command
renameVariables (Output d) vI vO =
  let [d'] = substitute [d] vI vO
  in Output d'
renameVariables (FOutput d) vI vO =                                   -- $ added
  let [d'] = substitute [d] vI vO
  in FOutput d'
renameVariables (COutput d) vI vO =
  let [d'] = substitute [d] vI vO
  in COutput d'
renameVariables (Return d) vI vO =                                    -- $ added
  let [d'] = substitute [d] vI vO
  in Return d'
renameVariables (FReturn d) vI vO =                                   -- $ added
  let [d'] = substitute [d] vI vO
  in FReturn d'
renameVariables (Read v) vI vO =
  let [Variable v'] = substitute [Variable v] vI vO
  in Read v'
renameVariables (FRead v) vI vO =                                     -- $ added
  let [Variable v'] = substitute [Variable v] vI vO
  in FRead v'
renameVariables (CRead v) vI vO =
  let [Variable v'] = substitute [Variable v] vI vO
  in CRead v'
renameVariables (Push d) vI vO =                                      -- $ added
  let [d'] = substitute [d] vI vO
  in Push d'
renameVariables (Pop v) vI vO =                                       -- $ added
  let [Variable v'] = substitute [Variable v] vI vO
  in Pop v'
renameVariables (ArrayAlloc v d) vI vO =                              -- $ added
  let [Variable v', d'] = substitute [Variable v, d] vI vO
  in ArrayAlloc v' d'
renameVariables (ArrayDealloc v) vI vO =                              -- $ added
  let [Variable v'] = substitute [Variable v] vI vO
  in ArrayDealloc v'
renameVariables (FromArray v1 v2 d) vI vO =                           -- $ added
  let [Variable v1', Variable v2', d'] = substitute [Variable v1, Variable v2, d] vI vO
  in FromArray v1' v2' d'
renameVariables (ToArray v d1 d2) vI vO =                             -- $ added
  let [Variable v', d1', d2'] = substitute [Variable v, d1, d2] vI vO
  in ToArray v' d1' d2'
renameVariables (ArrayCopy v d) vI vO =                               -- $ added
  let [Variable v', d'] = substitute [Variable v, d] vI vO
  in ArrayCopy v' d'
renameVariables (Copy v d) vI vO =
  let [Variable v', d'] = substitute [Variable v, d] vI vO
  in Copy v' d'
renameVariables (Convert v d) vI vO =                                 -- $ added
  let [Variable v', d'] = substitute [Variable v, d] vI vO
  in Convert v' d'
renameVariables (ConvertInt v d) vI vO =
  let [Variable v', d'] = substitute [Variable v, d] vI vO
  in ConvertInt v' d'
renameVariables (Add v d1 d2) vI vO =
  let [Variable v', d1', d2'] = substitute [Variable v, d1, d2] vI vO
  in Add v' d1' d2'
renameVariables (Sub v d1 d2) vI vO =
  let [Variable v', d1', d2'] = substitute [Variable v, d1, d2] vI vO
  in Sub v' d1' d2'
renameVariables (Mul v d1 d2) vI vO =
  let [Variable v', d1', d2'] = substitute [Variable v, d1, d2] vI vO
  in Mul v' d1' d2'
renameVariables (Div v d1 d2) vI vO =
  let [Variable v', d1', d2'] = substitute [Variable v, d1, d2] vI vO
  in Div v' d1' d2'
renameVariables (Mod v d1 d2) vI vO =
  let [Variable v', d1', d2'] = substitute [Variable v, d1, d2] vI vO
  in Mod v' d1' d2'
renameVariables (Neg v d) vI vO =
  let [Variable v', d'] = substitute [Variable v, d] vI vO
  in Neg v' d'
renameVariables (Call v l) vI vO =                                    -- $ added
  let [Variable v'] = substitute [Variable v] vI vO
  in Call v' l
renameVariables (VCall v1 v2) vI vO =
  let [Variable v1', Variable v2'] = substitute [Variable v1, Variable v2] vI vO
  in VCall v1' v2'
renameVariables (MCall var ref label) vI vO =
  let [Variable var', ref'] = substitute [Variable var, ref] vI vO
  in MCall var' ref' label
renameVariables (FAdd v d1 d2) vI vO =                                -- $ added
  let [Variable v', d1', d2'] = substitute [Variable v, d1, d2] vI vO
  in FAdd v' d1' d2'
renameVariables (FSub v d1 d2) vI vO =                                -- $ added
  let [Variable v', d1', d2'] = substitute [Variable v, d1, d2] vI vO
  in FSub v' d1' d2'
renameVariables (FMul v d1 d2) vI vO =                                -- $ added
  let [Variable v', d1', d2'] = substitute [Variable v, d1, d2] vI vO
  in FMul v' d1' d2'
renameVariables (FDiv v d1 d2) vI vO =                                -- $ added
  let [Variable v', d1', d2'] = substitute [Variable v, d1, d2] vI vO
  in FDiv v' d1' d2'
renameVariables (FNeg v d) vI vO =                                    -- $ added
  let [Variable v', d'] = substitute [Variable v, d] vI vO
  in FNeg v' d'
renameVariables (GotoCond1 l c d) vI vO =
  let [d'] = substitute [d] vI vO
  in GotoCond1 l c d'
renameVariables (GotoCond2 l c d1 d2) vI vO =
  let [d1', d2'] = substitute [d1, d2] vI vO
  in GotoCond2 l c d1' d2'
renameVariables (Solve v1 v2 s) vI vO = 
  let [Variable v1', v2'] = substitute [Variable v1, v2] vI vO 
  in Solve v1' v2' s
renameVariables (FromMemory v d) vI vO =
  let [Variable v', d'] = substitute [Variable v, d] vI vO
  in FromMemory v' d'
renameVariables (ToMemory d1 d2) vI vO =
  let [d1', d2'] = substitute [d1, d2] vI vO
  in ToMemory d1' d2'
renameVariables (GET v1 d1) vI vO =
  let [Variable v1', d1'] = substitute [Variable v1, d1] vI vO
  in GET v1' d1'
renameVariables (SET v1 d1 d2) vI vO =
  let [Variable v1', d1',d2'] = substitute [Variable v1, d1, d2] vI vO
  in SET v1' d1' d2'
renameVariables (GETARRAY v1 d1) vI vO = 
  let [Variable v1', d1'] = substitute [Variable v1, d1] vI vO
  in GETARRAY v1' d1'
renameVariables (SETARRAY v1 d1 d2) vI vO =
  let [Variable v1', d1', d2'] = substitute [Variable v1, d1, d2] vI vO
  in SETARRAY v1' d1' d2'
renameVariables (METHOD v1 d1 d2) vI vO =
  let (Variable v1':d1':d2') = substitute ([Variable v1, d1]++d2) vI vO
  in METHOD v1' d1' d2'
renameVariables (Send d1 d2) vI vO =
  let [d1', d2'] = substitute [d1,d2] vI vO
  in Send d1' d2'
renameVariables (GETResult v1 v2 v3) vI vO =
  let [Variable v1', Variable v2', Variable v3'] = substitute [Variable v1, Variable v2,Variable v3] vI vO
  in GETResult v1' v2' v3'
renameVariables (METHODResult v1 v2 v3) vI vO =
  let [Variable v1', Variable v2', Variable v3'] = substitute [Variable v1, Variable v2, Variable v3] vI vO
  in METHODResult v1' v2' v3'
renameVariables (Accept v1 v2) vI vO =
  let [Variable v1', Variable v2'] = substitute [Variable v1, Variable v2] vI vO
  in Accept v1' v2'
renameVariables c _ _ = c

substitute :: [Data] -> Variable -> Variable -> [Data]
substitute [] _ _ = []
substitute (Variable v : rest) vIn vOut
  | v == vIn = Variable vOut : substitute rest vIn vOut
substitute (d:rest) vIn vOut = d : substitute rest vIn vOut

variablesFromData :: [Data] -> [Variable]
variablesFromData [] = []
variablesFromData (Variable v : data_) = v : variablesFromData data_
variablesFromData (_ : data_) = variablesFromData data_
