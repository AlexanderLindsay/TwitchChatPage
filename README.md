# Twitch Chat Page For OBS

This is a project that creates a web page that OBS can be pointed at to host a twitch chat which can be stylized how you want it to be.

It uses comfy.js to help get the twitch chat information and elm to build the page. Changing the structure of the resulting chat message elements will requiring modifying the elm code, while the styling is handled by the style.css file. The current structure of the chat messages is highly specific to what I currently want and is supposed to be changed. This is more of a copy and modify project rather than a download and use project.

## PreReqs

This project makes use of [elm](https://elm-lang.org/) to control the javascript/html. The elm website has a good [install guide](https://guide.elm-lang.org/install/elm.html) for the various ways that it can be installed.


## Build

elm make .\src\Main.elm --output=elm.js

## How to use

1. The most important thing is to set the stream name in the `streamname.js` file to the stream you want to view the chat for. This does not log in to twitch and so will only work for streams that don't require a login.

2. Modify the style.css file and the elm code. Run the build command in the above section. Open the `index.html` file in a browser and verify that things look like you want them too. You may have to add some chat messages to your stream to get some sample ones to appear. Repeat this step until you have the look and layout you want.

3. Setup OBS to have a Browser source and point it at the `index.html` file. From that point on you need to configure OBS how you want it.

## Who is this for

This is for me, I am putting it up here in case others are interested but I don't think this has much value for anyone else except perhaps as a curiosity, a reference, or a starting point. You can ask questions and I will probably answer them. You can make change requests and I might do them. But I probably wont be changing this much unless it breaks for me.