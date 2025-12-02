module Input exposing (build, new, withAttributes, withDisabled, withOnChange, withRequired, withTransformer, withType, withValidator)

import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Events


type alias Props msg =
    { label : String
    , required : Bool
    , type_ : String
    , transformer : String -> String
    , validator : String -> Result (List (Html.Attribute msg)) ()
    , extraAttributes : List (Html.Attribute msg)
    , onChange : Maybe (String -> msg)
    }


type Input state msg
    = Input (Props msg)


type Dumb
    = Dumb


type WithInteraction
    = WithInteraction


withRequired : Bool -> Input any msg -> Input any msg
withRequired required (Input input) =
    Input { input | required = required }


withType : String -> Input any msg -> Input any msg
withType type_ (Input input) =
    Input { input | type_ = type_ }


withTransformer : (String -> String) -> Input any msg -> Input any msg
withTransformer transformer (Input input) =
    Input { input | transformer = transformer }


withValidator : (String -> Result (List (Html.Attribute msg)) ()) -> Input WithInteraction msg -> Input WithInteraction msg
withValidator validator (Input input) =
    Input { input | validator = validator }


withAttributes : List (Html.Attribute msg) -> Input any msg -> Input any msg
withAttributes attrs (Input input) =
    Input { input | extraAttributes = attrs }


withDisabled : Input Dumb msg -> Input WithInteraction msg
withDisabled (Input input) =
    Input input


withOnChange : (String -> msg) -> Input Dumb msg -> Input WithInteraction msg
withOnChange onChange (Input input) =
    Input { input | onChange = Just onChange }


new : String -> Input Dumb msg
new label =
    Input
        { label = label
        , required = False
        , type_ = "text"
        , validator = always (Result.Ok ())
        , transformer = identity
        , extraAttributes = []
        , onChange = Nothing
        }


build : String -> Input WithInteraction msg -> Html msg
build value (Input input) =
    let
        extraAttrs =
            case input.validator value of
                Result.Err attr ->
                    input.extraAttributes ++ attr

                Result.Ok () ->
                    input.extraAttributes

        interaction =
            input.onChange
                |> Maybe.map Events.onInput
                |> Maybe.withDefault (Attr.disabled True)
    in
    Html.input
        (Attr.type_ input.type_
            :: Attr.value value
            :: Attr.required input.required
            :: interaction
            :: extraAttrs
        )
        []
