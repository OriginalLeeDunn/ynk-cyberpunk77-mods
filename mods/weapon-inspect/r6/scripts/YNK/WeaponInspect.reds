// YNK Weapon Inspect: plays the weapon's idle-break animation on demand.
// The CET part (ynk_weapon_inspect) calls YnkRequestInspect() from its hotkey; the request is
// handed to the weapon state machine on its next tick, the same way the game sends IdleBreak
// after 20 seconds of standing still (ReadyEvents.OnTick). Pushing the event from outside the
// state machine doesn't play the animation.
module YNK.WeaponInspect

// Sim time of the last key press; 0 = no pending request
@addField(PlayerPuppet)
public let ynkInspectRequestedAt: Float;

@addMethod(PlayerPuppet)
public func YnkRequestInspect() -> Void {
  this.ynkInspectRequestedAt = EngineTime.ToFloat(GameInstance.GetSimTime(this.GetGame()));
}

@wrapMethod(ReadyEvents)
protected final func OnTick(timeDelta: Float, stateContext: ref<StateContext>, scriptInterface: ref<StateGameScriptInterface>) -> Void {
  wrappedMethod(timeDelta, stateContext, scriptInterface);
  let player: ref<PlayerPuppet> = scriptInterface.executionOwner as PlayerPuppet;
  if !IsDefined(player) || player.ynkInspectRequestedAt <= 0.0 {
    return;
  };
  let now: Float = EngineTime.ToFloat(GameInstance.GetSimTime(player.GetGame()));
  // Drop presses the weapon couldn't act on right away (e.g. while reloading), so they don't fire later
  if now - player.ynkInspectRequestedAt < 1.0 {
    scriptInterface.PushAnimationEvent(n"IdleBreak");
  };
  player.ynkInspectRequestedAt = 0.0;
}
