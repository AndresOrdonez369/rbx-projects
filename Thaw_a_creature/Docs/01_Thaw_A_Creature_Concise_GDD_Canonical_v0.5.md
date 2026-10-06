# THAW A CREATURE

## Concise Game Design Document - Canonical v0.5

**Platform:** Roblox  
**Genre:** Creature Collection / Expedition / Progression  
**Setting:** Stylized Norse-inspired frozen fantasy  
**Launch Target:** 3-week production  
**Launch Content Target:** 16 creatures, 5 Ice types, 4 rarities, 10 Hearth levels, 4 active Pen creature slots  

### Revision notes

- Locked multiplayer base topology and visitor-Warmth behavior.
- Locked no intentional raw-Ice drop action and full-Warmth Freeze recovery.
- Added private first-time onboarding Ice so a depleted shared field cannot break onboarding.
- Locked Special Ice failure/despawn behavior and reusable silhouette-profile philosophy.
- Corrected Week-1 Archive scope and the final experience-identity wording.

---


### v0.5 Revision - Jackpot Scale + Big-Number Progression

The v0.5 revision promotes per-copy size jackpots, big-number Warmth progression, stronger Hearth presentation, and expanded Day 6-7 content as canonical design.

## 1. High Concept

A supernatural winter known as The Great Frost has trapped creatures throughout a vast frozen
wilderness.
Players leave the safety of their Hearth, spot mysterious creatures trapped inside Ice, and risk
their Warmth to physically bring those Ice blocks home before freezing.
Recovered Ice thaws over time inside the player's Pen. Once ready, the player:

**CRACK -> CRACK -> SMASH**
to awaken the creature inside.
Creatures can then generate money, be sold, or be Equipped to make the player dramatically
faster-allowing increasingly dangerous expeditions deeper into the frozen world.


## 2. Core Fantasy

"How far into the Great Frost will I go for what is trapped inside?"
The game should make the player feel like an increasingly powerful frozen-wilderness explorer.
Early game:

A nearby Ice block feels dangerous to retrieve.
Late game:

The player races through previously threatening regions with a mythical
creature beside them, searching for enormous supernatural Ice deep in the
wilderness.

## 3. Unique Selling Proposition

The collectible has a journey before it becomes a reward.
Players do not simply buy or hatch creatures.
They:

SEE IT
-> WANT IT
-> RISK THE EXPEDITION
-> BRING IT HOME
-> WATCH IT THAW
-> SMASH IT OPEN
The Ice itself becomes desirable before the player knows exactly what is inside.
The player should form a story around important creatures:

"I saw this enormous Ice incredibly far away, barely made it home before
freezing, waited for it to thaw, and it turned into a Mammoth."
If the game feels like:

"Find object -> wait -> get pet"
the USP has failed.
The retrieval itself must be memorable.


## 4. Internal Tagline

See it. Risk it. Bring it home. Watch it thaw. Smash it open.

## 5. Core Emotional Pillars

```text
               Pillar                           Player Feeling
               [Mystery] Mystery                        What is trapped inside that Ice?
               [Risk] Risk                           Can I get it home before I freeze?
               [Anticipation] Anticipation                   It's almost ready...
               [Payoff] Payoff                         What am I about to awaken?
               [Ownership] Ownership                      Look at everything I've brought
                                                home.
               [Power] Power                          I'm dramatically faster than I used
                                                to be.
               [Progression] Progression                   I can finally reach what I saw
                                                earlier.
               [Spectacle] Spectacle                      Something huge is happening in this
                                                world.
```


## 6. Epicness Philosophy

Epicness should come from:

scale + presentation + consequence
around systems we are already building.
It should not require adding unnecessary mechanics.
When the game needs more epicness, first ask:

"Which existing moment needs to feel bigger?"
rather than:

"What new system should we add?"

## 7. Core Gameplay Loop


```text
            1   LEAVE THE HEARTH
            2           v
            3   SEARCH THE FROZEN WILDERNESS
            4           v
            5   SPOT A DESIRABLE ICE
            6           v
            7   RISK WARMTH TO REACH IT
            8           v
            9   CARRY IT HOME
           10           v
           11   PLACE IT IN YOUR PEN
           12           v
           13   ICE THAWS OVER TIME
           14           v
           15   KEEP EXPLORING / TRAIN WARMTH / MANAGE CREATURES
           16           v
           17   THE GREAT FROST / NIGHT RESET
           18           v
           19   NEW ICE APPEARS + THAWING ACCELERATES
           20           v
           21   ICE BECOMES READY
           22           v
           23   CRACK -> CRACK -> SMASH
           24           v
           25   AWAKEN CREATURE
           26           v
           27   PEN / EQUIP / SELL
           28           v
           29   EARN -> IMPROVE HEARTH -> TRAIN MORE WARMTH
           30           v
           31   MOVE FASTER + SURVIVE LONGER
           32           v
           33   REACH STRANGER ICE
```


The end of one goal should create the next one.

The reward should advertise the next reward.

## 8. Setting - The Great Frost

The world is a stylized Norse-inspired fantasy, not a historical Viking simulator or lore-heavy
adaptation of Norse mythology.
The visual language may use:
auroras;
runestones;
carved wood;
braziers and Hearths;
snowy mountains;
magical frost;
ancient ruins;
supernatural Ice;

mythical beasts.
The setting exists to make the existing mechanics feel larger and more coherent.
The player is not being promised:
Viking combat;
raids;
historical simulation;
mythology quests;
weapons gameplay.
The fantasy is:

ancient and mythical creatures awakening from an endless magical winter.

## 9. World Structure

The launch world is one continuous frozen wilderness.
Progression moves outward through:

Warm Hearth -> Regular -> Thick -> Ancient -> Black -> Meteor
Each region becomes:
colder;
stranger;
more visually supernatural;
more valuable;
harder to retrieve Ice from.
There are no portals or separate worlds.
Players should always understand:

farther = more dangerous = more exciting possibilities.

Launch multiplayer home layout:
up to four personal bases are grouped side-by-side along one shared home camp edge;
all bases face the same primary wilderness direction;
each player's Warm Zone is private gameplay space even though the camp is socially shared;
another player's Hearth does not refill Current Warmth or train Maximum Warmth.
This keeps route distance readable and prevents neighboring bases from becoming unintended expedition checkpoints.

## 10. Creature Fantasy Escalation

Creature progression should feel increasingly extraordinary.
Regular

Familiar frozen wildlife.
Thick
Larger and more impressive beasts.
Ancient
Prehistoric creatures from another age.
Black
Supernatural or mysterious beasts.
Meteor
Legendary creatures that feel almost mythological.
The overall escalation is:

Animal -> Beast -> Ancient -> Supernatural -> Legendary

## 11. No Hard Area Gates

Regions do not require specific Warmth, Heater, or creature levels.
Instead, each area has:

[Risk] Recommended Warmth
A player can always attempt an area early.
That allows moments like:

"I'm definitely underprepared...but maybe I can make it."
Recommended Warmth is guidance, not permission.


## 12. Warmth

Warmth represents expedition endurance.
The player has:

**Current Warmth**  
Drains while outside the safe Hearth area.

**Maximum Warmth**  
Permanent, uncapped progression.

Warmth is intentionally a **big-number progression stat**. Early values may be in the hundreds, while deeper progression may require thousands, tens of thousands, hundreds of thousands, or more. Watching the number climb should feel satisfying rather than clinically precise.

If Current Warmth reaches zero:

**FROZEN**

The player returns home and loses the Ice currently being carried.
They do not lose permanent progression.

Different regions may apply dramatically stronger cold severity. This allows larger Warmth values without requiring an impractically enormous map.

## 13. Permanent Warmth Training

While inside their own heated base area, the player continuously trains:

**Maximum Warmth**

Warmth has:
- no maximum;
- no Warmth XP;
- no training currency;
- no hard training cap.

The displayed gain should be deliberately gratifying. The player should see large values rising rapidly as the Hearth improves.

The fantasy remains simple:

> Stay beside your Hearth -> become more resistant to the cold -> attempt more absurd regions.

## 14. Hearth / Heater Progression

The Heater system is presented within the fantasy as the player's increasingly powerful **Hearth**.
Cash upgrades it.

A better Hearth means:
- Maximum Warmth trains dramatically faster;
- deeper Recommended Warmth targets become realistically reachable;
- the home base visibly communicates progression.

The Hearth does not determine a maximum Warmth value and does not directly grant a fixed Warmth level.

The Hearth must receive strong presentation because it is one of the game's main progression engines. Without changing its function, it should read as an important landmark through:
- strong fire/light/smoke/embers;
- a visible WarmZone treatment;
- `HEARTH LV. X`;
- visible `+Warmth/sec` training rate;
- next upgrade cost or `MAX` state.

The player should immediately understand:

> "Standing here is permanently making me stronger."

## 15. Equipped Creature = Speed

An Equipped creature provides large and immediately noticeable Movement Speed.

Speed is now determined by the **individual creature copy**, not rarity alone.
Each species has a base traversal identity, and the inherited size roll modifies that copy's final Speed.

This creates two simultaneous progression questions:
- Which species is naturally better for traversal?
- Did I roll an unusually large copy with an exceptional Speed modifier?

Size may strongly improve Speed, but it must scale more gently than Pen Income so even a `5x` visual jackpot does not destroy Warmth/distance gameplay.

The emotional requirement remains:

> "WHOA. I'm fast now."

Creature Speed serves two purposes:

**Progression**  
Reach farther before Warmth runs out.

**Compression**  
Previously solved terrain becomes much faster to cross during future attempts.

## 16. Speed Must Be Obvious

Speed jumps should be large enough that players do not need a stat panel to feel them, while the exact final Speed is still displayed on the creature for comparison.

A creature's final Speed comes from:

```text
Species Base Speed
x
Size-Derived Speed Multiplier
```

Movement presentation can reinforce actual Speed through:
- faster run animation;
- subtle FOV response;
- snow trails;
- rarity/size-specific effects.

Actual server-authoritative movement speed must change. Presentation cannot substitute for the real stat.

## 17. Carrying Ice


Players may carry:

one Ice at a time.
While carrying Ice:

Warmth drains faster.
Carrying Ice does not reduce Speed.
The tension comes from:

Can I make it home before the cold wins?

There is no intentional Drop Ice action at launch. A carry ends through successful Pen deposit or through expedition failure/reset/disconnect rules.
not from deliberately making movement frustrating.


## 18. Freezing

At zero Warmth:

**FROZEN**
The player:
loses/releases the carried Ice;
returns home;
refills;
can immediately try again.
On Freeze recovery, Current Warmth is restored immediately to Maximum Warmth at the player's own Hearth.
Failure costs:

time and opportunity
rather than permanent progress.
Higher creature Speed naturally makes future reattempts faster.


## 19. Ice Progression

Launch progression contains:
1. Regular Ice
2. Thick Ice
3. Ancient Ice
4. Black Ice
5. Meteor Ice

Different Ice types can have different:
- creature pools;
- rarity distributions;
- thaw times;
- base visual size;
- reference weight;
- effects;
- Recommended Warmth context.

Every wilderness Ice also receives an independent **size/weight jackpot roll** when it spawns.

Each Ice type has a base/reference size. The roll is converted to visible Scale through:

```text
Scale = cbrt(ActualWeight / ReferenceWeight)
```

The formula creates the size variation. Visual Scale is not rolled separately afterward.

The current design intentionally supports extreme rolls up to **5.0x visual Scale**. A near-maximum Ice may be absurdly large, visible from far away, overlap surrounding scenery, and become an immediate social/aspirational event.

Size is visible before retrieval but does not reveal the exact hidden creature or rarity.
Going farther must unlock new creature possibilities, not merely better percentages.

## 20. Seeing Ice

Players should often see desirable content before they can comfortably retrieve it.
This is intentional.

A player should occasionally stand at home or in an early zone and see:
- an enormous Ice formation;
- a freakishly oversized random Ice roll;
- strange runes;
- a giant obscured silhouette;
- a distant supernatural glow;

and think:

> "I NEED that one."

Visible aspiration is a core progression tool.

Size adds a new pre-reveal jackpot signal:

```text
Ice Type
+ Distance
+ Visible Scale
= desirability before the player knows the exact reward
```

A giant Ice is a promise that the resulting creature copy will preserve the same size multiplier after reveal.

## 21. Silhouette Rule

Ice should give clues without reliably revealing the exact creature.
Information progresses through:

distant vague shape
-> closer identifying features
-> clearer silhouette during thaw
-> almost recognizable form
-> final exact reveal
Mystery must survive until the Smash.

Launch uses a small reusable silhouette-profile set rather than one exact silhouette per species. Multiple species intentionally share profiles so the outline remains a clue rather than a guaranteed answer. Exact mappings live in Implementation Constants.


## 21A. One Size Roll - Full Journey

The server creates one authoritative size/weight roll when wilderness Ice spawns.
That roll survives the entire journey:

```text
Wilderness Ice
-> Carried Ice
-> Deposited / Thawing Ice
-> Ready Ice
-> CRACK -> CRACK -> SMASH
-> Revealed Creature Copy
```

There is no second creature-size reroll at reveal.
A gigantic Ice should not reveal a tiny version of its creature.

The same multiplier applies to each object's own base/reference size, so different Ice types and species remain visually distinct while sharing the jackpot magnitude.

Size initially does **not** change:
- hidden rarity odds;
- thaw duration;
- carry Warmth multiplier;
- Great Frost rules;
- guardian count.

Those remain separate balance systems unless explicitly revised later.


## 21B. Jackpot Scale Philosophy

Scale should be allowed to become intentionally ridiculous.
The rarest outcomes may reach approximately **5x visual Scale**.

At the top end:
- a creature may dominate the player's screen;
- a Pen creature may visually spill into neighboring Pen space;
- other players should notice it immediately;
- the result should naturally create screenshots, stories, and social comparison.

Gameplay allocation remains clean even when visuals overlap. Four Pen positions remain four logical income positions.

The purpose is not realism. The purpose is a jackpot moment that is readable before and after reveal.


## 22. Pen = Player's Home Story

The Pen is not merely an income interface.
It should visually communicate:

everything the player has brought back from the wilderness.
Inside the Pen can be:
creatures wandering;
ordinary Ice thawing;
giant unusual Ice;
Black or Meteor Ice pulsing;
Ice almost ready to reveal.
The Pen becomes a:

living trophy room + anticipation space.
Another player should be able to look at it and understand:

"This player has done things I haven't."

## 23. Pen Creature Slots

The Pen contains:

4 active income creature positions.
Creatures assigned there generate Cash.

Duplicates are allowed.


## 24. Pen Thawing

There is no dedicated Thaw Machine.
Successfully retrieved Ice is placed directly inside the player's Pen.
Its thaw timer begins automatically.
Thawing Ice does not consume one of the four creature-income positions.


## 25. Unlimited Thawing

There is no gameplay limit on simultaneous thawing Ice.
Players may accumulate multiple retrieved Ice blocks in their Pen.
The natural limitation is:

one retrieval per expedition.
There are no:
Thaw Slot upgrades;
incubator purchases;
storage expansions.
If large quantities eventually become visually awkward, that should be solved through
presentation rather than progression restrictions.


## 26. Thaw Time

Different Ice types can require different amounts of time to thaw.
Thaw duration depends primarily on:

Ice Type
rather than hidden creature rarity.
Players should not be able to determine:

"Long timer = Legendary."

The exact reward remains uncertain.


## 27. Offline Thawing

Thawing continues normally while the player is offline.
A player may return later and find:

**READY TO CRACK**
Ice waiting in their Pen.
Offline:

thawing progresses normally.
Online:

Night events can accelerate thawing.
This allows offline progress without making leaving the game the fastest strategy.


## 28. Visual Thawing

Ice becomes progressively more interesting as it thaws.
Example:

opaque frost
-> partial clearing
-> visible movement/silhouette
-> major cracks
-> READY TO CRACK
The player should repeatedly walk past Ice and think:

"That thing is almost ready."

## 29. Thawing Is Passive

The player cannot repeatedly tap to eliminate Thaw Time.

The timer exists to create:

anticipation + overlapping goals.
While waiting, the player can:
explore;
retrieve more Ice;
train Warmth;
manage creatures;
sell;
inspect the Archive;
wait for the next Great Frost.


## 30. Crack -> Crack -> Smash

When thawing completes:

**READY TO CRACK**
The player performs:

CRACK
CRACK
SMASH
There is:
no failure;
no timing grade;
no combo;
no accuracy requirement.
The interaction exists for tactile anticipation and payoff.


## 31. The Great Frost / Night Cycle

The world periodically enters:

Night / The Great Frost

This is a recurring server-wide transformation.
It is not a punishment.
Players are not required to return home.
Instead, it represents:

the magical frost reshaping the wilderness.

## 32. Great Frost Reset

When the Great Frost occurs:
unclaimed wilderness Ice resets;
new Ice is distributed;
carried Ice remains safe;
Pen Ice remains safe;
currently thawing Ice receives a Thaw Surge.
The mechanical action may be simple.
The presentation should feel significant.


## 33. Great Frost Thaw Surge

Each Great Frost gives active Pen Ice:

a significant burst of thaw progress.
This creates a natural reason to remain online.
The player waiting for an Ice to finish can think:

"One more Frost and this might be ready."

## 34. Special Ice

Every configurable X Great Frost cycles, a:

Special Ice
appears somewhere in the wilderness.

It should be visually unmistakable and desirable.
Special Ice guarantees:

a high-value creature opportunity with significantly increased rarity.
It does not reveal the exact creature before thawing.
Players still have to:

see it -> reach it -> retrieve it -> survive the return -> thaw it -> smash it open.

Special Ice remains a shared opportunity until claimed or until the next Great Frost refresh. If a player carrying Special Ice freezes, resets, dies, or disconnects before depositing it, the Special Ice returns to its authored wilderness spawn only if its originating Frost cycle is still current. If a newer Great Frost has already superseded that opportunity, it disappears instead.

## 35. Social Aspiration

Multiplayer does not require PvP or stealing to create social motivation.
Players should visibly advertise progression.
Examples:
an advanced player races past at enormous Speed;
someone carries a huge Meteor Ice toward camp;
a neighboring Pen contains creatures you have never seen;
a Legendary reveal creates visible effects;
everyone sees a Special Ice appear during the Great Frost.
The desired new-player reaction is:

"How do I become THAT player?"

## 36. The Five Hero Moments

These moments are canonical production targets.
Hero Moment 1 - The First Great Frost
Timing: Early game, ideally within the first few minutes.
The sky changes.
Aurora intensifies.
Wind rises.
The wilderness transforms.

New Ice appears.
Something large or unusual may emerge in the distance.
Desired reaction:

"Wait... WHAT just happened?"

Hero Moment 2 - The Impossible-Looking Ice
Very early, the player sees something dramatically beyond their current capability.
A huge silhouette.
Strange runes.
An enormous piece of Ice.
The player cannot comfortably retrieve it yet.
Desired reaction:

"I NEED that."
This establishes long-term aspiration before the player has earned it.


Hero Moment 3 - The Barely-Made-It-Home Run
This is the recurring USP moment.
The player carries something valuable toward home.
Warmth gets dangerously low.
Presentation escalates:

frost -> stronger wind -> warning audio -> Hearth visible ahead.
They cross into safety with almost nothing remaining.
Desired reaction:

"HOLY SHIT, I MADE IT."
This moment must be memorable.


Hero Moment 4 - The Legendary Smash

A valuable Ice has been visible in the Pen for some time.
It becomes ready.

CRACK
CRACK
SMASH
The reveal gets disproportionate presentation:
explosive Ice break;
strong camera response;
sound sting;
runic/rarity VFX;
creature animation/pose;
major rarity treatment.
Desired reaction:

"NO WAY. I GOT IT."

Hero Moment 5 - Becoming the Endgame Player
The player equips a powerful mythical creature.
Their Speed increases dramatically.
They cross areas that once felt enormous in seconds.
A newer player watches them race past.
Desired internal reaction:

"I've become powerful."
Desired observer reaction:

"How do I become THAT guy?"

## 37. Hero Moment Progression Arc

Together, the Hero Moments form:

WORLD IS EPIC
First Great Frost
v
I WANT THAT
Impossible Ice
v
I SURVIVED THAT
Dangerous retrieval
v
I GOT THAT
Legendary Smash
v
I AM THAT
Endgame power fantasy
This emotional progression is a core part of the game.


## 38. Creature Roster - Launch Target

The existing 16-species launch target remains a content target unless a later roster revision explicitly changes it.

Current canonical launch roster:

**Common**
1. Penguin
2. Rabbit
3. Seal
4. Arctic Fox

**Uncommon**
5. Wolf
6. Polar Bear
7. Moose
8. Walrus

**Rare**
9. Mammoth
10. Sabertooth
11. Woolly Rhino
12. Raptor
13. Dire Wolf

**Legendary**
14. Yeti
15. Frost Serpent
16. Ice Dragon

The revised prototype already has **11 completed creature meshes** available and should put all of them to use before producing redundant blockouts.
The exact set of those 11 models must be audited from the repository before assigning prototype pools; do not infer missing model IDs from this roster.

Species should increasingly communicate ancient/supernatural/mythic fantasy as progression deepens.

## 39. Creature Ownership States

Owned creatures are now **individual copies** rather than interchangeable species counts.

Each copy has a unique identity and at minimum preserves:
- CreatureGUID;
- CreatureID / species;
- inherited WeightMultiplier / SizeRoll.

From that data the game derives:
- visual Scale;
- final Pen Income;
- final Equipped Speed.

Owned copies may be:

**In Pen**  
Generate that copy's passive Cash value.

**Equipped**  
Follow the player and provide that copy's Speed.

**In Inventory**  
Owned but inactive.

Species discovery remains species-based. Owning or selling differently sized copies does not change whether the species has been discovered.

## 40. New Creature Routing

After reveal, the server creates a unique creature copy using the exact size roll inherited from the Ice.

If the Pen has room:
- assign that CreatureGUID to the first free active Pen position.

If the Pen is full:
- the CreatureGUID remains in Inventory.

Avoid unnecessary post-reveal menus.
The emotional high should not immediately become administrative work.

## 41. Equipped Creature

Players may Equip one individual creature copy.

If Equipped from the Pen:
- its Pen slot becomes empty;
- that copy stops generating Pen income;
- the exact copy keeps its Scale and stats;
- it follows the player visually at its inherited size;
- it provides its own final Movement Speed.

For readability, creature presentation should expose at least:

```text
SPEED <value>
PEN $<value>/s
```

`PEN $/s` is the copy's intrinsic Pen Income stat even while Equipped; it does not mean an Equipped creature is actively earning.

## 42. Selling

Creatures may be sold for immediate Cash.
Selling operates on a specific CreatureGUID because copies are no longer interchangeable.

This creates the ownership decision:

```text
Pen      = money over time
Equip    = traversal Speed
Inventory = reserve / comparison
Sell     = money now
```

The size jackpot increases duplicate desirability because another copy of the same species can have meaningfully different Scale, Income, and Speed.

Selling does not remove Frozen Archive discovery.
Size does not automatically modify Sell Value unless a later explicit balance revision says so.

## 43. Frozen Archive

The Frozen Archive tracks species discovery, not individual copies.

Undiscovered entries appear as:
- silhouette / ???

Discovered entries show:
- creature;
- rarity;
- identity.

Individual copy Scale/Income/Speed belong to Inventory/Pen/Equipped presentation rather than Archive completion.

The Archive should function as an advertisement for what remains undiscovered.

## 44. Economy

Launch has one currency:

**Cash**

Main sources:
- individual Pen creature income;
- selling creatures.

Primary sink:
- Hearth upgrades.

Pen income is copy-specific. Each species supplies BaseIncome and the creature's inherited Scale modifies the final value.
The rarity-only fixed-income model is superseded by this system.

No additional currencies are required at launch.

## 45. Recursive Progression

```text
Retrieve visually desirable Ice
        v
Awaken a unique creature copy
        v
Compare Size / Income / Speed
        v
Pen copies -> Cash
        v
Cash -> Better Hearth
        v
Better Hearth -> Much Faster Warmth Training
        v
More Warmth -> Survive Harsher Regions
        +
Better Equipped Copy -> Cross Distance Faster
        v
Reach Stranger / Larger / Rarer Ice
        v
Chance at another jackpot copy
```

The systems should continually feed one another.

A rare gigantic copy should feel capable of compressing earlier progression in a memorable way without making deeper regions permanently trivial.

## 46. Productive Waiting


The player should rarely feel they are merely waiting.
While an Ice thaws, they can:
retrieve another;
permanently train Warmth;
earn Cash;
upgrade their Hearth;
manage creatures;
inspect their collection;
prepare for the next Great Frost.

Something should almost always be progressing.

## 47. Session Rhythm

A healthy session naturally alternates between:
Expedition
Retrieve something valuable.
Home
Deposit it, train, manage and watch Ice thaw.
Great Frost
Wilderness refreshes and Pen Ice accelerates.
Reveal
Smash ready Ice open.
Progression
Creature, Cash, Warmth or Speed improves.
Then:

something farther away becomes attractive.

## 48. Motivation to Go Farther

The player should repeatedly encounter:

something they want before they can comfortably obtain it.
Motivation comes from:
inaccessible-looking Ice;
undiscovered Archive silhouettes;
creatures seen on other players;
Special Ice;
strange later environments;
increasingly mythic creature possibilities.
The desired question is:

"What is out there that I still haven't seen?"

## 49. Motivation to Return

Launch does not depend on:
Daily Quests;
login streaks;
daily reward calendars.
Return motivation comes from unfinished progression:
Ice continuing to thaw offline;
missing Archive creatures;
unfinished Warmth progression;
desired Hearth upgrade;
regions the player still cannot comfortably reach;
future Great Frost cycles;
Special Ice opportunities.
A returning player may immediately discover:

something they brought home yesterday is now READY TO CRACK.

## 50. First Minutes

The opening should communicate the entire fantasy with minimal explanation.

First expedition
Player sees nearby mysterious Ice.
Leaves safety.
Warmth begins draining.
Retrieves Ice.
Returns home.
Places it in the Pen.
At home
Ice begins thawing.
Player discovers Warmth training.
Player can retrieve another Ice or remain briefly at home.
First reveal
An onboarding Ice becomes ready quickly enough to teach:

**CRACK -> CRACK -> SMASH**
Creature revealed.
Equip teaches:

better creature = faster movement.
Early spectacle
Within the first few minutes, the player should also witness:

their first Great Frost
and ideally see:

one aspirational Ice far beyond their current capability.
The player should know very early:

the world gets much crazier than this.

Launch multiplayer onboarding reliability:
A first-time player who has no discovered creatures, no thawing Ice, and no carried Ice may receive one private onboarding Regular Ice at a dedicated authored point near their own base. It uses the normal Regular rarity and creature roll, so the reward remains genuinely random. It is not contested by other players and is not removed by Great Frost. If the player fails before deposit, it may reappear until they successfully bring an Ice home. Once the player has a deposited/revealed progression path, onboarding returns entirely to the shared wilderness.

This follows the rule: script the learning opportunity, never the excitement.

## 51. Prototype Purpose

The Week-1 prototype now exists to validate both the proven retrieval loop and the newly approved jackpot/progression expansion:

- 1 player;
- greybox/expanding progression world;
- all 11 already-completed creature meshes integrated when repository audit confirms their IDs;
- Regular + Thick plus additional functional Ice types brought forward as Days 6-7 allow;
- one authoritative Ice size/weight roll with up to 5x visual Scale;
- exact size inheritance into the revealed creature copy;
- per-copy creature ownership;
- species BaseIncome + BaseSpeed;
- size-derived Pen Income + Equipped Speed;
- visible creature Speed and Pen Income stats;
- big-number uncapped Warmth progression;
- Hearth upgrades with dramatically increasing training rates;
- Recommended Warmth signage for progression regions;
- one carried Ice;
- Pen thawing and multiple simultaneous thawing Ice;
- Great Frost reset + 10x active-phase prototype thaw boost;
- 3-hit reveal;
- 4 Pen income creatures;
- Inventory / Equip / Sell path;
- the approved minimal Survival Pressure Experiment, whose Day-5 gate passed.

Persistence/offline thawing remain later production requirements, but the per-copy data architecture must be launch-compatible before persistence is implemented.

## 52. Prototype Success Questions

The prototype must answer:

- Does the player voluntarily seek another Ice after a reveal?
- Is retrieving Ice exciting rather than merely functional?
- Does low-Warmth return create tension?
- Does thawing create anticipation rather than annoyance?
- Does the player naturally find productive things to do while waiting?
- Does watching big-number Warmth growth feel satisfying?
- Does a better Hearth feel dramatically more productive?
- Does a better individual creature copy feel meaningfully faster/more valuable?
- Does visible Ice Scale create route-changing `I NEED THAT` moments?
- Does a giant Ice fulfilling its promise with a giant creature create a jackpot story?
- Do duplicate species remain desirable because individual copies differ?
- Do Recommended Warmth signs create informed risk-taking rather than hard gating?
- Does the Great Frost create a `one more cycle` feeling?

Most importantly:

> "I saw this absurdly huge Ice, barely got it home, and it became an enormous creature that completely changed my progression."

is stronger evidence than:

> "You hatch pets."

## 53. Bare-Minimum 3-Week Launch

Target:
- 16 creature species target unless later roster revision changes it;
- individual CreatureGUID copies;
- one inherited size/weight roll per copy;
- up to 5x visual Scale jackpots;
- 5 Ice types;
- multiple progression regions;
- Recommended Warmth signage;
- large-number uncapped Warmth;
- Hearth training progression;
- species BaseIncome/BaseSpeed with size-derived final stats;
- 4 active Pen creatures;
- 1-second aggregate Pen income;
- unlimited Pen thawing;
- offline thaw progress;
- Great Frost cycle;
- Great Frost thaw acceleration;
- Special Ice;
- 1 Equipped creature;
- Inventory;
- Sell;
- Frozen Archive;
- 1 currency;
- persistence;
- multiplayer;
- one continuous world;
- hero-moment presentation.

## 54. Explicitly Not Required for Launch

Do not add unless testing proves otherwise:
- pickaxes;
- mining;
- creature-specific traversal abilities;
- bosses;
- complex weapon progression;
- separate Speed training;
- literal treadmill gameplay;
- Luck stat progression;
- extra currencies;
- stamina;
- hunger;
- prestige/rebirth;
- Daily Quests;
- login calendar;
- unrelated randomized per-copy combat stats;
- Thaw Slot upgrades;
- separate Thaw Machine;
- tap-to-reduce-Thaw-Time;
- complicated quest/lore systems.

**Approved exception:** per-copy variation from the single inherited Ice size/weight roll is canonical. It may modify visual Scale, Pen Income, and Equipped Speed. This is not permission to add randomized Damage, Defense, levels, skills, or arbitrary stat affixes.

The Day-5 Survival Pressure Experiment remains approved prototype evidence after PASS, but broader launch promotion of combat systems still requires an explicit later launch-scope decision.

## 55. Scope Priority

If production becomes constrained, protect:
1. Dangerous retrieval
Warmth + Ice + return trip + freeze/reset.
2. Creature desirability
Strong silhouettes and appealing creatures.
3. Thaw / Smash
Anticipation and reveal payoff.
4. Progression
Warmth training + Hearth + Speed.
5. The Five Hero Moments
Especially Great Frost, dangerous return and major reveal.
6. Night / Special Ice

7. Persistence / Multiplayer reliability
Cut environmental complexity and secondary presentation before adding new gameplay
systems.

## 56. USP Filter

Before adding any launch feature, ask whether it strengthens at least one of:

1. I saw something I desperately wanted.2. I barely managed to bring it
home.3. I couldn't wait to discover what was inside.
If it does not meaningfully strengthen one of those and adds production cost:

it probably does not belong in the three-week launch.

## 57. Core Design Rules

The verb should be boringly simple. The consequence should be
spectacular.

Script the learning opportunities. Never script the excitement.

The reward should advertise the next reward.

Better Hearth = faster Warmth progression.

Better creature = obviously faster traversal.

More Warmth = more expedition endurance.

Farther wilderness = stranger possibilities.

The Great Frost creates opportunity, not punishment.

Waiting should happen while another form of progression is available.

No hard gate where a recommendation can create a risk decision instead.

Do not add another system when an existing system can create the
desired feeling.

When the game needs more epicness, make an existing moment bigger
before adding another mechanic.

## 58. Canonical Experience Identity

Thaw A Creature is the game where you see enormous mysterious Ice
deep inside a supernatural frozen wilderness, decide whether you're
strong enough to risk the trip, race it home before your Warmth runs out, watch it thaw among the creatures you've already
awakened, and finally smash it open to discover what was trapped inside.
Progression should continually transform:

"I can't reach that."
into:

"I can get that now."
and eventually:

"I am the player other people see racing toward the impossible Ice."
That is the experience the rest of the project should now protect.
