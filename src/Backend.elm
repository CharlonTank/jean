module Backend exposing (..)

import Html
import L
import Lamdera exposing (ClientId, SessionId)
import Types exposing (..)


app =
    Lamdera.backend
        { init = init
        , update = update
        , updateFromFrontend = updateFromFrontend
        , subscriptions = subscriptions
        }


subscriptions : BackendModel -> Sub BackendMsg
subscriptions _ =
    Lamdera.onConnect ClientConnected


init : ( BackendModel, Cmd BackendMsg )
init =
    ( { message = "Hello from backend!", messages = [] }
    , Cmd.none
    )


update : BackendMsg -> BackendModel -> ( BackendModel, Cmd BackendMsg )
update msg model =
    case msg of
        NoOpBackendMsg ->
            ( model, Cmd.none )

        ClientConnected sessionId clientId ->
            ( model, L.sendToFrontend clientId (ReceiveMessageFromBackend model.messages) )


updateFromFrontend : SessionId -> ClientId -> ToBackend -> BackendModel -> ( BackendModel, Cmd BackendMsg )
updateFromFrontend sessionId clientId msg model =
    case msg of
        NoOpToBackend ->
            ( model, Cmd.none )

        ChangeMessageToBackend newValue ->
            ( { model | message = newValue, messages = newValue :: model.messages }
            , Lamdera.broadcast (ReceiveMessageFromBackend (newValue :: model.messages))
            )
