# Quest-Object-Alert
Since Epoch got rid of sparkles on quest objects, and so many of their custom quest objects are hard to spot, this addon will help alert you when you mouse over one so you can find them.

<img width="485" height="458" alt="Flare Screenshot" src="https://github.com/user-attachments/assets/f1122c4e-b96d-4d2e-b717-97ba35ce88eb" />

When your mouse hovers over an object that matches one of your quest objectives, it creates a flare on the screen and plays an audio ding.

The size, color, transparency, and duration of the flare can be configured, as well as whether and what sound will play.  
Open the config window with /qoaconfig.

Known Issue:

-If the quest objective is different from the in-world object name, this addon will not work.

Example:  Quest asks you to gather 5 "Bundles of Flowers", but the objects in the world are called "Flower Bushes", you will not see a flare or hear a sound.  
I could fix this in the future, but it'll require a database of all quests with discrepencies like these, and it's more work than I can put in for an initial release (and without a released server databsae).
