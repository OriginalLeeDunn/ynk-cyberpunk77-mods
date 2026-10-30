// YNK Canto Blueprint (PC edition): gives you what you need to build the Militech Canto Mk.6 cyberdeck
// (Blackwall Gateway) if you never got it. The game hands out the crafting spec and the decoded Cerberus
// core as Phantom Liberty quest rewards, and both are missable (the core only exists on the Reed route of
// "Firestarter", so siding with Songbird loses both). This adds, once each per save:
// - the crafting spec (the same recipe item the quest gives), tier by the game's own rule: Rare below
//   level 30, Epic 30-39, Legendary 40+;
// - one decoded Cerberus core, only if you hold the Canto recipe and have no core, no deck and no Erebus
//   (the core is shared with the Erebus SMG, so it stays one or the other).
// You still craft the deck yourself with the components it costs. Does nothing without Phantom Liberty.
// Every added name is prefixed YnkCanto so it can't collide with another mod.
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
  // by record, not by ItemID: weapons and decks carry a unique seed, so an ItemID built from the record never matches them
  return IsDefined(GameInstance.GetTransactionSystem(this.GetGame()).GetItemDataByTDBID(this, item));
}

@addMethod(PlayerPuppet)
public func YnkCantoOwnsRecipe() -> Bool {
  return this.YnkCantoOwns(t"Items.Recipe_Rare_HauntedCyberdeck") || this.YnkCantoOwns(t"Items.Recipe_Epic_HauntedCyberdeck") || this.YnkCantoOwns(t"Items.Recipe_Legendary_HauntedCyberdeck");
}

@addMethod(PlayerPuppet)
public func YnkCantoOwnsDeck() -> Bool {
  return this.YnkCantoOwns(t"Items.HauntedCyberdeck_Rare") || this.YnkCantoOwns(t"Items.HauntedCyberdeck_Epic") || this.YnkCantoOwns(t"Items.HauntedCyberdeck_Legendary");
}

// The Erebus SMG (internally the Haunted gun) uses the same core: owning it means that choice is made.
@addMethod(PlayerPuppet)
public func YnkCantoOwnsErebus() -> Bool {
  return this.YnkCantoOwns(t"Items.Common_Borg4a_HauntedGun") || this.YnkCantoOwns(t"Items.Uncommon_Borg4a_HauntedGun") || this.YnkCantoOwns(t"Items.Rare_Borg4a_HauntedGun") || this.YnkCantoOwns(t"Items.Epic_Borg4a_HauntedGun") || this.YnkCantoOwns(t"Items.Legendary_Borg4a_HauntedGun");
}

@addMethod(PlayerPuppet)
public func YnkCantoOwnsCore() -> Bool {
  return this.YnkCantoOwns(t"Items.Q305_Cerberus_core_cracked") || this.YnkCantoOwns(t"Items.Q305_Cerberus_core_uncracked");
}

// Runs a few seconds after a save loads (or a new game starts).
@addMethod(PlayerPuppet)
public func YnkCantoCheck() -> Void {
  // no Phantom Liberty: the items don't exist, so do nothing and look again next load
  if !IsDefined(TweakDBInterface.GetItemRecord(t"Items.Recipe_Rare_HauntedCyberdeck")) {
    return;
  };
  let quests: ref<QuestsSystem> = GameInstance.GetQuestsSystem(this.GetGame());
  let transaction: ref<TransactionSystem> = GameInstance.GetTransactionSystem(this.GetGame());
  let gaveSpec: Bool = false;
  let gaveCore: Bool = false;
  let tier: String = "Rare";

  // 1. the crafting spec
  if quests.GetFact(n"ynk_canto_blueprint_done") <= 0 {
    if quests.GetFact(n"haunted_deck_recipe_acquired") > 0 || this.YnkCantoOwnsRecipe() || this.YnkCantoOwnsDeck() {
      quests.SetFact(n"ynk_canto_blueprint_done", 1);   // the quest already gave it, or the deck is yours
    } else {
      let level: Float = GameInstance.GetStatsSystem(this.GetGame()).GetStatValue(Cast<StatsObjectID>(this.GetEntityID()), gamedataStatType.Level);
      let recipe: TweakDBID = t"Items.Recipe_Rare_HauntedCyberdeck";
      if level >= 40.0 {
        recipe = t"Items.Recipe_Legendary_HauntedCyberdeck";
        tier = "Legendary";
      } else {
        if level >= 30.0 {
          recipe = t"Items.Recipe_Epic_HauntedCyberdeck";
          tier = "Epic";
        };
      };
      if transaction.GiveItemByTDBID(this, recipe, 1) {
        quests.SetFact(n"ynk_canto_blueprint_done", 1);
        gaveSpec = true;
      };
    };
  };

  // 2. the decoded Cerberus core (own flag, so players who got 1.0.0 still receive it)
  if quests.GetFact(n"ynk_canto_core_done") <= 0 {
    if this.YnkCantoOwnsDeck() || this.YnkCantoOwnsErebus() || this.YnkCantoOwnsCore() {
      quests.SetFact(n"ynk_canto_core_done", 1);   // built it, chose the Erebus, or already holds a core
    } else {
      if gaveSpec || this.YnkCantoOwnsRecipe() || quests.GetFact(n"haunted_deck_recipe_acquired") > 0 {
        if transaction.GiveItemByTDBID(this, t"Items.Q305_Cerberus_core_cracked", 1) {
          quests.SetFact(n"ynk_canto_core_done", 1);
          gaveCore = true;
        };
      };
    };
  };

  if gaveSpec && gaveCore {
    this.YnkCantoNotify("Canto Mk.6 spec (" + tier + ") + core added");
  } else {
    if gaveSpec {
      this.YnkCantoNotify("Canto Mk.6 crafting spec added (" + tier + ")");
    } else {
      if gaveCore {
        this.YnkCantoNotify("Decoded Cerberus core added");
      };
    };
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
