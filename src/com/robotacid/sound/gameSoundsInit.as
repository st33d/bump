package com.robotacid.sound {
	
	/* Initialises the SoundManager and all of the sounds that are used in the game */
	public function gameSoundsInit():void {
		SoundManager.addSound(new DeathSound, "death", 0.7);
		SoundManager.addSound(new NudgeSound, "nudge", 0.7);
		SoundManager.addSound(new FallSound, "fall", 1.0);
		SoundManager.addSound(new StepSound, "step", 0.5);
		SoundManager.addSound(new JumpSound, "jump", 1.0);
		SoundManager.addSound(new KillSound, "kill", 0.5);
		SoundManager.addSound(new SpecialSound, "special", 0.4);
		SoundManager.addSound(new BlastSound, "blast", 0.6);
	}

}