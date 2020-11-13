module ProjectM36.DatabaseContext where
import ProjectM36.Base
import Control.Monad (void)
import qualified Data.Map as M
import qualified Data.HashSet as HS
import ProjectM36.DataTypes.Basic
import ProjectM36.AtomFunctions.Basic
import ProjectM36.Relation
import qualified Data.ByteString.Lazy as BL
import Data.Binary as B
import ProjectM36.AtomFunction as AF
import ProjectM36.DatabaseContextFunction as DBCF

empty :: DatabaseContext
empty = DatabaseContext { inclusionDependencies = M.empty, 
                          relationVariables = M.empty, 
                          notifications = M.empty,
                          atomFunctions = HS.empty,
                          dbcFunctions = HS.empty,
                          typeConstructorMapping = [] }

-- | Remove TransactionId markers on GraphRefRelationalExpr
stripGraphRefRelationalExpr :: GraphRefRelationalExpr -> RelationalExpr
stripGraphRefRelationalExpr = void
        
-- | convert an existing database context into its constituent expression.   
databaseContextAsDatabaseContextExpr :: DatabaseContext -> DatabaseContextExpr
databaseContextAsDatabaseContextExpr context = MultipleExpr $ relVarsExprs ++ incDepsExprs ++ funcsExprs
  where
    relVarsExprs = map (\(name, rel) -> Assign name (stripGraphRefRelationalExpr rel)) (M.toList (relationVariables context))
    incDepsExprs :: [DatabaseContextExpr]
    incDepsExprs = map (uncurry AddInclusionDependency) (M.toList (inclusionDependencies context))
    funcsExprs = [] -- map (\func -> ) (HS.toList funcs) -- there are no databaseExprs to add atom functions yet-}

basicDatabaseContext :: DatabaseContext
basicDatabaseContext = DatabaseContext { inclusionDependencies = M.empty,
                                         relationVariables = M.fromList [("true", ExistingRelation relationTrue),
                                                                         ("false", ExistingRelation relationFalse)],
                                         atomFunctions = basicAtomFunctions,
                                         dbcFunctions = basicDatabaseContextFunctions,
                                         notifications = M.empty,
                                         typeConstructorMapping = basicTypeConstructorMapping
                                         }

--for building the Merkle hash
hashBytes :: DatabaseContext -> BL.ByteString
hashBytes ctx = mconcat [incDeps, rvs, atomFs, dbcFs, nots, tConsMap]
  where
    incDeps = B.encode (inclusionDependencies ctx)
    rvs = B.encode (relationVariables ctx)
    atomFs = HS.foldr (mappend . AF.hashBytes) mempty (atomFunctions ctx)
    dbcFs = HS.foldr (mappend . DBCF.hashBytes) mempty (dbcFunctions ctx)
    nots = B.encode (notifications ctx)
    tConsMap = B.encode (typeConstructorMapping ctx)
