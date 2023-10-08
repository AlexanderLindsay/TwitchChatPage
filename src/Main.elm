port module Main exposing (Model, Msg(..), init, main, update, view)

import Browser
import Html exposing (Html, div, text, img)
import Html.Attributes exposing (src)
import Json.Decode exposing (Decoder, Error, Value, decodeValue, field, map3, list, int, string)
import Platform.Cmd as Cmd



-- MAIN


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }



-- PORTS


port messageReceiver : (Value -> msg) -> Sub msg



-- MODEL


type alias TwitchEmote =
    { id : String
    , start : Int
    , end : Int
    }

twitchEmoteDecoder : Decoder TwitchEmote
twitchEmoteDecoder =
    map3 TwitchEmote
        (field "id" string)
        (field "start" int)
        (field "end" int)

type alias TwitchMessage =
    { user : String
    , text : String
    , emotes: List TwitchEmote
    }


twitchMessageDecoder : Decoder TwitchMessage
twitchMessageDecoder =
    map3 TwitchMessage
        (field "user" string)
        (field "text" string)
        (field "emotes" (list twitchEmoteDecoder))


type alias Model =
    { messages : List TwitchMessage }


init : () -> ( Model, Cmd Msg )
init () =
    ( { messages = [] }, Cmd.none )



-- UPDATE


type Msg
    = Recv (Result Error TwitchMessage)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Recv result ->
            case result of
                Err err ->
                    ( { model | messages = { user = "error", text = Json.Decode.errorToString err, emotes = [] } :: model.messages }, Cmd.none )

                Ok message ->
                    ( { model | messages = message :: model.messages }, Cmd.none )



-- VIEW

emoteHtml : String -> Html Msg
emoteHtml id =
    let
        url = "https://static-cdn.jtvnw.net/emoticons/v2/" ++ id ++ "/default/dark/1.0"
    in
        img [ src url ] []

displayMessageText : String -> List TwitchEmote -> Html Msg
displayMessageText message emotes =
    message
    |> String.toList
    |> List.indexedMap (\index c -> (index, c))
    |> List.foldl (\(index, c) (result, current, end) ->
        case end of
            Nothing ->
                let
                    emote = 
                        emotes
                        |> List.filter (\e -> e.start == index)
                        |> List.head
                in
                    case emote of
                        Nothing -> (result, String.cons c current, Nothing)
                        Just mote -> (text current :: emoteHtml mote.id :: result, "", Just mote.end)
            Just endIndex ->
                if endIndex == index then
                    (result, "", Nothing)
                else
                    (result, "", Just endIndex)
    ) ([], "", Nothing)
    |> (\(result, _, _) -> result)
    |> div []


viewMessage : TwitchMessage -> Html Msg
viewMessage message =
    div []
        [ div [] [ text message.user ]
        , div [] [ displayMessageText message.text message.emotes ]
        ]


view : Model -> Html Msg
view model =
    model.messages
        |> List.reverse
        |> List.map viewMessage
        |> div []



-- SUBSCRIPTIONS
-- Subscribe to the `messageReceiver` port to hear about messages coming in
-- from JS. Check out the index.html file to see how this is hooked up to a
-- WebSocket.
--


subscriptions : Model -> Sub Msg
subscriptions _ =
    messageReceiver (Recv << decodeValue twitchMessageDecoder)
