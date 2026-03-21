# Queen catalog and passive resolution.

def default_queen() -> Chess/Types/QueenDef:
  queen_def{
    queen_default{},
    "Default Queen",
    pawn_first_move_max{target_player{}, 2},
  }

def plus_queen() -> Chess/Types/QueenDef:
  queen_def{
    queen_plus{},
    "Queen Triarch",
    pawn_first_move_max{target_player{}, 3},
  }

def minus_queen() -> Chess/Types/QueenDef:
  queen_def{
    queen_minus{},
    "Queen Tempo",
    pawn_first_move_max{target_player{}, 1},
  }

def queen_of_id(id: Chess/Types/QueenId) -> Chess/Types/QueenDef:
  match id:
    case queen_default{}:
      default_queen()
    case queen_plus{}:
      plus_queen()
    case queen_minus{}:
      minus_queen()

def queen_name(id: Chess/Types/QueenId) -> String:
  queen_name_from_def(queen_of_id(id))

def queen_name_from_def(qd: Chess/Types/QueenDef) -> String:
  match qd:
    case queen_def{qid, name, passive}:
      name

def initial_inventory() -> Chess/Types/Inventory:
  inventory{queen_default{}, 1, 1, 1}

def is_unlocked(inv: Chess/Types/Inventory, id: Chess/Types/QueenId) -> U32:
  match inv:
    case inventory{selected, d, p, m}:
      match id:
        case queen_default{}:
          d
        case queen_plus{}:
          p
        case queen_minus{}:
          m

def buy(inv: Chess/Types/Inventory, id: Chess/Types/QueenId) -> Chess/Types/Inventory:
  match inv:
    case inventory{selected, d, p, m}:
      match id:
        case queen_default{}:
          inventory{selected, 1, p, m}
        case queen_plus{}:
          inventory{selected, d, 1, m}
        case queen_minus{}:
          inventory{selected, d, p, 1}

def select(inv: Chess/Types/Inventory, id: Chess/Types/QueenId) -> Chess/Types/Inventory:
  select_unlocked(inv, id)

def select_unlocked(inv: Chess/Types/Inventory, id: Chess/Types/QueenId) -> Chess/Types/Inventory:
  match inv:
    case inventory{selected, d, p, m}:
      inventory{id, d, p, m}

def selected_queen(inv: Chess/Types/Inventory) -> Chess/Types/QueenId:
  match inv:
    case inventory{selected, d, p, m}:
      selected

def default_rules() -> Chess/Types/RuleSet:
  ruleset{2, 2}

def resolve_rules(inv: Chess/Types/Inventory) -> Chess/Types/RuleSet:
  id = selected_queen(inv)
  qd = queen_of_id(id)
  rules_from_def(qd)

def rules_from_def(qd: Chess/Types/QueenDef) -> Chess/Types/RuleSet:
  match qd:
    case queen_def{id, name, passive}:
      apply_passive(default_rules(), passive)

def apply_passive(base: Chess/Types/RuleSet, p: Chess/Types/Passive) -> Chess/Types/RuleSet:
  match p:
    case pawn_first_move_max{target, max_steps}:
      apply_pawn_first_move_max(base, target, max_steps)

def apply_pawn_first_move_max(
  base: Chess/Types/RuleSet,
  target: Chess/Types/EffectTarget,
  max_steps: U32,
) -> Chess/Types/RuleSet:
  match base:
    case ruleset{player_max, opponent_max}:
      match target:
        case target_player{}:
          ruleset{max_steps, opponent_max}
        case target_opponent{}:
          ruleset{player_max, max_steps}
        case target_both{}:
          ruleset{max_steps, max_steps}
