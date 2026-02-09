package funkin.game;

import flixel.math.FlxPoint;
import flixel.sound.FlxSound;
import flixel.tweens.FlxTween;
import flixel.util.FlxSignal.FlxTypedSignal;
import funkin.backend.chart.ChartData;
import funkin.backend.scripting.events.note.*;
import funkin.backend.system.Conductor;
import funkin.backend.system.Controls;

/**
 * Group of strums, that contains the strums and notes.
 * Used in PlayState.
**/
class StrumLine extends FlxTypedGroup<Strum>
{
	/**
	 * Signal that triggers whenever a note is hit. Similar to onPlayerHit and onDadHit, except strumline specific.
	 * To add a listener, do
	 * `strumLine.onHit.add(function(e:NoteHitEvent) {});`
	 */
	public var onHit = new FlxTypedSignal<NoteHitEvent->Void>();

	/**
	 * Signal that triggers whenever a note is missed. Similar to onPlayerMiss, except strumline specific.
	 * To add a listener, do
	 * `strumLine.onMiss.add(function(e:NoteMissEvent) {});`
	 */
	public var onMiss = new FlxTypedSignal<NoteMissEvent->Void>();

	/**
	 * Signal that triggers whenever a note is being updated. Similar to onNoteUpdate, except strumline specific.
	 * To add a listener, do
	 * `strumLine.onNoteUpdate.add(function(e:NoteUpdateEvent) {});`
	 */
	public var onNoteUpdate = new FlxTypedSignal<NoteUpdateEvent->Void>();

	/**
	 * Signal that triggers whenever a note is being deleted. Similar to onNoteDelete, except strumline specific.
	 * To add a listener, do
	 * `strumLine.onNoteDelete.add(function(e:SimpleNoteEvent) {});`
	 */
	public var onNoteDelete = new FlxTypedSignal<SimpleNoteEvent->Void>();

	/**
	 * Array containing all of the characters "attached" to those strums.
	 */
	public var characters:Array<Character>;

	/**
	 * Whenever this strumline is controlled by cpu or not.
	 */
	public var cpu(default, set):Bool = false;

	/**
	 * Whenever this strumline is from the opponent side or the player side.
	 */
	public var opponentSide:Bool = false;

	/**
	 * Controls assigned to this strumline.
	 */
	public var controls:Controls = null;

	/**
	 * Chart JSON data assigned to this StrumLine (Codename format)
	 */
	public var data:ChartStrumLine = null;

	/**
	 * Whenever Ghost Tapping is enabled.
	 */
	@:isVar public var ghostTapping(get, set):Null<Bool> = null;

	/**
	 * Group of all of the notes in this strumline. Using `forEach` on this group will only loop through the first notes for performance reasons.
	 */
	public var notes:NoteGroup;

	/**
	 * Whenever alt animation is enabled on this strumline.
	 */
	public var altAnim(get, set):Bool;

	/**
	 * Which animation suffix on characters that should be used when hitting notes.
	 */
	public var animSuffix(default, set):String = "";

	/**
	 * TODO: Write documentation about this being a variable that can help when making multi key
	 */
	public var strumAnimPrefix = ["left", "down", "up", "right"];

	/**
	 * Vocals sound (Vocals.ogg). Used for individual vocals per strumline.
	 */
	public var vocals:FlxSound;

	/**
	 * Extra data that can be added to the strum line.
	**/
	public var extra:Map<String, Dynamic> = [];

	function get_ghostTapping()
		return ghostTapping ?? PlayState.instance?.ghostTapping ?? false;

	inline function set_ghostTapping(b:Bool)
		return ghostTapping = b;

	private var startingPos:FlxPoint = FlxPoint.get(0, 0);

	/**
	 * The scale of the strums.
	 * If called after generate, the strums wont be scaled.
	 * You can only change it in the Charter.
	**/
	public var strumScale:Float = 1;

	public function new(characters:Array<Character>, startingPos:FlxPoint, strumScale:Float, cpu:Bool = false, opponentSide:Bool = true, ?controls:Controls,
			?vocalPrefix:String = "")
	{
		super();
		this.characters = characters;
		this.startingPos = startingPos;
		this.strumScale = strumScale;
		this.cpu = cpu;
		this.opponentSide = opponentSide;
		this.controls = controls;
		this.notes = new NoteGroup();

		var v = Paths.voices(PlayState.SONG.meta.name, PlayState.difficulty, vocalPrefix);
		vocals = vocalPrefix != "" ? FlxG.sound.load(Options.streamedVocals ? Assets.getMusic(v) : v) : new FlxSound();
		vocals.persist = false;
	}

	/**
	 * Generates the notes for the strumline.
	**/
	public function generate(strumLine:ChartStrumLine, ?startTime:Float)
	{
		var total = 0;
		if (strumLine.notes != null)
			for (note in strumLine.notes)
			{
				if (startTime != null && startTime > note.time)
					continue;
				total++;
				if (note.sLen > Conductor.stepCrochet * 0.75)
				{
					var len:Float = note.sLen;
					while (len > 10)
					{
						total++;
						len -= Math.min(len, Conductor.stepCrochet);
					}
				}
			}
		notes.preallocate(total);
		var il = 0, prev:Note = null;
		if (strumLine.notes != null)
			for (note in strumLine.notes)
			{
				if (startTime != null && startTime > note.time)
					continue;
				notes.members[total - (il++) - 1] = prev = new Note(this, note, false, prev);
				if (note.sLen > Conductor.stepCrochet * 0.75)
				{
					var len:Float = note.sLen, curLen:Float = 0;
					while (len > 10)
					{
						curLen = Math.min(len, Conductor.stepCrochet);
						notes.members[total - (il++) - 1] = prev = new Note(this, note, true, curLen, note.sLen - len, prev);
						len -= curLen;
						if (prev?.sustainParent != null)
							prev.sustainParent.tailCount++;
					}
				}
			}
		notes.sortNotes();
		var scrollSpeed = strumLine.scrollSpeed ?? PlayState.instance?.scrollSpeed ?? 1;
		// TODO: Make this work by accounting zoom and scroll speed changes  - Nex
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		notes.update(elapsed);
	}

	override function draw()
	{
		super.draw();
		notes.cameras = cameras;
		notes.draw();
	}

	/**
	 * Updates the notes.
	**/
	public inline function updateNotes()
	{
		__updateNote_songPos = Conductor.songPosition;
		if (__updateNote_event == null)
			__updateNote_event = PlayState.instance.__updateNote_event;
		var i = notes.length - 1, time = __updateNote_songPos + notes.limit;
		while (i >= 0)
		{
			var daNote = notes.members[i--];
			if (daNote == null || !daNote.exists)
				continue;
			if (daNote.strumTime > time)
				break;
			updateNote(daNote);
		}
	}

	var __updateNote_strum:Strum;
	var __updateNote_songPos:Float;
	var __updateNote_event:NoteUpdateEvent;

	/**
	 * Updates a note.
	 * This updates the position, state, and handles the input.
	**/
	public function updateNote(daNote:Note)
	{
		if ((__updateNote_strum = members[daNote.noteData]) == null)
			return;
		__updateNote_event.recycle(daNote, FlxG.elapsed, __updateNote_strum);
		onNoteUpdate.dispatch(__updateNote_event);
		if (__updateNote_event.cancelled)
			return;

		if (__updateNote_event.__updateHitWindow)
		{
			var hitWindow = Flags.USE_LEGACY_TIMING ? PlayState.instance.hitWindow : PlayState.instance.ratingManager.lastHitWindow;
			daNote.canBeHit = (daNote.strumTime > __updateNote_songPos - (hitWindow * daNote.latePressWindow)
				&& daNote.strumTime < __updateNote_songPos + (hitWindow * daNote.earlyPressWindow));
			if (daNote.strumTime < __updateNote_songPos - hitWindow && !daNote.wasGoodHit)
				daNote.tooLate = true;
		}

		if (cpu && __updateNote_event.__autoCPUHit && !daNote.avoid && !daNote.wasGoodHit && daNote.strumTime < __updateNote_songPos)
			PlayState.instance.goodNoteHit(this, daNote);

		if (daNote.wasGoodHit
			&& daNote.isSustainNote
			&& daNote.strumTime + daNote.sustainLength < __updateNote_songPos
			&& !daNote.noSustainClip)
		{
			deleteNote(daNote);
			return;
		}

		if (daNote.tooLate)
		{
			if (!cpu)
				PlayState.instance.noteMiss(this, daNote);
			else
				deleteNote(daNote);
			return;
		}

		if (__updateNote_event.strum != null)
		{
			if (__updateNote_event.__reposNote)
				__updateNote_event.strum.updateNotePosition(daNote);
			if (daNote.isSustainNote)
				daNote.updateSustain(__updateNote_event.strum);
		}
	}

	var __pressed:Array<Bool> = [];
	var __justPressed:Array<Bool> = [];
	var __justReleased:Array<Bool> = [];
	var __notePerStrum:haxe.ds.Vector<Note> = null;

	/**
	 * Updates the input for the strumline, and handles the input.
	 * @param id The ID of the strum
	**/
	public function updateInput(id:Int = 0)
	{
		updateNotes();
		if (cpu)
			return;

		if (__pressed.length != members.length)
		{
			__pressed.resize(members.length);
			__justPressed.resize(members.length);
			__justReleased.resize(members.length);
		}

		var anyPressed = false, anyJustPressed = false;
		for (i in 0...members.length)
		{
			var str = members[i];
			if (__pressed[i] = str.__getPressed(this))
				anyPressed = true;
			if (__justPressed[i] = str.__getJustPressed(this))
				anyJustPressed = true;
			__justReleased[i] = str.__getJustReleased(this);
		}

		var event = EventManager.get(InputSystemEvent).recycle(__pressed, __justPressed, __justReleased, this, id);
		if (PlayState.instance != null)
			PlayState.instance.gameAndCharsEvent("onInputUpdate", event);
		if (event.cancelled)
			return;

		__pressed = event.pressed ?? [];
		__justPressed = event.justPressed ?? [];
		__justReleased = event.justReleased ?? [];
		anyPressed = anyJustPressed = false;
		for (p in __pressed)
			if (p)
			{
				anyPressed = true;
				break;
			}
		if (anyPressed)
			for (p in __justPressed)
				if (p)
				{
					anyJustPressed = true;
					break;
				}

		if (__notePerStrum == null || __notePerStrum.length != members.length)
			__notePerStrum = new haxe.ds.Vector(members.length);
		for (i in 0...members.length)
			__notePerStrum[i] = null;

		if (anyPressed)
		{
			var notesMembers = notes.members,
				notesLen = notes.length,
				timeLimit = __updateNote_songPos + notes.limit;
			if (anyJustPressed)
			{
				var i = notesLen - 1;
				while (i >= 0)
				{
					var note = notesMembers[i--];
					if (note == null || !note.exists || !note.alive)
						continue;
					if (note.strumTime > timeLimit)
						break;
					if (__justPressed[note.strumID] && !note.isSustainNote && !note.wasGoodHit && note.canBeHit)
					{
						var cur = __notePerStrum[note.strumID],
							songPos = __updateNote_songPos;
						var noteDist = Math.abs(note.strumTime - songPos),
							curDist = cur != null ? Math.abs(cur.strumTime - songPos) : 999999;
						var notePenalty = note.avoid ? 1 : 0,
							curPenalty = (cur != null && cur.avoid) ? 1 : 0;
						if (cur == null || notePenalty < curPenalty || (notePenalty == curPenalty && noteDist < curDist))
							__notePerStrum[note.strumID] = note;
					}
				}
				if (!ghostTapping)
					for (k in 0...members.length)
						if (__justPressed[k] && __notePerStrum[k] == null)
							PlayState.instance.noteMiss(this, null, k, ID);
				for (i in 0...members.length)
					if (__notePerStrum[i] != null)
						PlayState.instance.goodNoteHit(this, __notePerStrum[i]);
			}
			for (c in characters)
				if (c.lastAnimContext != DANCE)
					c.__lockAnimThisFrame = true;
			var i = notesLen - 1;
			while (i >= 0)
			{
				var note = notesMembers[i--];
				if (note == null || !note.exists || !note.alive)
					continue;
				if (note.strumTime > timeLimit)
					break;
				if (__pressed[note.strumID]
					&& note.isSustainNote
					&& note.strumTime < __updateNote_songPos
					&& !note.wasGoodHit
					&& note.sustainParent.wasGoodHit)
					PlayState.instance.goodNoteHit(this, note);
			}
		}
		for (i in 0...members.length)
			members[i].updatePlayerInput(__pressed[i], __justPressed[i], __justReleased[i]);
		PlayState.instance.gameAndCharsCall("onPostInputUpdate");
	}

	/**
	 * Adds/removes health to/from the strumline.
	 * If the strumline is an opponent strumline, it will subtract the health, otherwise it will add the health.
	 * @param health The amount of health to add/remove
	**/
	public inline function addHealth(health:Float)
		PlayState.instance.health += health * (opponentSide ? -1 : 1);

	/**
	 * Generates strums, and adds them to the strumline.
	 * @param amount The amount of strums to generate (-1 for the default amount)
	**/
	public inline function generateStrums(amount:Int = -1)
	{
		if (amount == -1)
			amount = Flags.DEFAULT_STRUM_AMOUNT;
		for (i in 0...amount)
			add(createStrum(i));
	}

	override function destroy()
	{
		super.destroy();
		if (startingPos != null)
			startingPos.put();
		notes = FlxDestroyUtil.destroy(notes);
	}

	/**
	 * Creates a strum and returns the created strum (needs to be added manually).
	 * @param i Index of the strum
	 * @param animPrefix (Optional) Animation prefix (`left` = `arrowLEFT`, `left press`, `left confirm`).
	 * @param spritePath (Optional) The sprite's graphic path if you don't want the default one.
	 * @param playIntroAnimation (Optional) Whenever the intro animation should be played, by default might be `true` under certain conditions.
	 */
	public function createStrum(i:Int, ?animPrefix:String, ?spritePath:String, ?playIntroAnimation:Bool)
	{
		if (animPrefix == null)
			animPrefix = strumAnimPrefix[i % strumAnimPrefix.length];
		var babyArrow = new Strum(startingPos.x
			+ (Note.swagWidth * strumScale * (data.strumSpacing ?? 1) * i),
			startingPos.y
			+ (Note.swagWidth * 0.5)
			- (Note.swagWidth * strumScale * 0.5));
		babyArrow.ID = i;
		babyArrow.strumLine = this;
		if (data.scrollSpeed != null)
			babyArrow.scrollSpeed = data.scrollSpeed;

		var event = EventManager.get(StrumCreationEvent).recycle(babyArrow, PlayState.instance.strumLines.members.indexOf(this), i, animPrefix);
		event.__doAnimation = playIntroAnimation ?? (!MusicBeatState.skipTransIn
			&& (PlayState.instance != null ? PlayState.instance.introLength > 0 : true));
		if (spritePath != null)
			event.sprite = spritePath;
		if (PlayState.instance != null)
			event = PlayState.instance.gameAndCharsEvent("onStrumCreation", event);

		if (!event.cancelled)
		{
			babyArrow.frames = Paths.getFrames(event.sprite);
			for (a in [['green', 'UP'], ['blue', 'DOWN'], ['purple', 'LEFT'], ['red', 'RIGHT']])
				babyArrow.animation.addByPrefix(a[0], 'arrow${a[1]}');
			babyArrow.antialiasing = true;
			babyArrow.setGraphicSize(Std.int((babyArrow.width * Flags.DEFAULT_NOTE_SCALE) * strumScale));
			babyArrow.animation.addByPrefix('static', 'arrow${event.animPrefix.toUpperCase()}');
			babyArrow.animation.addByPrefix('pressed', '${event.animPrefix} press', 24, false);
			babyArrow.animation.addByPrefix('confirm', '${event.animPrefix} confirm', 24, false);
		}
		babyArrow.cpu = cpu;
		babyArrow.updateHitbox();
		babyArrow.scrollFactor.set();
		if (event.__doAnimation)
		{
			babyArrow.y -= 10;
			babyArrow.alpha = 0;
			FlxTween.tween(babyArrow, {y: babyArrow.y + 10, alpha: 1}, 1, {ease: FlxEase.circOut, startDelay: 0.5 + (0.2 * i * (4 / (data.keyCount ?? 4)))});
		}
		babyArrow.playAnim('static');
		insert(i, babyArrow);
		if (PlayState.instance != null)
			PlayState.instance.gameAndCharsEvent("onPostStrumCreation", event);
		return babyArrow;
	}

	/**
	 * Deletes a note from this strumline.
	 * @param note Note to delete
	 */
	public function deleteNote(note:Note)
	{
		if (note == null)
			return;
		var event = EventManager.get(SimpleNoteEvent).recycle(note);
		onNoteDelete.dispatch(event);
		if (!event.cancelled)
		{
			if (note.isSustainNote && note.sustainParent != null && note.sustainParent.tailCount > 0)
				note.sustainParent.tailCount--;
			note.kill();
			notes.remove(note, true);
			note.destroy();
		}
	}

	public static inline function calculateStartingXPos(hudXRatio:Float, scale:Float, spacing:Float, keyCount:Int)
		return (FlxG.width * hudXRatio) - ((Note.swagWidth * scale * ((keyCount / 2) - 0.5) * spacing) + Note.swagWidth * 0.5 * scale);

	public static inline function calculateStartingXPosFromInitialWidth(hudXRatio:Float, scale:Float, spacing:Float, keyCount:Int)
		return (FlxG.initialWidth * hudXRatio) - ((Note.swagWidth * scale * ((keyCount / 2) - 0.5) * spacing) + Note.swagWidth * 0.5 * scale);

	/**
	 * SETTERS & GETTERS
	 */
	#if REGION
	function set_cpu(b:Bool)
	{
		for (s in members)
			if (s != null)
				s.cpu = b;
		return cpu = b;
	}

	function set_animSuffix(s:String)
	{
		for (str in members)
			if (str != null)
				str.animSuffix = s;
		return animSuffix = s;
	}

	function set_altAnim(b:Bool)
	{
		animSuffix = b ? "-alt" : "";
		return b;
	}

	function get_altAnim()
		return animSuffix == "-alt";
	#end
}
