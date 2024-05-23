# Twitch Chat Page For OBS

This is a project that creates a web page that OBS can be pointed at to host a twitch chat which can be stylized how you want it to be.

It uses comfy.js to help get the twitch chat information and elm to build the page. Changing the structure of the resulting chat message elements will requiring modifying the elm code, while the styling is handled by the style.css file. The current structure of the chat messages is highly specific to what I currently want and is supposed to be changed. This is more of a copy and modify project rather than a download and use project.

## PreReqs

This project makes use of [elm](https://elm-lang.org/) to control the javascript/html. The elm website has a good [install guide](https://guide.elm-lang.org/install/elm.html) for the various ways that it can be installed.


## build

elm make .\src\Main.elm --output=elm.js