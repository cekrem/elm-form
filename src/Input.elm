module Input exposing (Dumb, Input, WithInteraction, build, new, withAttributes, withDisabled, withOnChange, withPlaceholder, withRequired, withTransformer, withType, withValidator)

import Html exposing (Attribute, Html)
import Html.Attributes as Attr
import Html.Events as Events
import Html.Lazy


type alias Props msg =
    { label : String
    , required : Bool
    , type_ : String
    , placeholder : Maybe String
    , transformer : String -> String
    , validator : String -> Result (List (Html.Attribute msg)) ()
    , extraAttributes : List (Html.Attribute msg)
    , onChange : Maybe (String -> msg)
    }


type Input interaction msg
    = Input (Props msg)


type Dumb
    = Dumb Never


type WithInteraction
    = WithInteraction Never


withRequired : Bool -> Input any msg -> Input any msg
withRequired required (Input input) =
    Input { input | required = required }


withPlaceholder : String -> Input any msg -> Input any msg
withPlaceholder placeholder (Input input) =
    Input { input | placeholder = Just placeholder }


withType : String -> Input any msg -> Input any msg
withType type_ (Input input) =
    Input { input | type_ = type_ }


withTransformer : (String -> String) -> Input any msg -> Input any msg
withTransformer transformer (Input input) =
    Input { input | transformer = transformer }


withValidator : (String -> Result (List (Html.Attribute msg)) ()) -> Input any msg -> Input any msg
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
        , placeholder = Nothing
        , validator = always (Result.Ok ())
        , transformer = identity
        , extraAttributes = []
        , onChange = Nothing
        }


build : String -> Input WithInteraction msg -> Html msg
build =
    Html.Lazy.lazy2 build_


build_ : String -> Input WithInteraction msg -> Html msg
build_ value (Input input) =
    let
        placeholderAttr : Html.Attribute msg
        placeholderAttr =
            input.placeholder
                |> Maybe.map Attr.placeholder
                |> Maybe.withDefault (Attr.class "")

        validatorAttrs : List (Html.Attribute msg)
        validatorAttrs =
            case input.validator value of
                Result.Err attr ->
                    attr

                Result.Ok () ->
                    []

        extraAttrs : List (Html.Attribute msg)
        extraAttrs =
            placeholderAttr :: (input.extraAttributes ++ validatorAttrs)

        interaction : Html.Attribute msg
        interaction =
            input.onChange
                |> Maybe.map Events.onInput
                |> Maybe.withDefault (Attr.disabled True)
    in
    Html.input
        (Attr.type_ input.type_
            :: Attr.value value
            :: Attr.required input.required
            :: Attr.attribute "aria-labelledby" input.label
            :: interaction
            :: extraAttrs
        )
        []
