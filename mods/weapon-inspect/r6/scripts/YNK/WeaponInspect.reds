// YNK Weapon Inspect: weapon inspect, lower-weapon and auto-lower on demand.
// - Inspect: plays the weapon's idle-break animation. The request is handed to the weapon state
//   machine (ReadyEvents.OnTick), the same way the game sends IdleBreak after 20 seconds of standing
//   still. Pushing the event from outside the state machine doesn't play it. If the weapon is
//   lowered, inspecting raises it first and plays the animation once it is back in Ready.
// - Lower: forces the game's own "safe" stance through DefaultTransition.IsSafeStateForced, and
//   raising requests a release from the "public safe" state (PublicSafeDecisions.ToPublicSafeToReady),
//   which the game otherwise only leaves when the area stops being a public zone. Aiming, shooting
//   or combat raises it immediately.
// - Auto-lower (optional, off by default): lowers the weapon after a few seconds without aiming or
//   shooting, out of combat.
// - Controller: double-tap D-pad Down (the "CycleObjectives" action). A single tap still cycles the
//   tracked objective; holding it is the phone, so holds are left alone.
// - Always First Equip (Nexus 2557) also lowers and raises the weapon. When it is installed the
//   lowered state is its flag (SetSafeStateForced), so the two mods share one state instead of
//   fighting over two.
// The CET part (ynk_weapon_inspect) binds the keyboard hotkeys and remembers the auto-lower setting.
module YNK.WeaponInspect

func YnkDoubleTapWindow() -> Float = 0.35; // max seconds between the two D-pad Down taps
func YnkInspectTimeout() -> Float = 4.0;   // drop an inspect the weapon couldn't act on (e.g. reloading)
func YnkInspectDelay() -> Float = 0.25;    // seconds in Ready before the animation, after a raise
func YnkAutoLowerDelay() -> Float = 3.0;   // seconds without aiming or shooting before auto-lower
func YnkInspectHold() -> Float = 3.5;      // seconds the weapon stays up for the inspect animation

@addField(PlayerPuppet)
public let ynkInspectRequestedAt: Float;   // sim time of a pending inspect; 0 = none pending

@addField(PlayerPuppet)
public let ynkLowered: Bool;               // own lowered state (unused when Always First Equip is installed)

@addField(PlayerPuppet)
public let ynkReleaseRequested: Bool;      // leave public safe on the next decision

@addField(PlayerPuppet)
public let ynkAutoLower: Bool;             // set by the CET part from its saved setting

@addField(PlayerPuppet)
public let ynkLastActive: Float;           // sim time of the last aim, shot or combat tick

@addField(PlayerPuppet)
public let ynkPadLastTap: Float;           // sim time of the last D-pad Down release; 0 = none

@addField(PlayerPuppet)
public let ynkHoldReadyUntil: Float;       // keep the weapon up until then, so an inspect isn't cut short

@addMethod(PlayerPuppet)
public func YnkNow() -> Float {
  return EngineTime.ToFloat(GameInstance.GetSimTime(this.GetGame()));
}

@addMethod(PlayerPuppet)
public func YnkHasWeapon() -> Bool {
  return IsDefined(GameInstance.GetTransactionSystem(this.GetGame()).GetItemInSlot(this, t"AttachmentSlots.WeaponRight"));
}

// ── one lowered state, ours or Always First Equip's ───────────────────────────────────────────

@if(ModuleExists("AlwaysFirstEquip"))
@addMethod(PlayerPuppet)
public func YnkIsLowered() -> Bool {
  return this.IsSafeStateForcedEQ();
}

@if(!ModuleExists("AlwaysFirstEquip"))
@addMethod(PlayerPuppet)
public func YnkIsLowered() -> Bool {
  return this.ynkLowered;
}

@if(ModuleExists("AlwaysFirstEquip"))
@addMethod(PlayerPuppet)
public func YnkSetLowered(lowered: Bool) -> Void {
  this.SetSafeStateForced(lowered);   // Always First Equip owns the safe-state hooks
}

@if(!ModuleExists("AlwaysFirstEquip"))
@addMethod(PlayerPuppet)
public func YnkSetLowered(lowered: Bool) -> Void {
  if !lowered && this.ynkLowered {
    this.ynkReleaseRequested = true;
  };
  if lowered {
    this.ynkReleaseRequested = false;
  };
  this.ynkLowered = lowered;
}

// Leave the "public safe" stance even when the game lowered the weapon by itself (public zones
// lower an idle weapon after a second), not only when this mod did.
@if(ModuleExists("AlwaysFirstEquip"))
@addMethod(PlayerPuppet)
public func YnkRequestRelease() -> Void {
  this.safeStateReleaseRequested = true;   // Always First Equip's release flag, read by its own hook
}

@if(!ModuleExists("AlwaysFirstEquip"))
@addMethod(PlayerPuppet)
public func YnkRequestRelease() -> Void {
  this.ynkReleaseRequested = true;
}

// The weapon state the game itself reports: 6 = Safe / public safe (set by SafeEvents and PublicSafeEvents).
@addMethod(PlayerPuppet)
public func YnkGameLowered() -> Bool {
  let bb: ref<IBlackboard> = GameInstance.GetBlackboardSystem(this.GetGame()).GetLocalInstanced(this.GetEntityID(), GetAllBlackboardDefs().PlayerStateMachine);
  return IsDefined(bb) && bb.GetInt(GetAllBlackboardDefs().PlayerStateMachine.RightWeapon) == 6;
}

@addMethod(PlayerPuppet)
public func YnkInspectPending() -> Bool {
  return this.ynkInspectRequestedAt > 0.0 && this.YnkNow() - this.ynkInspectRequestedAt <= YnkInspectTimeout();
}

// ── the actions ───────────────────────────────────────────────────────────────────────────────

// Inspect the weapon; if it is lowered (by this mod or by the game), raise it first.
@addMethod(PlayerPuppet)
public func YnkRequestInspect() -> Void {
  if this.YnkIsLowered() {
    this.YnkSetLowered(false);
  };
  this.YnkRequestRelease();
  this.ynkInspectRequestedAt = this.YnkNow();
}

// One-button flow: lowered (by this mod or the game) -> raise and inspect; otherwise lower.
@addMethod(PlayerPuppet)
public func YnkCycle() -> Void {
  if this.YnkIsLowered() || this.YnkGameLowered() {
    this.YnkRequestInspect();
  } else {
    this.YnkSetLowered(true);
  }
}

@addMethod(PlayerPuppet)
public func YnkSetAutoLower(enabled: Bool) -> Void {
  this.ynkAutoLower = enabled;
  this.ynkLastActive = this.YnkNow();
}

// ── controller: double-tap D-pad Down ────────────────────────────────────────────────────────

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
      if this.YnkHasWeapon() {
        this.YnkCycle();
      };
    } else {
      this.ynkPadLastTap = now;
    };
  };
  return wrappedMethod(action, consumer);   // not consumed: a tap still cycles the objective
}

// ── own safe-state hooks (only without Always First Equip, which has the same ones) ──────────

@if(!ModuleExists("AlwaysFirstEquip"))
@wrapMethod(DefaultTransition)
public final const func IsSafeStateForced(const stateContext: ref<StateContext>, const scriptInterface: ref<StateGameScriptInterface>) -> Bool {
  if wrappedMethod(stateContext, scriptInterface) {
    return true;
  };
  let player: ref<PlayerPuppet> = scriptInterface.executionOwner as PlayerPuppet;
  if !IsDefined(player) || !player.ynkLowered {
    return false;
  };
  if this.IsPlayerInCombat(scriptInterface) || scriptInterface.GetActionValue(n"RangedAttack") > 0.0 || scriptInterface.GetActionValue(n"CameraAim") > 0.0 {
    player.YnkSetLowered(false);
    return false;
  };
  return !scriptInterface.localBlackboard.GetBool(GetAllBlackboardDefs().PlayerStateMachine.SceneAimForced)
    && !scriptInterface.localBlackboard.GetBool(GetAllBlackboardDefs().PlayerStateMachine.SceneSafeForced);
}

@if(!ModuleExists("AlwaysFirstEquip"))
@wrapMethod(PublicSafeDecisions)
protected final const func ToPublicSafeToReady(const stateContext: ref<StateContext>, const scriptInterface: ref<StateGameScriptInterface>) -> Bool {
  if wrappedMethod(stateContext, scriptInterface) {
    return true;
  };
  let player: ref<PlayerPuppet> = scriptInterface.executionOwner as PlayerPuppet;
  return IsDefined(player) && player.ynkReleaseRequested;
}

@if(!ModuleExists("AlwaysFirstEquip"))
@wrapMethod(PublicSafeToReadyEvents)
protected final func OnEnter(stateContext: ref<StateContext>, scriptInterface: ref<StateGameScriptInterface>) -> Void {
  wrappedMethod(stateContext, scriptInterface);
  let player: ref<PlayerPuppet> = scriptInterface.executionOwner as PlayerPuppet;
  if IsDefined(player) {
    player.ynkReleaseRequested = false;
  };
}

// In a public zone the game lowers an idle weapon again after one second (idleTimeToEnter), which
// would cut the inspect short. Hold it up while a raise-and-inspect is pending or playing.
@wrapMethod(PublicSafeDecisions)
protected final const func EnterCondition(const stateContext: ref<StateContext>, const scriptInterface: ref<StateGameScriptInterface>) -> Bool {
  let player: ref<PlayerPuppet> = scriptInterface.executionOwner as PlayerPuppet;
  if IsDefined(player) && (player.YnkInspectPending() || player.YnkNow() < player.ynkHoldReadyUntil) {
    return false;
  };
  return wrappedMethod(stateContext, scriptInterface);
}

// ── every tick in Ready: pending inspect, activity, auto-lower ───────────────────────────────

@wrapMethod(ReadyEvents)
protected final func OnTick(timeDelta: Float, stateContext: ref<StateContext>, scriptInterface: ref<StateGameScriptInterface>) -> Void {
  wrappedMethod(timeDelta, stateContext, scriptInterface);
  let player: ref<PlayerPuppet> = scriptInterface.executionOwner as PlayerPuppet;
  if !IsDefined(player) || !this.IsRightWeaponLogic() {
    return;
  };
  let now: Float = player.YnkNow();
  player.ynkReleaseRequested = false;   // back in Ready: nothing left to release

  if this.IsPlayerInCombat(scriptInterface) || scriptInterface.GetActionValue(n"RangedAttack") > 0.0 || scriptInterface.GetActionValue(n"CameraAim") > 0.0 {
    player.ynkLastActive = now;
  };

  if player.ynkInspectRequestedAt > 0.0 {
    if now - player.ynkInspectRequestedAt > YnkInspectTimeout() {
      player.ynkInspectRequestedAt = 0.0;
    } else {
      if this.GetInStateTime() >= YnkInspectDelay() {
        scriptInterface.PushAnimationEvent(n"IdleBreak");
        player.ynkInspectRequestedAt = 0.0;
        player.ynkHoldReadyUntil = now + YnkInspectHold();
        player.ynkLastActive = now + 2.0;   // let the animation finish before auto-lower
      };
    };
    return;
  };

  if player.ynkAutoLower && !player.YnkIsLowered()
      && this.GetInStateTime() >= YnkAutoLowerDelay() && now - player.ynkLastActive >= YnkAutoLowerDelay() {
    player.YnkSetLowered(true);
  };
}
