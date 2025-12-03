# elm-form

Build type-safe, declarative forms with validation and transformation support.

## Overview

`elm-form` provides a simple, composable way to create HTML forms in Elm. It uses phantom types to ensure inputs are properly configured at compile time, and offers a clean API for validation and value transformation.

## Features

- **Type-safe**: Phantom types ensure inputs have interaction handlers before they can be rendered
- **Composable**: Build complex forms by composing simple, reusable inputs
- **Validation**: Add validators that provide visual feedback through HTML attributes
- **Transformation**: Transform input values (trim whitespace, change case, etc.)
- **Performance**: Optimized with lazy rendering
- **Accessible**: Built-in ARIA attributes for better accessibility

## Installation

```bash
elm install cekrem/elm-form
```

## Quick Example

```elm

module Main exposing (main)

import Browser
import Dict exposing (Dict)
import Form
import Html exposing (Html)
import Html.Attributes as Attr


type alias Model =
    { formValues : Dict String String
    }


type Msg
    = FormChanged (Dict String String)
    | FormSubmitted


init : Model
init =
    { formValues = Dict.empty }


emailValidator : String -> Result (List (Html.Attribute msg)) ()
emailValidator value =
    if String.contains "@" value && String.contains "." value then
        Ok ()

    else
        Err
            [ Attr.class "error"
            , Attr.attribute "aria-invalid" "true"
            ]


update : Msg -> Model -> Model
update msg model =
    case msg of
        FormChanged newValues ->
            { model | formValues = newValues }

        FormSubmitted ->
            -- Handle form submission
            model


view : Model -> Html Msg
view model =
    Html.div []
        [ Form.new [ Attr.class "contact-form" ]
            [ Form.input "name" "Full Name"
                |> Form.withRequired True
                |> Form.withTransformer String.trim
            , Form.input "email" "Email Address"
                |> Form.withType "email"
                |> Form.withRequired True
                |> Form.withValidator emailValidator
            , Form.input "message" "Message"
                |> Form.withRequired True
                |> Form.withTransformer String.trim
            ]
            |> Form.build model.formValues FormChanged FormSubmitted
        ]


main : Program () Model Msg
main =
    Browser.sandbox
        { init = init
        , update = update
        , view = view
        }
```

## API Overview

### Form Module

The `Form` module provides functions for creating and managing entire forms:

- **`Form`** - Opaque type representing a form
- **`new`** - Create a form with attributes and inputs
- **`input`** - Create a form input with a key and label
- **`withRequired`** - Mark an input as required
- **`withType`** - Set the input type (text, email, password, etc.)
- **`withTransformer`** - Add value transformation
- **`withValidator`** - Add validation with error attributes
- **`withAttributes`** - Add custom HTML attributes
- **`build`** - Render the form to HTML

### Input Module

The `Input` module provides low-level input building blocks with phantom types:

- **`Input`** - Type-safe input with phantom type for state tracking
- **`Dumb`** - Phantom type for inputs without interaction
- **`WithInteraction`** - Phantom type for inputs ready to render
- **`new`** - Create a basic input
- **`withOnChange`** - Add change handler (converts `Dumb` to `WithInteraction`)
- **`withDisabled`** - Mark as disabled (converts `Dumb` to `WithInteraction`)
- **`build`** - Render to HTML (requires `WithInteraction`)

## Complete Examples

### Login Form

```elm
import Dict exposing (Dict)
import Form
import Html exposing (Html)
import Html.Attributes as Attr


type Msg
    = FormChanged (Dict String String)
    | FormSubmitted


passwordValidator : String -> Result (List (Html.Attribute msg)) ()
passwordValidator value =
    if String.length value >= 8 then
        Ok ()

    else
        Err
            [ Attr.class "error"
            , Attr.title "Password must be at least 8 characters"
            , Attr.attribute "aria-invalid" "true"
            ]


view : Dict String String -> Html Msg
view formValues =
    Html.div []
        [ Form.new [ Attr.class "login-form" ]
            [ Form.input "username" "Username"
                |> Form.withRequired True
                |> Form.withTransformer String.trim
                |> Form.withAttributes [ Attr.autocomplete False ]
            , Form.input "password" "Password"
                |> Form.withType "password"
                |> Form.withRequired True
                |> Form.withValidator passwordValidator
            ]
            |> Form.build formValues FormChanged FormSubmitted
        ]
```

### Registration Form with Multiple Validators

```elm
import Dict exposing (Dict)
import Form
import Html exposing (Html)
import Html.Attributes as Attr


type Msg
    = FormChanged (Dict String String)
    | FormSubmitted


emailValidator : String -> Result (List (Html.Attribute msg)) ()
emailValidator value =
    if String.contains "@" value && String.contains "." value then
        Ok ()

    else
        Err
            [ Attr.class "error"
            , Attr.attribute "aria-invalid" "true"
            ]


usernameValidator : String -> Result (List (Html.Attribute msg)) ()
usernameValidator value =
    let
        length =
            String.length value

        isAlphanumeric =
            String.all (\c -> Char.isAlphaNum c || c == '_') value
    in
    if length >= 3 && length <= 20 && isAlphanumeric then
        Ok ()

    else
        Err
            [ Attr.class "error"
            , Attr.title "Username must be 3-20 characters, alphanumeric or underscore"
            ]


strongPasswordValidator : String -> Result (List (Html.Attribute msg)) ()
strongPasswordValidator value =
    let
        hasLength =
            String.length value >= 8

        hasUpper =
            String.any Char.isUpper value

        hasLower =
            String.any Char.isLower value

        hasDigit =
            String.any Char.isDigit value
    in
    if hasLength && hasUpper && hasLower && hasDigit then
        Ok ()

    else
        Err
            [ Attr.class "error"
            , Attr.title "Password must be 8+ chars with upper, lower, and digit"
            , Attr.attribute "aria-invalid" "true"
            ]


view : Dict String String -> Html Msg
view formValues =
    Html.div []
        [ Form.new [ Attr.class "registration-form" ]
            [ Form.input "email" "Email"
                |> Form.withType "email"
                |> Form.withRequired True
                |> Form.withValidator emailValidator
            , Form.input "username" "Username"
                |> Form.withRequired True
                |> Form.withTransformer (String.trim >> String.toLower)
                |> Form.withValidator usernameValidator
            , Form.input "password" "Password"
                |> Form.withType "password"
                |> Form.withRequired True
                |> Form.withValidator strongPasswordValidator
            , Form.input "confirm" "Confirm Password"
                |> Form.withType "password"
                |> Form.withRequired True
            ]
            |> Form.build formValues FormChanged FormSubmitted
        ]
```

### Using Input Module Directly

For more control, you can use the `Input` module directly:

```elm
import Input
import Html exposing (Html, div)
import Html.Attributes as Attr

type Msg
    = NameChanged String
    | EmailChanged String

view : String -> String -> Html Msg
view name email =
    div []
        [ Input.new "Name"
            |> Input.withRequired True
            |> Input.withPlaceholder "Enter your name"
            |> Input.withTransformer String.trim
            |> Input.withAttributes [ Attr.class "form-control" ]
            |> Input.withOnChange NameChanged
            |> Input.build name
        , Input.new "Email"
            |> Input.withType "email"
            |> Input.withRequired True
            |> Input.withPlaceholder "you@example.com"
            |> Input.withOnChange EmailChanged
            |> Input.build email
        ]
```

## Design Decisions

### Phantom Types

The `Input` module uses phantom types to prevent rendering inputs without interaction handlers. This ensures you can't accidentally create an input that doesn't respond to user interaction:

```elm
-- This won't compile:
Input.new "Name"
    |> Input.build ""

-- This will compile:
Input.new "Name"
    |> Input.withOnChange NameChanged
    |> Input.build ""
```

### Validator Attributes

Instead of returning error messages, validators return HTML attributes. This design:

- Keeps the library flexible (you provide your own error display)
- Enables accessibility features (ARIA attributes)
- Allows for CSS-based validation styling
- Follows the principle of separation of concerns

### Dictionary-Based State

Forms use `Dict String String` for state management because:

- It's simple and type-safe
- Keys can be any string you choose
- Easy to serialize/deserialize
- Works well with Elm's architecture

### Transformers

Transformers are applied during the `onChange` event, not during rendering. This ensures:

- The stored value is always in the transformed format
- Validation runs on the final value
- No confusion about whether displayed value matches stored value

## Contributing

Contributions are welcome! Please ensure your changes:

1. Follow Elm's package design guidelines
2. Include documentation with examples
3. Maintain type safety guarantees
4. Include tests for new functionality

## License

BSD-3-Clause
