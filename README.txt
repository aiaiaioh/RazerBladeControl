========================================================================
  RAZER BLADE CONTROL
  A lightweight, open-source alternative to Razer Synapse for older
  Razer Blade laptops.
========================================================================

WHAT IT DOES
  - Keyboard lighting effects
  - Power / performance and battery options
  - Fn-row control (use F1-F12 as media keys without holding Fn)
  - A small background service ("daemon") plus a simple control window

  It is NOT affiliated with or endorsed by Razer.


PLEASE READ FIRST - IT MIGHT NOT WORK ON YOUR MACHINE
  This is an experimental community project. It only works on the Razer
  models whose hardware it recognises. If it can't detect your laptop,
  it simply won't do anything - it won't harm your device, it just won't
  connect. Trying it costs you nothing; supported hardware is limited.

  Confirmed working:
    - Razer Blade 14 (2022) - RZ09-0427
  Untested / unknown:
    - Other Razer Blade models - try it and let us know!


REQUIREMENTS
  - Windows 10 or 11, 64-bit
  - Administrator rights (the background service needs direct hardware
    access - that's why you'll see a UAC prompt)
  - Razer Synapse should be CLOSED or uninstalled. Synapse holds the
    keyboard/hardware and will fight this app for control.


HOW TO RUN
  Portable version:
    1. Extract this folder anywhere (e.g. your Desktop).
    2. Double-click razer-gui.exe.

  Installer version:
    1. Run the setup, click through it, then launch from the Start menu.

  On first launch a UAC prompt appears - that's the background service
  starting up. Approve it, and the control window connects on its own.


"WINDOWS PROTECTED YOUR PC" MESSAGE
  Because this is a small open-source app, it isn't code-signed, so
  Windows SmartScreen shows a blue warning the first time you run it.
  This is expected. To continue:
       Click "More info"  ->  then "Run anyway".
  (You can read the full source code on GitHub if you'd like to verify
   what it does before running it.)


ANTIVIRUS
  Some antivirus tools flag apps that talk directly to hardware. If yours
  quarantines it, you may need to allow it manually. The source is public
  for inspection.


STARTING WITH WINDOWS (optional)
  In the app, go to the System tab and enable "Run daemon at startup".
  After that it launches automatically when you log in.


IF THE WINDOW SAYS "Cannot connect to razer-daemon"
  - Click the "Start Daemon" button and approve the UAC prompt.
  - Make sure Razer Synapse isn't running.
  - If it still won't connect, your device may not be supported.


WHERE YOUR SETTINGS ARE STORED
  %APPDATA%\razercontrol\
  (Uninstalling leaves this folder in place; delete it manually if you
   want a completely clean removal.)


SOURCE, UPDATES & REPORTING PROBLEMS
  https://github.com/aiaiaioh/razer-control-win
  Please report your laptop model and what did / didn't work - it helps
  build the compatibility list.
