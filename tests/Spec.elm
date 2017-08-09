module Spec exposing (..)

-- Core

import Char


-- 3rd

import Fuzz exposing (Fuzzer)
import Expect exposing (Expectation)
import Shrink
import Test exposing (Test, describe)
import Random.Pcg as Random exposing (Generator)


-- Local

import Building
import Id exposing (Id(..))
import Model exposing (Msg(..))
import Unit


msgFuzzer : Fuzzer Msg
msgFuzzer =
    Fuzz.custom msgGenerator Shrink.noShrink


intGenerator : Generator Int
intGenerator =
    Random.int Random.minInt Random.maxInt


pointGenerator : Generator ( Int, Int )
pointGenerator =
    Random.pair intGenerator intGenerator


idGenerator : Generator Id
idGenerator =
    Random.map Id intGenerator


buildableGenerator : Generator Model.Buildable
buildableGenerator =
    Random.choices <|
        List.map Random.constant <|
            List.map Model.BuildSubmarine Unit.all
                ++ List.map Model.BuildBuilding Building.all


msgGenerator : Generator Msg
msgGenerator =
    Random.choices
        [ Random.constant NoOp
        , Random.map (SetRandomSeed << Model.NewSeed) intGenerator
        , Random.constant EndTurn
        , Random.map SelectPoint pointGenerator
        , Random.map SelectUnit idGenerator
        , Random.map SelectTile pointGenerator
        , Random.map HoverPoint pointGenerator
        , Random.constant EndHover
        , Random.map3 PlanMove pointGenerator idGenerator pointGenerator
        , Random.map BuildOrder (Random.maybe Random.bool buildableGenerator)
        , Random.map NameEditorFull asciiGenerator
        , Random.map NameEditorAbbreviation asciiGenerator
        , Random.constant NameEditorSubmit
        ]


suite : Test
suite =
    describe "Msgs"
        [ -- This is to make sure we don't have things like functions
          -- in `Msg`, which can't be compared and prevent the debugger
          -- from being able to export sessions.
          Test.fuzz msgFuzzer "are comparable" <|
            \msg -> Expect.equal msg msg
        ]



--------------------------------------------------
-- The below is all copied from elm-test
-- (where it was unexported).
--------------------------------------------------


asciiGenerator : Generator String
asciiGenerator =
    Random.frequency
        [ ( 3, Random.int 1 10 )
        , ( 0.2, Random.constant 0 )
        , ( 1, Random.int 11 50 )
        , ( 1, Random.int 50 1000 )
        ]
        |> Random.andThen (lengthString asciiCharGenerator)


asciiCharGenerator : Generator Char
asciiCharGenerator =
    Random.map Char.fromCode (Random.int 32 126)


lengthString : Generator Char -> Int -> Generator String
lengthString charGenerator stringLength =
    Random.list stringLength charGenerator
        |> Random.map String.fromList
