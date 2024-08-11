module Types exposing (..)

import Browser exposing (UrlRequest)
import Browser.Navigation exposing (Key)
import Lamdera exposing (ClientId, SessionId)
import Url exposing (Url)


type alias FrontendModel =
    { key : Key
    , message : String
    }


type alias BackendModel =
    { message : String
    }


type FrontendMsg
    = UrlClicked UrlRequest
    | UrlChanged Url
    | NoOpFrontendMsg
    | ChangeMessage String


type ToBackend
    = NoOpToBackend
    | ChangeMessageToBackend String


type BackendMsg
    = NoOpBackendMsg
    | ClientConnected SessionId ClientId


type ToFrontend
    = NoOpToFrontend
    | ReceiveMessageFromBackend String
