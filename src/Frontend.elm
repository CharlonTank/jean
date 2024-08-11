module Frontend exposing (..)

import Auth.Common
import Auth.Flow
import Auth.Method.OAuthGoogle
import Browser exposing (UrlRequest(..))
import Browser.Navigation as Nav
import Element exposing (layout, text)
import Element.Input as Input
import Html
import Html.Events as HE
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


{-| replace with your app function to try it out
-}
appWithAuth =
    Lamdera.frontend
        { init = initWithAuth
        , onUrlRequest = UrlClicked
        , onUrlChange = UrlChanged
        , update = update
        , updateFromBackend = updateFromBackend
        , subscriptions = always Sub.none
        , view = viewWithAuth
        }


init : Url.Url -> Nav.Key -> ( FrontendModel, Cmd FrontendMsg )
init url key =
    ( { key = key
      , message = "Welcome to Lamdera! You're looking at the auto-generated base implementation. Check out src/Frontend.elm to start coding!"
      , authFlow = Auth.Common.Idle
      , authRedirectBaseUrl = { url | query = Nothing, fragment = Nothing }
      , login = NotLogged False
      , currentUser = Nothing
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

        GoogleSigninRequested ->
            Auth.Flow.signInRequested "OAuthGoogle" { model | login = NotLogged True } Nothing
                |> Tuple.mapSecond (AuthToBackend >> Lamdera.sendToBackend)

        Logout ->
            ( { model | login = NotLogged False }, Lamdera.sendToBackend LoggedOut )


updateFromBackend : ToFrontend -> FrontendModel -> ( FrontendModel, Cmd FrontendMsg )
updateFromBackend msg model =
    case msg of
        NoOpToFrontend ->
            ( model, Cmd.none )

        ReceiveMessageFromBackend newMessage ->
            ( { model | message = newMessage }
            , Cmd.none
            )

        AuthToFrontend authToFrontendMsg ->
            authUpdateFromBackend authToFrontendMsg model

        AuthSuccess userInfo ->
            ( { model | login = LoggedIn userInfo }, Cmd.batch [ Nav.pushUrl model.key "/", Lamdera.sendToBackend GetUserToBackend ] )

        UserDataToFrontend currentUser ->
            ( { model | currentUser = Just currentUser }, Cmd.none )

        UserInfoMsg mUserinfo ->
            case mUserinfo of
                Just userInfo ->
                    ( { model | login = LoggedIn userInfo }, Cmd.none )

                Nothing ->
                    ( { model | login = NotLogged False }, Cmd.none )


view : FrontendModel -> Browser.Document FrontendMsg
view model =
    { title = "SITE WEB"
    , body =
        [ layout []
            (Input.text []
                { onChange = ChangeMessage
                , text = model.message
                , placeholder = Nothing
                , label = Input.labelAbove [] (text "input")
                }
            )
        ]
    }


callbackForGoogleAuth : FrontendModel -> Url.Url -> Nav.Key -> ( FrontendModel, Cmd FrontendMsg )
callbackForGoogleAuth model url key =
    let
        ( authM, authCmd ) =
            Auth.Flow.init model
                "OAuthGoogle"
                url
                key
                (\msg -> Lamdera.sendToBackend (AuthToBackend msg))
    in
    ( authM, authCmd )


authCallbackCmd : FrontendModel -> Url.Url -> Nav.Key -> ( FrontendModel, Cmd FrontendMsg )
authCallbackCmd model url key =
    let
        { path } =
            url
    in
    case path of
        "/login/OAuthGoogle/callback" ->
            callbackForGoogleAuth model url key

        _ ->
            ( model, Cmd.none )


initWithAuth : Url.Url -> Nav.Key -> ( FrontendModel, Cmd FrontendMsg )
initWithAuth url key =
    let
        ( model, cmds ) =
            init url key
    in
    authCallbackCmd model url key
        |> Tuple.mapSecond (\cmd -> Cmd.batch [ cmds, cmd, Lamdera.sendToBackend GetUserToBackend ])


viewWithAuth : Model -> Browser.Document FrontendMsg
viewWithAuth model =
    { title = "View Auth Test"
    , body =
        [ Html.button
            [ HE.onClick GoogleSigninRequested ]
            [ Html.text "Sign in with Google" ]
        ]
    }


authUpdateFromBackend : Auth.Common.ToFrontend -> FrontendModel -> ( FrontendModel, Cmd FrontendMsg )
authUpdateFromBackend authToFrontendMsg model =
    case authToFrontendMsg of
        Auth.Common.AuthInitiateSignin url ->
            Auth.Flow.startProviderSignin url model

        Auth.Common.AuthError err ->
            Auth.Flow.setError model err

        Auth.Common.AuthSessionChallenge _ ->
            ( model, Cmd.none )
