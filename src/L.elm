module L exposing (..)

import Lamdera exposing (ClientId)
import Types exposing (BackendMsg, FrontendMsg, ToBackend, ToFrontend)


sendToFrontend : ClientId -> ToFrontend -> Cmd BackendMsg
sendToFrontend =
    Lamdera.sendToFrontend


sendToBackend : ToBackend -> Cmd FrontendMsg
sendToBackend =
    Lamdera.sendToBackend
