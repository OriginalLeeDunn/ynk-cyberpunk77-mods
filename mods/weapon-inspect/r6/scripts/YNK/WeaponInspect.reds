// YNK Weapon Inspect: weapon inspect, lower-weapon and auto-lower on demand.
// - Inspect (guns): plays the weapon's idle-break animation. The request is handed to the weapon state
//   machine (ReadyEvents.OnTick), the same way the game sends IdleBreak after 20 seconds of standing
//   still. Pushing the event from outside the state machine doesn't play it. If the weapon is
//   lowered, inspecting raises it first and plays the animation once it is back in Ready. Sprinting
//   can't play it, so a request made while sprinting waits (up to 10 s) until the sprint ends.
// - Inspect (melee): the melee animation graph has no idle-break or inspect event, so the weapon is
//   holstered and drawn again with the first-equip animation (the weapon flourish). Out of combat only;
//   fists and cyberware melee (Mantis Blades, Gorilla Arms, Monowire) are excluded.
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
func YnkInspectMaxWait() -> Float = 10.0;  // absolute limit, so an inspect queued during a sprint never fires much later
func YnkInspectDelay() -> Float = 0.25;    // seconds in Ready before the animation, after a raise
func YnkSettleTime() -> Float = 2.0;       // seconds standing still before the animation, after moving (the graph ignores IdleBreak sooner)
func YnkAutoLowerDelay() -> Float = 3.0;   // seconds without aiming or shooting before auto-lower
func YnkInspectHold() -> Float = 3.5;      // seconds the weapon stays up for the inspect animation

@addField(PlayerPuppet)
public let ynkInspectRequestedAt: Float;   // sim time of a pending inspect; 0 = none pending

@addField(PlayerPuppet)
public let ynkInspectLastBlocked: Float;   // last sim time the pending inspect had to wait (sprinting)

@addField(PlayerPuppet)
public let ynkStillSince: Float;           // sim time the player came to a standstill in Ready; 0 = moving

@addField(PlayerPuppet)
public let ynkLowered: Bool;              // own lowered state (unused when Always First Equip is installed)

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

// Sprinting can't play the animation: a pending inspect waits for it, and the wait doesn't count
// against the normal timeout (only against YnkInspectMaxWait).
@addMethod(PlayerPuppet)
public func YnkSprinting() -> Bool {
  let bb: ref<IBlackboard> = GameInstance.GetBlackboardSystem(this.GetGame()).GetLocalInstanced(this.GetEntityID(), GetAllBlackboardDefs().PlayerStateMachine);
  return IsDefined(bb) && bb.GetInt(GetAllBlackboardDefs().PlayerStateMachine.Locomotion) == 2;
}

@addMethod(PlayerPuppet)
public func YnkInspectPending() -> Bool {
  if this.ynkInspectRequestedAt <= 0.0 {
    return false;
  };
  let now: Float = this.YnkNow();
  if now - this.ynkInspectRequestedAt > YnkInspectMaxWait() {
    return false;
  };
  if this.YnkSprinting() {
    this.ynkInspectLastBlocked = now;
  };
  return now - MaxF(this.ynkInspectRequestedAt, this.ynkInspectLastBlocked) <= YnkInspectTimeout();
}

// Called every tick by the gun Ready state (ReadyEvents.OnTick), the only state that can play IdleBreak.
// Returns true when the animation was started.
@addMethod(PlayerPuppet)
public func YnkTryPlayInspect(inStateTime: Float, still: Bool, scriptInterface: ref<StateGameScriptInterface>) -> Bool {
  if this.ynkInspectRequestedAt <= 0.0 {
    return false;
  };
  if !this.YnkInspectPending() {
    this.ynkInspectRequestedAt = 0.0;
    return false;
  };
  if !still || this.YnkSprinting() || inStateTime < YnkInspectDelay() {
    return false;
  };
  scriptInterface.PushAnimationEvent(n"IdleBreak");
  let now: Float = this.YnkNow();
  this.ynkInspectRequestedAt = 0.0;
  this.ynkHoldReadyUntil = now + YnkInspectHold();
  this.ynkLastActive = now + 2.0;   // let the animation finish before auto-lower
  return true;
}

// ── the actions ───────────────────────────────────────────────────────────────────────────────

// Inspect the weapon; if it is lowered (by this mod or by the game), raise it first.
@addMethod(PlayerPuppet)
public func YnkRequestInspect() -> Void {
  if this.ynkRedrawStage != 0 {
    return;   // a melee redraw is still running: a second request would restart it
  };
  if this.YnkIsLowered() {
    this.YnkSetLowered(false);
  };
  if this.YnkMeleeRedrawEligible() {
    this.YnkBeginRedraw();
    return;
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

// The weapon state machine can't read the UI D-pad action, so the player listens for it directly.
// The original is called as a statement, not assigned: another mod that wraps OnGameAttached
// without a return type turns wrappedMethod() into Void, and assigning that fails to compile.
// Vanilla returns false here (it has no return statement), so that's what this returns too.
@wrapMethod(PlayerPuppet)
protected cb func OnGameAttached() -> Bool {
  wrappedMethod();
  this.RegisterInputListener(this, n"CycleObjectives");
  return false;
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

  // IdleBreak only plays standing and still (the game itself only sends it then), so the wait for
  // that doesn't count against the normal timeout. Right after stopping the graph is still blending
  // out of the walk, so the player has to stay still for a moment first.
  let still: Bool = WeaponTransition.GetPlayerSpeed(scriptInterface) < 0.10 && stateContext.IsStateActive(n"Locomotion", n"stand");
  if !still {
    player.ynkStillSince = 0.0;
  } else {
    if player.ynkStillSince <= 0.0 {
      player.ynkStillSince = now;
    };
  };
  if player.ynkInspectRequestedAt > 0.0 {
    let settled: Bool = still && now - player.ynkStillSince >= YnkSettleTime();
    if !settled {
      player.ynkInspectLastBlocked = now;
    };
    player.YnkTryPlayInspect(this.GetInStateTime(), settled, scriptInterface);
    return;
  };

  if player.ynkAutoLower && !player.YnkIsLowered()
      && this.GetInStateTime() >= YnkAutoLowerDelay() && now - player.ynkLastActive >= YnkAutoLowerDelay() {
    player.YnkSetLowered(true);
  };
}

// ── melee: replay the first-equip flourish ─────────────────────────────────────────────────────
// The melee animation graph (player_melee.animgraph) has no IdleBreak or any other inspect event, so
// IdleBreak does nothing for melee weapons. The one showy melee animation is the first-equip one
// (knife toss, katana flourish ...), which the equipment state machine plays when a weapon is drawn
// with gameEquipAnimationType.FirstEquip. So a melee inspect holsters the weapon, waits until it is
// really unequipped, then draws the same item again with FirstEquip. Out of combat only (the game
// refuses first-equip in combat). Fists and cyberware melee (Meleeware tag: Mantis Blades, Gorilla
// Arms, Monowire, Projectile Launcher) are left out.

func YnkRedrawTimeout() -> Float = 3.0;   // give up waiting for the unequip / the draw after this many seconds

public class YnkRedrawCallback extends DelayCallback {
  public let player: wref<PlayerPuppet>;

  public func Call() -> Void {
    if IsDefined(this.player) {
      this.player.YnkRedrawStep();
    };
  }
}

@addField(PlayerPuppet)
public let ynkRedrawStage: Int32;          // 0 idle, 1 waiting for the unequip, 2 waiting for the draw

@addField(PlayerPuppet)
public let ynkRedrawItem: ItemID;

@addField(PlayerPuppet)
public let ynkRedrawAt: Float;             // sim time the current stage started

@addMethod(PlayerPuppet)
public func YnkMeleeRedrawEligible() -> Bool {
  let item: ref<ItemObject> = GameInstance.GetTransactionSystem(this.GetGame()).GetItemInSlot(this, t"AttachmentSlots.WeaponRight");
  if !IsDefined(item) {
    return false;
  };
  let id: ItemID = item.GetItemID();
  if !WeaponObject.IsMelee(id) || WeaponObject.IsFists(id) {
    return false;
  };
  let tags: array<CName> = RPGManager.GetItemRecord(id).Tags();
  if ArrayContains(tags, n"Meleeware") {
    return false;
  };
  let bb: ref<IBlackboard> = GameInstance.GetBlackboardSystem(this.GetGame()).GetLocalInstanced(this.GetEntityID(), GetAllBlackboardDefs().PlayerStateMachine);
  return IsDefined(bb) && bb.GetInt(GetAllBlackboardDefs().PlayerStateMachine.Combat) != 1;
}

@addMethod(PlayerPuppet)
public func YnkScheduleRedraw() -> Void {
  let cb: ref<YnkRedrawCallback> = new YnkRedrawCallback();
  cb.player = this;
  GameInstance.GetDelaySystem(this.GetGame()).DelayCallback(cb, 0.1, false);
}

@addMethod(PlayerPuppet)
public func YnkBeginRedraw() -> Void {
  let item: ref<ItemObject> = GameInstance.GetTransactionSystem(this.GetGame()).GetItemInSlot(this, t"AttachmentSlots.WeaponRight");
  let request: ref<EquipmentSystemWeaponManipulationRequest> = new EquipmentSystemWeaponManipulationRequest();
  let eqSystem: wref<EquipmentSystem> = GameInstance.GetScriptableSystemsContainer(this.GetGame()).Get(n"EquipmentSystem") as EquipmentSystem;
  this.ynkRedrawItem = item.GetItemID();
  this.ynkRedrawStage = 1;
  this.ynkRedrawAt = this.YnkNow();
  request.owner = this;
  request.requestType = EquipmentManipulationAction.UnequipWeapon;
  eqSystem.QueueRequest(request);
  this.YnkScheduleRedraw();
}

@addMethod(PlayerPuppet)
public func YnkDrawRedrawItem(firstEquip: Bool) -> Void {
  let draw: ref<DrawItemRequest> = new DrawItemRequest();
  let eqSystem: wref<EquipmentSystem> = GameInstance.GetScriptableSystemsContainer(this.GetGame()).Get(n"EquipmentSystem") as EquipmentSystem;
  draw.owner = this;
  draw.itemID = this.ynkRedrawItem;
  if firstEquip {
    draw.equipAnimationType = gameEquipAnimationType.FirstEquip;
  };
  eqSystem.QueueRequest(draw);
}

@addMethod(PlayerPuppet)
public func YnkRedrawStep() -> Void {
  let elapsed: Float = this.YnkNow() - this.ynkRedrawAt;
  if this.ynkRedrawStage == 1 {
    if !this.YnkHasWeapon() {
      this.YnkDrawRedrawItem(true);
      this.ynkRedrawStage = 2;
      this.ynkRedrawAt = this.YnkNow();
    } else {
      if elapsed > YnkRedrawTimeout() {
        this.ynkRedrawStage = 0;   // the weapon never left the hand: nothing to undo
        return;
      };
    };
  } else {
    if this.ynkRedrawStage == 2 {
      if this.YnkHasWeapon() {
        this.ynkRedrawStage = 0;
        return;
      };
      if elapsed > YnkRedrawTimeout() {
        this.YnkDrawRedrawItem(false);   // the flourish draw didn't happen: don't leave the hand empty
        this.ynkRedrawStage = 0;
        return;
      };
    } else {
      return;
    };
  };
  this.YnkScheduleRedraw();
}
