port module Main exposing (Model, Msg(..), init, main, update, view)

import Browser
import Browser.Dom
import Html exposing (Html, div, text, img, span)
import Html.Attributes exposing (src, class, id)
import Json.Decode exposing (Decoder, Error, Value, decodeValue, field, map3, list, int, string)
import Platform.Cmd as Cmd
import Task
import Time

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
    { messages : List TwitchMessage
    , time : Time.Posix
    , zone: Time.Zone
    }


init : () -> ( Model, Cmd Msg )
init () =
    ( { messages = [], time = Time.millisToPosix 0, zone = Time.utc }
    , Cmd.batch [ Task.perform SetTime Time.now, Task.perform SetZone Time.here ]
    )

-- UPDATE


type Msg
    = NoOp
    | Recv (Result Error TwitchMessage)
    | SetTime Time.Posix
    | SetZone Time.Zone

jumpToBottom : String -> Cmd Msg
jumpToBottom id =
    Browser.Dom.getViewportOf id
        |> Task.andThen (\info -> 
            let
                _ = Debug.log "height" info.scene.height
            in
            Browser.Dom.setViewportOf id 0 (info.scene.height + 100)
        )
        |> Task.attempt (\_ -> NoOp)

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            (model, Cmd.none)
        SetTime now ->
            ({ model | time = now }, Cmd.none)
        SetZone here ->
            ({ model | zone = here }, Cmd.none)
        Recv result ->
            case result of
                Err err ->
                    ( { model | messages = { user = "error", text = Json.Decode.errorToString err, emotes = [] } :: model.messages }, Cmd.none )

                Ok message ->
                    ( { model | messages = message :: model.messages }, jumpToBottom "messages" )



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
                        Just mote -> (text (String.reverse current) :: emoteHtml mote.id :: result, "", Just mote.end)
            Just endIndex ->
                if endIndex == index then
                    (result, "", Nothing)
                else
                    (result, "", Just endIndex)
    ) ([], "", Nothing)
    |> (\(result, current, _) -> text (String.reverse current) :: result)
    |> List.reverse
    |> div []


viewMessage : TwitchMessage -> Html Msg
viewMessage message =
    div [ class "message" ]
        [ div [ class "username" ] [ text ("***" ++ String.toUpper message.user ++ "***") ]
        , div [ class "text" ] [ displayMessageText message.text message.emotes ]
        ]

viewMessages : List TwitchMessage -> Html Msg
viewMessages messages =
    messages
        |> List.take 15
        |> List.reverse
        |> List.map viewMessage
        |> div [ class "messages terminal-body", id "messages" ]

monthToString : Time.Month -> String
monthToString month =
    case month of
    Time.Jan -> "01"
    Time.Feb -> "02"
    Time.Mar -> "03"
    Time.Apr -> "04"
    Time.May -> "05"
    Time.Jun -> "06"
    Time.Jul -> "07"
    Time.Aug -> "08"
    Time.Sep -> "09"
    Time.Oct -> "10"
    Time.Nov -> "11"
    Time.Dec -> "12"

timeToString : Time.Zone -> Time.Posix -> String
timeToString zone time =
    String.padLeft 4 '0' (String.fromInt (Time.toMillis zone time))
    ++ " " ++
    String.padLeft 2 '0' (String.fromInt (Time.toDay zone time))
    ++ "." ++
    monthToString (Time.toMonth zone time)
    ++ "." ++
    "2337"

view : Model -> Html Msg
view model =
    div [ class "chat terminal"]
        [ div [ class "terminal-wrapper terminal-header" ] [ span [] [text "UESCTerm 802.11 (remote override)"], span [] [text (timeToString model.zone model.time) ] ]
        , viewMessages model.messages
        , div [ class "terminal-wrapper terminal-footer" ] [ span [] [ text "PgUp/PgDn/Arrows to Scroll" ], span [] [text "Return/Enter to Acknowledge" ] ]
        ]



-- SUBSCRIPTIONS
-- Subscribe to the `messageReceiver` port to hear about messages coming in
-- from JS. Check out the index.html file to see how this is hooked up to a
-- WebSocket.
--


subscriptions : Model -> Sub Msg
subscriptions _ =
    messageReceiver (Recv << decodeValue twitchMessageDecoder)
