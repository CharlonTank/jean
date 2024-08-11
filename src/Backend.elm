module Backend exposing (..)

import Auth.Common
import Auth.Flow
import Auth.Method.EmailMagicLink
import Auth.Method.OAuthGithub
import Auth.Method.OAuthGoogle
import DebugApp
import Dict exposing (Dict)
import Env
import Html
import L
import Lamdera exposing (ClientId, SessionId)
import Time exposing (Posix)
import Types exposing (..)


app =
    DebugApp.backend
        NoOpBackendMsg
        "ccb6fb00e4b9c6a6"
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
    ( { message = "Hello from backend!", pendingAuths = Dict.empty, sessions = Dict.empty, users = Dict.empty }
    , Cmd.none
    )


update : BackendMsg -> BackendModel -> ( BackendModel, Cmd BackendMsg )
update msg model =
    case msg of
        NoOpBackendMsg ->
            ( model, Cmd.none )

        ClientConnected sessionId clientId ->
            ( model, L.sendToFrontend clientId (ReceiveMessageFromBackend model.message) )

        AuthBackendMsg authMsg ->
            Auth.Flow.backendUpdate (backendConfig model) authMsg


updateFromFrontend : SessionId -> ClientId -> ToBackend -> BackendModel -> ( BackendModel, Cmd BackendMsg )
updateFromFrontend sessionId clientId msg model =
    case msg of
        NoOpToBackend ->
            ( model, Cmd.none )

        ChangeMessageToBackend newValue ->
            ( { model | message = newValue }
            , Lamdera.broadcast (ReceiveMessageFromBackend newValue)
            )

        AuthToBackend authToBackend ->
            Auth.Flow.updateFromFrontend (backendConfig model) clientId sessionId authToBackend model

        GetUserToBackend ->
            case Dict.get sessionId model.sessions of
                Just userInfo ->
                    case Dict.get userInfo.email model.users of
                        Just user ->
                            ( model, Cmd.batch [ Lamdera.sendToFrontend clientId <| UserInfoMsg <| Just userInfo, Lamdera.sendToFrontend clientId <| UserDataToFrontend <| userToFrontend user ] )

                        Nothing ->
                            let
                                user =
                                    createUser userInfo

                                newModel =
                                    insertUser userInfo.email user model
                            in
                            ( newModel, Cmd.batch [ Lamdera.sendToFrontend clientId <| UserInfoMsg <| Just userInfo, Lamdera.sendToFrontend clientId <| UserDataToFrontend <| userToFrontend user ] )

                Nothing ->
                    ( model, Lamdera.sendToFrontend clientId <| UserInfoMsg Nothing )

        LoggedOut ->
            ( { model | sessions = Dict.remove sessionId model.sessions }, Cmd.none )


renewSession : Lamdera.SessionId -> Lamdera.ClientId -> BackendModel -> ( BackendModel, Cmd BackendMsg )
renewSession _ _ model =
    ( model, Cmd.none )


handleAuthSuccess : BackendModel -> Lamdera.SessionId -> Lamdera.ClientId -> Auth.Common.UserInfo -> Auth.Common.MethodId -> Maybe Auth.Common.Token -> Time.Posix -> ( BackendModel, Cmd BackendMsg )
handleAuthSuccess backendModel sessionId clientId userInfo _ _ _ =
    let
        sessionsWithOutThisOne : Dict Lamdera.SessionId Auth.Common.UserInfo
        sessionsWithOutThisOne =
            Dict.filter (\_ { email } -> email /= userInfo.email) backendModel.sessions

        newSessions =
            Dict.insert sessionId userInfo sessionsWithOutThisOne

        response =
            AuthSuccess userInfo
    in
    ( { backendModel | sessions = newSessions }, Cmd.batch [ Lamdera.sendToFrontend clientId response ] )


logout : Lamdera.SessionId -> Lamdera.ClientId -> BackendModel -> ( BackendModel, Cmd msg )
logout sessionId _ model =
    ( { model | sessions = model.sessions |> Dict.remove sessionId }, Cmd.none )


backendConfig : BackendModel -> Auth.Flow.BackendUpdateConfig FrontendMsg BackendMsg ToFrontend FrontendModel BackendModel
backendConfig model =
    { asToFrontend = AuthToFrontend
    , asBackendMsg = AuthBackendMsg
    , sendToFrontend = Lamdera.sendToFrontend
    , backendModel = model
    , loadMethod = Auth.Flow.methodLoader config.methods
    , handleAuthSuccess = handleAuthSuccess model
    , isDev = True
    , renewSession = renewSession
    , logout = logout
    }


config : Auth.Common.Config FrontendMsg ToBackend BackendMsg ToFrontend FrontendModel BackendModel
config =
    { toBackend = AuthToBackend
    , toFrontend = AuthToFrontend
    , backendMsg = AuthBackendMsg
    , sendToFrontend = Lamdera.sendToFrontend
    , sendToBackend = Lamdera.sendToBackend
    , renewSession = renewSession
    , methods = [ Auth.Method.OAuthGoogle.configuration Env.googleAppClientId Env.googleAppClientSecret ]
    }


createUser : Auth.Common.UserInfo -> User
createUser userInfo =
    { email = userInfo.email }


insertUser : Email -> User -> BackendModel -> BackendModel
insertUser email newUser model =
    { model | users = Dict.insert email newUser model.users }


userToFrontend : User -> UserFrontend
userToFrontend user =
    { email = user.email }
