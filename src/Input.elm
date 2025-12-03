module Input exposing
    ( Input, Dumb, WithInteraction
    , new
    , withRequired, withType, withPlaceholder, withTransformer, withValidator, withAttributes
    , withOnChange, withDisabled
    , build
    )

{-| Build type-safe HTML input elements with validation and state management.

This module uses phantom types to ensure inputs are properly configured before
being rendered. An input must have interaction (via `withOnChange` or `withDisabled`)
before it can be built into HTML.


# Types

@docs Input, Dumb, WithInteraction


# Creating Inputs

@docs new


# Configuration

@docs withRequired, withType, withPlaceholder, withTransformer, withValidator, withAttributes


# Adding Interaction

@docs withOnChange, withDisabled


# Rendering

@docs build

-}

import Html exposing (Html)
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


{-| An input element with a phantom type parameter for compile-time state tracking.

The phantom type ensures that inputs have proper interaction handlers before
they can be rendered.

-}
type Input interaction msg
    = Input (Props msg)


{-| Phantom type representing an input without interaction.

Inputs with this type cannot be built yet - they need to be given interaction
via `withOnChange` or `withDisabled`.

-}
type Dumb
    = Dumb Never


{-| Phantom type representing an input with interaction.

Inputs with this type can be built into HTML.

-}
type WithInteraction
    = WithInteraction Never


{-| Mark an input as required or optional.

This sets the HTML `required` attribute.

    new "Email"
        |> withRequired True

-}
withRequired : Bool -> Input any msg -> Input any msg
withRequired required (Input input) =
    Input { input | required = required }


{-| Add placeholder text to an input.

    new "Search"
        |> withPlaceholder "Type to search..."
        |> withOnChange SearchChanged

-}
withPlaceholder : String -> Input any msg -> Input any msg
withPlaceholder placeholder (Input input) =
    Input { input | placeholder = Just placeholder }


{-| Set the input type (e.g., "text", "email", "password", "number").

    new "Password"
        |> withType "password"
        |> withRequired True
        |> withOnChange PasswordChanged

-}
withType : String -> Input any msg -> Input any msg
withType type_ (Input input) =
    Input { input | type_ = type_ }


{-| Add a transformer function that processes the input value.

The transformer is applied to the value before it's passed to the `onChange` handler.
This is useful for formatting, trimming, or normalizing input.

    new "Username"
        |> withTransformer String.trim
        |> withOnChange UsernameChanged

    new "Code"
        |> withTransformer String.toUpper
        |> withOnChange CodeChanged

-}
withTransformer : (String -> String) -> Input any msg -> Input any msg
withTransformer transformer (Input input) =
    Input { input | transformer = transformer }


{-| Add a validator function that returns additional HTML attributes on validation failure.

The validator receives the current value and can return error attributes that will
be applied to the input element. This is useful for providing visual feedback or
ARIA attributes for accessibility.

    import Html.Attributes as Attr

    lengthValidator : String -> Result (List (Html.Attribute msg)) ()
    lengthValidator value =
        if String.length value >= 3 then
            Ok ()
        else
            Err
                [ Attr.class "invalid"
                , Attr.attribute "aria-invalid" "true"
                ]

    new "Username"
        |> withValidator lengthValidator
        |> withOnChange UsernameChanged

-}
withValidator : (String -> Result (List (Html.Attribute msg)) ()) -> Input any msg -> Input any msg
withValidator validator (Input input) =
    Input { input | validator = validator }


{-| Add custom HTML attributes to an input.

    import Html.Attributes as Attr

    new "Email"
        |> withAttributes
            [ Attr.class "form-input"
            , Attr.autocomplete False
            ]
        |> withOnChange EmailChanged

-}
withAttributes : List (Html.Attribute msg) -> Input any msg -> Input any msg
withAttributes attrs (Input input) =
    Input { input | extraAttributes = attrs }


{-| Convert a `Dumb` input to a disabled input with interaction.

This allows you to build a disabled input without providing an onChange handler.

    new "Disabled Field"
        |> withDisabled
        |> build ""

-}
withDisabled : Input Dumb msg -> Input WithInteraction msg
withDisabled (Input input) =
    Input input


{-| Add an onChange handler to make the input interactive.

This is required before an input can be built. The handler receives the transformed
value after any transformer has been applied.

    type Msg
        = NameChanged String

    new "Name"
        |> withTransformer String.trim
        |> withOnChange NameChanged
        |> build currentValue

-}
withOnChange : (String -> msg) -> Input Dumb msg -> Input WithInteraction msg
withOnChange onChange (Input input) =
    Input { input | onChange = Just onChange }


{-| Create a new input with a label.

The input starts as `Dumb`, meaning it cannot be built yet. You must add
interaction via `withOnChange` or `withDisabled` before building.

    new "Email Address"

    new "Password"
        |> withType "password"
        |> withRequired True
        |> withOnChange PasswordChanged

-}
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


{-| Build an input into HTML.

The input must have interaction (via `withOnChange` or `withDisabled`) to be buildable.
The build function is optimized with lazy rendering for performance.

    type Msg
        = EmailChanged String

    view : String -> Html Msg
    view emailValue =
        new "Email"
            |> withType "email"
            |> withRequired True
            |> withOnChange EmailChanged
            |> build emailValue

-}
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
