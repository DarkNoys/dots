{-# LANGUAGE DeriveDataTypeable, TypeSynonymInstances, MultiParamTypeClasses #-}

--
-- Main {{
import XMonad
-- }}



------------
-- Layouts {{
import XMonad.Layout.Grid (Grid(..))
import XMonad.Layout.TabBarDecoration
import XMonad.Layout.ThreeColumns (ThreeCol(..))
-- }}

import XMonad.Hooks.ManageHelpers (doRectFloat, isFullscreen, doFullFloat)

-- Multi toggle
import XMonad.Layout.MultiToggle (Transformer, transform, Toggle(..), mkToggle1)

-- Scratchpad
import XMonad.Util.NamedScratchpad ( NamedScratchpad(..), namedScratchpadAction
                                   , namedScratchpadManageHook, defaultFloating)

-- True fullsceen
import XMonad.Layout.NoBorders (smartBorders, noBorders)

-- Correct FS
import XMonad.Hooks.EwmhDesktops (fullscreenEventHook, ewmh)

-- Mouse resize
import XMonad.Actions.MouseResize (mouseResize)
import XMonad.Layout.WindowArranger (windowArrange)
import XMonad.Actions.FlexibleManipulate (mouseWindow, linear)

-- StackSet
import qualified XMonad.StackSet as W

-- Mouse
--
import XMonad.Actions.UpdateFocus (focusOnMouseMove, adjustEventInput)


-- Best keybinding
import XMonad.Util.EZConfig (mkKeymap)

-- Spacing
import XMonad.Layout.Spacing (spacingRaw, Border(..))

-- Gaps
import XMonad.Layout.Gaps()

-----------
-- Windows
import XMonad.Actions.CopyWindow (kill1, copyToAll, killAllOtherCopies)
import XMonad.Actions.Navigation2D as Nav -- Window navigation

-- Move to master
import XMonad.Actions.Promote (promote)

import XMonad.Actions.CycleWS (nextWS, prevWS)

import Data.Default()
import Data.Map.Strict (Map)

import XMonad.Hooks.SetWMName (setWMName)

import XMonad.Util.Run (safeSpawn)

main :: IO()
main = do
  xmonad
  $ Nav.withNavigation2DConfig navConf
  $ ewmh
  $ def
    { terminal           = myTerminal
    , workspaces         = myWorkspaces
    , focusFollowsMouse  = True
    , modMask            = mod1Mask
    , keys               = myKeys
    , layoutHook         = mouseResize $ windowArrange $ myLayout
    , manageHook         = myManageHook
    , handleEventHook    = handleEventHook def  <+> focusOnMouseMove <+> fullscreenEventHook
    , startupHook        = myStartupHook
    , borderWidth        = 3
    , normalBorderColor  = myNormalBorderColor
    , focusedBorderColor = myFocusedBorderColor
    }
  where
  navConf = def
    { Nav.defaultTiledNavigation = centerNavigation
    }

------------
-- Color --
------------

myNormalBorderColor :: String
myNormalBorderColor  = "#3b4252"

myFocusedBorderColor :: String
myFocusedBorderColor = "#b48ead"

----------------
-- Parameters --
----------------
myTerminal = "kitty"

lockScreen :: String
lockScreen = "betterlockscreen -l" -- lockScreen

appMenu :: String
appMenu = "rofi -show combi" -- application menu

fileManager :: String
fileManager = terminalExecCommand myTerminal "env ranger" -- File manager

browser :: String
browser = "firefox" -- Browser


-- Screenshots
screenshotPath :: String
screenshotPath = "~/Pictures/Screenshots/screenshot-%Y-%m-%d_\\$wx\\$h.png"

screenshot :: String
screenshot = "scrot -m " ++ screenshotPath

scriptsPath :: String
scriptsPath = "~/scripts"

-----------
-- Utils --
-----------

-- Start command in treminal
terminalExecCommand :: String -> String -> String
terminalExecCommand t c = t ++ " -e " ++ c

sendStatusReport :: MonadIO m => m ()
sendStatusReport = spawn $ scriptsPath ++ "/status.sh"

pomodoroStatus = spawn $ scriptsPath ++ "/org-pomodoro-notify-status.sh"

------------------
-- Key bindings --
------------------

myKeys :: XConfig Layout -> Map (KeyMask, KeySym) (X ())
myKeys conf = mkKeymap conf $ concatMap ($ conf) keymaps
  where
  keymaps = [ baseKeys
            , mediaKeys
            , navKeys
            , actionKeys
            , appKeys]

-- Base keys
baseKeys :: XConfig Layout -> [(String, X ())]
baseKeys _ =
  [ ("M-S-r", spawn "xmonad --restart")
  , ("M-S-q", kill1)
  , ("M-<Space>", sendMessage NextLayout)]

-- Media keys
mediaKeys :: XConfig Layout -> [(String, X ())]
mediaKeys _ =
  -- volume
  [ ("<XF86AudioRaiseVolume>", spawn "amixer -D pulse set Master 5%+ umute")
  , ("<XF86AudioLowerVolume>", spawn "amixer -D pulse set Master 5%- umute")
  , ("<XF86AudioMute>", spawn "amixer -D pulse set Master toggle umute") ]

-- Navigation keys
navKeys :: XConfig Layout -> [(String, X ())]
navKeys conf =
  [ ("M-o", windows copyToAll) -- @@ Make focused window always visible
  , ("M-S-o",  killAllOtherCopies)] -- @@ Toggle window state back
  ++
  -- Window focus and swap
  [ ("M-"++modif++key, fun direct inf)
    | (key, direct) <- directKeys
    , (fun, modif, inf) <- [ (Nav.windowSwap, "S-", False)
                           , (Nav.windowGo, "", True)]
  ]
  -- PhysicalScreens
  -- [ ("M-"++modif++key, fun action)
  --   | (key, fun) <- zip ["w", "e"] [onPrevNeighbour def, onNextNeighbour def]
  --   , (action, modif) <- [ (W.view, "")
  --                        , (W.shift, "S-")]
  -- ]

  -- Move window to Master
          ++
  [ ("Mkuuголjkkkjkjkjk-<L>", sendMessage Expand)
  , ("M-<R>", sendMessage Shrink) ]
  ++
  [ ("M-]", nextWS)
  , ("M-[", prevWS) ]
  ++
  [ ("M-S-m", promote) ]
  -- Workspace focus and move windows to workspace
  ++
  [ ("M-"++modif++wid,  windows $ fun wname)
    | (wname, wid) <- zip (workspaces conf)
                          (map show ([1 .. 9] ++ [0]))
    , (fun, modif) <- [ (W.shift, "S-")
                      , (W.greedyView, "")]]
  where
  directKeys = [("j", Nav.D),
                ("k", Nav.U),
                ("l", Nav.R),
                ("h", Nav.L)]

-- Actions
actionKeys :: XConfig Layout -> [(String, X ())]
actionKeys conf =
  [ ("<Print>", spawn screenshot)
  , ("M-t", sendStatusReport) -- status
  , ("M-y", pomodoroStatus) -- status
  , ("M-S-t", namedScratchpadAction scratchpads "tray") -- Tray
  , ("M-f", sendMessage $ Toggle SPFULL)
  , ("M-S-f", withFocused $ windows . W.sink)
  , ("M-r", withFocused $ mouseWindow linear)
  ]


-- Applications keys
appKeys :: XConfig Layout -> [(String, X ())]
appKeys conf =
  [ ("M-b", spawn browser)
  , ("M-p", spawn lockScreen)
  , ("M-m", spawn "emacsclient -c -a '' --eval \"(mu4e)\"")
  , ("M-n", spawn fileManager)
  , ("M-<Return>", spawn $ terminal conf)
  , ("M-d", spawn appMenu)
  ]

------------
-- Layout --
------------
myLayout = (id
  . mkToggle1 SPFULL
  . spacingRaw False
               (Border 6 6 6 6)
               False
               (Border 6 6 6 6)
               True
  $
  Tall 1 (10/100) (2/3) |||
  ThreeColMid 1 (3/100) (1/2) |||
  Grid |||
  Mirror (Tall 1 (3/100) (1/2))) |||
  noBorders Full

data SPFULL = SPFULL deriving (Read, Show, Eq, Typeable)
instance Transformer SPFULL Window where
    transform _ x k = k (noBorders Full) (const x)

----------------
-- Workspaces --
----------------
myWorkspaces :: [String]
myWorkspaces = [ "1:term"
               , "2:web"
               , "3:code"
               , "4:file"]
               ++ (map show $ [5..9] ++ [0])

-----------------
-- Manage Hook --
-----------------
myManageHook = composeAll
    [ className =? "stalonetray" --> doF W.focusDown
    , resource =? "Toolkit" <&&> (className =? "firefox" <||> className =? "Firefox") --> doFloat
    -- , resource =? "Navigator" <&&> (className =? "firefox" <||> className =? "Firefox") --> doFloat
    , className =? "MEGAsync" --> doFloat
    , className =? "mpv" --> doRectFloat (W.RationalRect 0.25 0.25 0.5 0.5)
    , isFullscreen --> doFullFloat
    , namedScratchpadManageHook scratchpads
    ]

------------------
-- Startup Hook --
------------------
myStartupHook :: X ()
myStartupHook = spawnHooks <+> adjustEventInput <+> setWMName "LG3D"
  where
    spawnHooks = foldl1 (>>) $ map spawn commands
    commands = [ "compton"
               , "nitrogen --restore"
               , "blueman-applet"
               , "aw-server"
               , "aw-watcher-afk"
               , "aw-watcher-window"
               , "nm-applet"
               , "keynav"]

---------------
-- Sratchpad --
---------------
scratchpads :: [NamedScratchpad]
scratchpads =
  [ NS "tray" "stalonetray" (className =? "stalonetray") defaultFloating
  ]
