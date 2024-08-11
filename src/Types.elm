module Types exposing (..)

import Auth.Common
import Browser exposing (UrlRequest)
import Browser.Navigation exposing (Key)
import Dict exposing (Dict)
import Lamdera exposing (ClientId, SessionId)
import Url exposing (Url)


type alias FrontendModel =
    { key : Key
    , message : String
    , authFlow : Auth.Common.Flow
    , authRedirectBaseUrl : Url
    , login : LoginState
    , currentUser : Maybe UserFrontend
    }


type alias BackendModel =
    { message : String
    , pendingAuths : Dict Lamdera.SessionId Auth.Common.PendingAuth
    , sessions : Dict Lamdera.SessionId Auth.Common.UserInfo
    , users : Dict Email User
    }


type FrontendMsg
    = UrlClicked UrlRequest
    | UrlChanged Url
    | NoOpFrontendMsg
    | ChangeMessage String
    | GoogleSigninRequested
    | Logout


type ToBackend
    = NoOpToBackend
    | ChangeMessageToBackend String
    | AuthToBackend Auth.Common.ToBackend
    | GetUserToBackend
    | LoggedOut


type BackendMsg
    = NoOpBackendMsg
    | ClientConnected SessionId ClientId
    | AuthBackendMsg Auth.Common.BackendMsg


type ToFrontend
    = NoOpToFrontend
    | ReceiveMessageFromBackend String
    | AuthToFrontend Auth.Common.ToFrontend
    | AuthSuccess Auth.Common.UserInfo
    | UserInfoMsg (Maybe Auth.Common.UserInfo)
    | UserDataToFrontend UserFrontend


type alias Email =
    String


type alias User =
    { email : Email }


type alias UserFrontend =
    { email : Email }


type LoginState
    = JustArrived
    | NotLogged Bool
    | LoginTokenSent
    | LoggedIn Auth.Common.UserInfo
