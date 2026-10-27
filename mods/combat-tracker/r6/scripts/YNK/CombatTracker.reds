// YNK Combat Tracker
// Counts V's kills and headshots during a fight, per weapon, and shows a summary on the HUD when
// combat ends. A kill outside combat (a stealth takedown, say) gets its own short message.
//
// Hooks, all checked against the game's decompiled 2.5 scripts:
//   HitReactionComponent.EvaluateHit  every hit an NPC takes; we remember V's latest hit on it
//   NPCPuppet.OnDeath                 the NPC died; gameDeathEvent.instigator says who killed it
//   PlayerPuppet.OnCombatStateChanged V leaves combat; show the fight summary
// Every hook calls wrappedMethod first or last and changes nothing in the game's own logic.

// The latest hit V landed on this NPC. Set when the hit is evaluated, read when the NPC dies.
@addField(NPCPuppet)
let ynkHitByPlayer: Bool;

@addField(NPCPuppet)
let ynkHeadshot: Bool;

@addField(NPCPuppet)
let ynkWeapon: String;

// Current fight, and totals since the game was started (not saved).
@addField(PlayerPuppet)
let ynkFightKills: Int32;

@addField(PlayerPuppet)
let ynkFightHeadshots: Int32;

@addField(PlayerPuppet)
let ynkWeaponNames: array<String>;

@addField(PlayerPuppet)
let ynkWeaponKills: array<Int32>;

@addField(PlayerPuppet)
let ynkSessionKills: Int32;

@addField(PlayerPuppet)
let ynkSessionHeadshots: Int32;

func YnkWeaponName(weapon: wref<WeaponObject>) -> String {
  if !IsDefined(weapon) {
    return "Other";
  };
  let record: ref<Item_Record> = RPGManager.GetItemRecord(weapon.GetItemID());
  if !IsDefined(record) {
    return "Other";
  };
  return GetLocalizedTextByKey(record.DisplayName());
}

@wrapMethod(HitReactionComponent)
public func EvaluateHit(newHitEvent: ref<gameHitEvent>) -> Void {
  // Record before the game evaluates the hit, so the death that follows always sees it.
  // The headshot flag is set earlier, by DamageSystem.ProcessLocalizedDamage.
  let npc: wref<NPCPuppet> = this.m_ownerNPC;
  if IsDefined(npc) && IsDefined(newHitEvent) && IsDefined(newHitEvent.attackData) {
    let attack: ref<AttackData> = newHitEvent.attackData;
    let instigator: wref<GameObject> = attack.GetInstigator();
    if IsDefined(instigator) && instigator.IsPlayer() {
      npc.ynkHitByPlayer = true;
      npc.ynkHeadshot = attack.HasFlag(hitFlag.Headshot);
      npc.ynkWeapon = YnkWeaponName(attack.GetWeapon());
    };
  };
  wrappedMethod(newHitEvent);
}

@wrapMethod(NPCPuppet)
protected cb func OnDeath(evt: ref<gameDeathEvent>) -> Bool {
  let result: Bool = wrappedMethod(evt);
  let killedByPlayer: Bool = IsDefined(evt.instigator) && evt.instigator.IsPlayer();
  if killedByPlayer {
    let player: ref<PlayerPuppet> = GameInstance.GetPlayerSystem(this.GetGame()).GetLocalPlayerMainGameObject() as PlayerPuppet;
    if IsDefined(player) {
      let headshot: Bool = this.ynkHitByPlayer && this.ynkHeadshot;
      let weapon: String = this.ynkHitByPlayer ? this.ynkWeapon : "Other";
      player.YnkRecordKill(headshot, weapon);
    };
  };
  return result;
}

@wrapMethod(PlayerPuppet)
protected cb func OnCombatStateChanged(newState: Int32) -> Bool {
  let wasInCombat: Bool = this.m_inCombat;
  let result: Bool = wrappedMethod(newState);
  if wasInCombat && !this.m_inCombat {
    this.YnkShowFightSummary();
  };
  return result;
}

@addMethod(PlayerPuppet)
public func YnkRecordKill(headshot: Bool, weapon: String) -> Void {
  this.ynkFightKills += 1;
  this.ynkSessionKills += 1;
  if headshot {
    this.ynkFightHeadshots += 1;
    this.ynkSessionHeadshots += 1;
  };
  let i: Int32 = 0;
  let found: Bool = false;
  while i < ArraySize(this.ynkWeaponNames) && !found {
    if Equals(this.ynkWeaponNames[i], weapon) {
      this.ynkWeaponKills[i] += 1;
      found = true;
    };
    i += 1;
  };
  if !found {
    ArrayPush(this.ynkWeaponNames, weapon);
    ArrayPush(this.ynkWeaponKills, 1);
  };
  // Outside combat nothing will end the "fight", so report the kill straight away.
  if !this.m_inCombat {
    this.YnkShowFightSummary();
  };
}

@addMethod(PlayerPuppet)
public func YnkShowFightSummary() -> Void {
  if this.ynkFightKills == 0 {
    return;
  };
  let top: Int32 = 0;
  let i: Int32 = 1;
  while i < ArraySize(this.ynkWeaponKills) {
    if this.ynkWeaponKills[i] > this.ynkWeaponKills[top] {
      top = i;
    };
    i += 1;
  };
  let kills: String = this.ynkFightKills == 1 ? "1 kill" : IntToString(this.ynkFightKills) + " kills";
  let percent: Int32 = this.ynkFightHeadshots * 100 / this.ynkFightKills;
  let msg: String = kills + ", " + IntToString(this.ynkFightHeadshots) + " headshots (" + IntToString(percent) + "%)"
    + ". Top weapon: " + this.ynkWeaponNames[top] + " (" + IntToString(this.ynkWeaponKills[top]) + ")"
    + ". Session: " + IntToString(this.ynkSessionKills) + " kills, " + IntToString(this.ynkSessionHeadshots) + " headshots";
  this.YnkShowMessage(msg);

  this.ynkFightKills = 0;
  this.ynkFightHeadshots = 0;
  ArrayClear(this.ynkWeaponNames);
  ArrayClear(this.ynkWeaponKills);
}

// Same HUD warning message the game uses in PlayerPuppet.SetWarningMessage. Neutral type, because
// without a type WarningMessageGameController shows the red "attention" style; the slot is shared
// with the game's own warnings, so keep it up a bit longer than the game's 5 seconds.
@addMethod(PlayerPuppet)
public func YnkShowMessage(text: String) -> Void {
  let msg: SimpleScreenMessage;
  msg.isShown = true;
  msg.duration = 8.00;
  msg.type = SimpleMessageType.Neutral;
  msg.message = text;
  GameInstance.GetBlackboardSystem(this.GetGame()).Get(GetAllBlackboardDefs().UI_Notifications).SetVariant(GetAllBlackboardDefs().UI_Notifications.WarningMessage, ToVariant(msg), true);
}
