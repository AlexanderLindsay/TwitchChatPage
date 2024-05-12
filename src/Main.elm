port module Main exposing (Model, Msg(..), init, main, update, view)

import Browser
import Browser.Dom
import Html exposing (Html, div, text, img, span)
import Html.Attributes exposing (src, class, id)
import Json.Decode exposing (Decoder, Error, Value, decodeValue, field, map, map3, map5, list, int, string, oneOf)
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


port twitchEvent : (Value -> msg) -> Sub msg

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

type alias ChatMessage =
    { id: String
    , user : String
    , text : String
    , timestamp : String
    , emotes: List TwitchEmote
    }


chatMessageDecoder : Decoder ChatMessage
chatMessageDecoder =
    map5 ChatMessage
        (field "id" string)
        (field "user" string)
        (field "text" string)
        (field "timestamp" string)
        (field "emotes" (list twitchEmoteDecoder))

type alias BanRequest =
    { username : String }

banDecoder : Decoder BanRequest
banDecoder =
    map BanRequest
        (field "username" string)

type alias DeleteRequest =
    { id : String }

deleteDecoder : Decoder DeleteRequest
deleteDecoder =
    map DeleteRequest
        (field "id" string)

type TwitchEvent
    = DeleteRequestEvent DeleteRequest
    | BanRequestEvent BanRequest
    | ChatMessageEvent ChatMessage

twitchEventDecoder : Decoder TwitchEvent
twitchEventDecoder =
    oneOf
        [ map ChatMessageEvent chatMessageDecoder
        , map BanRequestEvent banDecoder 
        , map DeleteRequestEvent deleteDecoder
        ]

type alias Model =
    { messages : List ChatMessage
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
    | OnTwitchEvent (Result Error TwitchEvent)
    | SetTime Time.Posix
    | SetZone Time.Zone

jumpToBottom : String -> Cmd Msg
jumpToBottom id =
    Browser.Dom.getViewportOf id
        |> Task.andThen (\info -> 
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
        OnTwitchEvent decodedEvent ->
            case decodedEvent of
                Err err ->
                    ( model, Cmd.none )

                Ok event ->
                    case event of
                        ChatMessageEvent message ->
                            ( { model | messages = message :: model.messages }, jumpToBottom "messages" )
                        BanRequestEvent banRequest -> 
                            ( { model | messages = 
                                model.messages
                                |> List.filter (\m -> m.user /= banRequest.username )
                            }, jumpToBottom "messages" )
                        DeleteRequestEvent deleteRequest -> 
                            ( { model | messages = 
                                model.messages
                                |> List.filter (\m -> m.id /= deleteRequest.id )
                            }, jumpToBottom "messages" )


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

viewTimestamp : Time.Zone -> String -> Html Msg
viewTimestamp zone timestamp =
    let
        ts = String.toInt timestamp
            |> Maybe.withDefault 0
        px = Time.millisToPosix ts
        hour = 
            Time.toHour zone px
            |> String.fromInt
        minute = 
            Time.toMinute zone px
            |> String.fromInt
    in
    span [ class "timestamp" ] [ text (hour ++ ":" ++ minute) ]

viewMessage : Time.Zone -> ChatMessage -> Html Msg
viewMessage zone message =
    div [ class "message" ]
        [ div [ class "username" ] [ text ("***" ++ String.toUpper message.user ++ "***"), viewTimestamp zone message.timestamp ]
        , div [ class "text" ] [ displayMessageText message.text message.emotes ]
        ]

viewMessages : Time.Zone -> List ChatMessage -> Html Msg
viewMessages zone messages =
    messages
        |> List.take 15
        |> List.reverse
        |> List.map (viewMessage zone)
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

timeToHeaderText : Time.Zone -> Time.Posix -> String
timeToHeaderText zone time =
    String.padLeft 4 '0' (String.fromInt (Time.toMillis zone time))
    ++ " " ++
    monthToString (Time.toMonth zone time)
    ++ "." ++
    String.padLeft 2 '0' (String.fromInt (Time.toDay zone time))
    ++ "." ++
    "2337"

view : Model -> Html Msg
view model =
    div [ class "chat terminal"]
        [ div [ class "terminal-wrapper terminal-header" ] [ span [] [text "UESCTerm 802.11 (remote override)"], span [] [text (timeToHeaderText model.zone model.time) ] ]
        , viewMessages model.zone model.messages
        , div [ class "terminal-wrapper terminal-footer" ] [ span [] [ text "PgUp/PgDn/Arrows to Scroll" ], span [] [text "Return/Enter to Acknowledge" ] ]
        ]



-- SUBSCRIPTIONS
-- Subscribe to the `twitchEvent` port to hear about messages coming in
-- from JS. Check out the index.html file to see how this is hooked up to a
-- WebSocket.
--


subscriptions : Model -> Sub Msg
subscriptions _ =
    twitchEvent (OnTwitchEvent << decodeValue twitchEventDecoder)
