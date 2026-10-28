// YNK Weapon Inspect: weapon inspect and lower-weapon on demand.
// - Inspect: plays the weapon's idle-break animation. The request is handed to the weapon state
//   machine on its next tick, the same way the game sends IdleBreak after 20 seconds of standing
//   still (ReadyEvents.OnTick). Pushing the event from outside the state machine doesn't play it.
// - Lower: holds the weapon in the game's own "safe" stance (the one used when aiming at a friendly)
//   by answering true from ShouldEnterSafe while the toggle is on. Aiming, shooting or combat clears it.
// - Cycle (one button): first press lowers, second press inspects and raises.
// - Controller: double-tap D-pad Down (the "CycleObjectives" action) to cycle. A single tap still
//   cycles the tracked objective as usual; holding it is the phone, so holds are left alone.
// The CET part (ynk_weapon_inspect) binds the keyboard hotkeys.
module YNK.WeaponInspect

func YnkDoubleTapWindow() -> Float = 0.35; // max seconds between the two D-pad Down taps
func YnkInspectWindow() -> Float = 1.5; // drop inspect requests older than this

@addField(PlayerPuppet)
public let ynkInspectRequestedAt: Float;   // sim time of the request; 0 = none pending

@addField(PlayerPuppet)
public let ynkLowered: Bool;

@addField(PlayerPuppet)
public let ynkPadLastTap: Float;   // sim time of the last D-pad Down release; 0 = none

// The weapon state machine can't read the UI D-pad action, so the player listens for it directly
@wrapMethod(PlayerPuppet)
protected cb func OnGameAttached() -> Bool {
  let result: Bool = wrappedMethod();
  this.RegisterInputListener(this, n"CycleObjectives");
  return result;
}

@wrapMethod(PlayerPuppet)
protected cb func OnAction(action: ListenerAction, consumer: ListenerActionConsumer) -> Bool {
  if Equals(ListenerAction.GetName(action), n"CycleObjectives") && Equals(ListenerAction.GetType(action), gameinputActionType.BUTTON_RELEASED) {
    let now: Float = this.YnkNow();
    if this.ynkPadLastTap > 0.0 && now - this.ynkPadLastTap <= YnkDoubleTapWindow() {
      this.ynkPadLastTap = 0.0;
      if IsDefined(GameInstance.GetTransactionSystem(this.GetGame()).GetItemInSlot(this, t"AttachmentSlots.WeaponRight")) {
        this.YnkCycle();
      };
    } else {
      this.ynkPadLastTap = now;
    };
  };
  return wrappedMethod(action, consumer);   // not consumed: a tap still cycles the objective
}

@addMethod(PlayerPuppet)
public func YnkNow() -> Float {
  return EngineTime.ToFloat(GameInstance.GetSimTime(this.GetGame()));
}

@addMethod(PlayerPuppet)
public func YnkRequestInspect() -> Void {
  this.ynkInspectRequestedAt = this.YnkNow();
}

// One-button flow: lowered -> inspect and raise; otherwise lower.
@addMethod(PlayerPuppet)
public func YnkCycle() -> Void {
  if this.ynkLowered {
    this.ynkLowered = false;
    this.YnkRequestInspect();
  } else {
    this.ynkLowered = true;
  }
}

@wrapMethod(DefaultTransition)
protected final const func ShouldEnterSafe(const stateContext: ref<StateContext>, const scriptInterface: ref<StateGameScriptInterface>, const opt maxDistanceSquared: Float) -> Bool {
  let player: ref<PlayerPuppet> = scriptInterface.executionOwner as PlayerPuppet;
  if IsDefined(player) {
    if player.ynkLowered {
      if this.IsPlayerInCombat(scriptInterface) || scriptInterface.GetActionValue(n"RangedAttack") > 0.0 || scriptInterface.GetActionValue(n"CameraAim") > 0.0 {
        player.ynkLowered = false;
      } else {
        return true;
      };
    };
  };
  return wrappedMethod(stateContext, scriptInterface, maxDistanceSquared);
}

@wrapMethod(ReadyEvents)
protected final func OnTick(timeDelta: Float, stateContext: ref<StateContext>, scriptInterface: ref<StateGameScriptInterface>) -> Void {
  wrappedMethod(timeDelta, stateContext, scriptInterface);
  let player: ref<PlayerPuppet> = scriptInterface.executionOwner as PlayerPuppet;
  if !IsDefined(player) || player.ynkInspectRequestedAt <= 0.0 {
    return;
  };
  // Drop presses the weapon couldn't act on in time (e.g. while reloading), so they don't fire later
  if player.YnkNow() - player.ynkInspectRequestedAt < YnkInspectWindow() {
    scriptInterface.PushAnimationEvent(n"IdleBreak");
  };
  player.ynkInspectRequestedAt = 0.0;
}
