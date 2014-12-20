
module Data.Repa.Array.Boxed
        ( B
        , Array (..)
        , boxed
        , fromVectorB, toVectorB)
where
import Data.Repa.Eval.Array
import Data.Repa.Array.Delayed
import Data.Repa.Array.Window
import Data.Repa.Array.Internals.Bulk
import Data.Repa.Array.Internals.Shape
import Data.Repa.Array.Internals.Index
import qualified Data.Vector                    as V
import qualified Data.Vector.Mutable            as VM
import Control.Monad


-------------------------------------------------------------------------------
-- | Arrays of boxed elements.
-- 
--   This representation should only be used when your element type doesn't
--   have an Unbox instance. If it does, then use the Unboxed `U` 
--   representation will be faster.
--
data B

-- | Arrays of boxed elements.
instance Shape sh => Bulk B sh a where
 data Array B sh a
        = BArray sh !(V.Vector a)

 index  (BArray sh vec) ix
        | not $ inShapeRange zeroDim sh ix
        = error "repa-bulk.index[B] out of range"

        | otherwise
        = vec V.! (toIndex sh ix)

 extent (BArray sh _) = sh
 {-# INLINE extent #-}

deriving instance (Show sh, Show a) => Show (Array B sh a)
deriving instance (Read sh, Read a) => Read (Array B sh a)


-- | Constrain an array to have a boxed representation,
--   eg with @boxed (compute arr)@ 
boxed :: Array B sh a -> Array B sh a
boxed = id
{-# INLINE boxed #-}


-- Window ---------------------------------------------------------------------
instance Window B DIM1 a where
 window (Z :. start) (Z :. len) (BArray _sh vec)
        = BArray (Z :. len) (V.slice start len vec)
 {-# INLINE window #-}


-- Target ---------------------------------------------------------------------
instance Target B a where
 data Buffer B a 
  = BBuffer (VM.IOVector a)

 unsafeNewBuffer len
  = liftM BBuffer (VM.unsafeNew len)
 {-# INLINE unsafeNewBuffer #-}

 unsafeWriteBuffer (BBuffer mvec) ix
  = VM.unsafeWrite mvec ix
 {-# INLINE unsafeWriteBuffer #-}

 unsafeSliceBuffer start len (BBuffer mvec)
  = do  let mvec'  = VM.unsafeSlice start len mvec
        return  $  BBuffer mvec'
 {-# INLINE unsafeSliceBuffer #-}

 unsafeFreezeBuffer sh (BBuffer mvec)     
  = do  vec     <- V.unsafeFreeze mvec
        return  $  BArray sh vec
 {-# INLINE unsafeFreezeBuffer #-}

 touchBuffer _ 
  = return ()
 {-# INLINE touchBuffer #-}


-- Conversions ----------------------------------------------------------------
-- | O(1). Wrap a boxed vector as an array.
fromVectorB :: Shape sh
            => sh -> V.Vector e -> Array B sh e
fromVectorB sh vec
        = BArray sh vec
{-# INLINE [1] fromVectorB #-}


-- | O(1). Unpack a boxed vector from an array.
toVectorB :: Array B sh e -> V.Vector e
toVectorB (BArray _ vec)
        = vec
{-# INLINE [1] toVectorB #-}
