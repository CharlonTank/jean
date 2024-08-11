module Frontend exposing (..)

import Browser exposing (UrlRequest(..))
import Browser.Navigation as Nav
import Element exposing (layout, text, column)
import Element.Input as Input
import L
import Lamdera
import Types exposing (..)
import Url


app =
    Lamdera.frontend
        { init = init
        , onUrlRequest = UrlClicked
        , onUrlChange = UrlChanged
        , update = update
        , updateFromBackend = updateFromBackend
        , subscriptions = \m -> Sub.none
        , view = view
        }


init : Url.Url -> Nav.Key -> ( FrontendModel, Cmd FrontendMsg )
init url key =
    ( { key = key
      , message = "Welcome to Lamdera! You're looking at the auto-generated base implementation. Check out src/Frontend.elm to start coding!"
      , messages = []
      }
    , Cmd.none
    )


update : FrontendMsg -> FrontendModel -> ( FrontendModel, Cmd FrontendMsg )
update msg model =
    case msg of
        UrlClicked urlRequest ->
            case urlRequest of
                Internal url ->
                    ( model
                    , Nav.pushUrl model.key (Url.toString url)
                    )

                External url ->
                    ( model
                    , Nav.load url
                    )

        UrlChanged url ->
            ( model, Cmd.none )

        NoOpFrontendMsg ->
            ( model, Cmd.none )

        ChangeMessage newValue ->
            ( { model | message = newValue }
            , L.sendToBackend (ChangeMessageToBackend newValue)
            )

        SendMessageToBackend newMessage ->
            ( { model | message = "" }
            , L.sendToBackend (SendMessageToBackend newMessage)
            )


updateFromBackend : ToFrontend -> FrontendModel -> ( FrontendModel, Cmd FrontendMsg )
updateFromBackend msg model =
    case msg of
        NoOpToFrontend ->
            ( model, Cmd.none )

        ReceiveMessageFromBackend newMessages ->
            ( { model | messages = newMessages }
            , Cmd.none
            )


view : FrontendModel -> Browser.Document FrontendMsg
view model =
    { title = "SITE WEB"
    , body =
        [ layout []
            (column []
                [ Input.text []
                    { onChange = ChangeMessage
                    , text = model.message
                    , placeholder = Nothing
                    , label = Input.labelAbove [] (text "input")
                    }
                , Input.button [ Input.onPress (SendMessageToBackend model.message) ] (text "Send")
                , column []
                    (List.map (\msg -> text msg) model.messages)
                ]
            )
        ]
    }
