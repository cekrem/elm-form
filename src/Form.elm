module Form exposing
    ( Form, FormInput
    , new, input
    , withRequired, withType, withPlaceholder, withTransformer, withValidator, withAttributes
    , build
    )

{-| Build type-safe, declarative forms with validation and transformation support.

This module provides a simple way to create forms by composing inputs together.
It handles form state management, validation, and transformation of user input.


# Types

@docs Form, FormInput


# Creating Forms

@docs new, input


# Configuring Inputs

@docs withRequired, withType, withPlaceholder, withTransformer, withValidator, withAttributes


# Rendering

@docs build

-}

import Dict exposing (Dict)
import Html exposing (Html)
import Html.Events as Events
import Input exposing (Dumb, Input)


{-| An opaque type representing a form with multiple inputs.

A `Form` contains form-level attributes and a collection of inputs that will be
rendered together.

-}
type Form msg
    = Form (List (Html.Attribute msg)) (List (FormInput msg))


{-| Represents an input field within a form.

Each input has a unique `key` that identifies it in the form's value dictionary,
and configuration for how the input should behave and appear.

**Note**: You should create `FormInput` values using the `input` function
rather than constructing this record directly. The `input` function provides
a clean, type-safe way to create form inputs.

-}
type alias FormInput msg =
    { key : String
    , input_ : Input Dumb msg
    }


{-| Create a new form with form-level attributes and inputs.

    import Html.Attributes as Attr

    myForm : Form Msg
    myForm =
        new [ Attr.class "my-form" ]
            [ input "email" "Email Address"
                |> withType "email"
                |> withRequired True
            , input "name" "Full Name"
                |> withRequired True
            ]

-}
new : List (Html.Attribute msg) -> List (FormInput msg) -> Form msg
new attrs inputs =
    Form attrs inputs


{-| Create a new form input with a key and label.

The key is used to identify the input's value in the form state dictionary.

    input "username" "Username"

    input "bio" "Biography"
        |> withType "textarea"

-}
input : String -> String -> FormInput msg
input key label =
    { key = key
    , input_ = Input.new label
    }


{-| Mark an input as required or optional.

    input "email" "Email"
        |> withRequired True

-}
withRequired : Bool -> FormInput msg -> FormInput msg
withRequired required formInput =
    { formInput
        | input_ = formInput.input_ |> Input.withRequired required
    }


{-| Set the input type (e.g., "text", "email", "password", "number").

    input "password" "Password"
        |> withType "password"
        |> withRequired True

    input "age" "Age"
        |> withType "number"

-}
withType : String -> FormInput msg -> FormInput msg
withType type_ formInput =
    { formInput
        | input_ = formInput.input_ |> Input.withType type_
    }


{-| Add placeholder text to an input.

    input "search" "Search"
        |> withPlaceholder "Type to search..."

    input "email" "Email Address"
        |> withType "email"
        |> withPlaceholder "you@example.com"

-}
withPlaceholder : String -> FormInput msg -> FormInput msg
withPlaceholder placeholder formInput =
    { formInput
        | input_ = formInput.input_ |> Input.withPlaceholder placeholder
    }


{-| Add a transformer function that processes the input value before it's stored.

Transformers are useful for formatting input, such as removing whitespace or
converting to a specific case.

    input "username" "Username"
        |> withTransformer String.trim

    input "code" "Postal Code"
        |> withTransformer String.toUpper

-}
withTransformer : (String -> String) -> FormInput msg -> FormInput msg
withTransformer transformer formInput =
    { formInput
        | input_ = formInput.input_ |> Input.withTransformer transformer
    }


{-| Add a validator function that returns additional HTML attributes on validation failure.

Validators can return attributes like CSS classes or ARIA attributes to provide
visual feedback when validation fails.

    import Html.Attributes as Attr

    emailValidator : String -> Result (List (Html.Attribute msg)) ()
    emailValidator value =
        if String.contains "@" value then
            Ok ()
        else
            Err [ Attr.class "error", Attr.attribute "aria-invalid" "true" ]

    input "email" "Email"
        |> withType "email"
        |> withValidator emailValidator

-}
withValidator : (String -> Result (List (Html.Attribute msg)) ()) -> FormInput msg -> FormInput msg
withValidator validator formInput =
    { formInput
        | input_ = formInput.input_ |> Input.withValidator validator
    }


{-| Add custom HTML attributes to an input.

    import Html.Attributes as Attr

    input "name" "Name"
        |> withAttributes
            [ Attr.class "form-control"
            , Attr.placeholder "Enter your name"
            ]

-}
withAttributes : List (Html.Attribute msg) -> FormInput msg -> FormInput msg
withAttributes attrs formInput =
    { formInput
        | input_ = formInput.input_ |> Input.withAttributes attrs
    }


{-| Render the form to HTML.

Takes the current form values as a dictionary, a message constructor for handling
value changes, a message for form submission, and the form configuration.

    import Dict exposing (Dict)

    type Msg
        = FormChanged (Dict String String)
        | FormSubmitted

    view : Dict String String -> Html Msg
    view formValues =
        myForm
            |> build formValues FormChanged FormSubmitted

-}
build : Dict String String -> (Dict String String -> msg) -> msg -> Form msg -> Html msg
build values onChange onSubmit (Form attrs inputs) =
    Html.form (Events.onSubmit onSubmit :: attrs)
        (inputs
            |> List.map
                (\{ key, input_ } ->
                    let
                        value : String
                        value =
                            values |> Dict.get key |> Maybe.withDefault ""

                        onChangeInput : String -> msg
                        onChangeInput newVal =
                            onChange (values |> Dict.insert key newVal)
                    in
                    input_
                        |> Input.withOnChange onChangeInput
                        |> Input.build value
                )
        )
