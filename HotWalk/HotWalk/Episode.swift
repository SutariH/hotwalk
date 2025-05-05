import Foundation

enum UnlockType: String, Codable {
    case steps
    case streak
    case invite
    case returnAfterMiss
}

struct Episode: Identifiable, Codable {
    let id: String
    let title: String
    let unlockType: UnlockType
    let unlockValue: Int
    let synopsis: String
}

// Sample episodes data
let episodes: [Episode] = [
    Episode(
        id: "ep1",
        title: "Pilot: She Walks, Therefore She Is",
        unlockType: .steps,
        unlockValue: 1,
        synopsis: "She didn't mean to be seen. Her phone had died mid-scroll, her apartment smelled like the past, and the silence was getting bold. So she did the most unexpected thing: she left the house.\n\nThe air hit her differently. Charged. A little cinematic. The moment her sneaker met the sidewalk, the wind shifted like it knew something. A curtain twitched. A dog paused mid-pee. She passed a parked car and caught her reflection—messy bun, sunglasses at dusk, sweatshirt too big. She looked like a woman with a secret.\n\nShe didn't have one yet. But she could feel it forming. The plot hadn't begun—but something had."
    ),
    Episode(
        id: "ep2",
        title: "Revenge Steps & Lip Gloss",
        unlockType: .streak,
        unlockValue: 2,
        synopsis: "He texted \"you up?\" at 1:47 a.m. She didn't reply. She opened her Notes app, wrote three brutal lines of poetry, and fell asleep with one AirPod in. In the morning, she woke up vengeful.\n\nGloss on. Shoes tied. Jaw clenched like she had a press interview to storm out of. She wasn't walking toward anything. She was walking away—from everything she used to tolerate.\n\nShe passed his street. A test. She didn't flinch. In fact, she smirked. A passing car honked. Claudia, probably. Or maybe not. Either way, her steps hit the pavement like thunder, and the sidewalk responded by carrying her farther than she'd planned. By the time she returned, the text had been unsent. As if he sensed what he had lost."
    ),
    Episode(
        id: "ep3",
        title: "Gossip at the Crosswalk",
        unlockType: .streak,
        unlockValue: 3,
        synopsis: "She wore her headphones but no music played. She preferred the sound of her own thoughts this morning. It was golden hour. Her hair looked expensive. And as she stepped up to the crosswalk, she felt it: a shift. The red hand blinked like a warning. Something was about to happen.\n\nAcross the street, a small group whispered. One pointed. Another raised a phone. She didn't react. Not visibly. Inside, her pulse strutted like it had somewhere to be.\n\nLater that night, a TikTok surfaced: blurry footage of her at the corner, captioned \"idk who she is but i want her whole life.\" The video went mildly viral. Claudia sent it with a single eye emoji. Diego didn't say anything, but he definitely viewed it twice.\n\nShe watched the views climb. And she liked it."
    ),
    Episode(
        id: "ep4",
        title: "Crywalking Is Still Cardio",
        unlockType: .steps,
        unlockValue: 5000,
        synopsis: "It started with a playlist: Avril Lavigne, Hilary Duff, one sad Britney remix. Somewhere around track 4 she burst into tears—big, juicy, mascara-streaking tears. But she didn't turn back. No. She increased her pace. Because a Hot Girl doesn't cancel cardio just because she's crying. She cries cutely. In motion.\n\nPeople looked. One woman offered a tissue. A teen on a scooter yelled, \"Mood!\" And still she stomped on. Her lip gloss was clinging to dear life. The sidewalk was trembling. Claudia posted a selfie captioned \"healing era 💅\" that was definitely about her.\n\nLater that night she rewatched The OC with a bag of frozen peas on her ankles and thought, \"That was actually kind of iconic.\""
    ),
    Episode(
        id: "ep5",
        title: "Scandal at Sunset Pilates",
        unlockType: .streak,
        unlockValue: 5,
        synopsis: "Brunch was scheduled. Pilates was penciled in. Claudia had sent a ✨vibe check✨ voice note at 9:12 a.m. But by 4 p.m., she was missing.\n\nExcept she wasn't. She was out walking alone with a green juice and a scarf that whispered, \"I'm above group dynamics.\" The sunset hit just right. A passing tourist took a photo thinking she was a celebrity—possibly European.\n\nClaudia found out. Romy reposted the photo. Diego commented \"🤍.\" The Pilates girls were livid. Who goes off-grid during social prime time?\n\nShe did. And she looked expensive doing it."
    ),
    Episode(
        id: "ep6",
        title: "Hot Girl Walks Out… of the Group Chat",
        unlockType: .streak,
        unlockValue: 7,
        synopsis: "The group chat had been... off. Claudia kept sending recycled memes. Diego kept reacting with the same emoji. Romy was in her emoji-only era. It was suffocating. So, mid-walk, she did the unthinkable.\n\nShe left.\n\nThe notification hit at 4:42 p.m. Claudia screamed in a Zara fitting room. Diego dropped his matcha in a ceramic cup he brought from home. The chat was in ruins.\n\nShe, meanwhile, was strutting to Stars Are Blind in a velour tracksuit and platform sneakers that made her 2 inches taller and 100% done. A seagull followed her for two blocks like it sensed power. She didn't look back."
    ),
    Episode(
        id: "ep7",
        title: "That Time She Overshot Her Goal",
        unlockType: .steps,
        unlockValue: 10000,
        synopsis: "It was supposed to be a ten-minute loop. But then she saw Diego's new girlfriend at the café wearing her old scarf. So she kept walking.\n\nShe walked like she had an agent waiting at the end of the trail. Like she was legally required to storm past each ex-associated landmark. The nail salon. The record shop. The weird statue they once made out under. Every step was therapy with glitter on top.\n\nSomewhere around 8,300 steps she bought a plant she didn't need. At 9,000 she blocked three numbers. By 10K, she had redefined who she was and sent an apology voice memo to no one. She returned home with a limp, a glow, and zero regrets."
    ),
    Episode(
        id: "ep8",
        title: "The Comeback Season Premiere",
        unlockType: .returnAfterMiss,
        unlockValue: 1,
        synopsis: "She disappeared. Ghosted the leaderboard. Left everyone on \"read.\" Claudia texted \"u good?\" Romy sent a crystal emoji. Diego DMed \"I miss when u were chaotic.\"\n\nThen, on a random Tuesday, she logged 6,432 steps by noon and uploaded a blurry photo of her walking with her hood up and captioned it: \"back.\"\n\nBack from where? No one knew. But the comeback had range. She reappeared at full power, playlist updated, legs stronger, enemies confused. Claudia fake-smiled. Diego wrote a poem in Notes. She? She walked past them both wearing aviators and chewing gum like it was a legal warning."
    ),
    Episode(
        id: "ep9",
        title: "The Collab No One Saw Coming",
        unlockType: .invite,
        unlockValue: 1,
        synopsis: "Romy had always been mysterious—shows up without warning, wears silk scarves to the grocery store, has a ringtone that sounds like a ringtone. And now, somehow, Romy was on the walk.\n\nThey didn't speak much. Just power-walked in silence like they were being trailed by paparazzi. Claudia was rattled. Diego reposted a blurry Story with the caption \"????\" and then deleted it.\n\nThe photo hit the feed: matching tracksuits, zero smiles, pure chaos energy. The fandom spiraled. Was it friendship? PR? A soft launch? Who knew. All that mattered was: they were walking, and the world was watching."
    ),
    Episode(
        id: "ep10",
        title: "10K: She Did It For the Plot",
        unlockType: .steps,
        unlockValue: 10000,
        synopsis: "Why 10,000 steps? Why that day? No one knew.\n\nShe just… woke up feeling cursed and gorgeous. She spilled oat milk, tripped over a tote bag, saw Diego in someone's Story. So she left her house like a woman on a mission she invented.\n\nShe walked into three neighborhoods she wasn't emotionally prepared for. Got offered a free coffee. Accidentally joined a protest. Bought a very questionable hat.\n\nShe didn't even check her step count until her phone buzzed: \"10,031. Episode Unlocked.\" She laughed. Loudly. Alone.\n\nLater that night, Claudia called. She didn't answer. The plot was already too thick."
    ),
    Episode(
        id: "ep11",
        title: "14 Days Later: Still Hot",
        unlockType: .streak,
        unlockValue: 14,
        synopsis: "Two weeks. Fourteen days. Over 120,000 steps of avoiding texts, dodging emotional labor, and walking like she had a soundtrack playing at all times (she did—early Rihanna).\n\nBy now, she walked with intention. With velocity. With a middle finger energy that made birds flee. People noticed. The corner store guy started giving her free gum. Claudia posted a Notes-app Story. Diego reshared a photo of her from last summer—embarrassing.\n\nBut she didn't respond. Instead, she added two more blocks to her route, rewrote her hinge bio mid-walk, and mentally rearranged her entire career path.\n\nAnd somewhere in the background, the wind whispered: \"She's changing.\""
    ),
    Episode(
        id: "ep12",
        title: "28 Days of Power",
        unlockType: .streak,
        unlockValue: 28,
        synopsis: "She wasn't just walking now—she was floating. Gliding. Her shoelaces untied themselves out of fear. She hit 28 days and unlocked powers previously reserved for early-2000s pop stars during their reinvention era.\n\nShe updated her skincare routine, blocked someone just because their energy was weird, and left a voice memo that ended with, \"Anyway, do what you want. I'm on my walk.\" It sent shockwaves through three friend groups.\n\nClaudia started sending mysterious quotes in the group chat. Diego posted a mirror selfie with \"healing 🖤\" and zero context. No one could keep up.\n\nShe could. She walked past them all with a coconut water she didn't pay for and a podcast she didn't finish. That's called range."
    ),
    Episode(
        id: "ep13",
        title: "50 Days Unstoppable",
        unlockType: .streak,
        unlockValue: 50,
        synopsis: "Fifty days. At this point, she didn't even use the sidewalk—she just levitated six inches above it.\n\nHer friends stopped asking where she was. They already knew: walking. Always walking. Not for fitness. Not for goals. But for narrative tension.\n\nClaudia tried to plan a surprise party but gave up when she couldn't predict her location. Diego claimed he \"ran into her\" which was weird, because she was 7km outside the city wearing sunglasses and no patience.\n\nShe didn't track her steps anymore. She tracked story arcs. And she was just getting started."
    ),
    Episode(
        id: "ep14",
        title: "100 Days of Hot",
        unlockType: .streak,
        unlockValue: 100,
        synopsis: "100 days. Triple digits. A full Hot Girl Century.\n\nShe celebrated the way all legends do: silently, stylishly, and with zero regard for expectations. She turned off her phone, turned on Beyoncé's most unhinged deep cuts, and walked until her legs asked for union rights.\n\nClaudia went quiet. Diego sent a \"proud of you\" text that screamed regret. Romy sent a candle emoji. The world adjusted around her—timelines, temperatures, traffic lights. Even the pigeons knew to get out of her way.\n\nShe didn't respond to any of it. She was too busy being a milestone."
    ),
    Episode(
        id: "ep15",
        title: "15K: Unreachable and Unbothered",
        unlockType: .steps,
        unlockValue: 15000,
        synopsis: "Her phone was on Do Not Disturb. Claudia had sent \"???\" four times. Diego posted a song with no caption. But she? She was gone.\n\nNo updates. No Instagram Story. Just five hours of pure, glowing movement through unfamiliar neighborhoods and internal realizations.\n\nShe bought a smoothie that tasted like closure. She sat on a bench and wrote a list titled \"Things I Don't Need Anymore\" (spoiler: half of it was people). At one point, a butterfly landed on her shoulder. She didn't flinch. She just whispered, \"I get it.\"\n\nWhen she finally opened her phone, there were 42 messages and one emergency group chat called \"WHERE IS SHE.\" She smirked. She was exactly where she needed to be."
    ),
    Episode(
        id: "ep16",
        title: "20K: She's Gone Mobile",
        unlockType: .steps,
        unlockValue: 20000,
        synopsis: "They thought she was missing. Claudia called Romy. Diego called her mom. But in reality, she was deep in the suburbs with hoop earrings in and no signal.\n\nBy 17K steps, her aura changed colors. At 19K, she laughed to herself so hard she scared a cyclist. And at exactly 20K, she found a bakery that felt like it only appeared for girls in their spiritual rebirth arc.\n\nShe returned home just before sunset, hair tousled by fate, holding a tiny baguette and no explanations. The group chat was in shambles.\n\nShe replied:\n\"Sorry, just needed to walk it off.\"\nNo punctuation. That's how they knew she meant it."
    ),
    Episode(
        id: "ep17",
        title: "25K: The Asphalt Princess",
        unlockType: .steps,
        unlockValue: 25000,
        synopsis: "At 25K, the concrete began to worship her.\n\nShe floated down boulevards like the wind owed her rent. A barista handed her a latte \"on the house.\" A small dog stopped barking. Claudia saw her from across the street and dropped her yogurt parfait. Diego was nearby, allegedly, but tripped over a Lime scooter and missed everything.\n\nThis wasn't a walk. This was a public relations campaign for her next chapter.\n\nWhen asked where she was going, she responded, \"Nowhere.\" But she said it like she was headed to the Met Gala."
    ),
    Episode(
        id: "ep18",
        title: "30K: Who Let Her Do This?",
        unlockType: .steps,
        unlockValue: 30000,
        synopsis: "At 30K, reality glitches.\n\nShe passed a farmers' market, a wedding, a psychic shop, and one very attractive stranger who said \"Nice pace.\" That was it. That was the rom-com. No follow-up.\n\nRomy texted \"Are you okay?\" She replied with a photo of her walking in slow motion with wind in her hair and the caption \"I am the storm.\"\n\nSome say she joined a running cult. Others say she's transcended time. All we know is that she came home wearing a vintage jacket that looked cursed and holy at the same time."
    ),
    Episode(
        id: "ep19",
        title: "35K: Girl, Go Home",
        unlockType: .steps,
        unlockValue: 35000,
        synopsis: "Claudia filed a missing persons report. Diego texted \"just checking in 💔.\" The friend group started planning a memorial brunch.\n\nShe was not dead. She was just deep in a personal reckoning—and also lost in a park she didn't recognize.\n\nWhen she emerged, glowing and vaguely French, she said only, \"I took a detour.\" Then she tossed a croissant into the trash with perfect aim.\n\nEveryone was scared. Everyone was obsessed."
    )
] 