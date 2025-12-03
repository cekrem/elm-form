module Form exposing (build, input, new, withAttributes, withRequired, withTransformer, withType, withValidator)

import Dict exposing (Dict)
import Html exposing (Html)
import Html.Events as Events
import Input exposing (Dumb, Input)


type Form msg
    = Form (List (Html.Attribute msg)) (List (FormInput msg))


type alias FormInput msg =
    { key : String
    , input_ : Input Dumb msg
    }


new : List (Html.Attribute msg) -> List (FormInput msg) -> Form msg
new attrs inputs =
    Form attrs inputs


input : String -> String -> FormInput msg
input key label =
    { key = key
    , input_ = Input.new label
    }


withRequired : Bool -> FormInput msg -> FormInput msg
withRequired required formInput =
    { formInput
        | input_ = formInput.input_ |> Input.withRequired required
    }


withType : String -> FormInput msg -> FormInput msg
withType type_ formInput =
    { formInput
        | input_ = formInput.input_ |> Input.withType type_
    }


withTransformer : (String -> String) -> FormInput msg -> FormInput msg
withTransformer transformer formInput =
    { formInput
        | input_ = formInput.input_ |> Input.withTransformer transformer
    }


withValidator : (String -> Result (List (Html.Attribute msg)) ()) -> FormInput msg -> FormInput msg
withValidator validator formInput =
    { formInput
        | input_ = formInput.input_ |> Input.withValidator validator
    }


withAttributes : List (Html.Attribute msg) -> FormInput msg -> FormInput msg
withAttributes attrs formInput =
    { formInput
        | input_ = formInput.input_ |> Input.withAttributes attrs
    }


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
