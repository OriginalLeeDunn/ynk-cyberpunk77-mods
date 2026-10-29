// YNK Canto Blueprint (PC edition): gives you the crafting spec for the Militech Canto Mk.6 cyberdeck
// (Blackwall Gateway) if you never got it. The game hands it out as a Phantom Liberty quest reward and it is
// missable (side with Songbird in "Firestarter" and the blueprint is locked away). This adds the same recipe
// item the quest would have given, once, and you still craft the deck yourself with the usual materials.
// - Recipe tier follows the game's own rule for this reward: Rare below level 30, Epic 30-39, Legendary 40+.
// - Runs once per save (a quest fact remembers it). Does nothing if the quest already gave you the recipe,
//   if you already own the deck, or if Phantom Liberty isn't installed (it tries again next load).
// - Every added name is prefixed YnkCanto so it can't collide with another mod.
module YNK.CantoBlueprint

class YnkCantoCallback extends DelayCallback {
  private let m_player: wref<PlayerPuppet>;

  public func SetPlayer(player: ref<PlayerPuppet>) -> Void {
    this.m_player = player;
  }

  public func Call() -> Void {
    if IsDefined(this.m_player) {
      this.m_player.YnkCantoCheck();
    };
  }
}

@addMethod(PlayerPuppet)
public func YnkCantoNotify(text: String) -> Void {
  let msg: SimpleScreenMessage;
  msg.message = text;
  msg.isShown = true;
  msg.duration = 6.0;
  msg.type = SimpleMessageType.Neutral;
  let bb: ref<IBlackboard> = GameInstance.GetBlackboardSystem(this.GetGame()).Get(GetAllBlackboardDefs().UI_Notifications);
  bb.SetVariant(GetAllBlackboardDefs().UI_Notifications.OnscreenMessage, ToVariant(msg), true);
}

@addMethod(PlayerPuppet)
public func YnkCantoOwns(item: TweakDBID) -> Bool {
  return GameInstance.GetTransactionSystem(this.GetGame()).HasItem(this, ItemID.FromTDBID(item));
}

// Runs a few seconds after a save loads (or a new game starts).
@addMethod(PlayerPuppet)
public func YnkCantoCheck() -> Void {
  let quests: ref<QuestsSystem> = GameInstance.GetQuestsSystem(this.GetGame());
  if quests.GetFact(n"ynk_canto_blueprint_done") > 0 {
    return;
  };
  // no Phantom Liberty: the item doesn't exist, so do nothing and look again next load
  if !IsDefined(TweakDBInterface.GetItemRecord(t"Items.Recipe_Rare_HauntedCyberdeck")) {
    return;
  };
  // the quest already gave the recipe, or the deck is already yours
  if quests.GetFact(n"haunted_deck_recipe_acquired") > 0
      || this.YnkCantoOwns(t"Items.Recipe_Rare_HauntedCyberdeck") || this.YnkCantoOwns(t"Items.Recipe_Epic_HauntedCyberdeck") || this.YnkCantoOwns(t"Items.Recipe_Legendary_HauntedCyberdeck")
      || this.YnkCantoOwns(t"Items.HauntedCyberdeck_Rare") || this.YnkCantoOwns(t"Items.HauntedCyberdeck_Epic") || this.YnkCantoOwns(t"Items.HauntedCyberdeck_Legendary") {
    quests.SetFact(n"ynk_canto_blueprint_done", 1);
    return;
  };

  let level: Float = GameInstance.GetStatsSystem(this.GetGame()).GetStatValue(Cast<StatsObjectID>(this.GetEntityID()), gamedataStatType.Level);
  let recipe: TweakDBID = t"Items.Recipe_Rare_HauntedCyberdeck";
  let tier: String = "Rare";
  if level >= 40.0 {
    recipe = t"Items.Recipe_Legendary_HauntedCyberdeck";
    tier = "Legendary";
  } else {
    if level >= 30.0 {
      recipe = t"Items.Recipe_Epic_HauntedCyberdeck";
      tier = "Epic";
    };
  };
  if GameInstance.GetTransactionSystem(this.GetGame()).GiveItemByTDBID(this, recipe, 1) {
    quests.SetFact(n"ynk_canto_blueprint_done", 1);
    this.YnkCantoNotify("Militech Canto Mk.6 crafting spec added (" + tier + ")");
  };
}

// Every time the player enters the world (new game or loading a save): schedule the one-time check.
// The original is called as a statement, not assigned: another mod that wraps OnGameAttached without a
// return type turns wrappedMethod() into Void. Vanilla returns false here, so this does too.
@wrapMethod(PlayerPuppet)
protected cb func OnGameAttached() -> Bool {
  wrappedMethod();
  let callback: ref<YnkCantoCallback> = new YnkCantoCallback();
  callback.SetPlayer(this);
  GameInstance.GetDelaySystem(this.GetGame()).DelayCallback(callback, 8.0, false);
  return false;
}
